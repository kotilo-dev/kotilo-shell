#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Installs Quickshell and runtime dependencies for Kotilo Shell on pacman, dnf or apt systems.
# Idempotent. Re-run safely. Use --dry-run to print the commands only.
set -euo pipefail

DRY=0; [[ "${1:-}" == "--dry-run" ]] && DRY=1
run() { if [[ $DRY -eq 1 ]]; then echo "+ $*"; else echo "+ $*"; "$@"; fi; }
have() { command -v "$1" >/dev/null 2>&1; }

# Quickshell is not packaged for Debian/Ubuntu, so build the pinned revision.
QS_REPO="https://github.com/quickshell-mirror/quickshell"
QS_REV="2b4501a282689792b62e94f3fb30d8f512324fe6"   # 0.3.2
build_quickshell_apt() {
  run $SUDO apt-get install -y cmake ninja-build g++ pkg-config spirv-tools libcli11-dev qt6-base-dev qt6-base-private-dev \
    qt6-declarative-dev qt6-declarative-private-dev qt6-shadertools-dev qt6-wayland-dev qt6-wayland-private-dev libwayland-dev \
    wayland-protocols libdrm-dev libgbm-dev libegl-dev libpipewire-0.3-dev libpam0g-dev libglib2.0-dev libpolkit-agent-1-dev \
    libjemalloc-dev libxcb1-dev
  local src; src="$(mktemp -d)"
  run git -C "$src" init -q
  run git -C "$src" fetch -q --depth 1 "$QS_REPO" "$QS_REV"
  run git -C "$src" checkout -q FETCH_HEAD
  run cmake -S "$src" -B "$src/build" -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCRASH_HANDLER=OFF \
    -DDISTRIBUTOR="Kotilo deps.sh" -DCMAKE_INSTALL_PREFIX=/usr \
    -DINSTALL_QML_PREFIX="lib/$(dpkg-architecture -qDEB_HOST_MULTIARCH)/qt6/qml"
  run cmake --build "$src/build"
  run $SUDO cmake --install "$src/build"
  rm -rf "$src"
}
SUDO=""; [[ $EUID -ne 0 ]] && SUDO="sudo"

# Common runtime (names differ per distro; mapped below)
# - quickshell 0.3.2 (Qt6 QML shell toolkit: Arch extra, Fedora COPR, built from source on apt systems)        - qt6 declarative + wayland + svg
# - pipewire + wireplumber (audio)             - upower (battery)
# - networkmanager, bluez (network/bt)         - brightnessctl, playerctl
# - wl-clipboard, cliphist (clipboard)         - matugen (dynamic theme), swww or awww (wallpaper)
# - fonts: Inter, JetBrains Mono Nerd Font     - git, jq, python3 (scripts)
# - gh (GitHub tab), curl (RSS and weather), procps (Performance tab), cava (audio bars)
# Not installed here: a compositor (niri or hyprland; pacman/dnf package `niri`). Testing the other one nested needs it too, plus foot.

if have pacman; then
  echo "==> Arch-based system"
  PKGS=(qt6-declarative qt6-wayland qt6-svg qt6-5compat pipewire wireplumber upower networkmanager bluez bluez-utils
        brightnessctl playerctl wl-clipboard cliphist awww dbus libnotify git jq python3 github-cli curl procps-ng cava inter-font ttf-jetbrains-mono-nerd)
  run $SUDO pacman -S --needed --noconfirm "${PKGS[@]}"
  have qs || run $SUDO pacman -S --needed --noconfirm quickshell
  if have paru; then run paru -S --needed --noconfirm matugen-bin
  elif have yay; then run yay -S --needed --noconfirm matugen-bin
  else echo "!! Optional: matugen (dynamic theme, not used in 0.1) needs an AUR helper"; fi

elif have dnf; then
  echo "==> Fedora-based system"
  run $SUDO dnf install -y dnf-plugins-core
  # Quickshell COPR — see https://copr.fedorainfracloud.org (errornointernet/quickshell or current maintainer)
  run $SUDO dnf copr enable -y errornointernet/quickshell
  PKGS=(quickshell qt6-qtdeclarative qt6-qtwayland qt6-qtsvg qt6-qt5compat pipewire wireplumber upower NetworkManager bluez
        brightnessctl playerctl wl-clipboard dbus-tools libnotify git jq python3 gh curl procps-ng cava rsms-inter-fonts jetbrains-mono-fonts-all)
  run $SUDO dnf install -y "${PKGS[@]}"
  echo "!! Optional: cliphist, swww, matugen (not used in 0.1) are not in Fedora's repos"

elif have apt-get; then
  echo "==> Debian/Ubuntu-based system"
  PKGS=(qt6-declarative-dev qt6-wayland libqt6svg6 qt6-5compat-dev pipewire wireplumber upower network-manager bluez
        brightnessctl playerctl wl-clipboard dbus libnotify-bin git jq python3 gh curl procps cava fonts-inter fonts-jetbrains-mono
        qt6-svg-plugins qml6-module-qtquick qml6-module-qtquick-effects qml6-module-qtquick-layouts
        qml6-module-qtquick-window qml6-module-qtquick-controls qml6-module-qtqml-workerscript)
  run $SUDO apt-get update
  run $SUDO apt-get install -y "${PKGS[@]}"
  have qs || build_quickshell_apt
  echo "!! Optional: cliphist, swww, matugen (not used in 0.1) need a manual install"

else
  echo "Unsupported package manager. Install manually: quickshell, qt6 (declarative, wayland, svg), pipewire, upower, networkmanager, bluez, brightnessctl, playerctl, wl-clipboard, cliphist, swww, matugen, Inter, JetBrains Mono Nerd Font" >&2
  exit 1
fi

echo
if [[ $DRY -eq 1 ]]; then echo "quickshell: dry run, not checked"
elif have qs; then echo "quickshell: $(qs --version 2>/dev/null || echo present)"
else echo "!! quickshell (qs) not found on PATH"; exit 1; fi
echo "Done. Next: ./install/install.sh"
