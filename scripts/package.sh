#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Builds a release tarball and bumps version strings in packaging metadata.
# Usage: scripts/package.sh <version>   e.g. scripts/package.sh 0.1.0
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
VER="${1:-}"; [[ -n "$VER" ]] || { echo "usage: $0 <version>"; exit 1; }

scripts/test.sh

sed -i -E "s/readonly property string version: \"[^\"]+\"/readonly property string version: \"$VER\"/" Shell/Shell.qml
sed -i -E "s/^pkgver=.*/pkgver=$VER/" packaging/aur/PKGBUILD
sed -i -E "s/^Version:\s+.*/Version:        $VER/" packaging/copr/kotilo-shell.spec
sed -i -E "s/version = \"[^\"]+\";/version = \"$VER\";/" packaging/nix/flake.nix

mkdir -p dist
tar --exclude='./ref' --exclude='./dist' --exclude='./.git' --exclude='*.log' \
    --transform "s,^\.,kotilo-shell-$VER," -czf "dist/kotilo-shell-$VER.tar.gz" .
# PKGBUILD and the COPR spec fetch GitHub's tag archive, which has a different hash from this
# tarball and cannot be known inside the tag. Set sha256sums when publishing to the AUR.
sha=$(sha256sum "dist/kotilo-shell-$VER.tar.gz" | cut -d' ' -f1)
echo "dist/kotilo-shell-$VER.tar.gz  sha256 $sha"
echo "Next: update CHANGELOG.md, git tag v$VER, push, publish AUR/COPR, run nix flake update."
