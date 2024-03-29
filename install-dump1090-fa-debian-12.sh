#!/bin/bash

set -e
trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR

INSTALL_DIRECTORY=${PWD}

echo -e "\e[32mUpdating\e[39m"
apt update
apt install -y lsb-release

## Detect OS
OS_ID=`lsb_release -si`
OS_RELEASE=`lsb_release -sr`
OS_VERSION=`lsb_release -sc`

echo -e "\e[35mDETECTED OS VERSION" ${OS_ID} ${OS_RELEASE} ${OS_VERSION}  "\e[39m"

## DEBIAN
if [[ ${OS_VERSION} == bookworm ]]; then
  OS_VERSION=bookworm

## UBUNTU
elif [[ ${OS_VERSION} == lunar ]]; then
  OS_VERSION=bookworm

## KALI LINUX
elif [[ ${OS_ID} == Kali && ${OS_RELEASE%.*} == 2023 ]]; then
  OS_VERSION=bookworm

else
   echo -e "\e[01;31mdont know how to install on" ${OS_ID} ${OS_RELEASE} ${OS_VERSION} "\e[39m"
   exit
fi

echo -e "\e[36mBUILDING PACKAGE USING DEBIAN VER" ${OS_VERSION} "\e[39m"

echo -e "\e[32mInstalling Build tools and Build dependencies\e[39m"

##Build-Tools
apt install -y git
apt install -y build-essential
apt install -y devscripts

##Build-Depends:
apt install -y debhelper
apt install -y librtlsdr-dev
apt install -y libbladerf-dev
apt install -y libhackrf-dev
apt install -y liblimesuite-dev
apt install -y libusb-1.0-0-dev
apt install -y pkg-config
apt install -y libncurses5-dev
apt install -y libsoapysdr-dev

echo -e "\e[32mInstalling dependencies \e[39m"

##Depends:
apt install -y adduser
apt install -y lighttpd

if [[ ${OS_ID} == Kali ]];
then
systemctl enable lighttpd
systemctl restart lighttpd
fi

cd ${INSTALL_DIRECTORY}

if [[ -d dump1090 ]];
then
echo -e "\e[32mRenaming existing dump1090 folder by adding prefix \"old\" \e[39m"
mv dump1090 dump1090-old-$RANDOM
fi

echo -e "\e[32mCloning dump1090-fa source code\e[39m"
git clone https://github.com/flightaware/dump1090

cd ${INSTALL_DIRECTORY}/dump1090
git fetch --all
git reset --hard origin/dev

echo -e "\e[32mBuilding dump1090-fa package\e[39m"
./prepare-build.sh ${OS_VERSION}
cd ${INSTALL_DIRECTORY}/dump1090/package-${OS_VERSION}

dpkg-buildpackage -b --no-sign
DUMP_VER=$(grep "Version:" debian/dump1090-fa/DEBIAN/control | sed 's/^Version: //')

echo -e "\e[32mInstalling dump1090-fa\e[39m"
cd ../
dpkg -i dump1090-fa_${DUMP_VER}_*.deb

systemctl enable dump1090-fa
systemctl restart dump1090-fa

echo ""
echo -e "\e[32mDUMP1090-FA INSTALLATION COMPLETED \e[39m"
echo -e "\e[31mREBOOT Computer \e[39m"
echo -e "\e[31mREBOOT Computer \e[39m"
echo -e "\e[31mREBOOT Computer \e[39m"
echo ""















