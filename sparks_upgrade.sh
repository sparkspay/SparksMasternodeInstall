#!/bin/bash

TMP_FOLDER=$(mktemp -d)
CONFIG_FILE='sparks.conf'
CONFIGFOLDER='/root/.sparkscore'
COIN_DAEMON='sparksd'
COIN_CLI='sparks-cli'
COIN_PATH='/usr/local/bin/'
COIN_REPO='https://github.com/SparksReborn/sparkspay.git'
COIN_TGZ='https://github.com/SparksReborn/sparkspay/releases/download/v0.12.3.1/sparkscore-0.12.3.1-linux64.tar.gz'
COIN_BOOTSTRAP='https://github.com/SparksReborn/sparkspay/releases/download/v0.12.2.5/bootstrap.dat'
COIN_ZIP=$(echo $COIN_TGZ | awk -F'/' '{print $NF}')
SENTINEL_REPO='https://github.com/sparkscrypto/sentinel'
COIN_NAME='sparks'
COIN_PORT=8890
RPC_PORT=8818

NODEIP=$(curl -s4 icanhazip.com)

BLUE="\033[0;34m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
PURPLE="\033[0;35m"
RED='\033[0;31m'
GREEN="\033[0;32m"
NC='\033[0m'
MAG='\e[1;35m'


function purgeOldInstallation() {
    echo -e "${GREEN}Searching and removing old $COIN_NAME files and configurations${NC}"
    #kill wallet daemon
    systemctl stop Sparks > /dev/null 2>&1
    sudo killall Sparksd > /dev/null 2>&1
    #remove old ufw port allow
    #sudo ufw delete allow 8890/tcp > /dev/null 2>&1
    #remove old files
    if [ -d "~/.Sparks" ]; then
      #  sudo rm -rf ~/.Sparks > /dev/null 2>&1
      mv /root/.Sparks /root/.sparkscore  > /dev/null 2>&1
      mv ~/.sparkscore/Sparks.conf ~/.sparkscore/sparks.conf  > /dev/null 2>&1
    fi
    #remove binaries and Sparks utilities
    cd /usr/local/bin && sudo rm Sparks-cli Sparks-tx Sparksd > /dev/null 2>&1 && cd
    cd /usr/bin && sudo rm Sparks-cli Sparks-tx Sparksd > /dev/null 2>&1 && cd
    echo -e "${GREEN}* Done${NONE}";
}

function download_node() {
  echo -e "${GREEN}Downloading and Installing VPS $COIN_NAME Daemon${NC}"
  cd $TMP_FOLDER >/dev/null 2>&1
  wget -q $COIN_TGZ
  compile_error
  tar xvzf $COIN_ZIP >/dev/null 2>&1
  cd Sparkscore-0.12.3/bin
  chmod +x $COIN_DAEMON $COIN_CLI
  cp $COIN_DAEMON $COIN_CLI $COIN_PATH
  #cp sparks* $COIN_PATH
  cd ~ >/dev/null 2>&1
  rm -rf $TMP_FOLDER >/dev/null 2>&1
  clear
}

function install_sentinel() {
  echo -e "${GREEN}Installing sentinel.${NC}"
if [ -d "$CONFIGFOLDER/sentinal" ]; then
  echo  "* * * * * cd $CONFIGFOLDER/sentinel && ./venv/bin/python bin/sentinel.py >> $CONFIGFOLDER/sentinel.log 2>&1" > $CONFIGFOLDER/$COIN_NAME.cron
  crontab $CONFIGFOLDER/$COIN_NAME.cron
  rm $CONFIGFOLDER/$COIN_NAME.cron >/dev/null 2>&1
else
  apt-get -y install python-virtualenv virtualenv >/dev/null 2>&1
  git clone $SENTINEL_REPO $CONFIGFOLDER/sentinel >/dev/null 2>&1
  cd $CONFIGFOLDER/sentinel
  virtualenv ./venv >/dev/null 2>&1
  ./venv/bin/pip install -r requirements.txt >/dev/null 2>&1
  echo  "* * * * * cd $CONFIGFOLDER/sentinel && ./venv/bin/python bin/sentinel.py >> $CONFIGFOLDER/sentinel.log 2>&1" > $CONFIGFOLDER/$COIN_NAME.cron
  crontab $CONFIGFOLDER/$COIN_NAME.cron
  rm $CONFIGFOLDER/$COIN_NAME.cron >/dev/null 2>&1
fi

}

function configure_systemd() {
  rm /etc/systemd/system/Sparks.service >/dev/null 2>&1
  cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=$COIN_NAME service
After=network.target

[Service]
User=root
Group=root

Type=forking
#PIDFile=$CONFIGFOLDER/$COIN_NAME.pid

ExecStart=$COIN_PATH$COIN_DAEMON -daemon -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER
ExecStop=-$COIN_PATH$COIN_CLI -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER stop

Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  sleep 3
  systemctl start $COIN_NAME.service
  systemctl enable $COIN_NAME.service >/dev/null 2>&1

  if [[ -z "$(ps axo cmd:100 | egrep $COIN_DAEMON)" ]]; then
    echo -e "${RED}$COIN_NAME is not running${NC}, please investigate. You should start by running the following commands as root:"
    echo -e "${GREEN}systemctl start $COIN_NAME.service"
    echo -e "systemctl status $COIN_NAME.service"
    echo -e "less /var/log/syslog${NC}"
    exit 1
  fi
}



function compile_error() {
if [ "$?" -gt "0" ];
 then
  echo -e "${RED}Failed to compile $COIN_NAME. Please investigate.${NC}"
  exit 1
fi
}


function checks() {
if [[ $(lsb_release -d) != *16.04* ]]; then
  echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

if [ -n "$(pidof $COIN_DAEMON)" ] || [ -e "$COIN_DAEMOM" ] ; then
  echo -e "${RED}$COIN_NAME is already installed.${NC}"
  exit 1
fi
}

function prepare_system() {
echo -e "Preparing the VPS to setup. ${CYAN}$COIN_NAME${NC} ${RED}Masternode${NC}"
apt-get update >/dev/null 2>&1
apt -y dist-upgrade  >/dev/null 2>&1
apt -y autoremove >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade >/dev/null 2>&1
apt install -y software-properties-common >/dev/null 2>&1
echo -e "${PURPLE}Adding bitcoin PPA repository"
apt-add-repository -y ppa:bitcoin/bitcoin >/dev/null 2>&1
echo -e "Installing required packages, it may take some time to finish.${NC}"
apt-get update >/dev/null 2>&1
apt-get install libzmq3-dev -y >/dev/null 2>&1
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" make software-properties-common \
build-essential libtool autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev \
libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git wget curl libdb4.8-dev bsdmainutils libdb4.8++-dev \
libminiupnpc-dev libgmp3-dev ufw pkg-config libevent-dev  libdb5.3++ unzip libzmq5 >/dev/null 2>&1
if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
    echo "apt-get update"
    echo "apt -y install software-properties-common"
    echo "apt-add-repository -y ppa:bitcoin/bitcoin"
    echo "apt-get update"
    echo "apt install -y make build-essential libtool software-properties-common autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev \
libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git curl libdb4.8-dev \
bsdmainutils libdb4.8++-dev libminiupnpc-dev libgmp3-dev ufw pkg-config libevent-dev libdb5.3++ unzip libzmq5"
 exit 1
fi
clear
}

function important_information() {
 echo
 echo -e "Please check ${RED}$COIN_NAME${NC} is running with the following command: ${RED}systemctl status $COIN_NAME.service${NC}"
 echo -e "Use ${RED}$COIN_CLI masternode status${NC} to check your MN."
 if [[ -n $SENTINEL_REPO  ]]; then
 echo -e "${RED}Sentinel${NC} is installed in ${RED}/root/sentinel_$COIN_NAME${NC}"
 echo -e "Sentinel logs is: ${RED}$CONFIGFOLDER/sentinel.log${NC}"
 fi
 echo -e "${BLUE}================================================================================================================================"
 echo -e "${CYAN}Original install script by Real_Bit_Yoda Follow twitter to stay updated.  https://twitter.com/Real_Bit_Yoda${NC}"
 echo -e "${BLUE}================================================================================================================================${NC}"
 echo -e "${BLUE}================================================================================================================================"
 echo -e "${CYAN}This upgrade script by DrWeez "
 echo -e "${BLUE}================================================================================================================================${NC}"
 echo -e "${GREEN}Donations accepted but never required.${NC}"
 echo -e "${BLUE}================================================================================================================================${NC}"
 echo -e "${YELLOW}DrWeez SPK: GTWBJHbZreZaPmNiYvd2HAmQRXxBh3dTTZ"
 echo -e "${YELLOW}Real_Bit_Yoda BCH: qzgnck23pwfag8ucz2f0vf0j5skshtuql5hmwwjhds"
 echo -e "${YELLOW}Real_Bit_Yoda ETH: 0x765eA1753A1eB7b12500499405e811f4d5164554"
 echo -e "${YELLOW}Real_Bit_Yoda LTC: LNt9EQputZK8djTSZyR3jE72o7NXNrb4aB${NC}"
 echo -e "${BLUE}================================================================================================================================${NC}"

function setup_node() {
  #get_ip
  #create_config
  #create_key
  #update_config
#  enable_firewall
  install_sentinel
#  grab_bootstrap
#  important_information
  configure_systemd
  #created_upgrade
}


##### Main #####
clear

purgeOldInstallation #removed old Sparks* moves .Sparks to .sparkscore
checks # basic checks
prepare_system #upgrades systemd
download_node # downloads new version extracts and copies
setup_node # installs sentinal / reconfigures crontab && removes old service and creats new.
