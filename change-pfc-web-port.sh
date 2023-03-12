#!/bin/bash

PORT=`grep -o -P 'web_port.*? ' /etc/init.d/pfclient`

if [[ ${PORT} ]]; then
  echo "existing "${PORT}

elif [[ ! ${PORT} ]]; then
  echo "exiting port is default port (30053)"
fi

read -p "what web-page port number you want?" NEW_PORT
echo You have selected new web port  ${NEW_PORT}
echo "Changing Port. Please wait....."
echo " "
sudo sed -i "s/start-stop.*/start-stop-daemon --start --exec \$DAEMON -- --web_port=${NEW_PORT} -d -i \$PIDFILE -z \$CONFIGFILE -y \$LOGFILE \$ 2\>\/var\/log\/pfclient\/error.log /" /etc/init.d/pfclient
sudo systemctl daemon-reload
sudo systemctl restart pfclient
echo "Port number changed to" ${NEW_PORT}
echo -e "\e[01;32mSee the Web Interface (Map etc) at\e[39m"
echo -e "\e[39m        $(ip route | grep -m1 -o -P 'src \K[0-9,.]*'):"${NEW_PORT} "(IP-OF-PI:"${NEW_PORT}") \e[39m"
