#!/bin/bash
set -e
echo -e "\e[1;32mUpdating ...\e[0;39m"; sleep 2
apt update || true

echo -e "\e[1;32mInstalling following packages to provide QEMU support ...
   qemu-user  qemu-user-binfmt  binfmt-support\e[0;39m"; sleep 4

apt -y install qemu-user qemu-user-binfmt binfmt-support

echo -e "\e[1;32mAdding arhitecture arm64 to system ...\e[0;39m"; sleep 2
dpkg --add-architecture arm64
apt update

echo -e "\e[1;32mInstalling package libc6:arm64 to provide arm64 support ...\e[0;39m"; sleep 2
sudo apt -y install libc6:arm64
apt --fix-broken install

echo -e "\e[1;32mSetting up RB24 repository \e[0;39m"; sleep 2
apt install -y dirmngr gnupg
gpg --keyserver keyserver.ubuntu.com --recv-keys F2A8428D3C354953
gpg --export --armor F2A8428D3C354953 | sudo gpg --dearmor -o /etc/apt/keyrings/rb24.gpg

if [[ `lsb_release -sc` == bookworm ]]; then
   echo "deb [signed-by=/etc/apt/keyrings/rb24.gpg] https://apt.rb24.com/ bookworm main" | sudo tee /etc/apt/sources.list.d/rb24.list
elif [[ `lsb_release -sc` == trixie ]]; then
   echo "deb [signed-by=/etc/apt/keyrings/rb24.gpg] https://apt.rb24.com/ trixie main" | sudo tee /etc/apt/sources.list.d/rb24.list
fi

apt update

echo -e "\e[1;32mRunning command \"sudo apt install rbfeeder:arm64\" to nstalli rbfeeder from RB24 repository ...\e[0;39m"; sleep 2
apt install -y rbfeeder:arm64 || true
apt --fix-broken install
systemctl restart rbfeeder

echo -e "\e[1;32mDownloading & installing package \"mlat-client\" from github.com/abcd567a/ ...\e[0;39m"; sleep 2
if [[ `lsb_release -sc` == bookworm ]]; then
wget -O /tmp/mlat-client_0.2.13_bookworm_amd64.deb https://github.com/abcd567a/rbfeeder/releases/download/v1.0/mlat-client_0.2.13_bookworm_amd64.deb
apt install -y /tmp/mlat-client_0.2.13_bookworm_amd64.deb || true
apt --fix-broken install

elif [[ `lsb_release -sc` == trixie ]]; then
apt install -y python3-pyasyncore
wget -O /tmp/mlat-client_0.2.13_trixie_amd64.deb https://github.com/abcd567a/rbfeeder/releases/download/v1.0/mlat-client_0.2.13_trixie_amd64.deb
apt install -y /tmp/mlat-client_0.2.13_trixie_amd64.deb || true
apt --fix-broken install
fi

apt-mark hold mlat-client || true
systemctl restart rbfeeder

echo " "
echo -e "\e[1;32mTHE SCRIPT HAS COMPLETED INSTALLATION......\e[0;39m"
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

