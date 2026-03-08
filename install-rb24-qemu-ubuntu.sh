#!/bin/bash
set -e

OS_VER=`lsb_release -sc`
echo -e "\e[1;32mUpdating ...\e[0;39m"; sleep 2
apt update || true

echo -e "\e[1;32mInstalling packages to provide QEMU support ...\e[0;39m"; sleep 2
apt -y install qemu-user qemu-user-binfmt binfmt-support


echo -e "\e[1;32mAdding arhitecture arm64 to system ...\e[0;39m"; sleep 2
dpkg --add-architecture arm64


if [[ ${OS_VER} == noble ]]; then
cp -n /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.bak
echo -e "\e[1;32mAdding line \"Architectures: amd64\" to existing file \"ubuntu.sources\", if not already there ...\e[0;39m"; sleep 2
sed -i '/Architectures: amd64/d' /etc/apt/sources.list.d/ubuntu.sources
sed -i '/Types: deb/a Architectures: amd64' /etc/apt/sources.list.d/ubuntu.sources

echo -e "\e[1;32mCreating arm64 apt-source file \"ubuntu-ports-arm64.sources\"  \e[0;39m"; sleep 2
NOBLE_ARM64_SOURCES_FILE=/etc/apt/sources.list.d/ubuntu-ports-arm64.sources
touch ${NOBLE_ARM64_SOURCES_FILE}
chmod 777 ${NOBLE_ARM64_SOURCES_FILE}
echo "Writing code to file ubuntu-ports-arm64.sources"
/bin/cat <<EOM >${NOBLE_ARM64_SOURCES_FILE}
Types: deb
URIs: http://ports.ubuntu.com/ubuntu-ports/
Suites: noble noble-updates noble-security
Components: main restricted universe multiverse
Architectures: arm64
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

EOM

chmod 644 ${NOBLE_ARM64_SOURCES_FILE}


elif [[ ${OS_VER} == jammy ]]; then
cp -n /etc/apt/sources.list /etc/apt/sources.list.bak
echo -e "\e[1;32mAdding \"[arch=amd64]\" after \"deb\" to all lines in existing file \"sources.list\" ...\e[0;39m"; sleep 2
sed -i 's/^deb http/deb [arch=amd64] http/' /etc/apt/sources.list

echo -e "\e[1;32mCreating arm64 apt-source file \"ubuntu-ports-arm64.list\" ...\e[0;39m"; sleep 2
JAMMY_ARM64_SOURCES_FILE=/etc/apt/sources.list.d/ubuntu-ports-arm64.list
touch ${JAMMY_ARM64_SOURCES_FILE}
chmod 777 ${JAMMY_ARM64_SOURCES_FILE}
echo "Writing code to file ubuntu-ports-arm64.list"
/bin/cat <<EOM >${JAMMY_ARM64_SOURCES_FILE}
deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports jammy main restricted universe multiverse
deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports jammy-updates main restricted universe multiverse
deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports jammy-security main restricted universe multiverse

EOM

chmod 644 ${JAMMY_ARM64_SOURCES_FILE}

fi

apt update

echo -e "\e[1;32mInstalling package libc6:arm64 to provide ar m64 support ...\e[0;39m"; sleep 2
apt -y install libc6:arm64

if [[ ${OS_VER} == noble ]]; then
echo -e "\e[1;32mDownloading & installing package \"librtlsdr0\" from Debian archieves ...\e[0;39m"; sleep 2
wget -O /tmp/librtlsdr0_0.6.0-4_arm64.deb http://http.us.debian.org/debian/pool/main/r/rtl-sdr/librtlsdr0_0.6.0-4_arm64.deb
apt install -y /tmp/librtlsdr0_0.6.0-4_arm64.deb
fi

echo -e "\e[1;32mSetting up RB24 repository \e[0;39m"; sleep 2
apt install -y dirmngr gnupg
gpg --keyserver keyserver.ubuntu.com --recv-keys F2A8428D3C354953
gpg --export --armor F2A8428D3C354953 | sudo gpg --dearmor -o /etc/apt/keyrings/rb24.gpg

if [[ ${OS_VER} == noble ]]; then
echo "deb [signed-by=/etc/apt/keyrings/rb24.gpg] https://apt.rb24.com/ bookworm main" | sudo tee /etc/apt/sources.list.d/rb24.list
elif [[ ${OS_VER} == jammy ]]; then
echo "deb [signed-by=/etc/apt/keyrings/rb24.gpg] https://apt.rb24.com/ bullseye main" | sudo tee /etc/apt/sources.list.d/rb24.list
fi

apt update

echo -e "\e[1;32mRunning command \"apt install rbfeeder:arm64\" to nstalli rbfeeder from RB24 repository ...\e[0;39m"; sleep 2
apt install -y rbfeeder:arm64
systemctl restart rbfeeder

echo -e "\e[1;32mDownloading & installing package \"mlat-client\" from github.com/abcd567a/ ...\e[0;39m"; sleep 2
if [[ ${OS_VER} == noble ]]; then
apt install -y python3-pyasyncore
wget -O /tmp/mlat-client_0.2.13_noble_amd64.deb https://github.com/abcd567a/rbfeeder/releases/download/v1.0/mlat-client_0.2.13_noble_amd64.deb || true
apt install -y /tmp/mlat-client_0.2.13_noble_amd64.deb || true

elif [[ ${OS_VER} == jammy ]]; then
wget -O /tmp/mlat-client_0.2.13_jammy_amd64.deb https://github.com/abcd567a/rbfeeder/releases/download/v1.0/mlat-client_0.2.13_jammy_amd64.deb
apt install -y /tmp/mlat-client_0.2.13_jammy_amd64.deb
fi

apt-mark hold mlat-client || true

systemctl restart rbfeeder


echo " "
echo -e "\e[1;35m(1) Plese check your file \e[1;32msudo nano /etc/rbfeeder.ini \e" "\e[1;35m 
It will contain your feeder key and station number \e[0;39m"
echo ""
echo -e "\e[1;35m(2) Command to check status:      \e[1;32m sudo systemctl status rbfeeder \e[0;39m"
echo -e "\e[1;35m(3) Command to restart rbfeeder:  \e[1;32m sudo systemctl restart rbfeeder \e[0;39m"
echo ""
echo -e "\e[1;33m(4) The mlat-client has been installed. 
Configure your location (lat, lon, alt) to activate mlat. \e[0;39m"
echo ""
echo -e "\e[1;35m(5) Visit Radarbox Claims web page to link station to yor account \e[0;39m"
echo -e "\e[1;35mYou must login to your Radarbox account when visisting Claims page \e[0;39m"

echo " "

