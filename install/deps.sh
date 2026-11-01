#!/usr/bin/env bash
# Installs Quickshell and runtime dependencies for Kotilo Shell on pacman, dnf or apt systems.
# Idempotent. Re-run safely. Use --dry-run to print the commands only.
set -euo pipefail

DRY=0; [[ "${1:-}" == "--dry-run" ]] && DRY=1
run() { if [[ $DRY -eq 1 ]]; then echo "+ $*"; else echo "+ $*"; "$@"; fi; }
have() { command -v "$1" >/dev/null 2>&1; }
SUDO=""; [[ $EUID -ne 0 ]] && SUDO="sudo"

# Common runtime (names differ per distro; mapped below)
# - quickshell 0.3.2, rev 2b4501a (Qt6 QML shell toolkit; quickshell-git tracks HEAD, so check `qs --version`)        - qt6 declarative + wayland + svg
# - pipewire + wireplumber (audio)             - upower (battery)
# - networkmanager, bluez (network/bt)         - brightnessctl, playerctl
# - wl-clipboard, cliphist (clipboard)         - matugen (dynamic theme), swww (wallpaper)
# - fonts: Inter, JetBrains Mono Nerd Font     - git, jq, python3 (scripts)

if have pacman; then
  echo "==> Arch-based system"
  PKGS=(qt6-declarative qt6-wayland qt6-svg qt6-5compat pipewire wireplumber upower networkmanager bluez bluez-utils
        brightnessctl playerctl wl-clipboard cliphist swww git jq python3 inter-font ttf-jetbrains-mono-nerd)
  run $SUDO pacman -S --needed --noconfirm "${PKGS[@]}"
  if ! have qs; then
    if have paru; then run paru -S --needed --noconfirm quickshell-git matugen-bin
    elif have yay; then run yay -S --needed --noconfirm quickshell-git matugen-bin
    else echo "!! Install an AUR helper (paru/yay) then: paru -S quickshell-git matugen-bin"; fi
  fi

elif have dnf; then
  echo "==> Fedora-based system"
  run $SUDO dnf install -y dnf-plugins-core
  # Quickshell COPR — see https://copr.fedorainfracloud.org (errornointernet/quickshell or current maintainer)
  run $SUDO dnf copr enable -y errornointernet/quickshell
  PKGS=(quickshell qt6-qtdeclarative qt6-qtwayland qt6-qtsvg qt6-qt5compat pipewire wireplumber upower NetworkManager bluez
        brightnessctl playerctl wl-clipboard git jq python3 rsms-inter-fonts jetbrains-mono-fonts-all)
  run $SUDO dnf install -y "${PKGS[@]}"
  echo "!! cliphist, swww, matugen: install from COPR or cargo (see docs/INSTALL-fedora.md)"

elif have apt-get; then
  echo "==> Debian/Ubuntu-based system"
  PKGS=(qt6-declarative-dev qt6-wayland libqt6svg6 qt6-5compat-dev pipewire wireplumber upower network-manager bluez
        brightnessctl playerctl wl-clipboard git jq python3 fonts-inter fonts-jetbrains-mono)
  run $SUDO apt-get update
  run $SUDO apt-get install -y "${PKGS[@]}"
  echo "!! Quickshell is not packaged for Debian/Ubuntu. Build from source: https://quickshell.outfoxxed.me/docs/guide/install/"
  echo "!! cliphist, swww, matugen: install from source or cargo"

else
  echo "Unsupported package manager. Install manually: quickshell, qt6 (declarative, wayland, svg), pipewire, upower, networkmanager, bluez, brightnessctl, playerctl, wl-clipboard, cliphist, swww, matugen, Inter, JetBrains Mono Nerd Font" >&2
  exit 1
fi

echo
have qs && echo "quickshell: $(qs --version 2>/dev/null || echo present)" || echo "!! quickshell (qs) not found on PATH yet"
echo "Done. Next: ./install/install.sh"
