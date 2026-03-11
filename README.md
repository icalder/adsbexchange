# ADS-B Exchange Environment for NixOS PIs

## Introduction

This simple repo provides instructions for building a minimal Debian filesystem to be run under `systemd-nspawn`.

When the VM is up and running, [ADS-B Exchange feed client](https://github.com/ADSBexchange/feedclient) can be installed interactively by following its instructions:

```sh
sudo machinectl shell adsbexchange
curl -L -o /tmp/axfeed.sh https://adsbexchange.com/feed.sh
bash /tmp/axfeed.sh
```

## Creating the Filesystem

### Automated Build
The `rootfs.tar.gz` filesystem image is built automatically by GitHub Actions and published as a release artifact. This process is triggered whenever a new Git tag (e.g. `v1.0.0`) is pushed to the repository.

You can download the latest `rootfs.tar.gz` from the **Releases** page for this repository.

### Local Build (NixOS)
If you are running NixOS, you can build the rootfs locally using the provided flake.

1.  **Enable ARM Emulation** (if building for arm64 on x86_64):
    Add the following to your `configuration.nix`:
    ```nix
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
    ```

2.  **Run the Build Script**:
    ```sh
    nix develop
    # Build for current system (default)
    sudo build-rootfs
    # Or specify an architecture
    sudo build-rootfs arm64
    ```

The resulting tarball will be named `rootfs-arm64.tar.gz` or `rootfs-amd64.tar.gz`.

## Running the Environment

Creation of the systemd unit files is out-of-scope but assuming that is all setup proceed as follows:

```sh
sudo mkdir -p /var/lib/machines/adsbexchange
sudo tar -xpzf rootfs.tar.gz -C /var/lib/machines/adsbexchange --numeric-owner --xattrs --xattrs-include='*'
sudo systemctl start systemd-nspawn@adsbexchange.service
machinectl list
sudo machinectl shell adsbexchange
```