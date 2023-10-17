#!/bin/bash

set -e
trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR

#####################################################################################
echo -e "\e[1;35mCREATING THE DATA MIXER AND MAP OF COMBINED DATA \e[39;0m"
echo -e "\e[1;32mInstalling 2nd copy of dump1090-fa as mixer in --net-only mode \e[39;0m"
#####################################################################################
sleep 5
echo " Copying dump1090-fa binary as mixer....."
install -m 755 /usr/bin/dump1090-fa /usr/bin/mixer

INSTALL_FOLDER=/usr/share/mixer
if [[ ! -d ${INSTALL_FOLDER} ]];
then
echo -e "\e[32mCreating Installation Folder ${INSTALL_FOLDER} \e[39m"
mkdir ${INSTALL_FOLDER}
fi

cp -R /usr/share/skyaware/html  ${INSTALL_FOLDER}/

cp /usr/share/dump1090-fa/start-dump1090-fa  ${INSTALL_FOLDER}/start-mixer
sed -i 's/dump1090-fa/mixer/g' ${INSTALL_FOLDER}/start-mixer

cp /etc/default/dump1090-fa /etc/default/mixer
sed -i '/RECEIVER=/c\RECEIVER=none' /etc/default/mixer
sed -i '/NET_RAW_INPUT_PORTS=/c\NET_RAW_INPUT_PORTS=40001' /etc/default/mixer
sed -i '/NET_RAW_OUTPUT_PORTS=/c\NET_RAW_OUTPUT_PORTS=40002' /etc/default/mixer
sed -i '/NET_SBS_OUTPUT_PORTS=/c\NET_SBS_OUTPUT_PORTS=40003' /etc/default/mixer
sed -i '/NET_BEAST_INPUT_PORTS=/c\NET_BEAST_INPUT_PORTS=40004,40104' /etc/default/mixer
sed -i '/NET_BEAST_OUTPUT_PORTS=/c\NET_BEAST_OUTPUT_PORTS=40005' /etc/default/mixer


cp /etc/lighttpd/conf-available/89-skyaware.conf /etc/lighttpd/conf-available/89-mixer.conf
sed -i '/skyaware978/c\ ' /etc/lighttpd/conf-available/89-mixer.conf
sed -i 's/skyaware/mixer/g' /etc/lighttpd/conf-available/89-mixer.conf
sed -i 's/dump1090-fa/mixer/g' /etc/lighttpd/conf-available/89-mixer.conf
sed -i 's/8080/8585/g' /etc/lighttpd/conf-available/89-mixer.conf
ln -sf /etc/lighttpd/conf-available/89-mixer.conf  /etc/lighttpd/conf-enabled/89-mixer.conf
systemctl restart lighttpd

cp /lib/systemd/system/dump1090-fa.service /lib/systemd/system/mixer.service
sed -i 's/dump1090-fa/mixer/g' /lib/systemd/system/mixer.service
sed -i '/Description=/c\Description=adsb data mixer service' /lib/systemd/system/mixer.service
sed -i '/User=/c\User=mixer' /lib/systemd/system/mixer.service

if id -u mixer >/dev/null 2>&1; then
  echo "user mixer exists"
else
  echo "user mixer does not exist, creating user mixer"
  adduser --system --no-create-home mixer
fi

systemctl enable mixer
systemctl restart mixer

echo "Embeding Title in Mixer Map"
cp /usr/share/skyaware/html/index.html /usr/share/mixer/html/index.html.orig
sed -i '/<div class="buttonContainer">/i <div id="Mixer Title" style="text-align:center;width:175px;height:65px;">\n<font color=\#FFFFFF size=6><br>MIXER</font>\n<\/div> <!----- MIXER --->' /usr/share/mixer/html/index.html    
sed -i '/PageName = /c\PageName = \"MIXER\"; ' /usr/share/mixer/html/config.js

###################################################################################################
echo -e "\e[1;32mCREATION OF DATA MIXER AND COMBINED MAP COMPLETED \e[39;0m"
echo ""
echo -e "\e[1;35mNOW CREATING SOCAT PIPES TO PULL DATA FROM SOURCE (RECEIVERS) \e[39;0m"
sleep 5
###################################################################################################

echo -e "\e[1;32mInstalling socat Package..... \e[39;0m"
sleep 2
apt install -y socat

echo -e "\e[1;32mInstalling Scripts \"receivers.ip\" & \"pull\" to create socat connections..... \e[39;0m"
sleep 2
INSTALL_FOLDER=/usr/share/mixer
if [[ ! -d ${INSTALL_FOLDER} ]];
then
echo -e "\e[32mCreating Installation Folder ${INSTALL_FOLDER} \e[39m"
mkdir ${INSTALL_FOLDER}
fi

echo "Creating Receiver IP addresses file receivers.ip"
touch ${INSTALL_FOLDER}/receivers.ip
echo "127.0.0.1" > ${INSTALL_FOLDER}/receivers.ip

echo "Creating socat script file pull.sh"
PULL_SCRIPT=${INSTALL_FOLDER}/pull.sh
touch ${PULL_SCRIPT}
chmod 777 ${PULL_SCRIPT}
echo "Writing code to socat script file pull.sh"
/bin/cat <<EOM >${PULL_SCRIPT}
#!/bin/bash
RECEIVERS=/usr/share/mixer/receivers.ip
if  ! [[ -f ${RECEIVERS} ]]; then
   echo "RECEIVER's CONFIG FILE DOES NOT EXIST.... ";
   echo "Create it by command: sudo nano ${RECEIVERS} ";
   echo "and add IP Addresses of all receivers to it ";
   echo "(one site per line) ";
   echo "Like EXAMPLE below: ";
   echo "127.0.0.1";
   echo "192.168.0.24";
   echo "192.168.0.105";
   echo "";
   exit 0;

elif  [[ -f ${RECEIVERS} ]]; then
   if  ! [[ -s ${RECEIVERS} ]]; then
      echo "RECEIVER's CONFIG FILE IS EMPTY....";
      echo "Open it by command: sudo nano ${RECEIVERS} ";
      echo "Add target addresses to it ";
      echo "(one site per line) ";
      echo "Like EXAMPLE below: ";
      echo "127.0.0.1";
      echo "192.168.0.24";
      echo "192.168.0.105";
      echo "";
      exit 0;

   fi
fi


OPT="keepalive,keepidle=30,keepintvl=30,keepcnt=2,connect-timeout=30,retry=2,interval=15"
SRC=""
CMD=""
while read line;
do
[[ -z "$line" ]] && continue
CMD+="socat -dd -u TCP:${line}:30005,${OPT} TCP:127.0.0.1:40004,${OPT} | ";
done < ${RECEIVERS}

while true
do
      echo "CONNECTING MIXER TO RECEIVERS:"
      eval "${CMD%|*}"
      echo "LOST CONNECTION OF MIXER AND RECEIVERS:"
      echo "RE-CONNECTING MIXER TO RECEIVERS:"
      sleep 60
done

EOM

chmod +x ${PULL_SCRIPT}

echo "Creating systemd service file for pull"
PULL_SERVICE=/lib/systemd/system/pull.service
touch ${PULL_SERVICE}
chmod 777 ${PULL_SERVICE}
echo "Writing code to service file pull.service"
/bin/cat <<EOM >${PULL_SERVICE}
# socat pull service - by abcd567

[Unit]
Description=socat pull service by abcd567
Wants=network.target
After=network.target

[Service]
User=pull
RuntimeDirectory=pull
RuntimeDirectoryMode=0755
ExecStart=/bin/bash /usr/share/mixer/pull.sh
SyslogIdentifier=pull
Type=simple
Restart=on-failure
RestartSec=30
RestartPreventExitStatus=64
#Nice=-5

[Install]
WantedBy=default.target
EOM
chmod 644 ${PULL_SERVICE}

if id -u pull >/dev/null 2>&1; then
  echo "user pull exists"
else
  echo "user pull does not exist, creating user pull"
  adduser --system --no-create-home pull
fi

systemctl enable pull
systemctl restart pull


#######################################################################################################
echo ""
echo -e "\e[1;32mINSTALLATION OF MIXER, MAP, & SOCAT PIPES COMPLETED \e[39;0m"
echo ""
#######################################################################################################
echo -e "\e[1;95mIMPORTANT:  \e[39;0m"
echo -e "\e[1;39msudo nano /usr/share/mixer/receivers.ip \e[39;0m"
echo -e "\e[1;32min above file add IP's of your receivers/Pi's \e[39;0m"
echo -e "\e[1;32mOne IP per line, like EXAMPLE below \e[39;0m"
echo ""
echo -e "\e[1;39m127.0.0.1 \e[39;0m"
echo -e "\e[1;39m192.168.0.11 \e[39;0m"
echo -e "\e[1;39m192.168.0.23 \e[39;0m"
echo ""
echo -e "\e[1;32mAfter adding receiver IPs and saving the file, \e[39m"
echo -e "\e[1;32mrestart socat by following command: \e[39m"
echo -e "\e[1;39msudo systemctl restart pull  \e[39;0m"
echo ""
echo -e "\e[1;95mPlease see Map of Mixed Data at: \e[39;0m"
echo -e "\e[1;39m$(ip route | grep -m1 -o -P 'src \K[0-9,.]*')/mixer/ \e[39;0m"
echo -e "\e[1;39mOR \e[39;0m"
echo -e "\e[1;39m$(ip route | grep -m1 -o -P 'src \K[0-9,.]*'):8585 \e[39;0m"
echo ""
echo -e "\e[1;95mTo restart Mixer: \e[39m" "\e[1;39msudo systemctl restart mixer \e[39;0m"
echo -e "\e[1;95mTo restart Socat: \e[39m" "\e[1;39msudo systemctl restart pull \e[39;0m"
