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

## UBUNTU
if [[ ${OS_VERSION} == noble ]]; then
  OS_VERSION=bookworm
  
## ANY OTHER
else
   echo -e "\e[01;31mThis script is NOT for installation on" ${OS_ID} ${OS_RELEASE} ${OS_VERSION} "\e[39m"
   exit
fi

echo -e "\e[36mBUILDING PACKAGE USING DEBIAN VER" ${OS_VERSION} "\e[39m"

echo -e "\e[32mInstalling Build tools & Build dependencies\e[39m"

#Build-Tools
apt install -y \
git \
build-essential \
devscripts

#Build-Depends: 
apt install -y \
debhelper \
tcl8.6-dev \
autoconf \
python3-dev \
python3-venv \
python3-setuptools \
python3-filelock \
libz-dev \
openssl \
libboost-system-dev \
libboost-program-options-dev \
libboost-regex-dev \
libboost-filesystem-dev \
patchelf \
python3-wheel \
python3-build \
python3-pip

echo -e "\e[32mBuilding & Installing tcl-tls from source code. \e[39m"
echo -e "\e[32mInstalling tcl-tls dependencies \e[39m"
apt install -y \
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
git fetch --all
git reset --hard origin/master
echo -e "\e[32mbuilding tcl-tls package \e[39m"
if [[ ${OS_VERSION} == bookworm ]]; then 
  ./prepare-build.sh bullseye
  cd package-bullseye
  dpkg-buildpackage -b --no-sign
else
  ./prepare-build.sh ${OS_VERSION}
  cd package-${OS_VERSION}
  dpkg-buildpackage -b --no-sign
fi

echo -e "\e[32mInstalling tcl-tls package \e[39m"
cd ../
dpkg -i tcl-tls_*.deb
apt-mark hold tcl-tls

echo -e "\e[36mBUILDING PIAWARE PACKAGE USING DEBIAN VER" ${OS_VERSION} "\e[39m"

echo -e "\e[32mInstalling piaware dependencies \e[39m"

#Depends:
apt install -y \
net-tools \
iproute2 \
tclx8.4 \
tcl8.6 \
tcllib \
itcl3

cd ${INSTALL_DIRECTORY}

if [[ -d piaware_builder ]];
then
echo -e "\e[32mRenaming existing piaware_builder folder by adding prefix \"old\" \e[39m"
mv piaware_builder piaware_builder-old-$RANDOM
fi

echo -e "\e[32mCloning piaware source code and building package \e[39m"
git clone https://github.com/flightaware/piaware_builder
cd ${INSTALL_DIRECTORY}/piaware_builder
git fetch --all
git reset --hard origin/master
echo -e "\e[32mBuilding the piaware package \e[39m"
./sensible-build.sh ${OS_VERSION}
cd ${INSTALL_DIRECTORY}/piaware_builder/package-${OS_VERSION}

 sed -i  's/ clean_mlat-client / /' debian/rules
 sed -i  's/ build_mlat-client / /' debian/rules
 sed -i  's/ install_mlat-client / /' debian/rules
 sed -i '/override_dh_strip:/s/^/#/' debian/rules
 sed -i '/dh_strip -X debian/s/^/#/' debian/rules
 
 sed -i '/build_mlat-client/s/^/#/' debian/rules
 sed -i '/$(VENV)\/bin\/python -m build --skip-dependency-check/s/^/#/' debian/rules
 sed -i '/$(VENV)\/bin\/python -m pip install --no-index --no-deps/s/^/#/' debian/rules
 sed -i '/$(VENV)\/bin\/python -m build --skip-dependency-check/s/^/#/' debian/rules
 sed -i '/$(VENV)\/bin\/python -m pip install --no-index /s/^/#/' debian/rules
 
 sed -i '/install_mlat-client:/s/^/#/' debian/rules                     
 sed -i '/$(VENV)\/bin\/python $(VENV)\/bin\/cxfreeze --target-dir/s/^/#/' debian/rules
 sed -i '/cp -a $(CURDIR)\/freeze-mlat-client /s/^/#/' debian/rules     

 sed -i '/clean_mlat-client:/s/^/#/' debian/rules
 sed -i '/rm -fr mlat-client\/build/s/^/#/' debian/rules
 sed -i '/rm -fr cx_Freeze-6.15.9/s/^/#/' debian/rules
 sed -i '/rm -fr $(VENV) $(CURDIR)\/wheels/s/^/#/' debian/rules
 sed -i '/cp -a $(CURDIR)\/freeze-mlat-client/s/^/#/' debian/rules

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
echo -e "\e[1;35mThe piaware has been built WITHOUT fa-mlat-client \e[39m"
echo -e "\e[1;35mdue to mlat-client is incompatible to Python 3.12.... \e[39m"
echo -e "\e[1;31mMLAT will NOT be enabled .... \e[39m"

