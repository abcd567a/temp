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
OS_EQV_VERSION=""

echo -e "\e[35mDETECTED OS VERSION" ${OS_ID} ${OS_RELEASE} ${OS_VERSION}  "\e[39m"

## UBUNTU 24 & Debian 13
if [[ ${OS_VERSION} == noble ]] || [[ ${OS_VERSION} == trixie ]]; then
  OS_EQV_VERSION=trixie
  
## ANY OTHER
else
   echo -e "\e[01;31mThis script is NOT for installation on" ${OS_ID} ${OS_RELEASE} ${OS_VERSION} "\e[39m"
   exit
fi

echo -e "\e[36mBUILDING PACKAGE USING DEBIAN VER" ${OS_EQV_VERSION} "\e[39m"

echo -e "\e[32mInstalling Build tools, Build dependencies, & other Dependencies\e[39m"

##Build-Tools
apt install \
git \
build-essential \
devscripts

##Build-Depends: 
apt install \
debhelper \
tcl8.6-dev \
autoconf \
python3-dev \
python3-venv \
python3-setuptools \
python3-filelock \
python3-wheel \
python3-build \
python3-pip \
python3-pyasyncore \
libz-dev \
openssl \
libboost-system-dev \
libboost-program-options-dev \
libboost-regex-dev \
libboost-filesystem-dev \
patchelf

##Depends
apt install \
net-tools \
iproute2 \
tcl \
tclx8.4 \
tcl8.6 \
tcllib \
itcl3

echo -e "\e[32mBuilding & Installing tcl-tls from source code. \e[39m"
echo -e "\e[32mInstalling tcl-tls dependencies \e[39m"
apt install \
libssl-dev \
tcl-dev \
chrpath

cd  ${INSTALL_DIRECTORY}

if [[ -d tcltls-rebuild ]];
then
echo -e "\e[32mRenaming existing tcltls-rebuild folder by adding prefix \"old\" \e[39m"
mv tcltls-rebuild tcltls-rebuild-old-$RANDOM
fi

echo -e "\e[32mCloning tcl-tls source code \e[39m"
git clone https://github.com/flightaware/tcltls-rebuild
cd  ${INSTALL_DIRECTORY}/tcltls-rebuild
echo -e "\e[32mbuilding tcl-tls package \e[39m"
if [[ ${OS_EQV_VERSION} == trixie ]]; then 
  ./prepare-build.sh bullseye
  cd package-bullseye
  dpkg-buildpackage -b --no-sign
fi

echo -e "\e[32mInstalling tcl-tls package \e[39m"
cd ../
dpkg -i tcl-tls_*.deb
apt-mark hold tcl-tls

echo -e "\e[36mBUILDING PIAWARE PACKAGE USING DEBIAN VER" ${OS_VERSION} "\e[39m"

cd ${INSTALL_DIRECTORY}

if [[ -d piaware_builder ]];
then
echo -e "\e[32mRenaming existing piaware_builder folder by adding prefix \"old\" \e[39m"
mv piaware_builder piaware_builder-old-$RANDOM
fi

echo -e "\e[32mCloning piaware source code and building package \e[39m"
git clone https://github.com/abcd567a/piaware_builder
cd ${INSTALL_DIRECTORY}/piaware_builder
echo -e "\e[32mBuilding the piaware package \e[39m"
./sensible-build.sh ${OS_EQV_VERSION}
cd ${INSTALL_DIRECTORY}/piaware_builder/package-${OS_EQV_VERSION}
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

