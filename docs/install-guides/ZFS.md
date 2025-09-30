# ZFS

## Installation

Prerequisite: Server should be fully setup via ansible already.

Main guide - <https://wiki.debian.org/ZFS>:

```sh
sudo apt-get install -y zfsutils-linux zfs-dkms
```

## Setup

TODO: Fill this section

`ashift=12` (or 13, depending on your drive)

## Post installation

Install ZFS auto snapshots:

```sh
sudo apt-get install -y zfs-auto-snapshot
```

Disable atime, for performance reasons and avoid unnecessary snapshots diffs - <https://www.unixtutorial.org/zfs-performance-basics-disable-atime>:

```sh
sudo zfs set atime=off tank
sudo zfs set relatime=off tank
# Verify status:
zfs get all tank | grep time
```

Disable extended attributes, just because it's cleaner:

```sh
sudo zfs set xattr=off tank
# Verify status:
zfs get xattr tank
```

Enable compression:

```sh
sudo zfs set compression=lz4 tank
# Verify status:
zfs get compression tank
```

Enable autotrim:

```sh
sudo zpool set autotrim=on tank
# Verify status:
zpool get autotrim tank
```
