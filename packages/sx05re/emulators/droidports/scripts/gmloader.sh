PORTFILE="$1"
LIBSRC="/usr/config/emuelec/configs/gmloader/libc++_shared.so"

# Garante lib externa (mantém comportamento atual)
[ ! -e "/storage/roms/ports/gmloader/libc++_shared.so" ] && \
cp "$LIBSRC" "/storage/roms/ports/gmloader/libc++_shared.so"

# Injeta no .port se não existir
if ! unzip -l "$PORTFILE" | grep -q "lib/armeabi-v7a/libc++_shared.so"; then
    echo "Injetando libc++ no port..."

    mkdir -p /tmp/gmloader_fix/lib/armeabi-v7a
    cp "$LIBSRC" /tmp/gmloader_fix/lib/armeabi-v7a/

    (cd /tmp/gmloader_fix && zip -r "$PORTFILE" lib)

    rm -rf /tmp/gmloader_fix
fi

cd /storage/roms/ports/gmloader
gmloader "$PORTFILE"
