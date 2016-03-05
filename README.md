
*WARNING*: still in early stages, expect crashes, data loss and incompatible changes.

Cangallo is a tool that uses `qemu-img` and `libguestfs` to manage, create and organize qcow2 images. It's repository holds images and deltas of derived images in a similar way as Docker but in a block level instead of file level.

## Requirements

* Ruby 2.2.0
* qemu-img >= 2.4.0
* libguestfs, tested with 1.28 but should work with older images

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
$ bin/canga list
HASH                                     SIZE       DISK_SIZE  DESCRIPTION
2c2ceccb5ec5574f (delete_me)             104857600  200704
850dd1fccd8f5b1e (ubuntu:16.04)          2361393152 302292992
258471026d4d5403 (ubuntu:one:16.04)      2361393152 14893056   OpenNebula Compatible Ubuntu 16.04
2a492f15396a6768 (test_image)            1073741824 200704
```

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




