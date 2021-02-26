#!/bin/bash
#
# make odroid images
#

# Check if required dependencies are met.
deps=(
    partx losetup fdisk
    mkfs.vfat mkfs.ext4
    wget curl tar sudo
    arch-chroot yay
)

DEPENDENCIES=()
for dep in "${deps[@]}"; do
    command -v ${dep} 1>/dev/null 2>/dev/null || DEPENDENCIES+=("${dep}")
done

if [ "$DEPENDENCIES" != "" ]; then
    echo "Please install '${DEPENDENCIES[@]}' to use this script." 1>&2
    exit 1
fi

# Collect supported platforms
platforms=(
    $(ls platform | sed "s/^/  /g" | sed "s/.sh$//g")
)

# Collect supported environments
environments=(
    $(ls env | grep -v base.sh | sed "s/^/  /g" | sed "s/.sh$//g")
)

# check if user running script is root (currently not used)
alarm_check_root() {
    if [ $(id -u) -ne 0 ]; then
        echo "You need to be root to execute this command." 1>&2
        exit 1
    fi
}

# get value of an argument option, usage:
# alarm_getopt <arg_name> <multiple_values?1|0> <string>
# eg: alarm_getopt packages 1 $@
alarm_getopt(){
    local option_single="-$1"
    local option_double="--$1"
    local multiple="$2"

    while [ "$3" ]; do
        case "$3" in
            "$option_single" | "$option_double" )
                local value=""
                while [ "$3" ]; do
                    shift
                    if ! echo "$3" | grep -E "^\-" > /dev/null ; then
                        value="$value $3"
                    else
                        break
                    fi
                    if [ "$multiple" = "0" ]; then
                        break
                    fi
                done
                value=$(echo $value | xargs)
                if [ "$value" != "" ]; then
                    echo "$value"
                    return 0
                fi
                return 1
                ;;
        esac

        shift
    done
}

# Evaluate arguments passed as name=value as variables
alarm_eval_opts() {
    for arg in "$@"; do
        if echo "$arg" | grep "=" > /dev/null 2>&1 ; then
            eval "$arg"
        fi
    done
}

# Set image name and file download name and include platform script
alarm_set_platform() {
    if [ "$NAME" != "none" ]; then
        NAME=""
    fi

    for arg in "$@"; do
        if [[ " ${platforms[@]} " =~ " ${arg} " ]]; then
            if [ -e "platform/${arg}.sh" ]; then
                source "platform/${arg}.sh"

                if [ "${NAME}" = "" ]; then
                    NAME="ArchLinuxARM-odroid-${arg}-latest"
                fi
                if [ "${IMAGE}" = "" ]; then
                    IMAGE="ArchLinuxARM-odroid-${arg}"
                fi
                if [ "${IMAGE_SIZE}" = "" ]; then
                    IMAGE_SIZE=6
                fi
                if [ "${PLATFORM}" = "" ]; then
                    PLATFORM="${arg}"
                fi

                break
            fi
        fi
    done

    if [ "$NAME" = "" ]; then
        echo "Platform not yet supported." 1>&2
        exit 1
    fi
}

# set environment name and include its script
alarm_set_env() {
    ENVIRONMENT="$(alarm_getopt e 0 $@)"

    if [ "$ENVIRONMENT" = "" ]; then
        ENVIRONMENT="xfce"
    elif [ ! -e "env/${ENVIRONMENT}.sh" ]; then
        echo "Invalid environment: '${ENVIRONMENT}'" 1>&2
        exit 1
    else
        source "env/${ENVIRONMENT}.sh"
    fi

    IMAGE="${IMAGE}-${ENVIRONMENT}"
}

# Unmount image
alarm_umount_image() {
    image=$(losetup -j "${1}".img | cut -d: -f1)

    if echo ${image} | grep loop ; then
        if [ -e boot ]; then
            sudo umount boot
            rmdir boot
        fi

        if [ -e root ]; then
            sudo umount root/boot
            sudo umount root/dev
            sudo umount root/proc
            sudo umount root/sys
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
        git clone https://github.com/archdroid-org/pkgbuilds packages
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

alarm_yay_install() {
    sudo arch-chroot -u alarm root /usr/bin/yay -S --useask --removemake \
        --noconfirm --norebuild $@
}

alarm_print_vars() {
    alarm_set_env $@
    if [ "$ENVIRONMENT" != "" ]; then
        if type "env_variables" 1>/dev/null 2>&1 ; then
            echo "----------------------------------------------------------------"
            echo "Variables for environemnt ${ENVIRONMENT}:"
            echo "----------------------------------------------------------------"
            env_variables
        fi
    fi

    NAME="none"

    alarm_set_platform $@
    if [ "$NAME" = "none" ]; then
        return
    fi

    if [ -e "platform/${PLATFORM}.sh" ]; then
        source "platform/${PLATFORM}.sh"
    fi

    if type "platform_variables" 1>/dev/null 2>&1 ; then
        echo "----------------------------------------------------------------"
        echo "Variables for platform ${PLATFORM}:"
        echo "----------------------------------------------------------------"
        platform_variables
    else
        echo "No variables for the given platform."
    fi
}

alarm_chroot() {
    if [ ! -e $1 ]; then
        echo "Given image file does not exists."
        return
    fi

    local LOOP=$(sudo losetup -f --show $1)

    if [ ! -e $LOOP ] ; then
        echo "Invalid image file given."
        return
    fi

    sudo partx -a ${LOOP}

    mkdir image_chroot
    sudo mount -v -t ext4 ${LOOP}p2 image_chroot
    sudo mount -v -t vfat ${LOOP}p1 image_chroot/boot

    sudo arch-chroot image_chroot

    sudo umount image_chroot/boot
    sudo umount image_chroot

    sudo partx -d ${LOOP}
    sudo losetup -d ${LOOP}

    rmdir image_chroot
}

alarm_eval_opts $@

case "$1" in
    "build")
        alarm_set_platform $@
        alarm_set_env $@
        echo "--DETAILS-------------------------------------------------------"
        echo "  Platform:          $PLATFORM"
        echo "  Environment:       $ENVIRONMENT"
        echo "----------------------------------------------------------------"
        ;;
    "chroot")
        shift
        alarm_chroot $@
        exit 0;
        ;;
    "umount")
        shift
        alarm_set_platform $@
        alarm_set_env $@
        alarm_umount_image $IMAGE
        exit 0
        ;;
    "clean")
        rm -vf *.img *.tar.gz *.img.xz
        exit 0
        ;;
    "vars")
        alarm_print_vars $@
        exit 0
        ;;
    *)
        echo "Usage: build.sh <command> [<options>]"
        echo "Creates a ready to burn ArchLinuxARM image."
        echo ""
        echo "COMMANDS:"
        echo ""
        echo "  build <platform> [<options>]"
        echo "    -e <environment>"
        echo ""
        echo "  chroot <image-file.img>"
        echo "   chroot to an existing image file for easy modifications."
        echo ""
        echo "  umount <platform> [<options>]"
        echo "    -e <environment>"
        echo ""
        echo "  clean"
        echo "   Removes generated images and downloaded tarballs."
        echo ""
        echo "  vars [<platform>] [<options>]"
        echo "   Print the environment variables that can be set for"
        echo "   a platform or environment."
        echo "    -e <environment>"
        echo ""
        echo "Available platforms: ${platforms[@]}"
        echo ""
        echo "Available environments: ${environments[@]}"
        exit 0
esac

#
# Clean up
#
echo "Removing previous builded packages..."
sudo rm -rf mods/packages

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
    dd if=/dev/zero of=${IMAGE}.img bs=1M count=$((1024*IMAGE_SIZE))
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
alarm_build_package archlinuxdroid-repo


#
# PRE CHROOT HOOKS
#
if type "platform_pre_chroot" 1>/dev/null 2>&1 ; then
    echo "Executing platform pre chroot hook..."
    platform_pre_chroot
fi

if type "env_pre_chroot" 1>/dev/null 2>&1 ; then
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
if type "platform_variables" 1>/dev/null 2>&1 ; then
    platform_variables | while read var; do
        var_name=$(echo $var | cut -d: -f1)
        if [ "$((var_name))x" != "x" ]; then
            sudo sed -i "s|#!/bin/bash|#!/bin/bash\n${var_name}=\"$((var_name))\"|g" \
                root/platform.sh
        fi
    done
fi

# prepend environment variables to env script
if type "env_variables" 1>/dev/null 2>&1 ; then
    env_variables | while read var; do
        var_name=$(echo $var | cut -d: -f1)
        if [ "$((var_name))x" != "x" ]; then
            sudo sed -i "s|#!/bin/bash|#!/bin/bash\n${var_name}=\"$((var_name))\"|g" \
                root/env.sh
        fi
    done
fi

sudo cp env/base.sh root/setup.sh

sudo mkdir root/mods
sudo mount --bind mods root/mods
if [ ! -e usercache ]; then
    mkdir usercache
fi
sudo mkdir root/root/.cache
sudo mount --bind usercache root/root/.cache
sudo chown -R 1000:1000 root/root
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
if type "platform_post_chroot" 1>/dev/null 2>&1 ; then
    echo "Executing platform post chroot hook..."
    platform_post_chroot
fi

if type "env_post_chroot" 1>/dev/null 2>&1 ; then
    echo "Executing environment post chroot hook..."
    env_post_chroot
fi


#
# UNMOUNT AND FINISH
#
echo "Unmounting Image..."
sudo umount root/root/.cache
sudo rm -rf root/root/.cache
sudo rm -rf root/root/.config/yay
sudo chown -R 0:0 root/root
sudo umount root/var/cache/pacman/pkg
sudo umount root/mods
sudo rmdir root/mods
sudo umount root/boot
sudo umount root/sys
sudo umount root/dev
sudo umount root/proc
sudo umount root
rmdir boot root
sudo partx -d ${LOOP}
sudo losetup -d ${LOOP}

echo "Done!"
