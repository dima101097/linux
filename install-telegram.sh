#!/usr/bin/env bash
# Installs Telegram Desktop from the official site (tar.xz), no snap/flatpak.
# Installs into the user's home directory (no sudo), so the built-in auto-updater works.
#
#   ./install-telegram.sh            — install / reinstall
#   ./install-telegram.sh --remove   — uninstall (account data in ~/.local/share/TelegramDesktop is kept)

set -euo pipefail

URL="https://telegram.org/dl/desktop/linux"
INSTALL_DIR="$HOME/.local/opt/Telegram"
BIN_LINK="$HOME/.local/bin/telegram"

TMP=""

# On exit: clean up and keep the terminal open for 5 s or until a key is pressed
finish() {
    if [[ -n $TMP ]]; then rm -rf "$TMP"; fi
    if [[ -t 0 ]]; then
        echo
        read -rsn1 -t 5 -p "Press any key to close (closing automatically in 5 s)..." || true
        echo
    fi
}
trap finish EXIT

if [[ $EUID -eq 0 ]]; then
    echo "Do not run as root/sudo — Telegram is installed for the current user." >&2
    exit 1
fi

if [[ "${1:-}" == "--remove" ]]; then
    pkill -x Telegram 2>/dev/null || true
    rm -rf "$INSTALL_DIR"
    rm -f "$BIN_LINK" "$HOME"/.local/share/applications/org.telegram.desktop*.desktop
    rm -f "$HOME"/.local/share/icons/hicolor/*/apps/org.telegram.desktop*
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    echo "Telegram removed."
    exit 0
fi

if [[ "$(uname -m)" != "x86_64" ]]; then
    echo "The official Telegram Linux build is x86_64 only." >&2
    exit 1
fi

for cmd in curl tar xz; do
    command -v "$cmd" >/dev/null || { echo "Required program '$cmd' is missing (sudo apt install $cmd)" >&2; exit 1; }
done

TMP="$(mktemp -d)"

echo "==> Downloading Telegram from $URL"
curl -fL --progress-bar -o "$TMP/tsetup.tar.xz" "$URL"
tar -xJf "$TMP/tsetup.tar.xz" -C "$TMP"
[[ -x "$TMP/Telegram/Telegram" ]] || { echo "Unexpected archive contents" >&2; exit 1; }

echo "==> Installing to $INSTALL_DIR"
pkill -x Telegram 2>/dev/null && sleep 1 || true
rm -rf "$INSTALL_DIR"
mkdir -p "$(dirname "$INSTALL_DIR")"
mv "$TMP/Telegram" "$INSTALL_DIR"

mkdir -p "$(dirname "$BIN_LINK")"
ln -sf "$INSTALL_DIR/Telegram" "$BIN_LINK"

# On first launch Telegram creates its own menu entry, icon and tg:// handler
echo "==> First launch (Telegram registers itself in the applications menu)"
nohup "$INSTALL_DIR/Telegram" >/dev/null 2>&1 &
disown

echo "==> Done. Telegram is in the applications menu, or run: telegram"
echo "    It updates itself via the built-in updater."
