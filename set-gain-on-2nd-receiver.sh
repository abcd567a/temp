#!/bin/bash

echo "Adding set gain for 2nd Receiver....."

sudo cp -r /usr/local/sbin/gain  /usr/local/sbin/gain2  
sudo mv  /usr/local/sbin/gain2/gain.php /usr/local/sbin/gain2/gain2.php  

sudo sed -i 's/gain.php/gain2.php/g' /usr/local/sbin/gain2/gain2.php  
sudo sed -i 's/sbin\/gain/sbin\/gain2/g' /usr/local/sbin/gain2/gain2.php  

sudo sed -i 's/sbin\/gain/sbin\/gain2/g' /usr/local/sbin/gain2/setgain.sh
sudo sed -i 's/dump1090-fa/dump1090-fa2/g' /usr/local/sbin/gain2/setgain.sh  
sudo sed -i 's/RECEIVER_GAIN/RECEIVER_GAIN2/g' /usr/local/sbin/gain2/setgain.sh  
sudo sed -i 's/ADAPTIVE_DYNAMIC_RANGE/ADAPTIVE_DYNAMIC_RANGE2/g' /usr/local/sbin/gain2/setgain.sh  

sudo ln -sf /usr/local/sbin/gain2/gain2.php /var/www/html/gain2.php  

sudo cp -r /usr/share/skyaware/html  /usr/share/skyaware/html2  

sudo sed -i 's/skyaware\/html/skyaware\/html2/g'  /etc/lighttpd/conf-available/89-skyaware2.conf  

sudo cp /lib/systemd/system/set-gain.service /lib/systemd/system/set-gain2.service

sudo sed -i 's/sbin\/gain/sbin\/gain2/g' /lib/systemd/system/set-gain2.service  

sudo systemctl enable set-gain2  

sudo systemctl start set-gain2 

echo -e "\e[32m======================================= \e[39m"
echo -e "\e[32mSCRIPT COMPLETED INSTALLATION OF SET-GAIN FOR 2ND RECEIVER\e[39m"
echo -e "\e[32m======================================= \e[39m"

echo -e "\e[95m(1) In your browser, go to http://$(ip route | grep -m1 -o -P 'src \K[0-9,.]*')/gain2.php \e[39m"

echo -e "\e[32m(2) OPTIONAL STEP: Embed Set Gain Button & Dropdown in Skyaware2 Map \e[39m"
echo "(2.1) Make a backup copy of file index.html by following commands..."
echo ""
echo "      cd /usr/share/skyaware/html2  "
echo "      sudo cp index.html index.html.orig "
echo ""
echo "(2.2) Open file index.html for editing "
echo ""
echo "      sudo nano /usr/share/skyaware/html2/index.html "
echo ""
echo "Press Ctrl+W and type "buttonContainer" and press Enter key "
echo 'the cursor will jump to <div class="buttonContainer">'
echo -e '\e[95mInsert\e[39m following 3 lines \e[95mJUST ABOVE\e[39m the line \e[32m<div class="buttonContainer"> \e[39m'
echo ""
echo '  <div id="GAIN" style="text-align:center;width:175px;height:65px;">'
echo '  <iframe src=../../gain2.php style="border:0;width:175px;height:65px;">'
echo '  </iframe>'
echo '  </div> <!----- GAIN --->'
echo ""
echo -e "(2.3) Save & Close file.  "
echo -e "\e[95m(2.4) Go to http://$(ip route | grep -m1 -o -P 'src \K[0-9,.]*')/skyaware2/ \e[39m"
echo -e "\e[32m(2.5) Clear Browser cache (Ctrl+Shift+Delete) & Reload browser (Ctrl+F5) \e[39m"

