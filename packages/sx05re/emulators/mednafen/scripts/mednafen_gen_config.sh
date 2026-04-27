#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# NextOS-Elite-Edition: keyboard-only config generator.
#
# We drive mednafen with gptokeyb (gamepad → keyboard) instead of trying to map
# every gamepad's button/axis layout into mednafen's joystick bindings (the JELOS
# template approach broke on legacy USB pads using BTN_TRIGGER 288–299).
#
# Strategy: take the upstream template, then rewrite every
#   "joystick @GUID1@ @DEVICE_BTN_X@"
# fragment into a "keyboard 0x0 <scancode>" pair that matches mednafen.gptk.

. /etc/profile

TEMPLATE="${MEDNAFEN_CONFIG:-/usr/config/mednafen/mednafen.template}"
CFG="${MEDNAFEN_HOME:-/storage/.config/mednafen}/mednafen.cfg"

mkdir -p "$(dirname "$CFG")"
cp "$TEMPLATE" "$CFG"

# USB HID scancodes that line up with /usr/config/mednafen/mednafen.gptk
declare -A KB=(
    [DEVICE_BTN_EAST]=27          # A → X
    [DEVICE_BTN_SOUTH]=29         # B → Z
    [DEVICE_BTN_WEST]=22          # X → S
    [DEVICE_BTN_NORTH]=4          # Y → A
    [DEVICE_BTN_TL]=20            # L1 → Q
    [DEVICE_BTN_TR]=26            # R1 → W
    [DEVICE_BTN_TL2]=8            # L2 → E
    [DEVICE_BTN_TR2]=21           # R2 → R
    [DEVICE_BTN_TL2_MINUS]=8
    [DEVICE_BTN_TR2_MINUS]=21
    [DEVICE_BTN_START]=40         # Start → Enter
    [DEVICE_BTN_SELECT]=42        # Select → Backspace
    [DEVICE_BTN_MODE]=41          # Guide → Esc
    [DEVICE_BTN_THUMBL]=20        # L3 → Q (reuse)
    [DEVICE_BTN_THUMBR]=26        # R3 → W (reuse)
    [DEVICE_BTN_DPAD_UP]=82
    [DEVICE_BTN_DPAD_DOWN]=81
    [DEVICE_BTN_DPAD_LEFT]=80
    [DEVICE_BTN_DPAD_RIGHT]=79
    [DEVICE_BTN_AL_UP]=82
    [DEVICE_BTN_AL_DOWN]=81
    [DEVICE_BTN_AL_LEFT]=80
    [DEVICE_BTN_AL_RIGHT]=79
    [DEVICE_BTN_AR_UP]=82
    [DEVICE_BTN_AR_DOWN]=81
    [DEVICE_BTN_AR_LEFT]=80
    [DEVICE_BTN_AR_RIGHT]=79
    [DEVICE_FUNC_KEYA_MODIFIER]=224   # LCtrl (modifier slot, unused without combos)
    [DEVICE_FUNC_KEYB_MODIFIER]=226   # LAlt
)

# Convert every "joystick @GUID1@ @DEVICE_BTN_X@" → "keyboard 0x0 <scancode>"
TMP="$(mktemp)"
{
    while IFS= read -r line; do
        # Match the placeholder pattern; rewrite each occurrence
        while [[ "$line" =~ joystick[[:space:]]+@GUID1@[[:space:]]+@([A-Z0-9_]+)@ ]]; do
            tag="${BASH_REMATCH[1]}"
            sc="${KB[$tag]:-0}"
            # Escape '/' just in case (none expected, but cheap)
            line="${line//joystick @GUID1@ @${tag}@/keyboard 0x0 ${sc}}"
        done
        printf '%s\n' "$line"
    done < "$CFG"
} > "$TMP"
mv "$TMP" "$CFG"

# Strip leftover GUID placeholder if anything slipped through
sed -i 's/@GUID1@//g' "$CFG"

# Drop residual joystick lines that lost their GUID (e.g. vb right-pad axes,
# Saturn 3D-pad presets) — mednafen rejects the cfg if any survive.
# A "well-formed" joystick binding is "joystick <GUID> <button|abs>"; without
# the GUID the parser bails and refuses to load the whole file.
sed -i -E '/[[:space:]]joystick[[:space:]]+(abs_|button_)/d' "$CFG"
sed -i -E 's/[[:space:]]joystick[[:space:]]+&&[[:space:]]+joystick[[:space:]]+/ /g' "$CFG"

# Drop "command.*" entries that became "keyboard 0x0 N && keyboard 0x0 M" after
# substitution: "&&" is JELOS joystick-combo syntax, mednafen rejects it and
# only parses the first half — so e.g. command.exit fires on Enter alone, which
# then steals Start from every game. We exit via gptokeyb (Select+Start →
# SIGTERM) so we don't need these at all; keyboard hotkeys fall back to
# mednafen's compiled-in alt+shift+key defaults.
sed -i -E '/^command\.[A-Za-z_]+ keyboard 0x0 [0-9]+ (&&|\|\|)/d' "$CFG"
# Same defense for the corrupted "command.insert_eject_keyboard 0x0 N" line
# that the substitution can mangle when nested params share prefixes.
sed -i -E '/^command\.insert_eject_keyboard /d' "$CFG"

# Audio: NextOS runs PulseAudio. Sexyal's default probe lands on a non-syncing
# ALSA path on this kernel and emulation runs unthrottled (game speed-up).
# Mednafen 1.32 has no pulseaudio backend in sexyal, but SDL2 routes through
# pulse on this image — pin to sdl and audio_sync paces the frame loop.
sed -i 's|^sound\.driver .*|sound.driver sdl|' "$CFG"
sed -i 's|^sound\.device .*|sound.device default|' "$CFG"
