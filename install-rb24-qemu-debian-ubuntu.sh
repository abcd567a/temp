#!/bin/bash
set -e

sudo apt update
sudo apt -y install qemu-user qemu-user-binfmt binfmt-support

sudo dpkg --add-architecture arm64
sudo apt update
sudo apt -y install libc6:arm64

sudo apt install -y \
libbladerf2:arm64 \
libcurl4:arm64 \
libglib2.0-0:arm64 \
libjansson4:arm64 \
libncurses6:arm64 \
libprotobuf-c1:arm64 \
librtlsdr0:arm64 \
libtinfo6:arm64

wget -O rbfeeder_1.0.15+bookworm_arm64.deb https://apt.rb24.com/pool/main/r/rbfeeder/rbfeeder_1.0.15%2>
sudo dpkg -i rbfeeder_1.0.15+bookworm_arm64.deb && sudo apt -y --fix-broken install

sudo systemctl restart rbfeeder

echo "Plese check your file /etc/rbfeeder.ini. I will contain your feeder key and station number"
echo "Visit Radarbox Claims web page to claim the key and link station to yor account"
echo "You must login to your Radarbox account when visisting Claims page"

