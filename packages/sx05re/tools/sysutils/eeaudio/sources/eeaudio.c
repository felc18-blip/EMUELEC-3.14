#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#ifdef USE_ALSA
#include <alsa/asoundlib.h>
#endif

#ifdef USE_SDL
#include <SDL2/SDL.h>
#endif

void wake_alsa_via_alsa() {
#ifdef USE_ALSA
    snd_pcm_t *pcm_handle;
    int err = snd_pcm_open(&pcm_handle, "default", SND_PCM_STREAM_PLAYBACK, 0);
    if (err < 0) {
        fprintf(stderr, "ALSA: Failed to open PCM device: %s\n", snd_strerror(err));
        return;
    }
    printf("ALSA: PCM device opened successfully.\n");

    snd_pcm_close(pcm_handle);
    printf("ALSA: PCM device closed.\n");
#else
    printf("ALSA support not compiled in.\n");
#endif
}

void wake_alsa_via_sdl() {
#ifdef USE_SDL
    if (SDL_Init(SDL_INIT_AUDIO) < 0) {
        fprintf(stderr, "SDL2: Failed to initialize SDL audio: %s\n", SDL_GetError());
        return;
    }

    SDL_AudioSpec desired, obtained;
    SDL_memset(&desired, 0, sizeof(desired));
    desired.freq = 44100;
    desired.format = AUDIO_F32SYS;
    desired.channels = 2;
    desired.samples = 512;
    desired.callback = NULL;

    if (SDL_OpenAudio(&desired, &obtained) < 0) {
        fprintf(stderr, "SDL2: Failed to open audio: %s\n", SDL_GetError());
        SDL_Quit();
        return;
    }

    printf("SDL2: Audio device opened successfully.\n");

    SDL_CloseAudio();
    SDL_Quit();
    printf("SDL2: Audio device closed.\n");
#else
    printf("SDL2 support not compiled in.\n");
#endif
}

void set_volume(const char* vol_str) {
    char command[128];
    snprintf(command, sizeof(command), "amixer sset 'Music' %s", vol_str);
    printf("Setting volume: %s\n", command);
    int ret = system(command);
    if (ret != 0) {
        fprintf(stderr, "Failed to set volume.\n");
    }
}

int main(int argc, char* argv[]) {
    if (argc == 1) {
        // Default: ALSA
        wake_alsa_via_alsa();
    } else if (argc >= 2) {
        if (strcmp(argv[1], "SDL") == 0) {
            wake_alsa_via_sdl();
        } else if (strcmp(argv[1], "vol") == 0 && argc == 3) {
            // First wake audio, then set volume
            wake_alsa_via_alsa();  // Ensure mixer is available
            set_volume(argv[2]);
        } else {
            fprintf(stderr, "Usage:\n");
            fprintf(stderr, "  %s           # Wake ALSA via ALSA API\n", argv[0]);
            fprintf(stderr, "  %s SDL       # Wake ALSA via SDL2\n", argv[0]);
            fprintf(stderr, "  %s vol 80%%   # Set 'Music' volume to 80%%\n", argv[0]);
            return 1;
        }
    }

    return 0;
}
