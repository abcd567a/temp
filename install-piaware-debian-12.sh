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

echo -e "\e[32mInstalling Build tools & Build dependencies\e[39m"

#Build-Tools
apt install -y git
apt install -y build-essential
apt install -y devscripts

#Build-Depends:
apt install -y debhelper
apt install -y tcl8.6-dev
apt install -y autoconf
apt install -y python3-dev
apt install -y python3-build
apt install -y python3-venv
apt install -y python3-setuptools
apt install -y libz-dev
apt install -y openssl
apt install -y libboost-system-dev
apt install -y libboost-program-options-dev
apt install -y libboost-regex-dev
apt install -y libboost-filesystem-dev
apt install -y patchelf

echo -e "\e[32mBuilding & Installing tcl-tls from source code. \e[39m"
echo -e "\e[32mInstalling tcl-tls dependencies \e[39m"
apt install -y libssl-dev
apt install -y tcl-dev
apt install -y chrpath

echo -e "\e[32mCloning tcl-tls source code \e[39m"

cd  ${INSTALL_DIRECTORY}

if [[ -d tcltls-rebuild ]];
then
echo -e "\e[32mRenaming existing tcltls-rebuild folder by adding prefix \"old\" \e[39m"
mv tcltls-rebuild tcltls-rebuild-old-$RANDOM
fi

git clone https://github.com/flightaware/tcltls-rebuild
cd  ${INSTALL_DIRECTORY}/tcltls-rebuild
git fetch --all
git reset --hard origin/master
echo -e "\e[32mbuilding tcl-tls package \e[39m"
## ./prepare-build.sh ${OS_VERSION}
## cd package-${OS_VERSION}
./prepare-build.sh bullseye
cd package-bullseye

dpkg-buildpackage -b --no-sign
echo -e "\e[32mInstalling tcl-tls package \e[39m"
cd ../
dpkg -i tcl-tls_*.deb
apt-mark hold tcl-tls

echo -e "\e[32mInstalling piaware dependencies \e[39m"

#Depends:
apt install -y net-tools
apt install -y iproute2
apt install -y tclx8.4
apt install -y tcl8.6
apt install -y tcllib
apt install -y itcl3

echo -e "\e[32mCloning piaware source code and building package \e[39m"
cd ${INSTALL_DIRECTORY}
mv piaware_builder piaware_builder-old-$RANDOM
git clone https://github.com/flightaware/piaware_builder
cd ${INSTALL_DIRECTORY}/piaware_builder
git fetch --all
git reset --hard origin/dev
echo -e "\e[32mBuilding the piaware package \e[39m"
./sensible-build.sh ${OS_VERSION}
cd ${INSTALL_DIRECTORY}/piaware_builder/package-${OS_VERSION}

dpkg-buildpackage -b --no-sign
PIAWARE_VER=$(grep "Version:" debian/piaware/DEBIAN/control | sed 's/^Version: //')

echo -e "\e[32mInstalling piaware package\e[39m"
cd ../
dpkg -i piaware_${PIAWARE_VER}_*.deb

systemctl enable piaware
systemctl restart piaware

echo ""
echo -e "\e[32mPIAWARE INSTALLATION COMPLETED \e[39m"
echo ""
echo -e "\e[39mIf you already have  feeder-id, please configure piaware with it \e[39m"
echo -e "\e[39mFeeder Id is available on this address while loggedin: \e[39m"
echo -e "\e[94m    https://flightaware.com/adsb/stats/user/ \e[39m"
echo ""
echo -e "\e[39m    sudo piaware-config feeder-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \e[39m"
echo -e "\e[39m    sudo piaware-config allow-manual-updates yes \e[39m"
echo -e "\e[39m    sudo piaware-config allow-auto-updates yes \e[39m"
echo -e "\e[39m    sudo systemctl restart piaware \e[39m"
echo ""
echo -e "\e[39mIf you dont already have a feeder-id, please go to Flightaware Claim page while loggedin \e[39m"
echo -e "\e[94m    https://flightaware.com/adsb/piaware/claim \e[39m"
echo ""
