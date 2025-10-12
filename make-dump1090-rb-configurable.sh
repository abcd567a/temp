#!/bin/bash

DEDICATED_FOLDER=/usr/lib/dump1090-rb
echo "Creating folder /usr/lib/dump1090-rb"
sudo mkdir ${DEDICATED_FOLDER}

echo "Creating startup script file startup.sh"
STARTUP_SCRIPT=${DEDICATED_FOLDER}/startup.sh
sudo touch ${STARTUP_SCRIPT}
sudo chmod 777 ${STARTUP_SCRIPT}
echo "Writing code to startup script file startup.sh"
/bin/cat <<EOM >${STARTUP_SCRIPT}
#!/bin/sh
CONFIG=""
while read -r line; do CONFIG="\${CONFIG} \$line"; done < /etc/default/dump1090-rb
##cd ${DEDICATED_FOLDER}
/usr/bin/dump1090-rb \${CONFIG}
EOM
sudo chmod +x ${STARTUP_SCRIPT}

echo "Creating config file /etc/default/dump1090-rb"
CONFIG_FILE=/etc/default/dump1090-rb
sudo touch ${CONFIG_FILE}
sudo chmod 777 ${CONFIG_FILE}
echo "Writing code to config file dump1090-rb"
/bin/cat <<EOM >${CONFIG_FILE}
--gain 49.6
--device 0
--net
--net-ri-port 30001
--net-ro-port 30002
--net-sbs-port 30003
--net-bi-port 30004,30104
--net-bo-port 30005
--quiet 
--write-json /var/run/dump1090
--mlat 
--forward-mlat
--modeac 
--fix
--gnss

EOM
sudo chmod 644 ${CONFIG_FILE}

echo "Changing network_mode from false to true in file /etc/rbfeeder.ini   "
sed -i 's/^network_mode=.*/network_mode=true/' /etc/rbfeeder.ini

echo "Creating User dump1090 to run dump1090-rb"
sudo adduser --system --no-create-home dump1090
sudo usermod -aG plugdev dump1090

echo "Assigning ownership of dedicated folder to user dump1090"
sudo chown dump1090:dump1090 -R ${DEDICATED_FOLDER}

echo "Creating Service file dump1090-rb.service"
SERVICE_FILE=/lib/systemd/system/dump1090-rb.service
sudo touch ${SERVICE_FILE}
sudo chmod 777 ${SERVICE_FILE}
/bin/cat <<EOM >${SERVICE_FILE}
# dump1090-rb service for systemd
[Unit]
Description=dump1090-rb
Wants=network.target
After=network.target
[Service]
User=dump1090
RuntimeDirectory=dump1090
RuntimeDirectoryMode=0755
ExecStart=/bin/bash ${DEDICATED_FOLDER}/startup.sh
SyslogIdentifier=dump1090-rb
Type=simple
Restart=on-failure
RestartSec=30
RestartPreventExitStatus=64
Nice=-5
[Install]
WantedBy=default.target

EOM

sudo chmod 644 ${SERVICE_FILE}
sudo systemctl enable dump1090-rb
sudo systemctl restart dump1090-rb

echo " "
echo " "
echo -e "\e[32mINSTALLATION COMPLETED \e[39m"
echo -e "\e[32m=======================\e[39m"
echo -e "\e[32mPLEASE DO FOLLOWING:\e[39m"
echo -e "\e[32m=======================\e[39m"
echo " "
-e "\e[33m(2) If you want to change Gain or device serial number, \e[39m"
echo -e "\e[33m(2) then open file /etc/deault/dump1090-rb by following command:\e[39m"
echo -e "\e[39m     sudo nano /etc/deault/dump1090-rb \e[39m"
echo ""
echo -e "\e[33mAdd following lines:\e[39m"
echo -e "\e[39m     --lat xx.xxxx \e[39m"
echo -e "\e[39m     --lon yy.yyyy \e[39m"
echo ""
echo -e "\e[33m(Replace xx.xxxx and yy.yyyy \e[39m"
echo -e "\e[33mby your actual latitude and longitude) \e[39m"
echo -e "\e[33mSave (Ctrl+o) and Close (Ctrl+x) file /etc/default/dump1090-rb \e[39m"
echo ""
echo -e "\e[33mthen restart dump1090-rb by following command:\e[39m"
echo -e "\e[39m     sudo systemctl restart dump1090-rb \e[39m"
echo " "

echo -e "\e[32mTo see status\e[39m sudo systemctl status dump1090-rb"
echo -e "\e[32mTo restart\e[39m    sudo systemctl restart dump1090-rb"
echo -e "\e[32mTo stop\e[39m       sudo systemctl stop dump1090-rb"
echo ""
echo -e "\e[01;31mREBOOT RPi \e[39m"
echo -e "\e[01;31mREBOOT RPi \e[39m"
echo -e "\e[01;31mREBOOT RPi \e[39m"
echo ""

