# exfatprogs via cosmoStaticCross for Windows-x86_64, folded into one .exe with
# the cpp-rename recipe (lib.cppRenameMulticall, isCosmo path).
#
# Same portable-Linux-ism gaps as the macOS build (see ./darwin.nix), but
# cosmocc emulates Linux closely enough that it already ships byteswap.h,
# sys/sysmacros.h, linux/types.h (with __le16/__u8…) and O_DIRECT. The ONE
# header it still lacks is <linux/fs.h> — which on Linux only supplies the
# block-device ioctl numbers exfatprogs references (BLKSSZGET/BLKDISCARD).
# Those ioctls have graceful runtime fallbacks (a non-block fd makes ioctl()
# fail → default sector size / discard skipped), so a tiny shim header is
# enough. posix_fadvise is already #ifdef-guarded and compiles out.
#
# (cosmo's <linux/types.h> defines __u16/__u32/__u64 + __le* but omits __u8, so
# the shim adds that one typedef too.)
#
# Plus cosmo-no-o-excl.patch: Cosmopolitan's NT open() rejects O_EXCL on a
# regular file (the patch header has the details).
{ unpins-lib, spec }:
pkgs:
let
  cosmoPkgs = unpins-lib.lib.cosmoStaticCross pkgs;
  lib = cosmoPkgs.lib // unpins-lib.lib;

  # Only <linux/fs.h> is missing under cosmocc; reuse cosmo's own
  # <linux/types.h> for the __le/__u typedefs.
  shimDir = cosmoPkgs.runCommand "exfat-cosmo-shims" { } ''
    mkdir -p "$out/linux"
    cat > "$out/linux/fs.h" <<'EOF'
    #pragma once
    #include <stdint.h>
    #include <linux/types.h>
    typedef uint8_t __u8;   /* cosmo's <linux/types.h> omits __u8 */
    #ifndef BLKSSZGET
    #define BLKSSZGET 0
    #endif
    #ifndef BLKDISCARD
    #define BLKDISCARD 0
    #endif
    EOF
  '';

  basePkg = cosmoPkgs.exfatprogs.overrideAttrs (o: {
    patches = (o.patches or [ ]) ++ [ ./cosmo-no-o-excl.patch ];
    env = (o.env or { }) // {
      NIX_CFLAGS_COMPILE = builtins.concatStringsSep " " [
        (o.env.NIX_CFLAGS_COMPILE or "")
        "-isystem ${shimDir}"
      ];
    };
  });
in
lib.cppRenameMulticall (spec // {
  pkgs = cosmoPkgs;
  inherit basePkg;
  isCosmo = true;
})
