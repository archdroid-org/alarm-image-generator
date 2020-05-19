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

For now only images for the Odroid N2 are generated with plans to add
support for the Odroid C4. But it should be easy to add support for
many other platforms. Pull requests with improvements and platforms/
environments additions are welcome. The command line options need
some refining and improvements, but for now the option that generates
the images is working properly.

To generate a Odroid N2 image you would do:

```sh
./build.sh build n2
```

This will set the environment by default to xfce (you can specify
a different environment by using the -e flag). Then the
instructions on platform/n2.sh and env/xfce.sh are executed.
By default the script will install some packages, you can
take a look on env/base.sh for the defaults.

## Extending

Adding additional platforms and environments should be pretty simple.
The script uses a hook system to call into other scripts depending
on the desired platform and environment that was specified on the
command line options.

### Platforms

In case of adding a platform you would need to edit build.sh, add
the file to download, desired image name and platform code name to
the following code section:

```sh
for arg in "$@"; do
        case "$arg" in
          "n2")
              NAME="ArchLinuxARM-odroid-n2-latest"
              IMAGE="ArchLinuxARM-odroid-n2"
              PLATFORM="n2"
              ;;
          "c4")
              echo "Still working on this..." 1>&2
              exit 1
              ;;
        esac
    done
```

For example:

```sh
for arg in "$@"; do
        case "$arg" in
          "n2")
              NAME="ArchLinuxARM-odroid-n2-latest"
              IMAGE="ArchLinuxARM-odroid-n2"
              PLATFORM="n2"
              ;;
          "c2")
              NAME="ArchLinuxARM-odroid-c2-latest"
              IMAGE="ArchLinuxARM-odroid-c2"
              PLATFORM="c2"
              ;;
          "c4")
              echo "Still working on this..." 1>&2
              exit 1
              ;;
        esac
    done
```

Then you should add the installation instructions of this new platform
into platform/c2.sh. On this file you have to specify 3 hook
functions that get called by main build script:

* platform_pre_chroot
* platform_chroot_setup
* platform_post_chroot

You can take a look in platform/n2.sh to get an idea.

### Environments

Finally, adding environments should be the same  process as adding a
new platform. Lets say you want to add sway. You would create a new
file as env/sway.sh, and add to it the following hook functions:

* env_pre_chroot
* env_chroot_setup
* env_post_chroot

You can see the env/xfce.sh file for ideas. In order to use the new
platform and environment to generate a new image you would call the
script as follows:

```sh
./build.sh build -e sway rpi3
```

Pull requests with improvements, new platforms or environments are
welcome!

Inspiration for this script was taken from:
https://github.com/EasyPi/alarmpi-image