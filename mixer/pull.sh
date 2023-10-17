#!/bin/bash

RECEIVERS=/usr/share/mixer/receivers.ip
if  ! [ -f ${RECEIVERS} ]; then
   echo -e "\e[1;95mRECEIVER's CONFIG FILE DOES NOT EXIST.... \e[39;0m";
   echo -e "\e[1;95mCreate it by command: \e[39;0m" "\e[1;39msudo nano ${FILE}  \e[39;0m";
   echo -e "\e[1;32mand add IP Addresses of all receivers to it \e[39;0m";
   echo -e "\e[1;32m(one site per line) \e[39;0m";
   echo -e "\e[1;32mLike EXAMPLE below: \e[39;0m";
   echo "127.0.0.1";
   echo "192.168.0.24";
   echo "192.168.0.105";
   echo "";
   exit 0;

elif  [ -f ${RECEIVERS} ]; then
   if  ! [ -s ${RECEIVERS} ]; then
      echo -e "\e[1;95mRECEIVER's CONFIG FILE IS EMPTY.... \e[39;0m";
      echo -e "\e[1;95mOpen it by command: \e[39;0m" "\e[1;39msudo nano ${FILE}  \e[39;0m";
      echo -e "\e[1;95mAdd target addresses to it \e[39;0m";
      echo -e "\e[1;32m(one site per line) \e[39;0m";
      echo -e "\e[1;32Like EXAMPLE below: \e[39;0m";
      echo "127.0.0.1";
      echo "192.168.0.24";
      echo "192.168.0.105";
      echo "";
      exit 0;
   fi
fi


OPT="keepalive,keepidle=30,keepintvl=30,keepcnt=2,connect-timeout=30,retry=2,interval=15"
CMD=""
while read line;
do
[ -z "$line" ] && continue
CMD+="socat -dd -u TCP:${line}:30005,${OPT} TCP:127.0.0.1:40004,${OPT} | ";
done < ${RECEIVERS}

while true
do
      echo "CONNECTING MIXER TO TARGETS:"
      eval "${CMD%|*}"
      echo "LOST CONNECTION OF MIXER AND TARGETS:"
      echo "RE-CONNECTING MIXER TO TARGETS:"
      sleep 60
done

