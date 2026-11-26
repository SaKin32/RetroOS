#!/usr/bin/env bash
# RetroOS shortcut installer: run it ONCE, then double-click the "RetroOS" icon on your Desktop.
#   bash scripts/install-shortcut.sh          (add the shortcut)
#   bash scripts/install-shortcut.sh remove   (take it away again)

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"
APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
DESK="$(xdg-user-dir DESKTOP 2> /dev/null)"; DESK=${DESK:-$HOME/Desktop}
NAME=RetroOS.desktop

if [[ $1 == remove ]]; then
    rm -f "$APPS/$NAME" "$DESK/$NAME"
    echo "Shortcut removed."; exit 0
fi

mkdir -p "$APPS" "$DESK"
cat > "$APPS/$NAME" <<DESKTOP
[Desktop Entry]
Type=Application
Name=RetroOS
Comment=RetroOS Shell - OS lab in bash
Exec=bash "$SCRIPTS_DIR/launch-retroos.sh"
Terminal=false
Icon=utilities-terminal
Categories=System;TerminalEmulator;
DESKTOP
chmod +x "$APPS/$NAME"
cp "$APPS/$NAME" "$DESK/$NAME"
chmod +x "$DESK/$NAME"
# Ubuntu/GNOME: mark the icon as trusted so double-click works without asking
gio set "$DESK/$NAME" metadata::trusted true 2> /dev/null
gio set "$DESK/$NAME" metadata::gnome-desktop-trusted true 2> /dev/null

echo "Done. Shortcut added to:"
echo "   $DESK/$NAME   (Desktop)"
echo "   and the app menu (search 'RetroOS')"
echo
echo "If the icon shows a plain file icon: right-click it -> 'Allow Launching', then double-click."
echo "Do not move or rename the RetroOS_Shell folder afterwards (or just run this script again)."
