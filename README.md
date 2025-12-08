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

The `rootfs.tar.gz` filesystem image is built automatically by GitHub Actions and published as a release artifact. This process is triggered whenever a new Git tag (e.g. `v1.0.0`) is pushed to the repository.

You can download the latest `rootfs.tar.gz` from the **Releases** page for this repository.

## Running the Environment

Creation of the systemd unit files is out-of-scope but assuming that is all setup proceed as follows:

```sh
sudo mkdir -p /var/lib/machines/adsbexchange
sudo tar -xpzf rootfs.tar.gz -C /var/lib/machines/adsbexchange --numeric-owner --xattrs --xattrs-include='*'
sudo systemctl start systemd-nspawn@adsbexchange.service
machinectl list
sudo machinectl shell adsbexchange
```