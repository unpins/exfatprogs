# Changelog

## [Unreleased]

Initial release — `exfatprogs` 1.3.2 as a single self-contained binary, built
natively for Linux, macOS, and Windows.

### Added

- Builds for Linux (x86_64, aarch64, armv7l, i686, ppc64le, riscv64), macOS
  (x86_64, aarch64), and Windows.
- `mkfs.exfat`, `fsck.exfat`, `exfatlabel`, `dump.exfat`, `exfat2img` and
  `tune.exfat` in the one binary — `unpin install exfatprogs` creates all six.
- One man page per program embedded in the binary — read any with
  `unpin man exfatprogs <program>`.
- macOS and Windows builds, which upstream does not target: the tools work on
  exFAT image files there. Block devices remain Linux-only.
