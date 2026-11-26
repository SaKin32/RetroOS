#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if command -v gnome-terminal >/dev/null 2>&1; then
    exec gnome-terminal --title=RetroOS -- bash -c "cd \"$DIR\" && bash retroos.sh"

elif command -v konsole >/dev/null 2>&1; then
    exec konsole -e bash -c "cd \"$DIR\" && bash retroos.sh"

elif command -v xfce4-terminal >/dev/null 2>&1; then
    exec xfce4-terminal -x bash -c "cd \"$DIR\" && bash retroos.sh"

else
    echo "Starting RetroOS in current terminal..."
    cd "$DIR"
    exec bash retroos.sh
fi
