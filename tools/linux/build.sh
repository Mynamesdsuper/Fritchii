#!/usr/bin/env bash
# shellcheck shell=bash
# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# Builds lichii and eden-cli in BUILD_DIR (default ~/lx/build), configuring it first if needed.
# Env: BUILD_DIR, JOBS (default nproc). Extra arguments go to cmake --build.

set -euo pipefail

BUILD_DIR=${BUILD_DIR:-$HOME/lx/build}
JOBS=${JOBS:-$(nproc)}
export BUILD_DIR

if [ ! -f "$BUILD_DIR/build.ninja" ]; then
    "$(dirname "$0")/configure.sh"
fi
cmake --build "$BUILD_DIR" --target yuzu yuzu-cmd --parallel "$JOBS" "$@"
