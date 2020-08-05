# ArchLinuxARM Image Generator

Extensible shell script to generate disk image files from the
archlinuxarm.org tarball files.

## Introduction

The script generates images with a predefined set of configurations
and software packages. It works by reading separate shell scripts
that provide the neccesary commands to generate the image. These
scripts are divided in the following two components.

* platform - Instructions for a specific SOC (system on a chip), eg:
  odroid n2, odroid c2, etc... On these scripts you can specify
  commands to install specific kernels, u-boot files, config files...

* env - Instructions to install a Desktop Environment like: xfce,
  gnome, etc... On this scripts you can specify which software to
  install for a specific Desktop Environment, generate configuration
  files or anything else.

Also these components may depend on resources inside the 'mods'
directory which contains pre-defined configuration files that are
copied to the target generated image.

## Requirements

The main build.sh should detect if you have a missing dependency and
let you know, but besides this you will need the following:

* ArchLinux installation running same architecture of target image.
* User account with sudo priviliges.

## Usage

So far Odroid N2/N2+ and Odroid C4 images are generated, but it should
be easy to add support for many other platforms. Pull requests with
improvements and platforms/environments additions are welcome. The
command line options need some refining and improvements, but for now
the option that generates the images is working properly.

To generate a Odroid N2 image you would do:

```sh
./build.sh build n2
```

This will set the environment by default to xfce, you can specify
a different environment by using the -e flag, for example:

```sh
./build.sh build -e wayfire n2
```

Then the instructions on platform/n2.sh and env/wayfire.sh are
executed. By default the script will install some packages, you can
take a look on env/base.sh for the defaults.

## Extending

Adding additional platforms and environments should be pretty simple.
The script uses a hook system to call into other scripts depending
on the desired platform and environment that was specified on the
command line options.

### Platforms

In case of adding a platform you would need to add a platform shell
script in the **platform** directory with the name of the platform.
Lets say for example the Odroid **C2**, you would create a file called
**c2.sh**. After creating the file you can start by adding some variables
used by the build script:

```sh
#!/bin/bash

# Name of the tar file to download from ArchLinuxARM website
NAME="ArchLinuxARM-odroid-c2-latest"

# Name of the generated image file
IMAGE="ArchLinuxARM-odroid-c2"

# The size in gigabytes of the generated image file
IMAGE_SIZE=5
```

Then you should add the installation instructions of this new platform
into platform/c2.sh. by specifying 3 hook functions that get called
by main build script:

* platform_variables - declare variables used by the other hooks
* platform_pre_chroot - executed before entering the image chroot
* platform_chroot_setup - executed inside the image chroot
* platform_post_chroot - executed after exiting image chroot

You can take a look in platform/n2.sh to get an idea.

### Environments

Finally, adding environments should be the same  process as adding a
new platform. Lets say you want to add sway. You would create a new
file as env/sway.sh, and add to it the following hook functions:

* env_pre_chroot - executed before entering the image chroot
* env_chroot_setup - executed inside the image chroot
* env_post_chroot - executed after exiting image chroot

**Note:** You can overwrite the **IMAGE_SIZE** on this file in case
more than 6 GB are needed.

You can see the env/xfce.sh file for ideas. In order to use the new
platform and environment to generate a new image you would call the
script as follows:

```sh
./build.sh build -e sway c2
```

Pull requests with improvements, new platforms or environments are
welcome!

Inspiration for this script was taken from:
https://github.com/EasyPi/alarmpi-image
