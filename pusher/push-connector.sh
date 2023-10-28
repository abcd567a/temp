#!/bin/bash

OPT="keepalive,keepidle=30,keepintvl=30,keepcnt=2,connect-timeout=30,retry=2,interval=15"
CMD=""
CMD="socat -dd -u TCP:$1,${OPT} TCP:$2:$3,${OPT} ";
while true
    do
      echo "CONNECTING MIXER TO TARGET"
      eval "${CMD}"
      echo "LOST CONNECTION OF MIXER AND TARGET"
      echo "RE-CONNECTING MIXER TO TARGET"
     sleep 30
   done

