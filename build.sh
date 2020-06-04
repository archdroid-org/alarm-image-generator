#!/bin/bash
#
# make odroid images
#

# Check if required dependencies are met.
if ! which partx 1>/dev/null ; then
    DEPENDENCIES="$DEPENDENCIES partx"
fi

if ! which losetup 1>/dev/null ; then
    DEPENDENCIES="$DEPENDENCIES losetup"
fi

if ! which fdisk 1>/dev/null ; then
    DEPENDENCIES="$DEPENDENCIES fdisk"
fi

if ! which mkfs.vfat 1>/dev/null ; then
    DEPENDENCIES="$DEPENDENCIES mkfs.vfat"
fi

if ! which mkfs.ext4 1>/dev/null ; then
    DEPENDENCIES="$DEPENDENCIES mkfs.ext4"
fi

if ! which wget 1>/dev/null ; then
    DEPENDENCIES="$DEPENDENCIES wget"
fi

if ! which curl 1>/dev/null ; then
    DEPENDENCIES="$DEPENDENCIES curl"
fi

if ! which arch-chroot 1>/dev/null ; then
    DEPENDENCIES="$DEPENDENCIES arch-chroot"
fi

if ! which tar 1>/dev/null ; then
    DEPENDENCIES="$DEPENDENCIES tar"
fi

if ! which sudo 1>/dev/null ; then
    DEPENDENCIES="$DEPENDENCIES sudo"
fi

if ! which yay 1>/dev/null ; then
    DEPENDENCIES="$DEPENDENCIES yay"
fi

if [ "$DEPENDENCIES" != "" ]; then
    DEPENDENCIES_TRIM="$(echo "${DEPENDENCIES}" | sed 's/^ *//' 's/ *$//')"
    echo "Please install '$DEPENDENCIES' to use this script." 1>&2
    exit
fi

alarm_check_root() {
    if [ $(id -u) -ne 0 ]; then
        echo "You need to be root to execute this command." 1>&2
        exit 1
    fi
}

# Set image name and file download name
alarm_set_name() {
    NAME=""
    for arg in "$@"; do
        case "$arg" in
          "n2")
              NAME="ArchLinuxARM-odroid-n2-latest"
              IMAGE="ArchLinuxARM-odroid-n2"
              PLATFORM="n2"
              ;;
          "c4")
              NAME="ArchLinuxARM-odroid-n2-latest"
              IMAGE="ArchLinuxARM-odroid-c4"
              PLATFORM="c4"
              ;;
        esac
    done

    if [ "$NAME" = "" ]; then
        echo "Platform not supported." 1>&2
        exit 1
    fi
}

alarm_set_env() {
    ENVIRONMENT=""
    while [ "$1" ]; do
        case "$1" in
          "-e")
              shift
              ENVIRONMENT="$1"
              ;;
        esac
        shift
    done

    if [ "$ENVIRONMENT" = "" ]; then
        ENVIRONMENT="xfce"
    elif [ ! -e "env/${ENVIRONMENT}.sh" ]; then
        echo "Invalid environment: '${ENVIRONMENT}'" 1>&2
        exit 1
    else
        IMAGE="${IMAGE}-${ENVIRONMENT}"
    fi
}

# Unmount image
alarm_umount_image() {
    image=$(losetup -j "${1}".img | cut -d: -f1)

    if echo $image | grep loop ; then
        if [ -e boot ]; then
            sudo umount boot
            rmdir boot
        fi

        if [ -e root ]; then
            sudo umount root/boot
            sudo umount root
            rmdir root
        fi

        if [ -e "${image}"p1 ]; then
            sudo partx -d ${image}
        fi

        sudo losetup -d ${image}
    fi
}

alarm_build_package() {
    if [ ! -e "packages" ]; then
        git clone https://github.com/jgmdev/archlinux-odroid packages
    fi

    cd packages

    if [ ! -e "$1" ]; then
        yay -G "$1"
    fi

    cd "$1"

    package=$(ls *.pkg.tar.* | sort | tail -n1)
    if [ "$package" = "" ]; then
        echo "Building $1..."
        makepkg -CAs --skippgpcheck --noconfirm
    fi

    if [ ! -e ../../mods/packages ]; then
        mkdir ../../mods/packages
    fi

    cp *.pkg.tar.* ../../mods/packages

    cd ../../
}

alarm_print_vars() {
    if [ -e "platform/${PLATFORM}.sh" ]; then
        source "platform/${PLATFORM}.sh"
    fi

    if type "platform_variables" 1>/dev/null ; then
        echo "----------------------------------------------------------------"
        echo "Variables for ${PLATFORM}:"
        echo "----------------------------------------------------------------"
        platform_variables
    else
        echo "No variables for the given platform."
    fi
}

case "$1" in
    "build")
        alarm_set_name $@
        alarm_set_env $@
        echo "--DETAILS-------------------------------------------------------"
        echo "  Platform:          $PLATFORM"
        echo "  Environment:       $ENVIRONMENT"
        echo "----------------------------------------------------------------"
        ;;
    "umount")
        shift
        alarm_set_name $@
        alarm_set_env $@
        alarm_umount_image $IMAGE
        exit
        ;;
    "clean")
        rm *.img
        rm *.tar.gz
        rm *.img.xz
        exit
        ;;
    "vars")
        alarm_set_name $@
        alarm_print_vars
        exit
        ;;
    *)
        echo "Usage: build.sh <command> [<arguments>]"
        echo "Creates a ready to burn ArchLinuxARM image."
        echo ""
        echo "COMMANDS:"
        echo ""
        echo "  build [<options>] <platform>"
        echo "    -e <environment>"
        echo ""
        echo "  umount [<options>] <platform>"
        echo "    -e <environment>"
        echo ""
        echo "  clean"
        echo "  Removes generated images and downloaded tarballs."
        echo ""
        echo "  vars <platform>"
        echo "  Print the environment variables that can be set for a platform."
        echo ""
        echo "Available platforms: "
        ls platform | sed "s/^/  /g" | sed "s/.sh$//g"
        echo ""
        echo "Available environments: "
        ls env | grep -v base.sh | sed "s/^/  /g" | sed "s/.sh$//g"
        exit
esac

#
# INCLUDE PLATFORM AND ENVIRONMENT HOOKS
#
if [ -e "platform/${PLATFORM}.sh" ]; then
    source "platform/${PLATFORM}.sh"
fi

if [ -e "env/${ENVIRONMENT}.sh" ]; then
    source "env/${ENVIRONMENT}.sh"
fi


#
# DOWNLOAD
#
echo "Downloading ArchLinuxARM Tarball..."

if [ ! -e "${NAME}.tar.gz" ]; then
    wget http://os.archlinuxarm.org/os/${NAME}.tar.gz

    echo "Verifying donwload integrity..."
    if ! curl -sSL http://archlinuxarm.org/os/${NAME}.tar.gz.md5 | md5sum -c ; then
        echo "Wrong md5sum checksum: '${NAME}.tar.gz'" 1>&2
        echo "Manually delete the downloaded tarball and run the script again." 1>&2
        exit 1
    fi
fi

#
# DISK IMAGE
#
echo "Making Disk Image..."

# Dont generate the image everytime which wears out storage.
if [ ! -e "${IMAGE}.img" ]; then
    dd if=/dev/zero of=${IMAGE}.img bs=1M count=$((1024*7))
fi

fdisk ${IMAGE}.img <<EOF
o
n
p


+256M
t
c
n
p



w
EOF

#
# PARTITIONS SETUP
#
echo "Preparing Image Partitions..."

LOOP=$(sudo losetup -f --show ${IMAGE}.img)
sudo partx -a ${LOOP}

sudo mkfs.vfat -v -I ${LOOP}p1
sudo mkfs.ext4 -F -v ${LOOP}p2

mkdir boot root
sudo mount -v -t vfat ${LOOP}p1 boot
sudo mount -v -t ext4 ${LOOP}p2 root

#
# FILES EXTRACTION
#
echo "Copying Files..."

sudo tar xzf ${NAME}.tar.gz -C root . >/dev/null 2>&1
sudo sync

sudo mv root/boot/* boot
sudo sync

echo "Moving Boot Partition on root dir..."

sudo umount boot
sudo mount -v -t vfat ${LOOP}p1 root/boot


#
# BUILD PACKAGES
#
alarm_build_package yay-bin


#
# PRE CHROOT HOOKS
#
if type "platform_pre_chroot" 1>/dev/null ; then
    echo "Executing platform pre chroot hook..."
    platform_pre_chroot
fi

if type "env_pre_chroot" 1>/dev/null ; then
    echo "Executing environment pre chroot hook..."
    env_pre_chroot
fi


#
# CHROOT SETUP
#
echo "Starting environment setup..."

if [ -e "platform/${PLATFORM}.sh" ]; then
    sudo cp "platform/${PLATFORM}.sh" root/platform.sh
    sudo chmod 0755 root/platform.sh
fi

if [ -e "env/${ENVIRONMENT}.sh" ]; then
    sudo cp "env/${ENVIRONMENT}.sh" root/env.sh
    sudo chmod 0755 root/env.sh
fi

# prepend environment variables to platform script
if type "platform_variables" 1>/dev/null ; then
    for var in "$(platform_variables)" ; do
        var_name=$(echo $var | cut -d: -f1)
        if [ "$((var_name))x" != "x" ]; then
            sudo sed -i "s|#!/bin/bash|#!/bin/bash\n${var_name}=\"$((var_name))\"|g" \
                root/platform.sh
        fi
    done
fi

sudo cp env/base.sh root/setup.sh

sudo mkdir root/mods
sudo mount --bind mods root/mods

sudo mount --bind cache root/var/cache/pacman/pkg

sudo arch-chroot root /setup.sh


#
# CHROOT CLEANUP
#
sudo rm root/setup.sh

if [ -e "root/platform.sh" ]; then
    sudo rm root/platform.sh
fi

if [ -e "root/env.sh" ]; then
    sudo rm root/env.sh
fi

#
# POST CHROOT HOOKS
#
if type "platform_post_chroot" 1>/dev/null ; then
    echo "Executing platform post chroot hook..."
    platform_post_chroot
fi

if type "env_post_chroot" 1>/dev/null ; then
    echo "Executing environment post chroot hook..."
    env_post_chroot
fi


#
# UNMOUNT AND FINISH
#
echo "Unmounting Image..."
sudo umount root/var/cache/pacman/pkg
sudo umount root/mods
sudo rmdir root/mods
sudo umount root/boot
sudo umount root
rmdir boot root
sudo partx -d ${LOOP}
sudo losetup -d ${LOOP}

echo "Done!"
