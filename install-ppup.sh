#!/bin/bash
VERSION=ppup1090-vsns-nic-2024-05-19
INSTALL_FOLDER=/usr/share/ppup

echo " "
## Detect OS 
OS_ID=`lsb_release -si`
OS_RELEASE=`lsb_release -sr`
OS_VERSION=`lsb_release -sc`
echo -e "\e[35mDETECTED OS VERSION \e[32m" ${OS_ID} ${OS_RELEASE} ${OS_VERSION}  "\e[39m"
ARCHITECTURE=`uname -m`
echo -e "\e[35mDetected architecture \e[32m" ${ARCHITECTURE}  "\e[39m"
echo " "
sleep 5

echo "Creating folder ppup"
mkdir ${INSTALL_FOLDER}

echo "Downloading compiled binaries from coaa.co.uk"
wget -O ${INSTALL_FOLDER}/${VERSION}.zip https://www.coaa.co.uk/${VERSION}.zip

echo "Unzipping compiled binaries"
unzip ${INSTALL_FOLDER}/${VERSION}.zip -d ${INSTALL_FOLDER}
echo "Moving binaries folder"
mv ${INSTALL_FOLDER}/${VERSION}/* ${INSTALL_FOLDER}/
rm -rf ${INSTALL_FOLDER}/${VERSION}

echo "Detecting which binary should be copied to" ${INSTALL_FOLDER}

BINARY_FOLDER=""
if [[ ${OS_VERSION} == bookworm && ${ARCHITECTURE} == aarch64 ]]; then
   BINARY_FOLDER=Bookworm-64
   echo "Using Binary in Folder:" ${BINARY_FOLDER};


elif [[ ${OS_VERSION} == bookworm && ${ARCHITECTURE} == armv7l ]]; then
   BINARY_FOLDER=Bookworm-32
   echo "Using Binary in Folder:" ${BINARY_FOLDER};

elif [[ ${OS_VERSION} == bullseye && ${ARCHITECTURE} == aarch64 ]]; then
   BINARY_FOLDER=Bullseye-64
   echo "Using Binary in Folder:" ${BINARY_FOLDER};

elif [[ ${OS_VERSION} == bullseye && ${ARCHITECTURE} == armv7l ]]; then
   BINARY_FOLDER=Bullseye-32
   echo "Using Binary in Folder:" ${BINARY_FOLDER};

elif [[ ${OS_VERSION} == buster && ${ARCHITECTURE} == armv7l ]]; then
   BINARY_FOLDER=Buster-32
   echo "Using Binary in Folder:" ${BINARY_FOLDER};

else
  echo "Do NOT have ppup1090 binary for your OS.....aborting installation"
  exit

fi

echo "Copying binary to" ${INSTALL_FOLDER}
cp ${INSTALL_FOLDER}/${BINARY_FOLDER}/ppup1090 ${INSTALL_FOLDER}/
chmod +x ${INSTALL_FOLDER}/ppup1090
 

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
After=network.target

[Service]
User=ppup
RuntimeDirectory=ppup1090
RuntimeDirectoryMode=0755
ExecStart=${INSTALL_FOLDER}/ppup1090 --coaah ${INSTALL_FOLDER}/coaa.h
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
echo -e "\e[33m  1. Copy coaa.h to folder" ${INSTALL_FOLDER}"/  \e[39m"
echo -e "\e[95m     NOTE: If you do not already have a coaa.h file, \e[39m"
echo -e "\e[95m     or it has expired due to long priod of no use, \e[39m"
echo -e "\e[95m     then request it from following address: \e[39m"
echo -e "\e[39m       https://www.coaa.co.uk/rpi-request.htm \e[39m"
echo " "
echo -e "\e[33m  2. Restart ppup1090 by following command: \e[39m"
echo -e "\e[39m     sudo systemctl restart ppup1090 \e[39m"
echo " "
echo -e "\e[33m  3. Test ppup1090 status by following link \e[39m"
echo -e "\e[39m     https://www.coaa.co.uk/rpiusers.php?authcode=123456789 \e[39m"
echo -e "\e[95m     Instead of 123456789, use your authcode \e[39m"
echo -e "\e[95m     (your authcode is available in file coaa.h) \e[39m"
echo " "
echo -e "\e[32mTo see status\e[39m sudo systemctl status ppup1090 \e[39m"
echo -e "\e[32mTo restart\e[39m    sudo systemctl restart ppup1090 \e[39m"
echo -e "\e[32mTo stop\e[39m       sudo systemctl stop ppup1090 \e[39m"



