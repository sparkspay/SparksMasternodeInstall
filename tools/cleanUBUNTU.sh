#!/bin/bash
sudo dpkg --purge linux-headers-4.4.0-97 linux-headers-4.4.0-97-generic linux-image-4.4.0-97-generic linux-image-extra-4.4.0-97-generic
sudo dpkg --purge linux-headers-4.4.0-109 linux-headers-4.4.0-109-generic linux-image-4.4.0-109-generic linux-image-extra-4.4.0-109-generic
sudo dpkg --purge linux-headers-4.4.0-112 linux-headers-4.4.0-112-generic linux-image-4.4.0-112-generic linux-image-extra-4.4.0-112-generic
sudo dpkg --purge linux-headers-4.4.0-116 linux-headers-4.4.0-116-generic linux-image-4.4.0-116-generic linux-image-extra-4.4.0-116-generic
sudo dpkg --purge linux-headers-4.4.0-130 linux-headers-4.4.0-130-generic linux-image-4.4.0-130-generic linux-image-extra-4.4.0-130-generic
sudo dpkg --purge linux-headers-4.4.0-133 linux-headers-4.4.0-133-generic linux-image-4.4.0-133-generic linux-image-extra-4.4.0-133-generic
sudo dpkg --purge linux-headers-4.4.0-134 linux-headers-4.4.0-134-generic linux-image-4.4.0-134-generic linux-image-extra-4.4.0-134-generic
sudo dpkg --purge linux-headers-4.4.0-137 linux-headers-4.4.0-137-generic linux-image-4.4.0-137-generic linux-image-extra-4.4.0-137-generic
sudo dpkg --purge linux-headers-4.4.0-138 linux-headers-4.4.0-138-generic linux-image-4.4.0-138-generic linux-image-extra-4.4.0-138-generic
sudo dpkg --purge linux-headers-4.4.0-139 linux-headers-4.4.0-139-generic linux-image-4.4.0-139-generic linux-image-extra-4.4.0-139-generic
sudo apt-get -y -f install
sudo apt -y autoremove --purge
sudo apt update
sudo apt -y dist-upgrade
