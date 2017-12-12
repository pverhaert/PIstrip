#!/bin/bash
BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

RESET=`tput reset`
INIT=`tput init`
CURENT_RELEASE=$(uname -a)

if [ "$EUID" -ne 0 ]
  then 
  echo
  echo Installeer als root-gebruiker!
  echo ${RED}sudo bash PIstrip.sh${WHITE}
  echo
  exit
fi

function einde {
  echo 
  read -p 'Terug naar hoofdmenu' -n1 -s
  echo 
}


function updatePi {
  echo ${MAGENTA}Start update. Geduld, dit kan even duren...${WHITE}
  echo =========================================================== 
  sudo apt-get update && sudo apt-get upgrade
          
  echo
  echo ${MAGENTA}Overbodige bestanden wissen.${WHITE}
  echo =========================================================== 
  sudo apt-get autoclean && sudo apt-get clean;
          
  echo
  echo ${MAGENTA}Update voltooid.${WHITE}
  echo =========================================================== 
}


function hashPW {
  echo
  echo
  read -p 'SSID: ' wifiSSID
  read -sp 'Wifi wachtwoord (min 8 char): ' wifiPW
  echo
  echo Vervang in ${MAGENTA}\"ect\/wpa_supplicant\/wpa_supplicant.conf\"${WHITE} de gecodeerde psk-sleutel.
  echo
  wpa_passphrase $wifiSSID $wifiPW;
}

function installGit {
  if git --version &>/dev/null; then
      echo ${MAGENTA}Huidige versie: $(git --version) ${WHITE}
      echo    
  fi
  sudo apt-get install git
  echo
  echo
  echo ${MAGENTA}
  echo Installatie voltooid.
  echo git --version: $(git --version) 
  echo ${WHITE} 
}

function installWiringpi {
  if gpio -v &>/dev/null; then
      echo ${MAGENTA}Huidige versie: $(gpio -v) ${WHITE}
      echo    
  fi
  sudo apt-get install git wiringpi
  echo
  echo
  echo ${MAGENTA}
  echo Installatie voltooid.
  echo git --version: $(gpio -v) 
  echo ${WHITE} 
}

function installNode {
    # https://nodejs.org/en/download/releases/
    PICHIP=$(uname -m);  #Haal processor op
    NODE_URL=https://nodejs.org/dist/$1/
    LINK_TO_ZIP=$(curl -G $NODE_URL | awk '{print $2}' | grep -P 'href=\"node-v\d{1,}\.\d{1,}\.\d{1,}-linux-'$PICHIP'\.tar\.gz' | sed 's/href="//' | sed 's/<\/a>//' | sed 's/">.*//');
      
    if $LINK_TO_ZIP &>/dev/null; then
      echo ${RED}
      echo "Laatste versie nog niet beschikbaar voor $PICHIP processor!"
      echo ${WHITE}
      echo "Probeer een oudere versie"
    else
      echo ${GREEN}
      echo Download $NODE_URL$LINK_TO_ZIP
      echo ${WHITE}
      cd ~
      wget $NODE_URL$LINK_TO_ZIP
      cd /usr/local
      sudo tar xzvf ~/$LINK_TO_ZIP --strip=1
      cd ~
      rm $LINK_TO_ZIP;
      sudo apt-get remove --purge npm node nodejs
      # Allow Node to bind to port 80 without sudo (https://gist.github.com/firstdoit/6389682)
      # sudo apt-get install libcap2-bin
      sudo setcap 'cap_net_bind_service=+ep' `which node`
      cd ~
      echo        
      echo ${MAGENTA}Installatie voltooid.${WHITE}
      echo ${MAGENTA}node -v: $(node -v) ${WHITE}
      echo ${MAGENTA}nmp -v: $(npm -v) ${WHITE} 
    fi
}

while true; do
#echo ${INIT}
clear
echo "PI scripts: $CURENT_RELEASE"
echo ${GREEN}
echo "1.    update/upgrade RPi"
echo "2.    config RPi"
echo "3:    wijzig RPi wachtwoord"
echo "4.    hash WPA wachtwoord"
echo "5.    installeer GIT"
echo ${WHITE}
echo "----- Installeer node.js"
echo ${GREEN}
echo "60.    node latest"
echo "61.    node v8.9.3 (LTS)"
echo "62.    node v7.10.1"
echo "63.    node v6.11.0"
echo "64.    node v5.12.0"
echo "65.    node v4.8.3"
echo ${WHITE}
echo "----- LED strip toepassing"
echo ${GREEN}
echo "100.   - maak SSL certificaten voor https-protocol"
echo "101.   - installeer pm2 (Process Manager 2)"
echo "102.   - installeer express, pubnub, johnny-five en raspi-io"
echo ${WHITE}
echo "----- Shutdown/reboot"
echo ${GREEN}
echo "800.   - Shutdown (sudo halt)"
echo "801.   - Reboot (sudo reboot)"

echo ${WHITE}
echo
echo -n "Maak een keuze (0 = exit)"
read keuze
echo

case $keuze in
     1)
        echo ${INIT}
        updatePi
        einde
        ;;
     2)
         echo ${INIT}
         sudo raspi-config
         einde
         ;;
     3)
         echo ${INIT}
         passwd
         ;;
     4)
        echo ${INIT}
        hashPW
        einde
        ;;
     5)
        echo ${INIT}
        installGit
        einde
        ;;
     60)
        echo ${INIT}
        installNode "latest"
        einde
        ;;
     61)
        echo ${INIT}
        installNode "v8.9.3"
        einde
        ;;
     62)
        echo ${INIT}
        installNode "v7.10.1"
        einde
        ;;
     63)
        echo ${INIT}
        installNode "v6.11.0"
        einde
        ;;
     64)
        echo ${INIT}
        installNode "v5.12.0"
        einde
        ;;
     65)
        echo ${INIT}
        installNode "v4.8.3"
        einde
        ;;
     100)
        echo ${INIT}
        echo ${MAGENTA}maak "SSL certificaten.." voor https-protocol.${WHITE}
        cd /home/pi
        openssl req -x509 -nodes -days 1825 -newkey rsa:2048 -keyout server.key -out server.crt
        openssl pkcs8 -topk8 -inform PEM -outform PEM -in server.key -out server.pem
        echo ${MAGENTA}"server.pem" en "server.key" aangemaakt.${WHITE}
        einde
        ;;
     101)
        echo ${INIT}
        if node -v &>/dev/null; then
          cd /home/pi
          echo ${MAGENTA}Installeer pm2 globaal.${WHITE}
          sudo npm install -g pm2
          echo ${MAGENTA}Maak pm2 opstartbestand.${WHITE}
          sudo pm2 startup
          echo ${MAGENTA}Installatie voltooid.${WHITE}
        else
          echo ${RED}Installeer eerst node.js${WHITE}
        fi
        einde
        ;;
     102)
        echo ${INIT}
        if node -v &>/dev/null; then
          cd /home/pi
          echo ${WHITE}Installeer express, pubnub, johnny-five en raspi-io.
          echo De configuratie staat reeds in het bestand ${MAGENTA}package.json${WHITE}.
          echo Open ${MAGENTA}een NIEUW${WHITE} terminalvenster.
          echo Voer volgend commando uit: ${MAGENTA}$ npm install${WHITE}
        else
          echo ${RED}Installeer eerst node.js${WHITE}
        fi
        einde
        ;;
     800)
        echo ${INIT}
        sudo halt
        einde
        ;;
     801)
        echo ${INIT}
        sudo reboot
        einde
        ;;
     0)
        echo ${INIT}
        break
        ;;
esac  
done
