{
  description = "exfatprogs (mkfs.exfat + fsck.exfat + … ) as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # exfatprogs ships six sbin programs, each in its own subdir linking the shared
  # lib/libexfat.a. The library is plain fs code with no callbacks into the
  # programs, so we fold them with the cpp-rename recipe (lib.cppRenameMulticall), keeping a
  # single libexfat.a copy. The real binary is bin/exfatprogs(.exe); every
  # program name is an argv[0] alias.
  outputs = { self, unpins-lib }:
    let
      lib = unpins-lib.lib;
      # Shared fold spec; per-target bits (pkgs, basePkg, isTargetDarwin/isCosmo)
      # are merged in by `build` / `windowsBuild`.
      spec = {
        primary = "exfatprogs";
        # Recursive build: each program lives in its own subdir Makefile, so
        # recompile each program's objects there. The final $(LINK) and the
        # shared libexfat.a reference both resolve from mkfs/Makefile.
        makeSubdir = "mkfs";
        linkExtra = "$(top_builddir)/lib/libexfat.a";
        programs = [
          { name = "mkfs.exfat"; buildDir = "mkfs"; objs = [ "mkfs/mkfs.o" "mkfs/upcase.o" ]; }
          { name = "fsck.exfat"; buildDir = "fsck"; objs = [ "fsck/fsck.o" "fsck/repair.o" ]; }
          { name = "dump.exfat"; buildDir = "dump"; objs = [ "dump/dump.o" ]; }
          { name = "exfat2img"; buildDir = "exfat2img"; objs = [ "exfat2img/exfat2img.o" ]; }
          { name = "tune.exfat"; buildDir = "tune"; objs = [ "tune/tune.o" ]; }
          { name = "exfatlabel"; buildDir = "label"; objs = [ "label/label.o" ]; }
        ];
        extraInstall = ''
          mkdir -p "$out/share/man/man8"
          for m in mkfs.exfat fsck.exfat dump.exfat exfat2img tune.exfat exfatlabel; do
            if [ -f "manpages/$m.8" ]; then install -m644 "manpages/$m.8" "$out/share/man/man8/$m.8"; fi
          done
        '';
      };
    in
    lib.mkStandaloneFlake {
      inherit self;
      name = "exfatprogs";
      binName = "exfatprogs";
      # macOS: nixpkgs marks exfatprogs linux-only, but the gaps are portable
      # Linux-isms (byteswap.h, sys/sysmacros.h, linux/fs.h types + BLK ioctls,
      # O_DIRECT) with macOS equivalents and graceful runtime fallbacks — see
      # ./darwin.nix. The image-file path needs no real block-device I/O, so
      # exfatprogs builds and runs as a Mach-O. NOT linuxOnly.
      # Smoke: every exfatprogs *tool* exits non-zero on -V/--help (e.g.
      # mkfs.exfat -V → 1), which trips the smoke runner's `set -e`. Ask the
      # multicall dispatcher itself for `--help` instead: it lists the programs
      # and exits 0. (Not an empty arg list — macOS's bash 3.2 errors on
      # `"${SMOKE_ARGS[@]}"` for an empty array under `set -u`, failing the
      # darwin smoke; a single real arg sidesteps that.)
      smoke = [ "--help" ];
      smokePattern = "exfatprogs is one binary";
      build = pkgs:
        let isDarwin = pkgs.pkgsStatic.stdenv.hostPlatform.isDarwin;
        in
        lib.cppRenameMulticall (spec // {
          inherit pkgs;
          basePkg =
            if isDarwin
            then (import ./darwin.nix { inherit pkgs; }) pkgs.pkgsStatic.exfatprogs
            else pkgs.pkgsStatic.exfatprogs;
          isTargetDarwin = isDarwin;
        });
      # Windows: same portable-Linux-ism gaps as macOS. cosmocc gives the POSIX
      # layer (like dosfstools/e2fsprogs); the few headers cosmo still lacks are
      # supplied by the same shim approach. See ./cosmo.nix.
      windowsBuild = import ./cosmo.nix { inherit unpins-lib spec; };
    };
}
