#!/bin/bash

echo -e "\e[32mUpdating apt......\e[39m"
sudo apt update

echo -e "\e[32mInstalling php-cgi....\e[39m"
sudo apt install -y php-cgi

# Before enabling module fastcgi-php, detect if package php-cgi is installed, 
# and if not, advise user to install it manually and exit script 
if [[ $(dpkg-query -W -f='${STATUS}' php-cgi 2>/dev/null | grep -c "ok installed") -eq 0 ]] ; then
  echo -e ""
  echo -e "\e[91m\e[5mINSTALLATION HALTED!\e[25m"
  echo -e "UNABLE TO INSTALL PACKAGE PHP-CGI."
  echo -e "SETUP HAS BEEN TERMINATED!"
  echo -e ""
  echo -e "\e[93mPlease install package php-cgi manually, then run this script again.\e[39m"
  echo -e ""
  exit 1
fi

echo ""
echo -e "\e[32mEnabling module fastcgi-php....\e[39m"
sudo lighty-enable-mod fastcgi-php
sudo /etc/init.d/lighttpd force-reload

##############################################################
##############################################################
GAIN-1     GAIN-1     GAIN-1     GAIN-1      GAIN-1     GAIN-1
##############################################################
##############################################################

echo "Creating folder gain...."
sudo mkdir -p /usr/local/sbin/gain

echo "Creating file gain.php...."
FILE_GAIN="/usr/local/sbin/gain/gain.php"
sudo touch $FILE_GAIN

echo "making file gain.php writeable by script (666)...."
sudo chmod 666 $FILE_GAIN

echo "Writing code to file gain.php...."
sudo cat <<\EOT > $FILE_GAIN

<html>
 <form id="myform" action="gain.php" method="post" />
 <div><font color=#ff0000 face="'Helvetica Neue', Helvetica, Arial, sans-serif">Current Gain: <?php system('cat /usr/local/sbin/gain/currentgain');?> </font></div>
 <select name="gain" id="gain">
   <option value=60>60</option>
   <option value=49.6>49.6</option>
   <option value=48.0>48.0</option>
   <option value=44.5>44.5</option>
   <option value=43.9>43.9</option>
   <option value=43.4>43.4</option>
   <option value=42.1>42.1</option>
   <option value=40.2>40.2</option>
   <option value=38.6>38.6</option>
   <option value=37.2>37.2</option>
   <option value=36.4>36.4</option>
   <option value=33.8>33.8</option>
   <option value=32.8>32.8</option>
   <option value=29.7>29.7</option>
   <option value=28.0>28.0</option>
   <option value=25.4>25.4</option>
   <option value=22.9>22.9</option>
   <option value=20.7>20.7</option>
   <option value=19.7>19.7</option>
   <option value=16.6>16.6</option>
 </select>
 <input type="submit" value="Set Gain" style="color:#ffffff;background-color:#00A0E2;border-color:#00B0F0;" />
 </form>
</html>

<?php
function setgain(){
$gain="{$_POST['gain']}";
system("echo $gain > /usr/local/sbin/gain/newgain");
sleep(5);
header("Refresh:0");
}

if ("{$_POST['gain']}"){
setgain();
}

?>


EOT

echo "Code written to file gain.php...."
echo " Making it writeable by owner only (664)...."
sudo chmod 644 $FILE_GAIN

echo "Creating symlinks to file gain.php......"
sudo ln -sf /usr/local/sbin/gain/gain.php /var/www/html/gain.php
sudo ln -sf /usr/local/sbin/gain/gain.php /usr/share/gain.php

echo "Creating file setgain.sh...."
FILE_SETGAIN="/usr/local/sbin/gain/setgain.sh"
sudo touch $FILE_SETGAIN

echo "making file setgain.sh writeable by script (666)...."
sudo chmod 666 $FILE_SETGAIN


echo "Writing code to file setgain.sh...."
sudo cat <<\EOT > $FILE_SETGAIN

#!/bin/bash

# redirect all output and errors of this script to a log file
exec &>/usr/local/sbin/gain/log

# file that anyone can write to in order to set a new gain
fifo=/usr/local/sbin/gain/newgain

# remove $fifo so we are sure we can create our named pipe
rm -f $fifo

# create the named pipe with write access for everyone
mkfifo -m 666 $fifo

# read current gain and store in file currentgain
# script in gain.php will read gain value stored in currentgain and
# will display it on map as "Current Gain"
grep "RECEIVER_GAIN=" /etc/default/dump1090-fa | sed 's/^.*=//' > /usr/local/sbin/gain/currentgain


while sleep 1
do
        if ! [[ -r $fifo ]] || ! [[ -p $fifo ]]
        # exit the loop/script if $fifo is not readable or not a named pipe
        then break
        fi

        # read one line from the named pipe, remove all characters
        # but numbers, dot, minus and newline and store it in $line
        read line < <(tr -cd  '.\-0123456789\n' < $fifo)

        #set new gain
        gainnow=`sed -n 's/RECEIVER_GAIN=//p' /etc/default/dump1090-fa`
        sed -i 's/RECEIVER_GAIN='$gainnow'/RECEIVER_GAIN='$line'/' /etc/default/dump1090-fa 
        sed -i '/ADAPTIVE_DYNAMIC_RANGE=/c\ADAPTIVE_DYNAMIC_RANGE=no'  /etc/default/dump1090-fa

        #restart dump1090-fa to implement new gain value
        systemctl restart dump1090-fa

        # read updated gain and store in file currentgain
        grep "RECEIVER_GAIN=" /etc/default/dump1090-fa | sed 's/^.*=//' > /usr/local/sbin/gain/currentgain

        # script in gain.php will read the updated gain and display it on map
done

EOT

echo "code written to file setgain.sh...."
echo " Making it writeable by owner only (664)...."
sudo chmod 644 $FILE_SETGAIN

echo -e "\e[33m(1) Creating set-gain service file......\e[39m"
SERVICE_FILE=/lib/systemd/system/set-gain.service
sudo touch $SERVICE_FILE
sudo chmod 666 $SERVICE_FILE
sudo cat <<\EOT > $SERVICE_FILE
[Unit]
Description=Set Gain from Browser/Skyaware Map - By: abcd567

[Service]
ExecStart=/bin/bash /usr/local/sbin/gain/setgain.sh
Type=simple
Restart=on-failure
RestartSec=30
RestartPreventExitStatus=64
Nice=-5
[Install]
WantedBy=default.target
EOT

sudo chmod 644 $SERVICE_FILE
echo ""

echo -e "\e[32mStarting Set Gain add-on \e[39m"
sudo systemctl enable set-gain
sudo systemctl start set-gain

echo "Embeding Gain Button in Skyaware"
sudo sed -i '/<div class="buttonContainer">/i <div id="GAIN" style="text-align:center;width:175px;height:65px;">\n<iframe src=..\/..\/gain.php style="border:0;width:175px;height:65px;"><\/iframe>\n<\/div> <!----- GAIN --->' /usr/share/skyaware/html/index.html



##############################################################
##############################################################
GAIN-2     GAIN-2     GAIN-2     GAIN-2      GAIN-2     GAIN-2
##############################################################
##############################################################

echo "Creating folder gain2...."
sudo mkdir -p /usr/local/sbin/gain2

echo "Creating file gain2.php...."
FILE_GAIN2="/usr/local/sbin/gain2/gain2.php"
sudo touch $FILE_GAIN2

echo "making file gain.php writeable by script (666)...."
sudo chmod 666 $FILE_GAIN2

echo "Writing code to file gain2.php...."
sudo cat <<\EOT > $FILE_GAIN2

<html>
 <form id="myform" action="gain2.php" method="post" />
 <div><font color=#ff0000 face="'Helvetica Neue', Helvetica, Arial, sans-serif">Current Gain: <?php system('cat /usr/local/sbin/gain2/currentgain');?> </font></div>
 <select name="gain" id="gain">
   <option value=60>60</option>
   <option value=49.6>49.6</option>
   <option value=48.0>48.0</option>
   <option value=44.5>44.5</option>
   <option value=43.9>43.9</option>
   <option value=43.4>43.4</option>
   <option value=42.1>42.1</option>
   <option value=40.2>40.2</option>
   <option value=38.6>38.6</option>
   <option value=37.2>37.2</option>
   <option value=36.4>36.4</option>
   <option value=33.8>33.8</option>
   <option value=32.8>32.8</option>
   <option value=29.7>29.7</option>
   <option value=28.0>28.0</option>
   <option value=25.4>25.4</option>
   <option value=22.9>22.9</option>
   <option value=20.7>20.7</option>
   <option value=19.7>19.7</option>
   <option value=16.6>16.6</option>
 </select>
 <input type="submit" value="Set Gain" style="color:#ffffff;background-color:#00A0E2;border-color:#00B0F0;" />
 </form>
</html>

<?php
function setgain(){
$gain="{$_POST['gain']}";
system("echo $gain > /usr/local/sbin/gain2/newgain");
sleep(5);
header("Refresh:0");
}

if ("{$_POST['gain']}"){
setgain();
}

?>


EOT

echo "Code written to file gain2.php...."
echo " Making it writeable by owner only (664)...."
sudo chmod 644 $FILE_GAIN2

echo "Creating symlinks to file gain2.php......"
sudo ln -sf /usr/local/sbin/gain2/gain2.php /var/www/html/gain2.php
sudo ln -sf /usr/local/sbin/gain2/gain2.php /usr/share/gain2.php


echo "Creating file gain2/setgain.sh...."
FILE_SETGAIN2="/usr/local/sbin/gain2/setgain.sh"
sudo touch $FILE_SETGAIN2

echo "making file setgain.sh writeable by script (666)...."
sudo chmod 666 $FILE_SETGAIN2


echo "Writing code to file setgain.sh...."
sudo cat <<\EOT > $FILE_SETGAIN2

#!/bin/bash

# redirect all output and errors of this script to a log file
exec &>/usr/local/sbin/gain2/log

# file that anyone can write to in order to set a new gain
fifo2=/usr/local/sbin/gain2/newgain

# remove $fifo2 so we are sure we can create our named pipe
rm -f $fifo2

# create the named pipe with write access for everyone
mkfifo -m 666 $fifo2

# read current gain and store in file currentgain
# script in gain2.php will read gain value stored in currentgain and
# will display it on map as "Current Gain"
grep "RECEIVER_GAIN2=" /etc/default/dump1090-fa2 | sed 's/^.*=//' > /usr/local/sbin/gain2/currentgain


while sleep 1
do
        if ! [[ -r $fifo2 ]] || ! [[ -p $fifo2 ]]
        # exit the loop/script if $fifo2 is not readable or not a named pipe
        then break
        fi

        # read one line from the named pipe, remove all characters
        # but numbers, dot, minus and newline and store it in $line
        read line < <(tr -cd  '.\-0123456789\n' < $fifo2)

        #set new gain
        gainnow=`sed -n 's/RECEIVER_GAIN2=//p' /etc/default/dump1090-fa2`
        sed -i 's/RECEIVER_GAIN2='$gainnow'/RECEIVER_GAIN2='$line'/' /etc/default/dump1090-fa2 
        sed -i '/ADAPTIVE_DYNAMIC_RANGE2=/c\ADAPTIVE_DYNAMIC_RANGE2=no'  /etc/default/dump1090-fa2

        #restart dump1090-fa2 to implement new gain value
        systemctl restart dump1090-fa2

        # read updated gain and store in file currentgain
        grep "RECEIVER_GAIN2=" /etc/default/dump1090-fa2 | sed 's/^.*=//' > /usr/local/sbin/gain2/currentgain

        # script in gain2.php will read the updated gain and display it on map
done

EOT

echo "code written to file setgain2.sh...."
echo " Making it writeable by owner only (664)...."
sudo chmod 644 $FILE_SETGAIN2

echo -e "\e[33m(1) Creating set-gain2 service file......\e[39m"
SERVICE_FILE2=/lib/systemd/system/set-gain2.service
sudo touch $SERVICE_FILE2
sudo chmod 666 $SERVICE_FILE2
sudo cat <<\EOT > $SERVICE_FILE2
[Unit]
Description=Set Gain from Browser/Skyaware Map - By: abcd567

[Service]
ExecStart=/bin/bash /usr/local/sbin/gain2/setgain.sh
Type=simple
Restart=on-failure
RestartSec=30
RestartPreventExitStatus=64
Nice=-5
[Install]
WantedBy=default.target
EOT

sudo chmod 644 $SERVICE_FILE2
echo ""

echo -e "\e[32mStarting Set Gain add-on \e[39m"
sudo systemctl enable set-gain2
sudo systemctl start set-gain2

echo "Embeding Gain Button in Skyaware2"
sudo sed -i '/<div class="buttonContainer">/i <div id="GAIN" style="text-align:center;width:175px;height:65px;">\n<iframe src=..\/..\/gain2.php style="border:0;width:175px;height:65px;"><\/iframe>\n<\/div> <!----- GAIN --->' /usr/share/skyaware2/html/index.html

echo ""
echo -e "\e[32m======================================= \e[39m"
echo -e "\e[32mSCRIPT COMPLETED INSTALLATION \e[39m"
echo -e "\e[32m======================================= \e[39m"
echo ""
echo -e "\e[32mSTAND-ALONE GAIN BUTTONS\e[39m"
echo -e "\e[95m(1) In your browser, go to http://$(ip route | grep -m1 -o -P 'src \K[0-9,.]*')/gain.php \e[39m"
echo -e "\e[95m(1) In your browser, go to http://$(ip route | grep -m1 -o -P 'src \K[0-9,.]*')/gain2.php \e[39m"
echo ""
echo -e "\e[32mGAIN BUTTONS EMBEDED IN SKYAWARE MAPS\e[39m"
echo -e "\e[95m(2.4) Go to http://$(ip route | grep -m1 -o -P 'src \K[0-9,.]*')/skyaware/ \e[39m"
echo -e "\e[95m(2.4) Go to http://$(ip route | grep -m1 -o -P 'src \K[0-9,.]*')/skyaware2/ \e[39m"
echo ""
echo -e "\e[32m(2.5) Clear Browser cache (Ctrl+Shift+Delete) & Reload browser (Ctrl+F5) \e[39m"
echo ""
