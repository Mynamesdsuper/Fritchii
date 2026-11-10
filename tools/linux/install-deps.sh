#!/usr/bin/env bash
# shellcheck shell=bash
# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# Installs build and debug dependencies for a local Linux build, then Qt 6.8.3 (the CI version)
# into $QT_DIR with aqtinstall. Run as your user; it calls sudo for the package manager only.
# QT_DIR defaults to ~/lx/qt. SKIP_QT=1 skips the Qt download (use the distro Qt instead).

set -euo pipefail

QT_VERSION=6.8.3
QT_DIR=${QT_DIR:-$HOME/lx/qt}

# Same list as the Linux job in .github/workflows/release-binaries.yml, plus clang/lld, the
# debugging tools, Vulkan tools and what aqtinstall needs.
apt_pkgs=(
    autoconf cmake g++ gcc git glslang-tools libglu1-mesa-dev
    libpulse-dev libtool libudev-dev libxkbcommon-x11-0
    mesa-common-dev nasm ninja-build qt6-base-private-dev
    qt6-charts-dev qt6-tools-dev libavfilter-dev libavcodec-dev
    libswscale-dev pkg-config zlib1g-dev libva-dev libvdpau-dev
    spirv-tools spirv-headers libusb-1.0-0-dev
    libboost-dev libboost-fiber-dev libboost-context-dev
    libopus-dev libasound2-dev ccache
    libxcb-cursor0 libxcb-icccm4 libxcb-image0
    libxcb-keysyms1 libxcb-randr0 libxcb-render-util0 libxcb-shape0 libxcb-xinerama0 libxcb-xkb1
    clang-20 lld-20 clang lld llvm gdb systemd-coredump shellcheck
    vulkan-tools mesa-vulkan-drivers libvulkan1
    python3-venv curl unzip zip make bzip2
)
pacman_pkgs=(
    base-devel boost catch2 cmake enet ffmpeg fmt git glslang libzip lz4 ninja nlohmann-json
    openssl opus qt6-base qt6-multimedia qt6-charts qt6-tools sdl3 zlib zstd zip unzip
    vulkan-headers vulkan-utility-libraries vulkan-tools libusb spirv-tools spirv-headers
    clang lld llvm gdb ccache shellcheck python
)
dnf_pkgs=(
    autoconf cmake fmt-devel gcc gcc-c++ glslang hidapi-devel json-devel libtool libusb1-devel
    libzstd-devel lz4-devel nasm ninja-build openssl-devel pulseaudio-libs-devel qt6-linguist
    qt6-qtbase-private-devel qt6-qtbase-devel qt6-qtmultimedia-devel qt6-qtcharts-devel
    speexdsp-devel wayland-devel zlib-devel ffmpeg-free-devel libXext-devel boost-devel jq
    clang lld llvm gdb ccache ShellCheck vulkan-tools python3 unzip zip
)

if command -v apt-get > /dev/null; then
    sudo apt-get update
    sudo apt-get install -y --no-install-recommends "${apt_pkgs[@]}"
elif command -v pacman > /dev/null; then
    sudo pacman -Syu --needed "${pacman_pkgs[@]}"
    SKIP_QT=${SKIP_QT:-1}
elif command -v dnf > /dev/null; then
    sudo dnf install -y "${dnf_pkgs[@]}"
    SKIP_QT=${SKIP_QT:-1}
else
    echo "Unsupported distro: install the packages from docs/Deps.md by hand." >&2
    exit 1
fi

venv="$HOME/lx/aqt-venv"
make_venv() {
    [ -x "$venv/bin/pip" ] || python3 -m venv "$venv"
}

# CMakeLists.txt needs CMake 3.31+; Ubuntu 24.04 ships 3.28. Take a current one from PyPI and put
# it in ~/.local/bin, which Ubuntu's ~/.profile adds to PATH.
if ! printf '3.31\n%s\n' "$(cmake --version 2> /dev/null | sed -n '1s/[^0-9]*//p')" |
    sort -V -C; then
    make_venv
    # CMake 4 drops support for the old cmake_minimum_required of some bundled externals.
    "$venv/bin/pip" install --quiet --upgrade 'cmake>=3.31,<4'
    mkdir -p "$HOME/.local/bin"
    ln -sf "$venv/bin/cmake" "$venv/bin/ctest" "$venv/bin/cpack" "$HOME/.local/bin/"
    echo "CMake $("$venv/bin/cmake" --version | head -n 1) linked into ~/.local/bin (log in again for PATH)"
fi

# Rolling distros ship a current Qt; Ubuntu 24.04 ships 6.4, so take the CI version.
if [ "${SKIP_QT:-0}" = 1 ]; then
    exit 0
fi
if [ -x "$QT_DIR/$QT_VERSION/gcc_64/bin/qmake" ]; then
    echo "Qt $QT_VERSION already in $QT_DIR"
    exit 0
fi
make_venv
"$venv/bin/pip" install --quiet --upgrade aqtinstall
"$venv/bin/aqt" install-qt linux desktop "$QT_VERSION" linux_gcc_64 -m qtcharts -O "$QT_DIR"
echo "Qt $QT_VERSION installed in $QT_DIR/$QT_VERSION/gcc_64"
