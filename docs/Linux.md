# Linux

Local Linux builds use the scripts in `tools/linux/`. They take the same CMake options as the
`linux-x86_64` job in `.github/workflows/release-binaries.yml`, with `RelWithDebInfo` instead of
`Release` so gdb and `llvm-symbolizer` have symbols.

## Setup

```sh
tools/linux/install-deps.sh   # apt (Ubuntu 24.04+), pacman or dnf; asks for sudo
```

On Ubuntu 24.04 it also installs Qt 6.8.3 (the CI version) into `~/lx/qt` with aqtinstall and a
CMake 3.31 into `~/.local/bin` (the distro has Qt 6.4 and CMake 3.28; log in again for `PATH`).
Arch and Fedora use the distro Qt (`SKIP_QT=1` does the same on Ubuntu).

## Build

```sh
tools/linux/configure.sh      # ~/lx/build, clang 19+ and lld if present (else gcc), ccache
tools/linux/build.sh          # lichii and eden-cli with $(nproc) jobs
```

clang 18 and older crash on `ioctl_serialization.h`; on Ubuntu 24.04 `install-deps.sh` adds
`clang-20` from the distro repo.

Environment overrides: `BUILD_DIR`, `BUILD_TYPE`, `QT_DIR`, `CC`/`CXX`, `JOBS`. Extra arguments
go to `cmake` (configure) or `cmake --build` (build). Programs end up in `~/lx/build/bin/`.

`tools/linux/pgo.sh` builds like the `linux-x86_64-pgo` job (needs `clang-23` from apt.llvm.org,
or set `PGO_LLVM_VERSION`) into `~/lx/build-pgo`.

## Debug builds for a fix

```sh
tools/linux/build-fix.sh <branch> <build-name> "<Game> - <fix>" ["ENV=VAL ..."] ["log filter"]
```

Same contract as the Windows script in `AGENTS.md`. It switches the checkout to `<branch>`
(refuses with uncommitted changes), builds, and copies `lichii` and `eden-cli` (unstripped) into
`~/lx/debug/<build-name>/`. It writes a `run.sh` there that exports the env vars and starts
`lichii -x "<log filter>"`, and a launcher `Lichii Debug - <Game> - <fix>` in
`~/.local/share/applications/`. The build uses the normal user data in `~/.local/share/eden`.
When it exits, `run.sh` copies `eden_log.txt*` from `~/.local/share/eden/log/` into the build
folder.

## Crash debugging

A host crash (the log just stops) leaves a core dump with systemd-coredump:

```sh
coredumpctl list lichii
coredumpctl gdb lichii              # newest crash; then: bt, thread apply all bt
coredumpctl dump lichii -o core     # or keep the core and read it later:
gdb -batch -ex bt ~/lx/debug/<build>/lichii core
```

The split-GPU-thread check (`EDEN_NX2_SPLIT_CHECK=1`) and other log lines print stacks as
`<module>+<offset>`. Symbolize them with:

```sh
llvm-symbolizer --obj=~/lx/debug/<build>/lichii --inlines <offset>
```

If `coredumpctl` lists nothing, check `cat /proc/sys/kernel/core_pattern` (it must pipe to
`systemd-coredump`) and `ulimit -c` (must not be 0).

## Developing from Windows via WSL2

- Use WSL2 with `Ubuntu-24.04`. Clone inside the WSL file system (`~/fritchii`): building from
  `/mnt/c` is several times slower and loses the executable bit.
- Edit from Windows through `\\wsl.localhost\Ubuntu-24.04\home\<user>\fritchii`, but run `git`,
  the scripts and builds inside WSL (`wsl -d Ubuntu-24.04 -- bash -lc "..."`). Saving a script
  from Windows drops its executable bit: run `chmod +x` again in WSL.
- WSL gets half the host RAM by default. A parallel clang build wants about 2 GB per job; raise it
  in `%UserProfile%\.wslconfig` (`[wsl2]`, `memory=24GB`, `swap=16GB`), then `wsl --shutdown`.
- WSLg shows the Qt window, and Vulkan runs through Mesa `dzn` on top of D3D12. That is enough
  to check that Lichii starts, lists a Vulkan device and writes its log. It is **not** a test of
  rendering speed or correctness: check those on a real Linux PC with a native driver (Mesa
  RADV/ANV/NVK or the NVIDIA driver). The CI Linux jobs are the real build check.
