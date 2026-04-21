#!/usr/bin/env python3
"""EmuELEC eka2l1 firmware, SIS installer, device selector, UID creator & lowercase converter (controller UI)."""
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present worstcase_scenario (https://github.com/worstcase-scenario)

import os
import glob
import sys
import time
import subprocess
import shutil
import re
from typing import List, Optional, Tuple
from evdev import InputDevice, list_devices, ecodes as e

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
EKA_EXE         = "/usr/bin/eka2l1/eka2l1_sdl2"
EKA_CONFIG      = "/storage/.config/eka2l1"
EKA_BIOS_DIR    = "/storage/roms/bios/eka2l1"
EKA_ROMS_DIR    = "/storage/roms/ngage"
EKA_LOG         = "/emuelec/logs/eka2l1-install.log"
EKA_CONFIG_YML  = os.path.join(EKA_CONFIG, "config.yml")
EKA_Z_DRIVES    = os.path.join(EKA_CONFIG, "data", "drives", "z")

# ---------------------------------------------------------------------------
# Exceptions
# ---------------------------------------------------------------------------
class UserQuit(Exception):
    pass

class GoBack(Exception):
    pass

# ---------------------------------------------------------------------------
# Controller
# ---------------------------------------------------------------------------
controller = None

class ControllerInput:
    def __init__(self, preferred_path: Optional[str] = None):
        self.preferred_path = preferred_path
        self.dev = wait_for_controller(preferred_path)
        self.preferred_path = getattr(self.dev, "path", preferred_path)
        self.last_hat_x = 0
        self.last_hat_y = 0

    def reconnect(self):
        old_path = getattr(self.dev, "path", self.preferred_path)
        self.close()
        self.last_hat_x = 0
        self.last_hat_y = 0
        log(f"Controller disconnected, waiting for reconnect (last path: {old_path})")
        print("\nController disconnected. Waiting for reconnect...", flush=True)
        self.dev = wait_for_controller(old_path)
        self.preferred_path = getattr(self.dev, "path", old_path)
        log(f"Controller reconnected: {self.dev.name} ({self.dev.path})")

    def wait_for_input(self) -> str:
        while True:
            try:
                for event in self.dev.read_loop():
                    if event.type == e.EV_KEY and event.value == 1:
                        code = event.code
                        if code == e.BTN_DPAD_UP:    return 'up'
                        if code == e.BTN_DPAD_DOWN:  return 'down'
                        if code == e.BTN_DPAD_LEFT:  return 'left'
                        if code == e.BTN_DPAD_RIGHT: return 'right'
                        if code in (e.BTN_SOUTH, e.BTN_START): return 'a'
                        if code == e.BTN_EAST:       return 'b'
                        if code == e.BTN_NORTH:      return 'y'
                        if code == e.BTN_WEST:       return 'x'
                        if code in (e.BTN_SELECT, e.BTN_MODE): return 'select'
                        if code == e.KEY_UP:         return 'up'
                        if code == e.KEY_DOWN:       return 'down'
                        if code == e.KEY_LEFT:       return 'left'
                        if code == e.KEY_RIGHT:      return 'right'
                        if code == e.KEY_ENTER:      return 'a'
                        if code in (e.KEY_ESC, e.KEY_BACKSPACE): return 'b'

                    if event.type == e.EV_ABS:
                        if event.code == e.ABS_HAT0Y:
                            if event.value < 0 and self.last_hat_y >= 0:
                                self.last_hat_y = event.value
                                return 'up'
                            if event.value > 0 and self.last_hat_y <= 0:
                                self.last_hat_y = event.value
                                return 'down'
                            if event.value == 0:
                                self.last_hat_y = 0
                        if event.code == e.ABS_HAT0X:
                            if event.value < 0 and self.last_hat_x >= 0:
                                self.last_hat_x = event.value
                                return 'left'
                            if event.value > 0 and self.last_hat_x <= 0:
                                self.last_hat_x = event.value
                                return 'right'
                            if event.value == 0:
                                self.last_hat_x = 0
            except OSError as ex:
                if getattr(ex, "errno", None) == 19:
                    self.reconnect()
                    continue
                raise

    def close(self):
        try:
            self.dev.close()
        except Exception:
            pass


def wait_for_controller(preferred_path: Optional[str] = None) -> InputDevice:
    print("\nWaiting for controller...", flush=True)
    if preferred_path:
        try:
            dev = InputDevice(preferred_path)
            print(f"Controller found: {dev.name} ({dev.path})", flush=True)
            return dev
        except OSError:
            pass

    while True:
        for path in list_devices():
            try:
                dev = InputDevice(path)
            except OSError:
                continue

            caps = dev.capabilities()
            keys = caps.get(e.EV_KEY, [])
            abs_caps = caps.get(e.EV_ABS, [])

            has_face = any(btn in keys for btn in (
                e.BTN_SOUTH, e.BTN_EAST, e.BTN_NORTH, e.BTN_WEST
            ))
            has_dpad = any(btn in keys for btn in (
                e.BTN_DPAD_UP, e.BTN_DPAD_DOWN, e.BTN_DPAD_LEFT, e.BTN_DPAD_RIGHT
            ))
            has_hat = any(ax in abs_caps for ax in (e.ABS_HAT0X, e.ABS_HAT0Y))

            if has_face or has_dpad or has_hat:
                print(f"Controller found: {dev.name} ({dev.path})", flush=True)
                return dev

        time.sleep(1.0)


def init_controller(preferred_path: Optional[str] = None):
    global controller
    controller = ControllerInput(preferred_path)

# ---------------------------------------------------------------------------
# Screen
# ---------------------------------------------------------------------------
def unblank_framebuffer():
    for p in ("/sys/class/graphics/fb0/blank", "/sys/class/graphics/fb1/blank"):
        try:
            with open(p, "w") as f:
                f.write("0")
        except Exception:
            pass

def clear_screen():
    unblank_framebuffer()
    print("\033[2J\033[H", end='', flush=True)

# ---------------------------------------------------------------------------
# UI Primitives
# ---------------------------------------------------------------------------
def show_menu(title: str, options: List[str], selected: int = 0,
              info: str = "", offset: int = 0, visible: int = 20) -> None:
    clear_screen()
    print("=" * 72)
    print(f"  E K A 2 L 1   C O M M A N D E R  -  {title}")
    print("=" * 72)
    if info:
        print(f"\n{info}\n")
    total = len(options)
    end = min(offset + visible, total)
    for i in range(offset, end):
        marker = "  > " if i == selected else "    "
        print(f"{marker}{options[i]}")
    if end < total:
        print("    ...")
    print("\n" + "-" * 72)
    print("D-Pad: Navigate | A: Select | B: Back | Select: Quit")
    print("-" * 72)
    sys.stdout.flush()


def select_from_list(title: str, items: List[str], info: str = "",
                     visible: int = 20) -> Optional[int]:
    if not items:
        return None

    total = len(items)
    selected = 0
    offset = 0

    while True:
        if selected < offset:
            offset = selected
        elif selected >= offset + visible:
            offset = selected - visible + 1

        offset = max(0, min(offset, max(0, total - visible)))
        show_menu(title, items, selected, info, offset, visible)

        key = controller.wait_for_input()
        if key == 'select':
            raise UserQuit()
        elif key == 'up':
            selected = max(0, selected - 1)
        elif key == 'down':
            selected = min(total - 1, selected + 1)
        elif key == 'left':
            selected = max(0, selected - visible)
        elif key == 'right':
            selected = min(total - 1, selected + visible)
        elif key == 'a':
            return selected
        elif key == 'b':
            raise GoBack()


def ok_dialog(title: str, message: str) -> None:
    while True:
        show_menu(title, ["OK"], 0, message)
        key = controller.wait_for_input()
        if key == 'select':
            raise UserQuit()
        if key in ('a', 'b'):
            return


def confirm_dialog(title: str, message: str, default_yes: bool = True) -> bool:
    options = ["Yes", "No"]
    selected = 0 if default_yes else 1

    while True:
        show_menu(title, options, selected, message)
        key = controller.wait_for_input()
        if key == 'select':
            raise UserQuit()
        elif key in ('up', 'down'):
            selected = 1 - selected
        elif key == 'a':
            return selected == 0
        elif key == 'b':
            return False

# ---------------------------------------------------------------------------
# Directory browser
# ---------------------------------------------------------------------------
def choose_directory_interactive(prompt: str, start_dir: str) -> str:
    current = os.path.abspath(start_dir)

    while True:
        try:
            entries = os.listdir(current)
            subdirs = sorted(
                d for d in entries
                if os.path.isdir(os.path.join(current, d)) and not d.startswith('.')
            )
        except Exception:
            subdirs = []

        options: List[str] = ["[Use This Directory]"]
        if current != "/":
            options.append("[.. Parent Directory]")
        options.extend(subdirs)

        idx = select_from_list(prompt, options, f"Current: {current}")
        if idx is None:
            raise GoBack()

        selected = options[idx]
        if selected == "[Use This Directory]":
            return current
        elif selected == "[.. Parent Directory]":
            parent = os.path.dirname(current)
            if parent and parent != current:
                current = parent
        else:
            current = os.path.join(current, selected)

# ---------------------------------------------------------------------------
# Log / run helper
# ---------------------------------------------------------------------------
def log(msg: str):
    try:
        with open(EKA_LOG, "a") as f:
            f.write(msg + "\n")
    except Exception:
        pass


def run_eka(args: List[str], timeout: int = 120) -> int:
    cmd = [EKA_EXE] + args
    log("Running: " + " ".join(cmd))
    print("", flush=True)

    try:
        result = subprocess.run(cmd, cwd=EKA_CONFIG, timeout=timeout)
        return result.returncode
    except subprocess.TimeoutExpired:
        log("Process timed out")
        return 0
    except Exception as ex:
        log(f"Exception: {ex}")
        return 1


def run_eka_capture(args: List[str], timeout: int = 120) -> Tuple[int, str]:
    cmd = [EKA_EXE] + args
    log("Running (capture): " + " ".join(cmd))

    try:
        result = subprocess.run(
            cmd,
            cwd=EKA_CONFIG,
            timeout=timeout,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            errors="replace",
        )
        output = result.stdout or ""
        if output:
            log(output.rstrip())
        return result.returncode, output
    except subprocess.TimeoutExpired as ex:
        output = (ex.stdout or "") if isinstance(ex.stdout, str) else ""
        if output:
            log(output.rstrip())
        log("Process timed out")
        return 124, output
    except Exception as ex:
        log(f"Exception: {ex}")
        return 1, ""


def eka_success(ret: int) -> bool:
    """eka2l1 often segfaults (exit -11 / 245) after install - treat as success."""
    return ret in (0, -11, 245)

# ---------------------------------------------------------------------------
# Device handling
# ---------------------------------------------------------------------------
def parse_listdevices_output(output: str) -> List[Tuple[int, str]]:
    devices: List[Tuple[int, str]] = []
    for raw_line in output.splitlines():
        line = raw_line.strip()
        match = re.match(r'^(\d+)\s*:\s*(.+)$', line)
        if match:
            devices.append((int(match.group(1)), match.group(2).strip()))
    return devices


def get_current_device_index() -> Optional[int]:
    if not os.path.exists(EKA_CONFIG_YML):
        return None

    try:
        with open(EKA_CONFIG_YML, "r", encoding="utf-8") as f:
            for line in f:
                match = re.match(r'^\s*device\s*:\s*([0-9]+)\s*$', line)
                if match:
                    return int(match.group(1))
    except Exception as ex:
        log(f"Failed to read config.yml: {ex}")

    return None


def set_device_index(index: int) -> None:
    os.makedirs(EKA_CONFIG, exist_ok=True)

    lines: List[str] = []
    if os.path.exists(EKA_CONFIG_YML):
        try:
            with open(EKA_CONFIG_YML, "r", encoding="utf-8") as f:
                lines = f.readlines()
        except Exception as ex:
            log(f"Failed to read existing config.yml: {ex}")
            lines = []

    replaced = False
    new_lines: List[str] = []

    for line in lines:
        if re.match(r'^\s*device\s*:\s*[0-9]+\s*$', line):
            new_lines.append(f"device: {index}\n")
            replaced = True
        else:
            new_lines.append(line)

    if not replaced:
        if new_lines and not new_lines[-1].endswith("\n"):
            new_lines[-1] += "\n"
        new_lines.append(f"device: {index}\n")

    with open(EKA_CONFIG_YML, "w", encoding="utf-8") as f:
        f.writelines(new_lines)

    log(f"Set device to {index} in {EKA_CONFIG_YML}")


def change_device():
    clear_screen()
    print("Loading device list...", flush=True)

    ret, output = run_eka_capture(["--listdevices"])
    devices = parse_listdevices_output(output)

    if ret != 0 and not devices:
        ok_dialog("Error", f"Could not get device list.\n\nSee log: {EKA_LOG}")
        return

    if not devices:
        ok_dialog("Error", "No devices found.")
        return

    current_device = get_current_device_index()
    options: List[str] = []

    for device_num, device_name in devices:
        label = f"{device_num} : {device_name}"
        if current_device is not None and device_num == current_device:
            label += "  [CURRENT]"
        options.append(label)

    info = "Select device to write into config.yml"

    try:
        idx = select_from_list("Change Device", options, info, visible=16)
    except GoBack:
        return

    if idx is None:
        return

    device_num, device_name = devices[idx]

    warning = ""
    if "Don't Select this Rom" in device_name or "brick EKA2L1" in device_name:
        warning = "\n\nWARNING:\nThis device is marked as unsafe in EKA2L1."

    if not confirm_dialog(
        "Confirm Device",
        f"Set this device?\n\n{device_num} : {device_name}{warning}"
    ):
        return

    try:
        set_device_index(device_num)
        ok_dialog("Done", f"Device changed successfully.\n\ndevice: {device_num}")
    except Exception as ex:
        log(f"Failed to write config.yml: {ex}")
        ok_dialog("Error", f"Could not write config.yml\n\nSee log: {EKA_LOG}")

# ---------------------------------------------------------------------------
# Uppercase-to-lowercase converter for device trees
# ---------------------------------------------------------------------------
def is_within_path(path: str, base: str) -> bool:
    try:
        return os.path.commonpath([os.path.abspath(path), os.path.abspath(base)]) == os.path.abspath(base)
    except Exception:
        return False


def compute_lowercase_path(path: str) -> str:
    parent = os.path.dirname(path)
    base = os.path.basename(path)
    return os.path.join(parent, base.lower())


def collect_lowercase_rename_ops(root: str) -> Tuple[List[Tuple[str, str]], List[str]]:
    ops: List[Tuple[str, str]] = []
    errors: List[str] = []

    for current_root, dirs, files in os.walk(root, topdown=False):
        for name in sorted(files):
            if name != name.lower():
                old_path = os.path.join(current_root, name)
                new_path = os.path.join(current_root, name.lower())
                ops.append((old_path, new_path))

        for name in sorted(dirs):
            if name != name.lower():
                old_path = os.path.join(current_root, name)
                new_path = os.path.join(current_root, name.lower())
                ops.append((old_path, new_path))

    root_base = os.path.basename(root)
    if root_base and root_base != root_base.lower():
        ops.append((root, compute_lowercase_path(root)))

    target_to_source: dict = {}
    for old_path, new_path in ops:
        if new_path in target_to_source and target_to_source[new_path] != old_path:
            errors.append(
                f'Collision: both\n{target_to_source[new_path]}\nand\n{old_path}\nwould become\n{new_path}'
            )
            continue

        target_to_source[new_path] = old_path

        if os.path.exists(new_path) and os.path.abspath(new_path) != os.path.abspath(old_path):
            errors.append(f'Collision: target already exists\n{new_path}')

    return ops, errors


def convert_tree_to_lowercase(root_path):
    renamed = []
    errors = []

    root_path = os.path.abspath(root_path)
    final_root = root_path

    def unique_temp_name(path):
        base = path + ".__tmp_lowercase__"
        candidate = base
        idx = 1
        while os.path.exists(candidate):
            candidate = f"{base}{idx}"
            idx += 1
        return candidate

    def safe_case_rename(src, dst):
        if src == dst:
            return src

        src_abs = os.path.abspath(src)
        dst_abs = os.path.abspath(dst)

        if src_abs.lower() == dst_abs.lower():
            tmp = unique_temp_name(src_abs)
            os.rename(src_abs, tmp)
            os.rename(tmp, dst_abs)
            return dst_abs

        if os.path.exists(dst_abs):
            raise FileExistsError(f"Target already exists: {dst_abs}")

        os.rename(src_abs, dst_abs)
        return dst_abs

    for current_root, dirs, files in os.walk(root_path, topdown=False):
        for name in files:
            src = os.path.join(current_root, name)
            dst = os.path.join(current_root, name.lower())

            if src == dst:
                continue

            try:
                new_path = safe_case_rename(src, dst)
                renamed.append((src, new_path))
                log(f"Renamed file: {src} -> {new_path}")
            except Exception as ex:
                errors.append(f"Failed to rename\n{src}\n->\n{dst}\n{ex}")
                log(f"ERROR renaming file: {src} -> {dst} ({ex})")

        for name in dirs:
            src = os.path.join(current_root, name)
            dst = os.path.join(current_root, name.lower())

            if src == dst:
                continue

            try:
                new_path = safe_case_rename(src, dst)
                renamed.append((src, new_path))
                log(f"Renamed dir: {src} -> {new_path}")
            except Exception as ex:
                errors.append(f"Failed to rename\n{src}\n->\n{dst}\n{ex}")
                log(f"ERROR renaming dir: {src} -> {dst} ({ex})")

    parent = os.path.dirname(root_path)
    base = os.path.basename(root_path)
    lower_base = base.lower()

    if base != lower_base:
        src = root_path
        dst = os.path.join(parent, lower_base)
        try:
            final_root = safe_case_rename(src, dst)
            renamed.append((src, final_root))
            log(f"Renamed root dir: {src} -> {final_root}")
        except Exception as ex:
            errors.append(f"Failed to rename\n{src}\n->\n{dst}\n{ex}")
            log(f"ERROR renaming root dir: {src} -> {dst} ({ex})")

    return renamed, errors, final_root


def convert_device_paths_to_lowercase():
    start_dir = "/storage/.config/eka2l1/data"

    try:
        target_dir = choose_directory_interactive(
            "Lowercase Converter: Select Folder",
            start_dir
        )
    except GoBack:
        return

    warning = ""
    abs_target = os.path.abspath(target_dir)

    if abs_target == "/":
        warning = "\n\nWARNING:\nThis will rename files and folders recursively from the root directory."
    elif abs_target == "/storage":
        warning = "\n\nWARNING:\nThis will rename the complete contents of /storage recursively."

    if not confirm_dialog(
        "Confirm Lowercase Conversion",
        "Convert folder names and file names to lowercase recursively?\n\n"
        f"Selected folder:\n{target_dir}{warning}"
    ):
        return

    clear_screen()
    print("Converting names to lowercase...", flush=True)

    renamed, errors, final_root = convert_tree_to_lowercase(target_dir)

    if errors:
        preview = "\n\n".join(errors[:3])
        more = ""
        if len(errors) > 3:
            more = f"\n\n... and {len(errors) - 3} more error(s)."
        ok_dialog(
            "Conversion Result",
            f"Conversion stopped with errors.\n\n"
            f"Renamed: {len(renamed)}\n"
            f"Errors: {len(errors)}\n\n"
            f"{preview}{more}\n\nSee log: {EKA_LOG}"
        )
        return

    if not renamed:
        ok_dialog(
            "Conversion Result",
            f"Nothing to rename.\n\nAll names are already lowercase in:\n{target_dir}"
        )
        return

    renamed_sorted = sorted(renamed, key=lambda item: item[1].lower())
    options = [f"{os.path.basename(new)}  <=  {os.path.basename(old)}" for old, new in renamed_sorted]
    selected = 0
    offset = 0
    visible = 14

    while True:
        if selected < offset:
            offset = selected
        elif selected >= offset + visible:
            offset = selected - visible + 1

        offset = max(0, min(offset, max(0, len(options) - visible)))
        show_menu(
            "Lowercase Conversion Result",
            options,
            selected,
            f"Converted: {len(renamed)}\nFinal folder: {final_root}\n\nPress A or B to return.",
            offset,
            visible
        )
        key = controller.wait_for_input()
        if key == "select":
            raise UserQuit()
        elif key == "up":
            selected = max(0, selected - 1)
        elif key == "down":
            selected = min(len(options) - 1, selected + 1)
        elif key == "left":
            selected = max(0, selected - visible)
        elif key == "right":
            selected = min(len(options) - 1, selected + visible)
        elif key in ("a", "b"):
            return

# ---------------------------------------------------------------------------
# Mode 1: Install firmware
# ---------------------------------------------------------------------------
def install_firmware():
    try:
        bios_dir = choose_directory_interactive(
            "Firmware: Select Directory", EKA_BIOS_DIR)
    except GoBack:
        return

    rpkg_files = sorted(glob.glob(os.path.join(bios_dir, "*.rpkg")) +
                        glob.glob(os.path.join(bios_dir, "*.RPKG")))
    rom_files = sorted(glob.glob(os.path.join(bios_dir, "*.rom")) +
                       glob.glob(os.path.join(bios_dir, "*.ROM")))

    if not rpkg_files:
        ok_dialog("Error", f"No .rpkg file found in:\n{bios_dir}")
        return
    if not rom_files:
        ok_dialog("Error", f"No .rom file found in:\n{bios_dir}")
        return

    rpkg = rpkg_files[0]
    if len(rpkg_files) > 1:
        try:
            idx = select_from_list("Select RPKG", [os.path.basename(f) for f in rpkg_files])
            if idx is None:
                return
            rpkg = rpkg_files[idx]
        except GoBack:
            return

    rom = rom_files[0]
    if len(rom_files) > 1:
        try:
            idx = select_from_list("Select ROM", [os.path.basename(f) for f in rom_files])
            if idx is None:
                return
            rom = rom_files[idx]
        except GoBack:
            return

    info = (
        f"RPKG: {os.path.basename(rpkg)}\n"
        f"ROM:  {os.path.basename(rom)}\n\n"
        f"Install firmware?"
    )
    if not confirm_dialog("Install Firmware", info):
        return

    seed_dir = os.path.join(EKA_CONFIG, "data", "roms", "rm-409")
    os.makedirs(seed_dir, exist_ok=True)
    try:
        shutil.copy2(rom, os.path.join(seed_dir, os.path.basename(rom)))
    except Exception:
        pass

    clear_screen()
    print("Installing firmware...", flush=True)
    print(f"  {os.path.basename(rpkg)}", flush=True)
    print(f"  {os.path.basename(rom)}", flush=True)
    print("\nThis may take a few minutes...", flush=True)

    ret = run_eka(["--installdevice", rpkg, rom])

    if eka_success(ret):
        ok_dialog("Done", "Firmware installed successfully!\n\n(Non-zero exit after install is normal)")
    else:
        ok_dialog("Error", f"Installation failed (code {ret})\n\nSee log: {EKA_LOG}")

# ---------------------------------------------------------------------------
# Mode 2: Install SIS games
# ---------------------------------------------------------------------------
def find_sis_files_recursive(root_dir: str) -> List[str]:
    sis_files: List[str] = []
    valid_exts = (".sis", ".sisx")
    for current_root, _, files in os.walk(root_dir):
        for name in files:
            if name.lower().endswith(valid_exts):
                sis_files.append(os.path.join(current_root, name))
    return sorted(sis_files, key=lambda p: p.lower())


def get_relative_path(path: str, base: str) -> str:
    try:
        rel = os.path.relpath(path, base)
        return rel.replace("\\", "/")
    except Exception:
        return os.path.basename(path)


def parse_listapp_to_map(output: str) -> dict:
    app_map = {}
    for name, uid in parse_listapp_output(output):
        app_map[uid.lower()] = name.strip()
    return app_map


def get_installed_apps_map() -> dict:
    ret, output = run_eka_capture(["--listapp"])
    if ret != 0 and not output.strip():
        return {}
    return parse_listapp_to_map(output)


def find_new_app_after_install(before_apps: dict, after_apps: dict) -> Optional[Tuple[str, str]]:
    new_uids = [uid for uid in after_apps if uid not in before_apps]
    if len(new_uids) == 1:
        uid = new_uids[0]
        return after_apps[uid], uid

    candidates = []
    for uid in new_uids:
        name = after_apps[uid]
        if not is_system_app(name):
            candidates.append((name, uid))

    if len(candidates) == 1:
        return candidates[0]

    if candidates:
        return candidates[0]

    return None


def find_graphic_in_same_folder(folder: str) -> Optional[str]:
    exts = (".png", ".jpg", ".jpeg", ".bmp", ".gif", ".webp")
    candidates = []

    try:
        for name in os.listdir(folder):
            full = os.path.join(folder, name)
            if os.path.isfile(full) and name.lower().endswith(exts):
                candidates.append(full)
    except Exception:
        return None

    if not candidates:
        return None

    return sorted(candidates, key=lambda p: os.path.basename(p).lower())[0]


def copy_matching_image_for_uid(source_folder: str, app_name: str, uid_output_dir: str) -> Optional[str]:
    image_src = find_graphic_in_same_folder(source_folder)
    if not image_src:
        return None

    os.makedirs(uid_output_dir, exist_ok=True)

    safe_name = sanitize_uid_name(app_name)
    ext = os.path.splitext(image_src)[1].lower()
    target_name = f"{safe_name}{ext}"
    target_path = os.path.join(uid_output_dir, target_name)

    try:
        shutil.copy2(image_src, target_path)
        log(f"Copied artwork: {image_src} -> {target_path}")
        return target_name
    except Exception as ex:
        log(f"Failed to copy artwork {image_src} -> {target_path}: {ex}")
        return None


def install_sis():
    try:
        sis_dir = choose_directory_interactive(
            "SIS/SISX: Select Directory", EKA_ROMS_DIR)
    except GoBack:
        return

    sis_files = find_sis_files_recursive(sis_dir)

    if not sis_files:
        ok_dialog("Error", f"No .sis or .sisx files found in:\n{sis_dir}")
        return

    image_out_dir = os.path.join(sis_dir, "media", "images")

    try:
        mode_idx = select_from_list(
            "SIS/SISX Installer Mode",
            [
                "Install all SIS/SISX files (recursive)",
                "Select SIS/SISX files individually (recursive)",
            ],
            f"{len(sis_files)} file(s) found recursively in:\n{sis_dir}"
        )
    except GoBack:
        return

    if mode_idx is None:
        return

    selected_files = []

    if mode_idx == 0:
        if not confirm_dialog(
            "Install All",
            f"Install all {len(sis_files)} SIS/SISX files recursively?\n\nDirectory:\n{sis_dir}"
        ):
            return
        selected_files = sis_files
    else:
        sis_options = [get_relative_path(f, sis_dir) for f in sis_files]

        try:
            selected_indexes = select_multiple_from_list(
                "Select SIS/SISX Files",
                sis_options,
                f"Directory:\n{sis_dir}\n\nToggle files with A, press Y to install.",
                visible=14
            )
        except GoBack:
            return

        if not selected_indexes:
            ok_dialog("SIS/SISX Installer", "No SIS/SISX files selected.")
            return

        selected_files = [sis_files[i] for i in selected_indexes]

        if not confirm_dialog(
            "Install Selected",
            f"Install {len(selected_files)} selected SIS/SISX file(s)?"
        ):
            return

    success = 0
    fail = 0
    failed_files = []
    artwork_copied = 0
    artwork_failed = 0

    for pos, sis_file in enumerate(selected_files, start=1):
        clear_screen()
        rel_name = get_relative_path(sis_file, sis_dir)
        print(f"Installing {pos}/{len(selected_files)}:")
        print(f"  {rel_name}")

        before_apps = get_installed_apps_map()
        ret = run_eka(["--install", sis_file])
        after_apps = get_installed_apps_map()

        if eka_success(ret):
            success += 1
            log(f"SIS/SISX installed successfully: {sis_file}")

            new_app = find_new_app_after_install(before_apps, after_apps)
            if new_app:
                app_name, uid = new_app
                copied_name = copy_matching_image_for_uid(
                    os.path.dirname(sis_file),
                    app_name,
                    image_out_dir
                )
                if copied_name:
                    artwork_copied += 1
                    log(f"Matched artwork for app '{app_name}' ({uid}): {copied_name}")
                else:
                    artwork_failed += 1
                    log(f"No artwork copied for app '{app_name}' ({uid}) from folder {os.path.dirname(sis_file)}")
            else:
                artwork_failed += 1
                log(f"Could not determine new app UID/name after install: {sis_file}")
        else:
            fail += 1
            failed_files.append(rel_name)
            log(f"SIS/SISX install failed ({ret}): {sis_file}")

    if fail == 0:
        ok_dialog(
            "Done",
            f"Installation completed successfully.\n\n"
            f"Installed: {success}\n"
            f"Failed: {fail}\n"
            f"Artwork copied: {artwork_copied}\n"
            f"Artwork unresolved: {artwork_failed}\n\n"
            f"Artwork target:\n{image_out_dir}"
        )
    else:
        preview = "\n".join(failed_files[:8])
        more = ""
        if len(failed_files) > 8:
            more = f"\n... and {len(failed_files) - 8} more"

        ok_dialog(
            "Installation Result",
            f"Completed.\n\n"
            f"Installed: {success}\n"
            f"Failed: {fail}\n"
            f"Artwork copied: {artwork_copied}\n"
            f"Artwork unresolved: {artwork_failed}\n\n"
            f"Failed files:\n{preview}{more}\n\nSee log:\n{EKA_LOG}"
        )

# ---------------------------------------------------------------------------
# UID launcher creator
# ---------------------------------------------------------------------------
def parse_listapp_output(output: str) -> List[Tuple[str, str]]:
    apps: List[Tuple[str, str]] = []
    for raw_line in output.splitlines():
        line = raw_line.strip()
        match = re.match(r'^\d+\s*:\s*(.*?)\s*\(UID:\s*(0x[0-9a-fA-F]+)\)\s*$', line)
        if match:
            name = match.group(1).strip()
            uid = match.group(2).strip().lower()
            apps.append((name, uid))
    return apps


def sanitize_uid_name(name: str) -> str:
    name = re.sub(r'[\\/:*?"<>|]', '_', name)
    name = name.replace("'", "_")
    name = re.sub(r'\s+', ' ', name).strip()
    while name.startswith('.'):
        name = '_' + name[1:]
    if not name:
        name = 'unnamed'
    return name


def is_system_app(name: str) -> bool:
    name_lc = name.lower().strip()
    system_names = {
        '', 'installer', 'applications', 'help', 'screensaver', 'telephone', 'app. manager',
        'messaging', 'recorder', 'multimedia', 'settings', 'call divert', 'sysap', 'startup',
        'voice mailbox', 'profiles', 'to-do', 'calendar', 'calculator', 'clock', 'notes',
        'speed dial', 'favourites', 'bluetooth', 'ussd', 'composer', 'fixed dialling',
        'autolock', 'save certificate', 'info message', 'bounce', 'about product',
        'services', 'pushviewer', 'download', 'realone player', 'screen shot',
        'memory card', 'converter', 'videoui', 'contacts', 'images', 'menu',
        'cell broadcast', 'log', 'e-mail', 'sim services', 'service nos.',
        'sim directory', 'radio', 'music player', 'unlockmmc'
    }
    return name_lc in system_names


def build_uid_candidates(apps: List[Tuple[str, str]]) -> Tuple[List[Tuple[str, str]], int, int, int]:
    candidates: List[Tuple[str, str]] = []
    seen_uids = set()
    skipped_system = 0
    skipped_blank = 0
    skipped_dup = 0

    for name, uid in apps:
        name = name.strip()
        uid = uid.strip().lower()

        if not name:
            skipped_blank += 1
            continue
        if uid in seen_uids:
            skipped_dup += 1
            continue
        if is_system_app(name):
            seen_uids.add(uid)
            skipped_system += 1
            continue

        seen_uids.add(uid)
        candidates.append((name, uid))

    return candidates, skipped_system, skipped_blank, skipped_dup


def show_multi_select_menu(title: str, options: List[str], checked: set, selected: int = 0,
                           info: str = "", offset: int = 0, visible: int = 16) -> None:
    clear_screen()
    print("=" * 72)
    print(f"  E K A 2 L 1   I N S T A L L E R  -  {title}")
    print("=" * 72)
    if info:
        print(f"\n{info}\n")
    total = len(options)
    end = min(offset + visible, total)
    for i in range(offset, end):
        cursor = "  > " if i == selected else "    "
        mark = "[x]" if i in checked else "[ ]"
        print(f"{cursor}{mark} {options[i]}")
    if end < total:
        print("    ...")
    print("\n" + "-" * 72)
    print("D-Pad: Navigate | A: Toggle | Y: Create Selected | B: Back | Select: Quit")
    print("-" * 72)
    sys.stdout.flush()


def select_multiple_from_list(title: str, items: List[str], info: str = "",
                              visible: int = 16) -> Optional[List[int]]:
    if not items:
        return []

    total = len(items)
    selected = 0
    offset = 0
    checked = set()

    while True:
        if selected < offset:
            offset = selected
        elif selected >= offset + visible:
            offset = selected - visible + 1

        offset = max(0, min(offset, max(0, total - visible)))
        show_multi_select_menu(title, items, checked, selected, info, offset, visible)

        key = controller.wait_for_input()
        if key == 'select':
            raise UserQuit()
        elif key == 'up':
            selected = max(0, selected - 1)
        elif key == 'down':
            selected = min(total - 1, selected + 1)
        elif key == 'left':
            selected = max(0, selected - visible)
        elif key == 'right':
            selected = min(total - 1, selected + visible)
        elif key == 'a':
            if selected in checked:
                checked.remove(selected)
            else:
                checked.add(selected)
        elif key == 'y':
            return sorted(checked)
        elif key == 'b':
            raise GoBack()


def show_available_uid_apps(candidates: List[Tuple[str, str]]) -> None:
    if not candidates:
        ok_dialog('Available Apps', 'No launchable non-system apps found.')
        return

    options = [f'{name} ({uid})' for name, uid in candidates]
    selected = 0
    offset = 0
    visible = 14

    while True:
        if selected < offset:
            offset = selected
        elif selected >= offset + visible:
            offset = selected - visible + 1

        offset = max(0, min(offset, max(0, len(options) - visible)))
        show_menu(
            'Available Apps',
            options,
            selected,
            f'Available launchable apps: {len(candidates)}\n\nPress A to continue or B to go back.',
            offset,
            visible
        )

        key = controller.wait_for_input()
        if key == 'select':
            raise UserQuit()
        elif key == 'up':
            selected = max(0, selected - 1)
        elif key == 'down':
            selected = min(len(options) - 1, selected + 1)
        elif key == 'left':
            selected = max(0, selected - visible)
        elif key == 'right':
            selected = min(len(options) - 1, selected + visible)
        elif key == 'a':
            return
        elif key == 'b':
            raise GoBack()


def show_generated_uid_list(created_entries: List[Tuple[str, str, str]], out_dir: str) -> None:
    if not created_entries:
        ok_dialog('Generated UID Files', f'No UID files were created.\n\nOutput: {out_dir}')
        return

    options = [f"{name} -> {uid} [{filename}]" for name, uid, filename in created_entries]
    selected = 0
    offset = 0
    visible = 14

    while True:
        if selected < offset:
            offset = selected
        elif selected >= offset + visible:
            offset = selected - visible + 1

        offset = max(0, min(offset, max(0, len(options) - visible)))
        show_menu(
            'Generated UID Files',
            options,
            selected,
            f'Output: {out_dir}\nCreated: {len(created_entries)}\n\nPress A or B to return.',
            offset,
            visible
        )

        key = controller.wait_for_input()
        if key == 'select':
            raise UserQuit()
        elif key == 'up':
            selected = max(0, selected - 1)
        elif key == 'down':
            selected = min(len(options) - 1, selected + 1)
        elif key == 'left':
            selected = max(0, selected - visible)
        elif key == 'right':
            selected = min(len(options) - 1, selected + visible)
        elif key in ('a', 'b'):
            return


def write_uid_files(selected_apps: List[Tuple[str, str]], out_dir: str) -> List[Tuple[str, str, str]]:
    created_entries: List[Tuple[str, str, str]] = []
    os.makedirs(out_dir, exist_ok=True)

    for name, uid in selected_apps:
        safe_name = sanitize_uid_name(name)
        target = os.path.join(out_dir, f'{safe_name}.uid')
        if os.path.exists(target):
            target = os.path.join(out_dir, f'{safe_name}_{uid}.uid')

        try:
            with open(target, 'w', encoding='utf-8') as f:
                f.write(uid + '\n')
            log(f'Created UID launcher: {target} -> {uid}')
            created_entries.append((name, uid, os.path.basename(target)))
        except Exception as ex:
            log(f'Failed to create UID launcher {target}: {ex}')

    return created_entries


def xml_escape(text: str) -> str:
    return (text.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace('"', "&quot;")
                .replace("'", "&apos;"))


def create_uid_gamelist():
    try:
        uid_dir = choose_directory_interactive(
            "Gamelist: Select UID Directory", EKA_ROMS_DIR)
    except GoBack:
        return

    uid_files = sorted(glob.glob(os.path.join(uid_dir, "*.uid")) +
                       glob.glob(os.path.join(uid_dir, "*.UID")))

    if not uid_files:
        ok_dialog("Error", f"No .uid files found in:\n{uid_dir}")
        return

    out_file = os.path.join(uid_dir, "gamelist.xml")
    image_dir = os.path.join(uid_dir, "media", "images")

    if os.path.exists(out_file):
        if not confirm_dialog(
            "Overwrite?",
            f"gamelist.xml already exists in:\n{uid_dir}\n\nOverwrite it?"
        ):
            return

    lines = ['<?xml version="1.0"?>', '<gameList>']

    for uid_file in uid_files:
        base = os.path.basename(uid_file)
        name = os.path.splitext(base)[0]

        image_tag = "./media/images/ngage.png"
        for ext in (".png", ".jpg", ".jpeg", ".bmp", ".gif", ".webp"):
            candidate = os.path.join(image_dir, name + ext)
            if os.path.exists(candidate):
                image_tag = f"./media/images/{xml_escape(name + ext)}"
                break

        lines.append('\t<game>')
        lines.append(f'\t\t<path>./{xml_escape(base)}</path>')
        lines.append(f'\t\t<name>{xml_escape(name)}</name>')
        lines.append(f'\t\t<desc>{xml_escape(name)}</desc>')
        lines.append(f'\t\t<image>{image_tag}</image>')
        lines.append('\t\t<video>./media/videos/ngage.mp4</video>')
        lines.append('\t</game>')

    lines.append('</gameList>')

    try:
        with open(out_file, "w", encoding="utf-8", newline="\n") as f:
            f.write("\n".join(lines) + "\n")
    except Exception as ex:
        log(f"Failed to write gamelist.xml {out_file}: {ex}")
        ok_dialog("Error", f"Failed to write gamelist.xml:\n{ex}")
        return

    ok_dialog(
        "Done",
        f"gamelist.xml created successfully.\n\n"
        f"UID files: {len(uid_files)}\n"
        f"Output:\n{out_file}"
    )


def create_uid_launchers():
    try:
        out_dir = choose_directory_interactive(
            'UID Creator: Select Output Directory', '/storage/roms')
    except GoBack:
        return

    clear_screen()
    print('Loading installed app list...', flush=True)

    ret, output = run_eka_capture(['--listapp'])
    apps = parse_listapp_output(output)

    if ret != 0 and not apps:
        ok_dialog('Error', f'Could not get app list.\n\nSee log: {EKA_LOG}')
        return

    if not apps:
        ok_dialog('Error', 'No installed apps found.')
        return

    candidates, skipped_system, skipped_blank, skipped_dup = build_uid_candidates(apps)
    candidates = sorted(candidates, key=lambda item: (item[0].lower(), item[1]))

    if not candidates:
        ok_dialog('Error', 'No launchable non-system apps found.')
        return

    try:
        show_available_uid_apps(candidates)
        mode_idx = select_from_list(
            'UID Creator Mode',
            ['Create all UID launcher files', 'Select apps individually'],
            f'Output: {out_dir}\n\nAvailable apps: {len(candidates)}'
        )
    except GoBack:
        return

    if mode_idx is None:
        return

    selected_apps: List[Tuple[str, str]] = []

    if mode_idx == 0:
        if not confirm_dialog(
            'Create All UID Files',
            f'Create {len(candidates)} UID launcher files in:\n\n{out_dir}'
        ):
            return
        selected_apps = candidates
    else:
        app_options = [f'{name} ({uid})' for name, uid in candidates]
        try:
            selected_indexes = select_multiple_from_list(
                'Select Apps For UID',
                app_options,
                f'Output: {out_dir}\n\nToggle apps with A, then press Y to create.',
                visible=14
            )
        except GoBack:
            return

        if not selected_indexes:
            ok_dialog('UID Creator', 'No apps selected.')
            return

        selected_apps = [candidates[i] for i in selected_indexes]

        if not confirm_dialog(
            'Create Selected UID Files',
            f'Create {len(selected_apps)} selected UID launcher files in:\n\n{out_dir}'
        ):
            return

    created_entries = write_uid_files(selected_apps, out_dir)

    ok_dialog(
        'Done',
        f'UID launcher creation finished.\n\n'
        f'Output: {out_dir}\n\n'
        f'Requested: {len(selected_apps)}\n'
        f'Created: {len(created_entries)}\n'
        f'Skipped system apps: {skipped_system}\n'
        f'Skipped blank names: {skipped_blank}\n'
        f'Skipped duplicate UIDs: {skipped_dup}'
    )

    show_generated_uid_list(created_entries, out_dir)

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
DEFAULT_CONFIG_YML = """bkg-path: ""
font: ""
log-read: false
log-write: false
log-ipc: false
log-svc: false
log-passed: false
log-exports: false
cpu: dynarmic
device: 0
language: 1
emulator-language: -1
enable-gdb-stub: false
data-storage: data
gdb-port: 24689
internet-bluetooth-port: 35689
enable-srv-rights: true
enable-srv-sa: true
enable-srv-drm: true
fbs-enable-compression-queue: false
enable-btrace: false
stop-warn-touchscreen-disabled: false
dump-imb-range-code: false
hide-mouse-in-screen-space: false
enable-nearest-neighbor-filter: true
integer-scaling: true
cpu-load-save: true
mime-detection: true
rtos-level: ""
ui-new-style: true
svg-icon-cache-reset: true
imei: 540806859904945
mmc-id: 00000000-00000000-00000000-00000000
audio-master-volume: 100
current-keybind-profile: default
screen-buffer-sync: preferred
report-mmfdev-underflow: false
disable-display-content-scale: false
device-display-name: EKA2L1
midi-backend: tsf
hsb-bank-path: resources/defaultbank.hsb
sf2-bank-path: resources/defaultbank.sf2
bt-central-server-url: btnetplay.12z1.com
background-image: ""
background-image-opacity: 255
enable-hw-gles1: true
log-filter: "*:trace"
hide-system-apps: true
btnet-port-offset: 15000
btnet-password: ""
btnet-discovery-mode: 0
enable-upnp: true
extensive-logging: false
internet-bluetooth-friends:
  []
"""


def _create_default_config():
    cfg_path = os.path.join(EKA_CONFIG, "config.yml")
    if not os.path.exists(cfg_path):
        try:
            with open(cfg_path, "w") as f:
                f.write(DEFAULT_CONFIG_YML)
            log("Created default config.yml")
            return True
        except Exception as ex:
            log(f"Failed to create config.yml: {ex}")
    return False


def _seed_bundled_files():
    install_dir = "/usr/bin/eka2l1"
    if not os.path.isdir(install_dir):
        ok_dialog("Error", f"eka2l1 install directory not found:\n{install_dir}")
        return

    clear_screen()
    print("Seeding bundled data...", flush=True)
    seeded = []

    for item in os.listdir(install_dir):
        src = os.path.join(install_dir, item)
        dst = os.path.join(EKA_CONFIG, item)
        if not os.path.exists(dst):
            try:
                if os.path.isdir(src):
                    shutil.copytree(src, dst)
                else:
                    shutil.copy2(src, dst)
                seeded.append(item)
                log(f"Seeded: {item}")
                print(f"  {item}", flush=True)
            except Exception as ex:
                log(f"Seed failed for {item}: {ex}")

    cfg_created = _create_default_config()
    if cfg_created:
        seeded.append("config.yml (default)")
        print("  config.yml (default)", flush=True)

    if seeded:
        ok_dialog("Seed Bundled Files", f"Done!\n\nCopied {len(seeded)} item(s) into:\n{EKA_CONFIG}\n\nYou can now install firmware and games.")
    else:
        ok_dialog("Seed Bundled Files", "Nothing to seed - all files already present.")


def _autoset_device_from_zdrive():
    devices_yml = os.path.join(EKA_CONFIG, "data", "devices.yml")
    z_drives_dir = os.path.join(EKA_CONFIG, "data", "drives", "z")
    cfg_path = os.path.join(EKA_CONFIG, "config.yml")

    if not os.path.isfile(devices_yml) or not os.path.isdir(z_drives_dir):
        return

    device_keys = []
    try:
        with open(devices_yml, "r") as f:
            for line in f:
                stripped = line.rstrip()
                if stripped and not stripped.startswith(" ") and stripped.endswith(":"):
                    device_keys.append(stripped[:-1])
    except Exception as ex:
        log(f"_autoset_device_from_zdrive: could not read devices.yml: {ex}")
        return

    available_z = {
        d.lower(): d for d in os.listdir(z_drives_dir)
        if os.path.isdir(os.path.join(z_drives_dir, d))
    }

    match_index = None
    for i, key in enumerate(device_keys):
        if key.lower() in available_z:
            match_index = i
            log(f"_autoset_device_from_zdrive: matched device {key} at index {i}")
            break

    if match_index is None:
        log("_autoset_device_from_zdrive: no matching Z-drive found")
        return

    if not os.path.isfile(cfg_path):
        _create_default_config()

    try:
        with open(cfg_path, "r") as f:
            lines = f.readlines()

        new_lines = []
        for line in lines:
            if line.startswith("device:"):
                new_lines.append(f"device: {match_index}\n")
            else:
                new_lines.append(line)

        with open(cfg_path, "w") as f:
            f.writelines(new_lines)

        log(f"_autoset_device_from_zdrive: set device: {match_index}")
    except Exception as ex:
        log(f"_autoset_device_from_zdrive: failed to update config.yml: {ex}")


def _import_preconfigured():
    try:
        src_dir = choose_directory_interactive(
            "Select source directory (must contain a 'data' folder)",
            "/storage/roms/bios/eka2l1"
        )
    except GoBack:
        return

    data_src = os.path.join(src_dir, "data")
    if not os.path.isdir(data_src):
        ok_dialog("Error", f"No 'data' folder found in:\n{src_dir}\n\nPlease select a directory that contains a pre-configured eka2l1 'data' folder.")
        return

    data_dst = os.path.join(EKA_CONFIG, "data")
    os.makedirs(data_dst, exist_ok=True)

    clear_screen()
    print(f"Importing data from:\n  {data_src}", flush=True)
    print("Only adding new files - existing files will not be overwritten.", flush=True)
    log(f"Importing pre-configured data from: {data_src}")

    added = 0
    skipped = 0

    for root, dirs, files in os.walk(data_src):
        rel = os.path.relpath(root, data_src)
        dst_root = os.path.join(data_dst, rel) if rel != "." else data_dst
        os.makedirs(dst_root, exist_ok=True)

        for fname in files:
            src_file = os.path.join(root, fname)
            dst_file = os.path.join(dst_root, fname)

            if fname == "devices.yml" and os.path.exists(dst_file):
                backup = dst_file + ".bak"
                try:
                    shutil.copy2(dst_file, backup)
                    shutil.copy2(src_file, dst_file)
                    log(f"Overwritten with backup: {dst_file}")
                    added += 1
                except Exception as ex:
                    log(f"Failed to overwrite devices.yml: {ex}")
                    skipped += 1
                continue

            if not os.path.exists(dst_file):
                try:
                    shutil.copy2(src_file, dst_file)
                    log(f"Added: {dst_file}")
                    added += 1
                except Exception as ex:
                    log(f"Failed to copy {src_file}: {ex}")
                    skipped += 1
            else:
                skipped += 1

    _autoset_device_from_zdrive()

    ok_dialog("Import Complete",
              f"Import finished!\n\n"
              f"Added: {added} file(s)\n"
              f"Skipped (already exist): {skipped} file(s)\n\n"
              f"devices.yml overwritten (backup: devices.yml.bak)\n"
              f"Device index auto-set to match available firmware.")


def first_run_setup():
    _seed_bundled_files()


def main():
    preferred = sys.argv[1] if len(sys.argv) > 1 else None
    init_controller(preferred)

    os.makedirs(EKA_CONFIG, exist_ok=True)

    try:
        with open(EKA_LOG, "w") as f:
            f.write("EmuELEC eka2l1 Commander Log\n")
    except Exception:
        pass

    clear_screen()
    print("Starting eka2l1 Commander...", flush=True)
    time.sleep(0.5)

    try:
        while True:
            try:
                idx = select_from_list(
                    "Main Menu",
                    [
                        "[ RUN THIS FIRST ! ] : Setup eka2l1 (copy needed files to EmuELEC)",
                        "Import pre-configured devices-collection",
                        "Install firmware (.rpkg + .rom)",
                        "Install games and apps (.sis/.sisx)",
                        "Create UID launcher-files from installed games and apps (.uid)",
                        "Create gamelist.xml from .uid launcher-files",
                        "Show / change current device",
                        "Convert uppercase device paths and files to lowercase",
                        "Exit",
                    ],
                    "What would you like to do?"
                )

                if idx is None or idx == 8:
                    break
                if idx == 0:
                    try:
                        first_run_setup()
                    except GoBack:
                        continue
                elif idx == 1:
                    try:
                        _import_preconfigured()
                    except GoBack:
                        continue
                elif idx == 2:
                    try:
                        install_firmware()
                    except GoBack:
                        continue
                elif idx == 3:
                    try:
                        install_sis()
                    except GoBack:
                        continue
                elif idx == 4:
                    try:
                        create_uid_launchers()
                    except GoBack:
                        continue
                elif idx == 5:
                    try:
                        create_uid_gamelist()
                    except GoBack:
                        continue
                elif idx == 6:
                    try:
                        change_device()
                    except GoBack:
                        continue
                elif idx == 7:
                    try:
                        convert_device_paths_to_lowercase()
                    except GoBack:
                        continue
            except GoBack:
                continue

    except UserQuit:
        pass
    except KeyboardInterrupt:
        pass
    finally:
        clear_screen()
        print("Exiting eka2l1 Commander...", flush=True)
        time.sleep(0.5)
        if controller:
            controller.close()


if __name__ == "__main__":
    main()