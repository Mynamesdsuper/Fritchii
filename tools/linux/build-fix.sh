#!/usr/bin/env bash
# shellcheck shell=bash
# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# Linux counterpart of the Windows build-fix.sh in AGENTS.md:
#   build-fix.sh <branch> <build-name> "<Game> - <fix>" ["ENV=VAL ..."] ["log filter"]
# Switches the source tree to <branch>, builds it, copies the programs to
# ~/lx/debug/<build-name>/ and adds a "Lichii Debug - <Game> - <fix>" desktop launcher. The
# launcher uses the normal user data (~/.local/share/eden) and copies the log next to the build.
# Env: SRC_DIR, BUILD_DIR, DEBUG_ROOT (~/lx/debug), JOBS.

set -euo pipefail

if [ $# -lt 3 ] || [ $# -gt 5 ]; then
    echo "usage: $0 <branch> <build-name> \"<Game> - <fix>\" [\"ENV=VAL ...\"] [\"log filter\"]" >&2
    exit 2
fi
branch=$1
name=$2
title=$3
env_vars=${4:-}
log_filter=${5:-}

case "$name" in
    */* | .* | '') echo "invalid build name: $name" >&2; exit 2 ;;
esac

script_dir=$(cd "$(dirname "$0")" && pwd)
SRC_DIR=${SRC_DIR:-$(cd "$script_dir/../.." && pwd)}
DEBUG_ROOT=${DEBUG_ROOT:-$HOME/lx/debug}
export SRC_DIR

if [ -n "$(git -C "$SRC_DIR" status --porcelain --untracked-files=no)" ]; then
    echo "$SRC_DIR has uncommitted changes; commit or stash them first" >&2
    exit 1
fi
git -C "$SRC_DIR" switch "$branch"
"$script_dir/build.sh"

BUILD_DIR=${BUILD_DIR:-$HOME/lx/build}
out="$DEBUG_ROOT/$name"
mkdir -p "$out"
# Unstripped, so gdb and llvm-symbolizer work on the copy.
cp "$BUILD_DIR/bin/lichii" "$BUILD_DIR/bin/eden-cli" "$out/"
git -C "$SRC_DIR" rev-parse HEAD > "$out/commit.txt"

# Env vars are split on spaces like the Windows script.
read -ra env_list <<< "$env_vars"
{
    echo '#!/usr/bin/env bash'
    for kv in "${env_list[@]}"; do
        printf 'export %q\n' "$kv"
    done
    printf 'filter=%q\n' "$log_filter"
    cat << 'EOF'
here=$(cd "$(dirname "$0")" && pwd)
# Ubuntu's soft core limit is 0, which makes systemd-coredump drop the core.
ulimit -c unlimited 2> /dev/null || true
log_dir=${XDG_DATA_HOME:-$HOME/.local/share}/eden/log
if [ -n "$filter" ]; then "$here/lichii" -x "$filter" "$@"; else "$here/lichii" "$@"; fi
status=$?
cp -f "$log_dir"/eden_log.txt* "$here/" 2> /dev/null
exit "$status"
EOF
} > "$out/run.sh"
chmod +x "$out/run.sh"

apps=${XDG_DATA_HOME:-$HOME/.local/share}/applications
mkdir -p "$apps"
desktop="$apps/lichii-debug-$name.desktop"
cat > "$desktop" << EOF
[Desktop Entry]
Type=Application
Name=Lichii Debug - $title
Comment=Debug build $name ($branch)
Exec="$out/run.sh"
Path=$out
Icon=$SRC_DIR/dist/lichii.png
Terminal=false
Categories=Game;Emulator;
EOF
chmod +x "$desktop"

echo "Build:    $out"
echo "Launcher: $desktop"
