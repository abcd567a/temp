#!/bin/bash

TARGETS=/usr/share/mixer/targets.ip
if  ! [[ -f ${TARGETS} ]]; then
   echo -e "\e[1;95mTARGET CONFIG FILE DOES NOT EXIST.... \e[39;0m";
   echo -e "\e[1;95mCreate it by command: \e[39;0m" "\e[1;39msudo nano ${FILE}  \e[39;0m";
   echo -e "\e[1;32mand add target addresses to it \e[39;0m";
   echo -e "\e[1;32m(one site per line) \e[39;0m";
   echo -e "\e[1;32min following format: \e[39;0m";
   echo "Data-Type:IP-Address:Port";
   echo "The Data-Type can be beast, msg, or avr, as per requirement of site";
   echo "";
   exit 0;

elif  [[ -f ${TARGETS} ]]; then
   if  ! [[ -s ${TARGETS} ]]; then
      echo -e "\e[1;95mTARGET CONFIG FILE IS EMPTY.... \e[39;0m";
      echo -e "\e[1;95mOpen it by command: \e[39;0m" "\e[1;39msudo nano ${FILE}  \e[39;0m";
      echo -e "\e[1;95mAdd target addresses to it \e[39;0m";
      echo -e "\e[1;32m(one site per line) \e[39;0m";
      echo -e "\e[1;32min following format: \e[39;0m";
      echo "Data-Type:IP-Address:Port";
      echo "The Data-Type can be beast, msg, or avr, as per requirement of site";
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
IFS=":" read F1 F2 F3 <<< $line

if [[ $F1 == "msg" ]]; then
SRC="127.0.0.1:40003";
elif [[ $F1 == "beast" ]]; then
SRC="127.0.0.1:40005";
fi

CMD+="socat -dd -u TCP:${SRC},${OPT} TCP:${F2}:${F3},${OPT} | ";
done < ${TARGETS}

while true
do
      echo "CONNECTING MIXER TO TARGETS:"
      eval "${CMD%|*}"
      echo "LOST CONNECTION OF MIXER AND TARGETS:"
      echo "RE-CONNECTING MIXER TO TARGETS:"
      sleep 60
done

