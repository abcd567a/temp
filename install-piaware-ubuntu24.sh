#!/bin/bash

echo -e "\e[1;32mUpdating\e[0;39m"
apt update

set -e
trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR

INSTALL_DIRECTORY=${PWD}

apt install -y lsb-release

## Detect OS
OS_ID=`lsb_release -si`
OS_RELEASE=`lsb_release -sr`
OS_VERSION=`lsb_release -sc`
OS_EQV_VERSION="noble"

echo -e "\e[1;35mDETECTED OS VERSION" ${OS_ID} ${OS_RELEASE} ${OS_VERSION}  "\e[0;39m"

## UBUNTU 24, Debian 13, and LinuxMint 22
if [[ ${OS_VERSION} == noble ]] || [[ ${OS_VERSION} == wilma ]] || [[ ${OS_VERSION} == xia ]]; then
      echo -e "\e[01;31mDetected OS version" ${OS_ID} ${OS_RELEASE} ${OS_VERSION} "Proceeding with Installation\e[0;39m"
else
   echo -e "\e[01;31mThis script is NOT for installation on" ${OS_ID} ${OS_RELEASE} ${OS_VERSION} "\e[39m"
   echo -e "\e[01;31mAborting installation .... \e[39m"
   exit
fi

echo -e "\e[1;36mBUILDING PACKAGE USING Ubuntu ver" ${OS_EQV_VERSION} "\e[0;39m"

echo -e "\e[1;32mInstalling Build tools \e[0;39m"
sleep 3
##Build-Tools
apt install -y \
git \
build-essential \
devscripts

echo -e "\e[1;32mInstalling Build dependencies \e[0;39m"
sleep 3
##Build-Depends:
apt install -y \
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

echo -e "\e[1;32mInstalling other Dependencies\e[0;39m"
sleep 3
##Depends
apt install -y \
net-tools \
iproute2 \
tcl \
tclx8.4 \
tcl8.6 \
tcllib \
tcl-tls \
itcl3 \
rsyslog

echo -e "\e[1;36mBUILDING PIAWARE PACKAGE USING DEBIAN VER" ${OS_VERSION} "\e[0;39m"
cd ${INSTALL_DIRECTORY}
if [[ -d piaware_builder ]];
then
echo -e "\e[1;32mRenaming existing piaware_builder folder by adding prefix \"old\" \e[0;39m"
mv piaware_builder piaware_builder-old-$RANDOM
fi
echo -e "\e[1;32mCloning piaware source code \e[0;39m"
git clone --depth 1 https://github.com/abcd567a/piaware_builder

echo -e "\e[1;32mBuilding the piaware package \e[0;39m"
cd ${INSTALL_DIRECTORY}/piaware_builder
./sensible-build.sh ${OS_EQV_VERSION}
cd ${INSTALL_DIRECTORY}/piaware_builder/package-${OS_EQV_VERSION}
dpkg-buildpackage -b --no-sign
PIAWARE_VER=$(grep "Version:" debian/piaware/DEBIAN/control | sed 's/^Version: //')

echo -e "\e[1;32mInstalling piaware package\e[0;39m"
cd ../
dpkg -i piaware_${PIAWARE_VER}_*.deb

systemctl enable piaware
systemctl restart piaware

echo ""
echo -e "\e[1;32mPIAWARE INSTALLATION COMPLETED \e[0;39m"
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

