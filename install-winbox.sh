#!/usr/bin/env bash
# Installs MikroTik WinBox 4 (native Linux build) from the official mikrotik.com site.
# Installs into the user's home directory, no sudo and no wine.
#
#   ./install-winbox.sh            — install / update to the latest version
#   ./install-winbox.sh --remove   — uninstall (and optionally remove the firewall rules)
#   ./install-winbox.sh --firewall — only add the firewall rules for the Neighbors tab

set -euo pipefail

FALLBACK_VERSION="4.4"
INSTALL_DIR="$HOME/.local/opt/WinBox"
BIN_LINK="$HOME/.local/bin/winbox"
DESKTOP_FILE="$HOME/.local/share/applications/winbox.desktop"

# Incoming UDP ports WinBox needs to see routers in the Neighbors tab:
#   5678  — MNDP (MikroTik Neighbor Discovery Protocol)
#   20561 — connecting to a router by MAC address
FW_PORTS=(5678 20561)
FW_COMMENT="WinBox Neighbors"

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

# ask "Question" [y|n] — returns 0 on "yes". Without a terminal, assumes "no".
ask() {
    local def="${2:-y}" hint reply
    [[ $def == y ]] && hint="[Y/n]" || hint="[y/N]"
    [[ -t 0 ]] || return 1
    read -rp "$1 $hint " reply || return 1
    reply="${reply:-$def}"
    [[ $reply =~ ^[Yy] ]]
}

# Sets FW (firewalld | ufw | nftables | empty) and FW_ON (1 — enabled)
detect_firewall() {
    FW="" FW_ON=0
    if command -v firewall-cmd >/dev/null; then
        FW=firewalld
        [[ "$(firewall-cmd --state 2>/dev/null)" == running ]] && FW_ON=1
    elif command -v ufw >/dev/null; then
        FW=ufw
        grep -qE '^ENABLED=yes' /etc/ufw/ufw.conf 2>/dev/null && FW_ON=1
    elif command -v nft >/dev/null && systemctl is-enabled -q nftables 2>/dev/null; then
        FW=nftables
        systemctl is-active -q nftables && FW_ON=1
    fi
    return 0
}

# firewall_rules add|remove
firewall_rules() {
    local op="$1" p
    case "$FW" in
        ufw)
            for p in "${FW_PORTS[@]}"; do
                if [[ $op == add ]]; then
                    sudo ufw allow proto udp to any port "$p" comment "$FW_COMMENT"
                else
                    sudo ufw delete allow proto udp to any port "$p" || true
                fi
            done
            ;;
        firewalld)
            local cmd=(firewall-cmd --permanent)
            [[ $FW_ON == 1 ]] || cmd=(firewall-offline-cmd)
            for p in "${FW_PORTS[@]}"; do
                sudo "${cmd[@]}" "--$op-port=$p/udp" || [[ $op == remove ]]
            done
            if [[ $FW_ON == 1 ]]; then sudo firewall-cmd --reload; fi
            ;;
        nftables)
            # Everyone's nftables config is different — don't edit it automatically
            echo "   Add this line to the input chain in /etc/nftables.conf:"
            local list; list="$(printf '%s, ' "${FW_PORTS[@]}")"
            echo "       udp dport { ${list%, } } accept comment \"$FW_COMMENT\""
            echo "   then run: sudo systemctl reload nftables"
            ;;
    esac
}

setup_firewall() {
    echo
    echo "WinBox discovers routers (Neighbors tab) via incoming UDP ports ${FW_PORTS[*]}."
    echo "If the firewall blocks them, the neighbor list stays empty."
    ask "Add a firewall rule for these ports?" y || { echo "   Skipped. Later: $0 --firewall"; return 0; }

    detect_firewall
    if [[ -z $FW ]]; then
        echo "   No firewall (ufw, firewalld, nftables) found — nothing is blocking, no rules needed."
        return 0
    fi

    if [[ $FW_ON == 1 ]]; then
        echo "==> Firewall $FW is enabled, adding rules (sudo password required)"
    else
        echo "   Firewall $FW is installed but disabled — it is not blocking anything right now."
        ask "   Add the rule anyway (takes effect once the firewall is enabled)?" n || { echo "   Skipped."; return 0; }
        echo "==> Adding rules to $FW (sudo password required)"
    fi
    firewall_rules add && echo "   Rules for UDP ${FW_PORTS[*]} added."
}

if [[ $EUID -eq 0 ]]; then
    echo "Do not run as root/sudo — WinBox is installed for the current user." >&2
    exit 1
fi

if [[ "${1:-}" == "--firewall" ]]; then
    setup_firewall
    exit 0
fi

if [[ "${1:-}" == "--remove" ]]; then
    pkill -x WinBox 2>/dev/null || true
    rm -rf "$INSTALL_DIR"
    rm -f "$BIN_LINK" "$DESKTOP_FILE"
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    echo "WinBox removed."
    detect_firewall
    if [[ $FW == ufw || $FW == firewalld ]] && ask "Remove the $FW rules for UDP ${FW_PORTS[*]}?" n; then
        firewall_rules remove
    fi
    exit 0
fi

for cmd in curl unzip sha256sum; do
    command -v "$cmd" >/dev/null || { echo "Required program '$cmd' is missing (sudo apt install $cmd)" >&2; exit 1; }
done

echo "==> Looking up the latest WinBox version on mikrotik.com"
URL="$(curl -fsSL https://mikrotik.com/download/winbox 2>/dev/null \
    | grep -oE 'https://download\.mikrotik\.com/routeros/winbox/[0-9.]+/WinBox_Linux\.zip' \
    | sort -uV | tail -n1 || true)"
if [[ -z "$URL" ]]; then
    URL="https://download.mikrotik.com/routeros/winbox/$FALLBACK_VERSION/WinBox_Linux.zip"
    echo "   Could not detect the version from the page, using $FALLBACK_VERSION"
fi
VERSION="$(sed -E 's#.*/winbox/([0-9.]+)/.*#\1#' <<<"$URL")"

TMP="$(mktemp -d)"

echo "==> Downloading WinBox $VERSION"
curl -fL --progress-bar -o "$TMP/WinBox_Linux.zip" "$URL"

echo "==> Verifying SHA256"
if EXPECTED="$(curl -fsSL "$URL.sha256" | awk '{print $1}')" && [[ -n "$EXPECTED" ]]; then
    ACTUAL="$(sha256sum "$TMP/WinBox_Linux.zip" | awk '{print $1}')"
    [[ "$EXPECTED" == "$ACTUAL" ]] || { echo "Checksum mismatch!" >&2; exit 1; }
    echo "   OK"
else
    echo "   Checksum file not available, skipping"
fi

mkdir -p "$TMP/x"
unzip -q "$TMP/WinBox_Linux.zip" -d "$TMP/x"
[[ -f "$TMP/x/WinBox" ]] || { echo "Unexpected archive contents" >&2; exit 1; }
chmod +x "$TMP/x/WinBox"

echo "==> Installing to $INSTALL_DIR"
pkill -x WinBox 2>/dev/null && sleep 1 || true
rm -rf "$INSTALL_DIR"
mkdir -p "$(dirname "$INSTALL_DIR")"
mv "$TMP/x" "$INSTALL_DIR"

mkdir -p "$(dirname "$BIN_LINK")"
ln -sf "$INSTALL_DIR/WinBox" "$BIN_LINK"

mkdir -p "$(dirname "$DESKTOP_FILE")"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=WinBox
Comment=MikroTik RouterOS management ($VERSION)
Exec="$INSTALL_DIR/WinBox"
Icon=$INSTALL_DIR/assets/img/winbox.png
Terminal=false
Type=Application
Categories=Network;System;
StartupWMClass=WinBox
Keywords=mikrotik;routeros;router;
EOF
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

# Check system libraries (Qt/xcb)
MISSING="$(ldd "$INSTALL_DIR/WinBox" 2>/dev/null | awk '/not found/{print $1}' || true)"
if [[ -n "$MISSING" ]]; then
    echo "!! Missing libraries:"; echo "$MISSING" | sed 's/^/   /'
    echo "   Usually fixed with:"
    echo "   sudo apt install libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-render-util0 libxcb-xkb1 libxkbcommon-x11-0 libxcb-cursor0"
fi

setup_firewall

echo
echo "==> Done. WinBox $VERSION is in the applications menu, or run: winbox"
