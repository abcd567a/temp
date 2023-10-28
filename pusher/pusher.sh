#!/bin/bash

TARGETS=/usr/share/pusher/targets.ip
VARS_DIR=/usr/share/pusher/vars
systemctl stop push@*
rm ${VARS_DIR}/*
if  ! [[ -f ${TARGETS} ]]; then
   echo "TARGET CONFIG FILE DOES NOT EXIST....";
   echo "Create it by command: sudo nano ${TARGETS}  ";
   echo "and add target addresses to it ";
   echo "(one site per line) ";
   echo "in following format: ";
   echo "Data-Type:IP-Address:Port";
   echo "The Data-Type can be beast, msg, or avr, as per requirement of site";
   echo "";
   exit 0;

elif  [[ -f ${TARGETS} ]]; then
   if  ! [[ -s ${TARGETS} ]]; then
      echo "TARGET CONFIG FILE IS EMPTY....";
      echo "Open it by command: sudo nano ${TARGETS} ";
      echo "Add target addresses to it ";
      echo "(one site per line) ";
      echo "in following format: ";
      echo "Data-Type:IP-Address:Port";
      echo "The Data-Type can be beast, msg, or avr, as per requirement of site";
      echo "";
      exit 0;

   fi
fi

SRC=""
while read line;
do
[[ -z "$line" ]] && continue
IFS=":" read F1 F2 F3 <<< $line

if [[ $F1 == "beast" ]]; then
SRC="127.0.0.1:40005";
elif [[ $F1 == "msg" ]]; then
SRC="127.0.0.1:40003";
elif [[ $F1 == "avr" ]]; then
SRC="127.0.0.1:40002";
fi

echo var1="${SRC}" > ${VARS_DIR}/${F2}
echo var2="${F2}" >> ${VARS_DIR}/${F2}
echo var3="${F3}" >> ${VARS_DIR}/${F2}

systemctl restart push@${F2}
echo "Created push@"${F2};

done < ${TARGETS}

