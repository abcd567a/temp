#!/bin/bash
INSTALL_FOLDER=/usr/share/ppup1090

echo "Creating folder ppup1090"
mkdir ${INSTALL_FOLDER}

echo "Creating symlink to ppup1090 binary in folder /usr/bin/ "
ln -s ${INSTALL_FOLDER}/ppup1090 /usr/bin/ppup1090


echo "Creating User ppup to run ppup1090"
adduser --system --no-create-home ppup

echo "Assigning ownership of install folder to user ppup"
sudo chown ppup:ppup -R ${INSTALL_FOLDER}

echo "Creating Service file ppup1090.service"
SERVICE_FILE=/lib/systemd/system/ppup1090.service
touch ${SERVICE_FILE}
chmod 777 ${SERVICE_FILE}
/bin/cat <<EOM >${SERVICE_FILE}
# ppup1090 service for systemd

[Unit]
Description=ppup1090 Planeplotter uploader
After=network.target dump1090-fa.service 
PartOf=dump1090-fa.service

[Service]
User=ppup
RuntimeDirectory=ppup1090
RuntimeDirectoryMode=0755
ExecStart=/usr/share/ppup1090/ppup1090 --coaah /usr/share/ppup1090/coaa.h
SyslogIdentifier=ppup1090
Type=simple
Restart=on-failure
RestartSec=30
RestartPreventExitStatus=64
Nice=-5

[Install]
WantedBy=default.target

EOM

chmod 644 ${SERVICE_FILE}
systemctl enable ppup1090
systemctl restart ppup1090

echo " "
echo " "
echo -e "\e[32mINSTALLATION COMPLETED \e[39m"
echo -e "\e[32m=======================\e[39m"
echo -e "\e[32mPLEASE DO FOLLOWING:\e[39m"
echo -e "\e[32m=======================\e[39m"
echo " "
echo -e "\e[33m1. Copy coaa.h to folder /usr/share/ppup1090/ \e[39m"
echo " "
echo -e "\e[33m2. Copy compiled binary ppup1090 to folder /usr/share/ppup1090/ \e[39m"
echo -e "\e[95m   IMPORTANT: Make sure the binary is named ppup1090 \e[39m"
echo " "
echo -e "\e[33m3. Make the copied binary executable by following command: \e[39m"
echo -e "\e[39m     sudo chmod +x /usr/share/ppup1090 \e[39m"
echo " "
echo -e "\e[33m4. Restart ppup1090 by following command: \e[39m"
echo -e "\e[39m     sudo systemctl restart ppup1090 \e[39m"
echo " "

echo -e "\e[32mTo see status\e[39m sudo systemctl status ppup1090 \e[39m"
echo -e "\e[32mTo restart\e[39m    sudo systemctl restart ppup1090 \e[39m"
echo -e "\e[32mTo stop\e[39m       sudo systemctl stop ppup1090 \e[39m"



