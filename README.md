# Fritchii Linux

A Linux-first fork of [Fritchii](https://github.com/Frizti/Fritchii) (itself a fork of
[Eglantine](https://github.com/Djihads80/Eglantine) / Eden), a Nintendo Switch 2 emulator. The
emulator code follows upstream `nx2`; this fork makes building, running and debugging on Linux
first-class. Work happens on the `linux` branch.

## Download

Get the latest build from [Releases](https://github.com/Mynamesdsuper/Fritchii/releases): an
AppImage (self-contained, glibc 2.39+) or a tar.gz, for x86_64 and aarch64. Prefer the PGO
builds. You must dump your own keys, firmware and games; none are provided.

## Build on Linux

```sh
tools/linux/install-deps.sh   # apt, pacman or dnf; asks for sudo
tools/linux/configure.sh
tools/linux/build.sh          # programs in ~/lx/build/bin
```

Needs clang 19+ or gcc 13+. Details, debug builds, crash debugging and developing from Windows
via WSL2: [docs/Linux.md](docs/Linux.md). What changed: [CHANGELOG.md](CHANGELOG.md).

## Upstream

> Hi everybody i'm frizti i make things that work hopefully i love you
> — Frizti, author of Fritchii
