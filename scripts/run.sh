#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

clear
echo -e "\033[?25h"

if [ ! -f "$DIR/retroos.sh" ]; then
    echo "Error: retroos.sh not found!"
    exit 1
fi

cd "$DIR"
exec bash "$DIR/retroos.sh" "$@"
