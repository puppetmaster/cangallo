
**WARNING**: still in early stages, expect crashes, data loss and incompatible changes.

Cangallo is a tool that uses `qemu-img` and `libguestfs` to manage, create and organize qcow2 images. It's repository holds images and deltas of derived images in a similar way as Docker but in a block level instead of file level.

## Requirements

* Ruby 2.2.0
* qemu-img >= 2.4.0
* libguestfs, tested with 1.28 but should work with older versions
* keybase, for index sign and verify functionality

## Ruby dependencies installation

```
$ bundle install
```

## Creating a qcow2 image

```
$ bin/canga create test.qcow2 1G
qemu-img create -f qcow2 test.qcow2 1G
$ qemu-img info test.qcow2
image: test.qcow2
file format: qcow2
virtual size: 1.0G (1073741824 bytes)
disk size: 392K
cluster_size: 65536
Format specific information:
    compat: 1.1
    lazy refcounts: false
    refcount bits: 16
    corrupt: false
```

# Adding an image to the repository

```
$ bin/canga add test.qcow2 --tag test_image
Calculating image sha1 with libguestfs (it will take some time)
 100% ⟦▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒⟧ --:--
Image SHA1: 2a492f15396a6768bcbca016993f4b4c8b0b5307
Copying file to repository
qemu-img convert -p -O qcow2 -c test.qcow2 repo/2a492f15396a6768bcbca016993f4b4c8b0b5307.qcow2
qemu-img info --output=json repo/2a492f15396a6768bcbca016993f4b4c8b0b5307.qcow2
```

# Listing images in the repository

```
NAME                                  SIZE DESCRIPTION
  default:zentyal                1221.1 Mb
^ default:zentyal/one               2.8 Mb Zentyal with context packages
  default:centos72                372.9 Mb
^ default:473d40cc50278446         60.6 Mb OpenNebula Compatible CentOS 7
  default:alpine                   76.6 Mb
^ default:e7033e957c559fb0          0.4 Mb test image
  remote:zentyal                 1221.1 Mb
^ remote:zentyal/one                2.8 Mb Zentyal with context packages
 *remote:centos72                 372.9 Mb
```

* `^`: has a parent
* `*`: image was still not downloaded

# Creating a derived image

To create a derived image a "Cangafile" is used. It's a yaml file like this one:

```yaml
---
description: OpenNebula Compatible Ubuntu 16.04
os: Ubuntu 16.04
parent: 850dd1fccd8f5b1e201755beec0754ab3fb610b7
files:
  - context /
run:
  - dpkg -i /context/one-context*deb
  - apt-get remove -y cloud-init
  - apt-get install -y util-linux cloud-utils ruby
  - rm -rf /context
  - apt-get clean
```

* `files` is an array with files and directories to be copied into the image.
* `run` is also an array wih the commands to be executed

Example:

```
$ bin/canga build Cangafile.latest
copy-in context:/
run-command dpkg -i /context/one-context*deb
run-command apt-get remove -y cloud-init
run-command apt-get install -y util-linux cloud-utils ruby
run-command rm -rf /context
run-command apt-get clean
qemu-img create -f qcow2 -o backing_file=/home/jfontan/projects/cangallo/repo/850dd1fccd8f5b1e201755beec0754ab3fb610b7.qcow2 repo/temp-1.qcow2
[   0.0] Examining the guest ...
[   6.3] Setting a random seed
[   6.3] Copying: context to /
[   6.3] Running: dpkg -i /context/one-context*deb
[   8.6] Running: apt-get remove -y cloud-init
[  11.1] Running: apt-get install -y util-linux cloud-utils ruby
[  51.4] Running: rm -rf /context
[  51.5] Running: apt-get clean
[  52.5] Finishing off
[   3.3] Trimming /dev/sda1
[   3.5] Sparsify in-place operation completed with no errors
Calculating image sha1 with libguestfs (it will take some time)
 100% ⟦▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒⟧ --:--
Image SHA1: 8a02f25118384ca9142081af76e24de7d1dd6816
Copying file to repository
qemu-img convert -p -O qcow2 -c -o backing_file=/home/jfontan/projects/cangallo/repo/850dd1fccd8f5b1e201755beec0754ab3fb610b7.qcow2 repo/temp-1.qcow2 repo/8a02f25118384ca9142081af76e24de7d1dd6816.qcow2
qemu-img info --output=json repo/8a02f25118384ca9142081af76e24de7d1dd6816.qcow2
qemu-img rebase -u -b 850dd1fccd8f5b1e201755beec0754ab3fb610b7.qcow2 repo/8a02f25118384ca9142081af76e24de7d1dd6816.qcow2
Deleting temporary image
```

The image generated is a compressed delta to the parent image. Its hash is `8a02f25118384ca9` and you can see in the list command it only holds the diffence to the parent image (`850dd1fccd8f5b1e`):

```
$ bin/canga list
HASH                                     SIZE       DISK_SIZE  DESCRIPTION
850dd1fccd8f5b1e (ubuntu:16.04)          2361393152 302292992
8a02f25118384ca9                         2361393152 14819328   OpenNebula Compatible Ubuntu 16.04
```

# Tag an image

```
$ bin/canga tag ubuntu:one:16.04 8a02f25118384ca9142081af76e24de7d1dd6816
$ bin/canga list
HASH                                     SIZE       DISK_SIZE  DESCRIPTION
850dd1fccd8f5b1e (ubuntu:16.04)          2361393152 302292992
8a02f25118384ca9 (ubuntu:one:16.04)      2361393152 14819328   OpenNebula Compatible Ubuntu 16.04
```

# Sign index

```
$ bin/canga sign
$ ls -l repo/index.yaml.sig
-rw-r--r-- 1 jfontan jfontan 801 Mar 13 16:52 repo/index.yaml.sig
```

# Verify index signature

```
$ bin/canga verify
Signature verified. Signed by jfontan 4 minutes ago (2016-03-13 16:52:28 +0100 CET).
PGP Fingerprint: d21c933397d1dea76ab4035a5255eb6cbbceb6b3.
```

# Download a repo index

```
$ bin/canga fetch --repo=remote
```

# Pull images from a remote repository

```
$ bin/canga list
NAME                                  SIZE DESCRIPTION
 *remote:centos72                 372.9 Mb
^*remote:473d40cc50278446          60.6 Mb OpenNebula Compatible CentOS 7
$ bin/canga pull remote:473d40cc50278446
Downloading remote:centos72
curl -o '/home/jfontan/.cangallo/remote/5318a77f9faae02f2e575e903045fcd8fa66d791e912fca7fbe96189e413a1cb.qcow2' 'http://localhost:8000/5318a77f9faae02f2e575e903045fcd8fa66d791e912fca7fbe96189e413a1cb.qcow2'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  373M  100  373M    0     0   273M      0  0:00:01  0:00:01 --:--:--  273M
Downloading remote:473d40cc50278446
curl -o '/home/jfontan/.cangallo/remote/473d40cc502784464d69b41bd38109e5794b48169ee803b80bcb625b98d5bedf.qcow2' 'http://localhost:8000/473d40cc502784464d69b41bd38109e5794b48169ee803b80bcb625b98d5bedf.qcow2'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 60.7M  100 60.7M    0     0   210M      0 --:--:-- --:--:-- --:--:--  210M
$ bin/canga list
NAME                                  SIZE DESCRIPTION
  remote:centos72                 372.9 Mb
^ remote:473d40cc50278446          60.6 Mb OpenNebula Compatible CentOS 7
```





