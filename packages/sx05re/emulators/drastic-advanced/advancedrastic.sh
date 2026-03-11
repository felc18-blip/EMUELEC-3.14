#!/bin/sh

. /etc/profile

@LIBEGL@

CONFIG_DIR="/storage/.config/drastic-advanced"

cd "${CONFIG_DIR}"

exec ./drastic "$@"