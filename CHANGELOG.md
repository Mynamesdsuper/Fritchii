# Changelog

Changes of this Linux-first fork of [Fritchii](https://github.com/Frizti/Fritchii), on the
`linux` branch. Emulation changes come from upstream `nx2`; this file lists only what the fork
adds.

## fritchii-linux-v1 — 2026-11-10

Based on Fritchii `nx2` at `f66ea633db`.

### Build

- Builds with clang 19 or newer: `-mtls-dialect=gnu2` is now passed only when the compiler
  accepts it (clang 18 rejected it on every file).
- clang 18 and older crash on `nvdrv/devices/ioctl_serialization.h`; the local scripts pick
  clang 19+ (Ubuntu 24.04: `clang-20` from the distro repo) or fall back to gcc.

### Linux tools (`tools/linux/`)

- `install-deps.sh`: dependencies for Ubuntu/Debian (apt), Arch (pacman) and Fedora (dnf); on
  Ubuntu 24.04 also Qt 6.8.3 (the CI version, via aqtinstall), CMake 3.31 and clang-20.
- `configure.sh` / `build.sh`: CMake + Ninja + ccache with the CI Linux options,
  RelWithDebInfo, build dir `~/lx/build`.
- `build-fix.sh`: per-fix debug build in `~/lx/debug/<build>/` with a desktop launcher
  `Lichii Debug - <Game> - <fix>`, env vars and log filter, normal user data, log copied next
  to the build, core dumps enabled.
- `pgo.sh`: local equivalent of the `linux-x86_64-pgo` CI job.

### Debugging

- `EDEN_NX2_SPLIT_CHECK=1` now works on Linux (it was Windows-only and did nothing), with
  stacks as `<module>+<offset>` for `llvm-symbolizer`.
- Crash debugging on Linux with systemd-coredump, `coredumpctl gdb` and `llvm-symbolizer`.

### Docs

- New `docs/Linux.md`: build, debug builds, crash debugging, developing from Windows via WSL2.
- `AGENTS.md`: Linux build commands and a Linux host-crash row.

### Known limits on Linux

- NVIDIA DLSS (Streamline) is Windows-only; Linux uses FSR 3.1.
- The `nx2_sampler` stack sampler is Windows-only; use `perf record -g`.
- Tested in WSL2 (start-up, window, Vulkan device, log) and by CI builds; not yet played on a
  real Linux GPU driver.
