// NextOS joy-remap: lê /dev/input/eventN com BTN_TRIGGER+ codes (288-299)
// e cria gamepad virtual via uinput com BTN_GAMEPAD+ codes (304+).
//
// Wrappers/jogos que escutam só códigos modernos (BTN_SOUTH/EAST/etc) passam
// a enxergar o gamepad antigo.
//
// Modo dinâmico: lê SDL gamecontrollerdb.txt e gera mapping baseado no
// GUID do device. Mapping table fallback (hardcoded) cobre o "USB Gamepad"
// genérico (GUID 0300605b1008...) caso a DB falhe.
//
// Build (cross via NextOS toolchain):
//   aarch64-libreelec-linux-gnu-gcc -O2 -o joy-remap joy-remap.c
//
// Use:  joy-remap /dev/input/event2 [/path/to/gamecontrollerdb.txt]
//       (defaults to /storage/.config/SDL-GameControllerDB/gamecontrollerdb.txt
//        and /usr/share/SDL2/gamecontrollerdb.txt)

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>
#include <linux/input.h>
#include <linux/uinput.h>
#include <sys/ioctl.h>

#define MAX_BTNS 32

// SDL controller button enum order (a, b, x, y, back, guide, start,
// leftstick, rightstick, leftshoulder, rightshoulder, dpup, dpdown,
// dpleft, dpright, misc1, paddle1..4, touchpad)
typedef enum {
    SDL_A = 0, SDL_B, SDL_X, SDL_Y,
    SDL_BACK, SDL_GUIDE, SDL_START,
    SDL_LSTICK, SDL_RSTICK, SDL_LSHOULDER, SDL_RSHOULDER,
    SDL_DPUP, SDL_DPDOWN, SDL_DPLEFT, SDL_DPRIGHT,
    SDL_MISC1,
    SDL_BTN_COUNT
} sdl_btn;

// Each SDL button gets translated to a kernel evdev "modern" code that
// gamepad-aware wrappers/SDL2 expect.
static const unsigned sdl_to_kernel[SDL_BTN_COUNT] = {
    [SDL_A]         = BTN_SOUTH,    // 304
    [SDL_B]         = BTN_EAST,     // 305
    [SDL_X]         = BTN_WEST,     // 308 (XInput X)
    [SDL_Y]         = BTN_NORTH,    // 307
    [SDL_BACK]      = BTN_SELECT,   // 314
    [SDL_GUIDE]     = BTN_MODE,     // 316
    [SDL_START]     = BTN_START,    // 315
    [SDL_LSTICK]    = BTN_THUMBL,   // 317
    [SDL_RSTICK]    = BTN_THUMBR,   // 318
    [SDL_LSHOULDER] = BTN_TL,       // 310
    [SDL_RSHOULDER] = BTN_TR,       // 311
    [SDL_DPUP]      = BTN_DPAD_UP,
    [SDL_DPDOWN]    = BTN_DPAD_DOWN,
    [SDL_DPLEFT]    = BTN_DPAD_LEFT,
    [SDL_DPRIGHT]   = BTN_DPAD_RIGHT,
    [SDL_MISC1]     = BTN_TRIGGER_HAPPY,
};

// physical kernel code -> SDL button (built dynamically from DB or fallback).
// indexed by physical button index; -1 if unmapped.
static int phys_to_sdl[MAX_BTNS];

// physical button index -> physical kernel code (same order kernel reports)
static unsigned phys_codes[MAX_BTNS];
static int phys_count = 0;

// hat values from DB: hat_map[axis_id][position] -> sdl_btn (or -1)
// position bits: 1=up, 2=right, 4=down, 8=left
static int hat_to_sdl[2][9];   // [hat_id 0/1][position bit]

// axis swap: physical axis idx -> sdl axis idx (-1 if unmapped). For
// most cases identity is fine.
static int axis_remap[16];
static int axis_invert[16];

static int virt_fd = -1;
static int src_fd  = -1;
static int last_hat_x = 0, last_hat_y = 0;

// Hardcoded fallback mapping for "USB Gamepad" (Felipe's pad, GUID 0300605b1008).
// Phys codes 288-299 -> SDL buttons.
static const struct {
    unsigned in_code;
    int sdl;
} fallback_map[] = {
    { BTN_TRIGGER, SDL_X },     // 288 b0
    { BTN_THUMB,   SDL_A },     // 289 b1
    { BTN_THUMB2,  SDL_B },     // 290 b2
    { BTN_TOP,     SDL_Y },     // 291 b3
    { BTN_TOP2,    SDL_LSHOULDER }, // 292 b4
    { BTN_PINKIE,  SDL_RSHOULDER }, // 293 b5
    { BTN_BASE,    -1 },        // 294 b6 (lefttrigger - axis usually)
    { BTN_BASE2,   -1 },        // 295 b7 (righttrigger)
    { BTN_BASE3,   SDL_BACK },  // 296 b8
    { BTN_BASE4,   SDL_START }, // 297 b9
    { BTN_BASE5,   SDL_LSTICK },// 298 b10
    { BTN_BASE6,   SDL_RSTICK },// 299 b11
};
#define FALLBACK_LEN (sizeof(fallback_map)/sizeof(fallback_map[0]))

static unsigned linux_input_id_to_guid_byte(int v) {
    return (unsigned)(v & 0xff);
}

// Build SDL2-style 32-byte GUID for /dev/input/eventN device.
// GUID format (Linux SDL2): 03000000 + vendor_le4 + 0000 + product_le4 +
// 0000 + version_le4 + 0000. Each byte is 2 hex chars.
static int build_guid(int fd, char out_guid[33]) {
    struct input_id ids = {0};
    if (ioctl(fd, EVIOCGID, &ids) < 0) return -1;
    snprintf(out_guid, 33,
        "%02x000000"   // bus (low byte)
        "%02x%02x0000" // vendor le16
        "%02x%02x0000" // product le16
        "%02x%02x0000" // version le16
        "00000000",
        linux_input_id_to_guid_byte(ids.bustype),
        linux_input_id_to_guid_byte(ids.vendor),
        linux_input_id_to_guid_byte(ids.vendor >> 8),
        linux_input_id_to_guid_byte(ids.product),
        linux_input_id_to_guid_byte(ids.product >> 8),
        linux_input_id_to_guid_byte(ids.version),
        linux_input_id_to_guid_byte(ids.version >> 8));
    out_guid[32] = 0;
    return 0;
}

// Enumerate physical button kernel codes in the same order SDL2 numbers them.
// SDL2 uses udev/evdev: it iterates KEY bits 0..KEY_MAX, the "n-th set bit"
// becomes button index n.
static int enumerate_buttons(int fd) {
    unsigned long key_bits[(KEY_MAX/8/sizeof(long))+1];
    memset(key_bits, 0, sizeof(key_bits));
    if (ioctl(fd, EVIOCGBIT(EV_KEY, sizeof(key_bits)), key_bits) < 0)
        return -1;

    phys_count = 0;
    // SDL2's button order on Linux: scan in numeric order over BTN_* ranges.
    // Felipe's pad has BTN_TRIGGER..BTN_BASE6 (288-299) only.
    for (unsigned c = BTN_MISC; c < KEY_MAX && phys_count < MAX_BTNS; c++) {
        if (key_bits[c/(8*sizeof(long))] & (1UL << (c%(8*sizeof(long))))) {
            phys_codes[phys_count++] = c;
        }
    }
    return phys_count;
}

// Parse one SDL DB token like "a:b1" or "dpleft:h0.8" or "leftx:a0".
// Updates phys_to_sdl[] / hat_to_sdl[] / axis_remap[] tables.
static void parse_db_token(const char *tok) {
    const char *colon = strchr(tok, ':');
    if (!colon) return;
    char key[32];
    size_t klen = (size_t)(colon - tok);
    if (klen >= sizeof(key)) return;
    memcpy(key, tok, klen); key[klen] = 0;

    int sdl_idx = -1;
    if      (!strcmp(key, "a"))             sdl_idx = SDL_A;
    else if (!strcmp(key, "b"))             sdl_idx = SDL_B;
    else if (!strcmp(key, "x"))             sdl_idx = SDL_X;
    else if (!strcmp(key, "y"))             sdl_idx = SDL_Y;
    else if (!strcmp(key, "back"))          sdl_idx = SDL_BACK;
    else if (!strcmp(key, "guide"))         sdl_idx = SDL_GUIDE;
    else if (!strcmp(key, "start"))         sdl_idx = SDL_START;
    else if (!strcmp(key, "leftstick"))     sdl_idx = SDL_LSTICK;
    else if (!strcmp(key, "rightstick"))    sdl_idx = SDL_RSTICK;
    else if (!strcmp(key, "leftshoulder"))  sdl_idx = SDL_LSHOULDER;
    else if (!strcmp(key, "rightshoulder")) sdl_idx = SDL_RSHOULDER;
    else if (!strcmp(key, "dpup"))          sdl_idx = SDL_DPUP;
    else if (!strcmp(key, "dpdown"))        sdl_idx = SDL_DPDOWN;
    else if (!strcmp(key, "dpleft"))        sdl_idx = SDL_DPLEFT;
    else if (!strcmp(key, "dpright"))       sdl_idx = SDL_DPRIGHT;
    // Axis tokens stay identity (most engines map them right anyway).
    else return;

    const char *val = colon + 1;
    if (val[0] == 'b') {
        // button N -> sdl_idx
        int n = atoi(val + 1);
        if (n >= 0 && n < MAX_BTNS) phys_to_sdl[n] = sdl_idx;
    } else if (val[0] == 'h') {
        // hN.bit  → dpad mapping
        int hat = 0, bit = 0;
        sscanf(val + 1, "%d.%d", &hat, &bit);
        if (hat >= 0 && hat < 2 && bit > 0 && bit < 9)
            hat_to_sdl[hat][bit] = sdl_idx;
    }
}

static int load_db_mapping(const char *db_path, const char *guid) {
    FILE *fp = fopen(db_path, "r");
    if (!fp) return -1;
    char line[4096];
    int found = 0;
    while (fgets(line, sizeof(line), fp)) {
        if (line[0] == '#') continue;
        if (strncmp(line, guid, 32) != 0) continue;
        // matched
        found = 1;
        char *p = line + 33;          // past GUID + comma
        char *end = strchr(p, '\n'); if (end) *end = 0;
        // skip device name (next token before next comma)
        char *name_end = strchr(p, ','); if (!name_end) break;
        char *tok = name_end + 1;
        while (*tok) {
            char *next = strchr(tok, ',');
            if (next) *next = 0;
            if (*tok) parse_db_token(tok);
            if (!next) break;
            tok = next + 1;
        }
        break;
    }
    fclose(fp);
    return found ? 0 : -1;
}

// Apply hardcoded fallback if DB lookup failed: enumerate phys codes and map
// them by table.
static void apply_fallback(void) {
    fprintf(stderr, "[joy-remap] no DB match, applying fallback mapping\n");
    for (int i = 0; i < phys_count; i++) {
        int sdl = -1;
        for (size_t j = 0; j < FALLBACK_LEN; j++)
            if (fallback_map[j].in_code == phys_codes[i]) {
                sdl = fallback_map[j].sdl;
                break;
            }
        phys_to_sdl[i] = sdl;
    }
    // hat fallback (most pads use h0.X for dpad)
    hat_to_sdl[0][1] = SDL_DPUP;
    hat_to_sdl[0][2] = SDL_DPRIGHT;
    hat_to_sdl[0][4] = SDL_DPDOWN;
    hat_to_sdl[0][8] = SDL_DPLEFT;
}

static void cleanup(int sig) {
    (void)sig;
    if (virt_fd >= 0) {
        ioctl(virt_fd, UI_DEV_DESTROY);
        close(virt_fd);
    }
    if (src_fd >= 0) {
        ioctl(src_fd, EVIOCGRAB, 0);
        close(src_fd);
    }
    fprintf(stderr, "[joy-remap] cleanup done\n");
    exit(0);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "usage: %s /dev/input/eventN [gamecontrollerdb.txt]\n", argv[0]);
        return 1;
    }
    const char *src_path = argv[1];
    const char *db_paths[] = {
        argc >= 3 ? argv[2] : NULL,
        "/storage/.config/SDL-GameControllerDB/gamecontrollerdb.txt",
        "/usr/share/SDL2/gamecontrollerdb.txt",
        NULL,
    };

    // init mappings
    for (int i = 0; i < MAX_BTNS; i++) phys_to_sdl[i] = -1;
    for (int h = 0; h < 2; h++) for (int b = 0; b < 9; b++) hat_to_sdl[h][b] = -1;
    for (int i = 0; i < 16; i++) { axis_remap[i] = i; axis_invert[i] = 0; }

    src_fd = open(src_path, O_RDONLY);
    if (src_fd < 0) {
        fprintf(stderr, "[joy-remap] open(%s): %s\n", src_path, strerror(errno));
        return 1;
    }

    char guid[33];
    if (build_guid(src_fd, guid) == 0) {
        fprintf(stderr, "[joy-remap] device GUID: %s\n", guid);
    } else {
        guid[0] = 0;
    }

    if (enumerate_buttons(src_fd) < 0) {
        fprintf(stderr, "[joy-remap] EVIOCGBIT KEY: %s\n", strerror(errno));
        return 1;
    }
    fprintf(stderr, "[joy-remap] enumerated %d physical buttons\n", phys_count);

    int loaded = -1;
    for (int i = 0; db_paths[i] && loaded < 0; i++)
        loaded = load_db_mapping(db_paths[i], guid);

    if (loaded < 0) {
        apply_fallback();
    } else {
        fprintf(stderr, "[joy-remap] DB mapping loaded\n");
    }

    if (ioctl(src_fd, EVIOCGRAB, 1) < 0)
        fprintf(stderr, "[joy-remap] EVIOCGRAB: %s\n", strerror(errno));
    else
        fprintf(stderr, "[joy-remap] grabbed %s\n", src_path);

    virt_fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
    if (virt_fd < 0) virt_fd = open("/dev/input/uinput", O_WRONLY | O_NONBLOCK);
    if (virt_fd < 0) {
        fprintf(stderr, "[joy-remap] /dev/uinput: %s\n", strerror(errno));
        return 1;
    }

    ioctl(virt_fd, UI_SET_EVBIT, EV_KEY);
    ioctl(virt_fd, UI_SET_EVBIT, EV_ABS);
    ioctl(virt_fd, UI_SET_EVBIT, EV_SYN);

    // Declare all SDL-mapped kernel codes
    for (int i = 0; i < SDL_BTN_COUNT; i++)
        if (sdl_to_kernel[i]) ioctl(virt_fd, UI_SET_KEYBIT, sdl_to_kernel[i]);

    // Pass-through axes
    int abs_codes[] = { ABS_X, ABS_Y, ABS_Z, ABS_RX, ABS_RY, ABS_RZ,
                        ABS_HAT0X, ABS_HAT0Y };
    for (size_t i = 0; i < sizeof(abs_codes)/sizeof(abs_codes[0]); i++)
        ioctl(virt_fd, UI_SET_ABSBIT, abs_codes[i]);

    struct uinput_user_dev udev_setup = { 0 };
    snprintf(udev_setup.name, UINPUT_MAX_NAME_SIZE, "NextOS Virtual Gamepad");
    udev_setup.id.bustype = BUS_USB;
    udev_setup.id.vendor  = 0x1234;
    udev_setup.id.product = 0x5678;
    udev_setup.id.version = 1;
    for (size_t i = 0; i < sizeof(abs_codes)/sizeof(abs_codes[0]); i++) {
        int code = abs_codes[i];
        if (code == ABS_HAT0X || code == ABS_HAT0Y) {
            udev_setup.absmin[code] = -1; udev_setup.absmax[code] = 1;
        } else {
            udev_setup.absmin[code] = 0;  udev_setup.absmax[code] = 255;
            udev_setup.absflat[code] = 15;
        }
    }
    if (write(virt_fd, &udev_setup, sizeof(udev_setup)) != sizeof(udev_setup)) return 1;
    if (ioctl(virt_fd, UI_DEV_CREATE) < 0) return 1;
    fprintf(stderr, "[joy-remap] virtual gamepad ready\n");

    signal(SIGINT, cleanup);
    signal(SIGTERM, cleanup);

    // Build phys_code → sdl_idx lookup combining DB (which used button index)
    // and the order kernel reports physical codes.
    // After DB load, phys_to_sdl[N] = sdl button. After fallback, same.
    // We need: phys_code -> sdl_idx. Walk phys_codes, lookup phys_to_sdl[idx].

    struct input_event ev;
    while (1) {
        ssize_t n = read(src_fd, &ev, sizeof(ev));
        if (n != sizeof(ev)) {
            if (errno == EINTR) continue;
            break;
        }

        if (ev.type == EV_KEY) {
            // find physical index for this code
            int idx = -1;
            for (int i = 0; i < phys_count; i++)
                if (phys_codes[i] == (unsigned)ev.code) { idx = i; break; }
            if (idx < 0) continue;
            int sdl = phys_to_sdl[idx];
            if (sdl < 0 || sdl >= SDL_BTN_COUNT) continue;
            unsigned out_code = sdl_to_kernel[sdl];
            if (!out_code) continue;
            ev.code = out_code;
        } else if (ev.type == EV_ABS) {
            // Hat axes -> emit dpad button events (from hat_to_sdl)
            if (ev.code == ABS_HAT0X || ev.code == ABS_HAT0Y) {
                int hat = 0;
                int *last = (ev.code == ABS_HAT0X) ? &last_hat_x : &last_hat_y;
                int v = ev.value;
                // Compute released bit and pressed bit
                int rel_bit = 0, pre_bit = 0;
                if (ev.code == ABS_HAT0X) {
                    if (*last < 0) rel_bit = 8;       // left bit
                    else if (*last > 0) rel_bit = 2;  // right bit
                    if (v < 0) pre_bit = 8;
                    else if (v > 0) pre_bit = 2;
                } else { // HAT0Y
                    if (*last < 0) rel_bit = 1;       // up
                    else if (*last > 0) rel_bit = 4;  // down
                    if (v < 0) pre_bit = 1;
                    else if (v > 0) pre_bit = 4;
                }
                struct input_event out;
                memset(&out, 0, sizeof(out));
                out.type = EV_KEY;
                if (rel_bit && hat_to_sdl[hat][rel_bit] >= 0) {
                    out.code = sdl_to_kernel[hat_to_sdl[hat][rel_bit]];
                    out.value = 0;
                    write(virt_fd, &out, sizeof(out));
                }
                if (pre_bit && hat_to_sdl[hat][pre_bit] >= 0) {
                    out.code = sdl_to_kernel[hat_to_sdl[hat][pre_bit]];
                    out.value = 1;
                    write(virt_fd, &out, sizeof(out));
                }
                *last = v;
                // also forward the raw axis (some engines read directly)
                write(virt_fd, &ev, sizeof(ev));
                continue;
            }
            // pass other axes through
        } else if (ev.type != EV_SYN) {
            continue;
        }

        if (write(virt_fd, &ev, sizeof(ev)) != sizeof(ev)) {
            // ignore short writes; try next event
        }
    }

    cleanup(0);
    return 0;
}
