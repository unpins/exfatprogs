# exfatprogs

[exfatprogs](https://github.com/exfatprogs/exfatprogs) — the userspace utilities for the exFAT filesystem: `mkfs.exfat`, `fsck.exfat`, `dump.exfat`, `exfat2img`, `tune.exfat` and `exfatlabel`. A single self-contained binary, built natively for Linux, macOS, and Windows.

[![CI](https://github.com/unpins/exfatprogs/actions/workflows/exfatprogs.yml/badge.svg)](https://github.com/unpins/exfatprogs/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-✓-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-✓-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) catalog; install it with [`unpin`](https://github.com/unpins/unpin): `unpin install exfatprogs`.

All three platforms create and check exFAT filesystems in image files. Linux also operates on block devices (`/dev/sd*`); on macOS and Windows it is image-only. The Windows build is a [Cosmopolitan](https://github.com/jart/cosmopolitan) `.exe` (see Build notes).

## Usage

Run a program with [unpin](https://github.com/unpins/unpin):

```bash
unpin exfatprogs mkfs.exfat -L MYVOLUME disk.img
unpin exfatprogs fsck.exfat -n disk.img
unpin exfatprogs exfatlabel disk.img
```

To install the programs onto your PATH:

```bash
unpin install exfatprogs
```

`unpin install exfatprogs` creates `mkfs.exfat`, `fsck.exfat`, `dump.exfat`, `exfat2img`, `tune.exfat` and `exfatlabel`. `unpin info exfatprogs` lists every command and what it does.

## Build locally

```bash
nix build github:unpins/exfatprogs
./result/bin/exfatprogs mkfs.exfat -L MYVOLUME disk.img
```

Or run directly:

```bash
nix run github:unpins/exfatprogs -- mkfs.exfat -V
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/exfatprogs/releases) page has standalone binaries for manual download.

## Build notes

- **Platforms:** Linux, macOS, Windows. macOS/Windows have no exFAT block-device layer, so the tools work on image files but not live block devices.
- **macOS:** upstream targets Linux, but the gaps are portable Linux-isms with graceful fallbacks — a small shim include dir supplies `<byteswap.h>`, `<sys/sysmacros.h>` and the `<linux/types.h>`/`<linux/fs.h>` kernel typedefs + `BLK*` ioctl numbers, plus `-DO_DIRECT=0`. See [`darwin.nix`](darwin.nix).
- **Windows:** built via [Cosmopolitan](https://github.com/jart/cosmopolitan), not mingw — see [`cosmo.nix`](cosmo.nix). cosmocc already provides most of the Linux layer; the one missing header (`<linux/fs.h>`) is shimmed, the `__u8` typedef cosmo's `<linux/types.h>` omits is added, and `O_EXCL` is neutralized on the image fd (cosmo's NT `open()` EINVALs on `O_RDWR|O_EXCL` for a regular file; wine tolerates it, so it only surfaced on a real Windows host).
- **Multicall:** the six programs are folded into one binary — on Linux by the unpin-llvm engine (per-program bitcode module), and on macOS/Windows by a source-level `main` → `<prog>_main` rename (`lib.cppRenameMulticall`). Either way a single copy of the shared `libexfat.a` is kept.
- **Man pages:** the section-8 pages are embedded; read with `unpin man exfatprogs mkfs.exfat`.
- **Tests:** no native suite is wired — exfatprogs' automake `make check` has no tests, and its real integration tests (`tests/`) need loopback devices/root, which the build sandbox lacks. The release smoke test lists the folded programs.
