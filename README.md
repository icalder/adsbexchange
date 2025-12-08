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

```sh
nix-shell -p debootstrap
sudo debootstrap --variant=minbase --include=systemd,dbus,apt,locales,bash-completion,curl,whiptail trixie ./fs
sudo systemd-nspawn -D ./fs /bin/bash -c "
  export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin;
  apt-get clean;
  rm -rf /var/lib/apt/lists/*;
"
sudo tar --numeric-owner --xattrs --xattrs-include='*' -cpzf rootfs.tar.gz -C fs .
```

## Running the Environment

Creation of the systemd unit files is out-of-scope but assuming that is all setup proceed as follows:

```sh
sudo mkdir -p /var/lib/machines/adsbexchange
sudo tar -xpzf rootfs.tar.gz -C /var/lib/machines/adsbexchange --numeric-owner --xattrs --xattrs-include='*'
sudo systemctl start systemd-nspawn@adsbexchange.service
machinectl list
sudo machinectl shell adsbexchange
```