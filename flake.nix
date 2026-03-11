{
  description = "Debian rootfs builder for ADS-B Exchange";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        defaultDebianArch = 
          if system == "x86_64-linux" then "amd64"
          else if system == "aarch64-linux" then "arm64"
          else "arm64"; # Fallback
        
        buildScript = pkgs.writeShellScriptBin "build-rootfs" ''
          set -euo pipefail

          ARCH="${defaultDebianArch}"
          MINIMAL=false
          VARIANT="bookworm"

          # Parse arguments
          while [[ $# -gt 0 ]]; do
            case $1 in
              --minimal) MINIMAL=true; shift ;;
              arm64|amd64) ARCH="$1"; shift ;;
              *) echo "Unknown argument: $1"; exit 1 ;;
            esac
          done

          OUT_DIR="fs-$ARCH"
          TARBALL="rootfs-$ARCH.tar.gz"

          echo "Building Debian $VARIANT rootfs for $ARCH (Minimal: $MINIMAL)..."

          # Ensure we are running as root
          if [ "$EUID" -ne 0 ]; then
            echo "Please run as root (sudo)"
            exit 1
          fi

          # Clean up previous builds
          rm -rf "$OUT_DIR" "$TARBALL"

          if [ "$MINIMAL" = true ]; then
            # Using mmdebstrap for ultra-minimal build
            # We exclude perl-base specifically if you really don't want it, 
            # but note that many things in Debian assume it's there.
            mmdebstrap \
              --variant=essential \
              --architecture="$ARCH" \
              --include=systemd,dbus,apt,curl,whiptail \
              "$VARIANT" \
              "$OUT_DIR"
          else
            # Standard debootstrap
            debootstrap \
              --variant=minbase \
              --arch="$ARCH" \
              --include=systemd,dbus,apt,locales,procps,bash-completion,curl,whiptail \
              "$VARIANT" \
              "$OUT_DIR"
          fi

          # Perform minimal cleanup using nspawn
          systemd-nspawn -D "$OUT_DIR" /bin/bash -c "
            export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
            apt-get clean
            rm -rf /var/lib/apt/lists/*
          "

          # Package the rootfs
          echo "Packaging $TARBALL..."
          tar --numeric-owner --xattrs --xattrs-include='*' -cpzf "$TARBALL" -C "$OUT_DIR" .

          echo "Done! Created $TARBALL"
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            debootstrap
            mmdebstrap
            qemu-user
            buildScript
          ];

          shellHook = ''
            echo "ADS-B Exchange Rootfs Build Environment"
            echo "Available commands:"
            echo "  sudo build-rootfs [--minimal] [arm64|amd64]  (default: ${defaultDebianArch})"
            echo ""
            echo "Note: --minimal uses mmdebstrap for an even smaller footprint."
            echo "Note: To build arm64 on x86_64, ensure 'boot.binfmt.emulatedSystems = [ \"aarch64-linux\" ];' is in your NixOS config."
          '';
        };

        packages.default = buildScript;
      }
    );
}
