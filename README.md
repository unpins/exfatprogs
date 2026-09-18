# exfatprogs

[exfatprogs](https://github.com/exfatprogs/exfatprogs) — the userspace programs for the exFAT filesystem: `mkfs.exfat`, `fsck.exfat`, `dump.exfat`, `exfat2img`, `tune.exfat` and `exfatlabel`. A single self-contained binary, built natively for Linux, macOS, and Windows.

[![CI](https://github.com/unpins/exfatprogs/actions/workflows/exfatprogs.yml/badge.svg)](https://github.com/unpins/exfatprogs/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-✓-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-✓-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) catalog; install it with [`unpin`](https://github.com/unpins/unpin): `unpin install exfatprogs`.

All three platforms create and check exFAT filesystems in image files. Linux also operates on block devices (`/dev/sd*`); on macOS and Windows it is image-only.

## Usage

Run a program with [unpin](https://github.com/unpins/unpin):

```bash
unpin exfatprogs --unpin-program=mkfs.exfat -L MYVOLUME disk.img
unpin exfatprogs --unpin-program=fsck.exfat -n disk.img
unpin exfatprogs --unpin-program=exfatlabel disk.img
```

To install the programs onto your PATH:

```bash
unpin install exfatprogs
```

`unpin install exfatprogs` creates `mkfs.exfat`, `fsck.exfat`, `dump.exfat`, `exfat2img`, `tune.exfat` and `exfatlabel`. `unpin info exfatprogs` lists every command and what it does.

## Man pages

One page per program is embedded — read any with
`unpin man exfatprogs <program>`, e.g. `unpin man exfatprogs mkfs.exfat`.

## Build locally

```bash
nix build github:unpins/exfatprogs
./result/bin/exfatprogs --unpin-program=mkfs.exfat -L MYVOLUME disk.img
```

Or run directly:

```bash
nix run github:unpins/exfatprogs -- --unpin-program=mkfs.exfat -V
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/exfatprogs/releases) page has standalone binaries for manual download.

## Build notes

- **Block devices:** Linux only. macOS and Windows expose no exFAT block-device layer, so there the tools work on image files.
- **macOS:** upstream targets Linux, but the gaps are portable Linux-isms with graceful fallbacks — a small shim include dir supplies `<byteswap.h>`, `<sys/sysmacros.h>` and the `<linux/types.h>`/`<linux/fs.h>` kernel typedefs + `BLK*` ioctl numbers, plus `-DO_DIRECT=0`. See [`darwin.nix`](darwin.nix).
- **Windows:** built via [Cosmopolitan](https://github.com/jart/cosmopolitan), not mingw — Cosmopolitan already provides most of the Linux layer upstream targets.
- **Tests:** no native suite is wired — exfatprogs' automake `make check` has no tests, and its real integration tests (`tests/`) need loopback devices/root, which the build sandbox lacks. The release smoke test lists the folded programs.
