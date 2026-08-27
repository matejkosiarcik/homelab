# ZFS

Tl;DR (on NAS):

| Key        | Value             |
|------------|-------------------|
| ZPool      | `tank`            |
| Dataset    | `tank/data`       |
| Mountpoint | `/tank/data`      |
| Snapshots  | `/tank/snapshots` |

## Installation

Prerequisite: Server should be fully setup via Ansible already.

Main guide - <https://wiki.debian.org/ZFS>:

```sh
sudo apt-get install -y zfsutils-linux zfs-dkms
```

## Setup

Create ZFS pool:

```sh
sudo zpool create -o ashift=12 -o autotrim=on tank /dev/<device>
# <device> - device identifier, eg. sdb
# ashift=12 - 4K sectors, recommended for most disks
# NOTE: To find out sector size on disk: lsblk -o NAME,MODEL,PHY-SEC,LOG-SEC
```

NOTE: Some Zpool properties may not be changed afterwards (ashift), but some may be changed afterwards (autotrim).

Create dataset:

```sh
# mkdir -p /tank/data
sudo zfs create -o atime=off -o compression=lz4 -o dedup=off -o mountpoint=/tank/data -o relatime=off -o snapdir=visible -o xattr=off tank/data
sudo chown -R homelab:homelab /tank/data
```

NOTE: Dataset properties may be changed afterwards.

<!-- Symlink to access snapshots:

```sh
# TODO: Device where to keep this or not
ln -sf /tank/data/.zfs/snapshot /tank/data/snapshots
``` -->

Verify it:

```sh
sudo zpool status tank
sudo zfs list tank/data
```

## Post installation

Install ZFS auto snapshots:

```sh
sudo apt-get install -y zfs-auto-snapshot
```

For changing properties afterwards, run:

Enable autotrim:

```sh
sudo zpool set property=value tank
# Verify status:
zpool get property tank
# Or get all properties: zpool get all tank
```

Disable extended attributes, just because it's cleaner:

```sh
sudo zfs set property=value tank/data
# Verify status:
zfs get property tank/data
# Or get all properties: zfs get all tank/data
```
