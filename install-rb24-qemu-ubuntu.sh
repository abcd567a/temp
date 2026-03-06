#!/bin/bash
set -e

sudo apt update || true

echo -e "\e[1;32mInstalling packages to provide QEMU support ...\e[0;39m"
sudo apt -y install qemu-user qemu-user-binfmt binfmt-support

echo -e "\e[1;32mAdding line \"Architectures: amd64\" to existing file \"ubuntu.sources\", if not already there ...\e[0;39m"
sudo sed -i '/Architectures: amd64/d' /etc/apt/sources.list.d/ubuntu.sources
sudo sed -i '/Types: deb/a Architectures: amd64' /etc/apt/sources.list.d/ubuntu.sources

echo -e "\e[1;32mAdding arhitecture arm64 to system ...\e[0;39m"
sudo dpkg --add-architecture arm64

echo -e "\e[1;32mCreating arm64 apt-source file \"ubuntu-ports-arm64.sources\"  \e[0;39m"
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

echo -e "\e[1;32mInstalling package libc6:arm64 to provide ar m64 support ...\e[0;39m"
sudo apt -y install libc6:arm64

echo -e "\e[1;32mDownloading & installing package \"librtlsdr0\" from Debian archieves ...\e[0;39m"
sudo wget -O /tmp/librtlsdr0_0.6.0-4_arm64.deb http://http.us.debian.org/debian/pool/main/r/rtl-sdr/librtlsdr0_0.6.0-4_arm64.deb
sudo dpkg -i /tmp/librtlsdr0_0.6.0-4_arm64.deb

echo -e "\e[1;32mSetting up RB24 repository \e[0;39m"
sudo apt install -y dirmngr gnupg
gpg --keyserver keyserver.ubuntu.com --recv-keys F2A8428D3C354953
gpg --export --armor F2A8428D3C354953 | sudo gpg --dearmor -o /etc/apt/keyrings/rb24.gpg
echo "deb [signed-by=/etc/apt/keyrings/rb24.gpg] https://apt.rb24.com/ bookworm main" | sudo tee /etc/apt/sources.list.d/rb24.list

sudo apt update 

echo -e "\e[1;32mRunning command \"sudo apt install rbfeeder\" to nstalli rbfeeder:arm64 from RB24 repository ...\e[0;39m"
sudo apt install -y rbfeeder

sudo systemctl restart rbfeeder

echo " "
echo -e "\e[1;35mPlese check your file \e[1;32m /etc/rbfeeder.ini \e" "\e[1;35m It will contain your feeder key and station number \e[0;39m"
echo -e "\e[1;35mVisit Radarbox Claims web page to claim the key and link station to yor account \e[0;39m"
echo -e "\e[1;35mYou must login to your Radarbox account when visisting Claims page \e[0;39m"




