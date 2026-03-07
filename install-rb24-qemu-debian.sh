#!/bin/bash
set -e

sudo apt update || true

echo -e "\e[1;32mInstalling packages to provide QEMU support ...\e[0;39m"
sudo apt -y install qemu-user qemu-user-binfmt binfmt-support

echo -e "\e[1;32mAdding arhitecture arm64 to system ...\e[0;39m"
sudo dpkg --add-architecture arm64
sudo apt update

echo -e "\e[1;32mInstalling package libc6:arm64 to provide ar m64 support ...\e[0;39m"
sudo apt -y install libc6:arm64

echo -e "\e[1;32mSetting up RB24 repository \e[0;39m"
sudo apt install -y dirmngr gnupg
gpg --keyserver keyserver.ubuntu.com --recv-keys F2A8428D3C354953
gpg --export --armor F2A8428D3C354953 | sudo gpg --dearmor -o /etc/apt/keyrings/rb24.gpg
echo "deb [signed-by=/etc/apt/keyrings/rb24.gpg] https://apt.rb24.com/ bookworm main" | sudo tee /etc/apt/sources.list.d/rb24.list

sudo apt update

echo -e "\e[1;32mRunning command \"sudo apt install rbfeeder\" to nstalli rbfeeder:arm64 from RB24 repository ...\e[0;39m"
sudo apt install -y rbfeeder
sudo systemctl restart rbfeeder

echo -e "\e[1;32mDownloading & installing package \"mlat-client\" from github.com/abcd567a/ ...\e[0;39m"
sudo apt install -y python3-pyasyncore
wget -O /tmp/mlat-client_0.2.13_trixie_amd64.deb https://github.com/abcd567a/rbfeeder/releases/download/v1.0/mlat-client_0.2.13_trixie_amd64.deb || true
sudo apt install -y /tmp/mlat-client_0.2.13_trixie_amd64.deb || true
sudo apt-mark hold mlat-client || true
sudo systemctl restart rbfeeder

echo " "
echo -e "\e[1;35mPlese check your file \e[1;32m /etc/rbfeeder.ini \e" "\e[1;35m It will contain your feeder key and station number \e[0;39m"
echo -e "\e[1;35mVisit Radarbox Claims web page to claim the key and link station to yor account \e[0;39m"
echo -e "\e[1;35mYou must login to your Radarbox account when visisting Claims page \e[0;39m"

