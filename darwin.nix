# exfatprogs darwin portability shims.
#
# Upstream exfatprogs targets Linux (nixpkgs meta.platforms is linux-only), but
# the gaps are all portable Linux-isms, not anything fundamental — exFAT is a
# filesystem format, and the image-file path (mkfs.exfat on a regular file)
# needs no real block-device I/O. We supply a small shim include dir + two
# defines so it builds as a macOS Mach-O:
#
#   * <byteswap.h>        — glibc-only; map bswap_16/32/64 → __builtin_bswap*.
#   * <sys/sysmacros.h>   — Linux-only; macOS keeps major/minor/makedev in
#                           <sys/types.h>, so the shim just includes that.
#   * <linux/types.h>     — __u8/__le16/… kernel typedefs (plain fixed-width
#                           aliases; exFAT uses them only as on-disk storage
#                           types) + loff_t.
#   * <linux/fs.h>        — pulls the typedefs and defines BLKSSZGET/BLKDISCARD.
#                           These ioctls have graceful runtime fallbacks: a
#                           non-block fd makes ioctl() fail → default sector
#                           size / discard-skipped (both image-file no-ops).
#   * -DO_DIRECT=0        — macOS has no O_DIRECT (it uses fcntl F_NOCACHE); the
#                           only user is the optional fsck `--verify` open, which
#                           degrades to a normal read. 0 = no extra open flag.
#   * posix_fadvise       — already #ifdef POSIX_FADV_WILLNEED in exfat_dir.c, so
#                           it compiles out on macOS with no shim.
{ pkgs }:
let
  shimDir = pkgs.runCommand "exfat-darwin-shims" { } ''
    mkdir -p "$out/linux" "$out/sys"
    cat > "$out/byteswap.h" <<'EOF'
    #pragma once
    #define bswap_16(x) __builtin_bswap16(x)
    #define bswap_32(x) __builtin_bswap32(x)
    #define bswap_64(x) __builtin_bswap64(x)
    EOF
    cat > "$out/sys/sysmacros.h" <<'EOF'
    #pragma once
    #include <sys/types.h>
    EOF
    cat > "$out/linux/types.h" <<'EOF'
    #pragma once
    #include <stdint.h>
    typedef uint8_t  __u8;   typedef uint16_t __u16;
    typedef uint32_t __u32;  typedef uint64_t __u64;
    typedef uint16_t __le16; typedef uint32_t __le32; typedef uint64_t __le64;
    typedef uint16_t __be16; typedef uint32_t __be32; typedef uint64_t __be64;
    typedef int64_t  loff_t;
    EOF
    cat > "$out/linux/fs.h" <<'EOF'
    #pragma once
    #include <linux/types.h>
    #ifndef BLKSSZGET
    #define BLKSSZGET 0
    #endif
    #ifndef BLKDISCARD
    #define BLKDISCARD 0
    #endif
    EOF
  '';
in
p: p.overrideAttrs (o: {
  env = (o.env or { }) // {
    NIX_CFLAGS_COMPILE = builtins.concatStringsSep " " [
      (o.env.NIX_CFLAGS_COMPILE or "")
      "-isystem ${shimDir}"
      "-DO_DIRECT=0"
    ];
  };
  # nixpkgs marks exfatprogs linux-only (meta.platforms), so a darwin build is
  # refused at eval ("not available on the requested hostPlatform"). The gaps
  # are all portable Linux-isms shimmed above, so widen the platform set to let
  # it evaluate and build as a Mach-O.
  meta = (o.meta or { }) // { platforms = pkgs.lib.platforms.unix; };
})
