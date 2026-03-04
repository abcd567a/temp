#!/bin/bash
set -e

sudo apt update
sudo apt -y install qemu-user qemu-user-binfmt binfmt-support

echo "Adding line \"Architectures: amd64\" to existing file \"ubuntu.sources\", if not already there ..."
sudo sed -i '/Architectures: amd64/d' /etc/apt/sources.list.d/ubuntu.sources
sudo sed -i '/Types: deb/a Architectures: amd64' /etc/apt/sources.list.d/ubuntu.sources

echo "Adding arhitecture arm64 to system ..."
sudo dpkg --add-architecture arm64

echo "Creating arm64 apt-source file \"ubuntu-ports-arm64.sources\"   "
ARM64_SOURCES_FILE=/etc/apt/sources.list.d/ubuntu-ports-arm64.sources
touch ${ARM64_SOURCES_FILE}
chmod 777 ${ARM64_SOURCES_FILE}
echo "Writing code to file ubuntu-ports-arm64.sources"
/bin/cat <<EOM >${ARM64_SOURCES_FILE}
Types: deb
URIs: http://ports.ubuntu.com/ubuntu-ports/
Suites: noble noble-updates noble-security
Components: main restricted universe multiverse
Architectures: arm64
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

EOM

chmod 644 ${ARM64_SOURCES_FILE}

sudo apt update

sudo apt -y install libc6:arm64

sudo apt install -y \
libbladerf2:arm64 \
libcurl4:arm64 \
libglib2.0-0:arm64 \
libjansson4:arm64 \
libncurses6:arm64 \
libprotobuf-c1:arm64 \
libtinfo6:arm64

echo "downloading and installing packge librtlsdr0:arm64 ..."
wget -O librtlsdr0_0.6.0-4_arm64.deb http://http.us.debian.org/debian/pool/main/r/rtl-sdr/librtlsdr0_0.6.0-4_arm64.deb
dpkg -i librtlsdr0_0.6.0-4_arm64.deb

echo "downloading & installing rbfeeder:arm64 ..."
wget -O rbfeeder_1.0.15+bookworm_arm64.deb https://apt.rb24.com/pool/main/r/rbfeeder/rbfeeder_1.0.15%2bbookworm_arm64.deb
sudo dpkg -i rbfeeder_1.0.15+bookworm_arm64.deb || true
sudo apt -y --fix-broken install

sudo systemctl restart rbfeeder

echo "Plese check your file /etc/rbfeeder.ini. It will contain your feeder key and station number"
echo "Visit Radarbox Claims web page to claim the key and link station to yor account"
echo "You must login to your Radarbox account when visisting Claims page"




