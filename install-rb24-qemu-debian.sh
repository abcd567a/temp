#!/bin/bash
set -e

sudo apt update
sudo apt -y install qemu-user qemu-user-binfmt binfmt-support

sudo dpkg --add-architecture arm64
sudo apt update
sudo apt -y install libc6:arm64

sudo apt install dirmngr gnupg
gpg --keyserver keyserver.ubuntu.com --recv-keys F2A8428D3C354953
gpg --export --armor F2A8428D3C354953 | sudo gpg --dearmor -o /etc/apt/keyrings/rb24.gpg
echo "deb [signed-by=/etc/apt/keyrings/rb24.gpg] https://apt.rb24.com/ bookworm main" | sudo tee /etc/apt/sources.list.d/rb24.list

sudo apt update
sudo apt install rbfeeder

sudo systemctl restart rbfeeder

echo "Plese check your file /etc/rbfeeder.ini. I will contain your feeder key and station number"
echo "Visit Radarbox Claims web page to claim the key and link station to yor account"
echo "You must login to your Radarbox account when visisting Claims page"

