#!/bin/bash

# Set environment name
ENV_NAME="Minimal"

# Overwrite platform image size since we need less space.
IMAGE_SIZE=3

# Called before entering the disk image chroot
env_pre_chroot() {
    echo "Env pre-chroot..."
}

# Called inside the chroot
env_chroot_setup() {
    echo "Env chroot-setup..."
}

# Called after exiting the disk image chroot
env_post_chroot() {
    echo "Env post-chroot..."
}
