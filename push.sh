#!/bin/bash

OPTIONS="keepalive,keepidle=30,keepintvl=30,keepcnt=2,connect-timeout=30,retry=2,interval=15"
CMD=""
IFS=":"
while read -r field1 field2 field3; do
if [[ ${field1} == "beast" ]]; then
source="127.0.0.1:40005";
elif [[ ${field1} == "msg" ]]; then
source="127.0.0.1:40003";
elif [[ ${field1} == "avr" ]]; then
source="127.0.0.1:30002";
fi

CMD="${CMD} \
  socat -dd -u TCP:${source},${OPTIONS} TCP:${field2}:${field3},${OPTIONS} | \
    ";  done < /usr/share/mixer/targets.ip


while true
do
      echo "CONNECTING MIXER TO TARGETS:"

      eval "${CMD%|*}"

      echo "LOST CONNECTION OF MIXER AND TARGETS:"
      echo "RE-CONNECTING MIXER TO TARGETS:"
      sleep 60
done


