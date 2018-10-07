#!/bin/bash

#'.________._______ .______  .______  .____/\ .________
#|    ___/: ____  |:      \ : __   \ :   /  \|    ___/
#|___    \|    :  ||   .   ||  \____||.  ___/|___    \
#|       /|   |___||   :   ||   :  \ |     \ |       /
#|__:___/ |___|    |___|   ||   |___\|      \|__:___/
#   :                  |___||___|    |___\  /   :
#  v 12.3.2                               \/ '
# This is a custom version for my own deployments

# please use official version
# https://github.com/SparksReborn/SparksMasternodeInstall

#added fail to FailtoBan
#added creation of upgrade.sh because i am LAZY :D
#added checks
#changed install for root or non root user
#added option to secure with SSH-RSA-KEY
#added elivated privilages for non root install
# info file


#USERNAME=newuser
#useradd -m -s /bin/bash -G adm,systemd-journal,sudo $USERNAME && passwd $USERNAME
#su $USERNAME
#cd ~/


ADVANCE='1'
USER=$USER
TMP_FOLDER=$(mktemp -d)
CONFIG_FILE='sparks.conf'
COIN_DAEMON='sparksd'
COIN_VERSION='v0.12.3.2'
COIN_WALLET_VERSION='61000'
COIN_CLI='sparks-cli'
COIN_PATH='/usr/local/bin/'
COIN_REPO='https://github.com/SparksReborn/sparkspay.git'
COIN_TGZ='https://github.com/SparksReborn/sparkspay/releases/download/v0.12.3.2/sparkscore-0.12.3.2-linux64.tar.gz'
COIN_EPATH='sparkscore-0.12.3/bin'
COIN_BOOTSTRAP='https://github.com/SparksReborn/sparkspay/releases/download/bootstrap/bootstrap.dat'
COIN_ZIP=$(echo $COIN_TGZ | awk -F'/' '{print $NF}')
SENTINEL_REPO='https://github.com/SparksReborn/sentinel.git'
COIN_NAME='sparks'
COIN_PORT=8890
RPC_PORT=8818
STIL_BUSY='true'
mnsync='false'
#defined in functions, declared here as public
MNGENKEY=''
SSH_RSA_KEY=''
sencheck=''
HOMEPATH=''
CONFIGFOLDER=''

NODEIP=$(curl -s4 icanhazip.com)

BLUE="\033[0;34m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
PURPLE="\033[0;35m"
RED='\033[0;31m'
GREEN="\033[0;32m"
NC='\033[0m'
MAG='\e[1;35m'


function defineuserpath() {
    if [[ $USER = "root" ]]; then
    HOMEPATH='/root/'
    CONFIGFOLDER='/root/.sparkscore'
  else
    HOMEPATH='/home/'$USER'/'
    CONFIGFOLDER='/home/'$USER'/.sparkscore'
  fi
}

function intro(){

  echo '.________._______ .______  .______  .____/\ .________
  |    ___/: ____  |:      \ : __   \ :   /  \|    ___/
  |___    \|    :  ||   .   ||  \____||.  ___/|___    \
  |       /|   |___||   :   ||   :  \ |     \ |       /
  |__:___/ |___|    |___|   ||   |___\|      \|__:___/
     :                  |___||___|    |___\  /   :
   Auto Installer v1.0.0                   \/ '

  echo -e "${GREEN}This script will prepair your VPS and install the latest version of ${RED}$COIN_NAME${NC}"
  echo -e "${GREEN}After installation and configuration the script run a series of tests   "
  echo
  echo -e "${GREEN}The complete process will take appoximatly 20+ minutes ${NC}"
  echo -e "${GREEN}Important configuration infomation and commands can be found ${NC}"
  echo -e "${GREEN}in $CONFIGFOLDER/$COIN_NAME.info ${NC}"
  echo
  echo -e "${GREEN}When the ${RED}$COIN_NAME${NC} masternode is synced you will be prompted to  ${NC}"
  echo -e "${GREEN}start the master node in the windows wallet. ${NC}"
#  echo -e "${GREEN}restart the VPS, Please do not skip this step.  ${NC}"
#  echo -e "${GREEN}After the VPS has restarted you can start the alias in your windows wallet ${NC}"
  echo
  echo -e "${RED}The script will over write your crontab, please backup custom infomation before you continue ${NC}"
  echo -e "${RED}Press CTR+C to exit now if you need to backup info in your crontab ${NC}"
  echo
  echo -e "${YELLOW}Lets get started,"
  echo

}

purgeOldInstallation() {
    echo -e "${GREEN}Searching for and removing old $COIN_NAME files${NC}"
    #kill wallet daemon
    sudo systemctl stop $COIN_NAME.service > /dev/null 2>&1
    sudo killall $COIN_DAEMON > /dev/null 2>&1
    #remove old ufw port allow
    sudo ufw delete allow 8890/tcp > /dev/null 2>&1
    #remove old files
	  sudo rm $CONFIGFOLDER/bootstrap.dat.old > /dev/null 2>&1
	  cd /usr/local/bin && sudo rm $COIN_CLI $COIN_DAEMON > /dev/null 2>&1 && cd
    cd /usr/bin && sudo rm $COIN_CLI $COIN_DAEMON > /dev/null 2>&1 && cd
    sudo rm -rf ~/$CONFIGFOLDER > /dev/null 2>&1
    #remove binaries and Sparks utilities
    #removed
    #cd /usr/bin && sudo rm Sparks-cli Sparks-tx Sparksd > /dev/null 2>&1 && cd
    #cd /usr/local/bin && sudo rm Sparks-cli Sparks-tx Sparksd > /dev/null 2>&1 && cd
  #  echo -e "${GREEN}Clean up Done${NONE}";
}

function install_sentinel() {
  echo -e "${GREEN}Installing sentinel.${NC}"
  sudo apt-get -y install python-virtualenv virtualenv >/dev/null 2>&1
  git clone $SENTINEL_REPO $CONFIGFOLDER/sentinel >/dev/null 2>&1
  sudo chown -R $USER:$USER $CONFIGFOLDER/sentinel
  cd $CONFIGFOLDER/sentinel
    virtualenv ./venv >/dev/null 2>&1
  ./venv/bin/pip install -r requirements.txt >/dev/null 2>&1
  echo  "* * * * * cd $CONFIGFOLDER/sentinel && ./venv/bin/python bin/sentinel.py >> $CONFIGFOLDER/sentinel.log 2>&1" > $CONFIGFOLDER/$COIN_NAME.cron
  crontab $CONFIGFOLDER/$COIN_NAME.cron
  rm $CONFIGFOLDER/$COIN_NAME.cron >/dev/null 2>&1
}

function download_node() {
  echo -e "${GREEN}Downloading and Installing VPS $COIN_NAME Daemon${NC}"
  cd $TMP_FOLDER >/dev/null 2>&1
  wget -q $COIN_TGZ
  compile_error
  tar xvzf $COIN_ZIP >/dev/null 2>&1

  cd $COIN_EPATH

  chmod +x $COIN_DAEMON $COIN_CLI
  sudo cp $COIN_DAEMON $COIN_CLI $COIN_PATH
  cd ~ >/dev/null 2>&1
  rm -rf $TMP_FOLDER >/dev/null 2>&1
  #clear
  echo -e "${GREEN}$COIN_NAME Daemon is installed${NC}"
}

function configure_systemd() {
  echo -e "${GREEN}Configuring $COIN_NAME$ system service${NC}"
###New
echo \
"[Unit]
Description=$COIN_NAME daemon service
After=network.target

[Service]
User=$USER
Type=forking


#PIDFile=$CONFIGFOLDER/$COIN_NAME.pid

ExecStart=/usr/local/bin/$COIN_DAEMON -daemon -conf=$CONFIGFOLDER/$COIN_NAME.conf -datadir=$CONFIGFOLDER/
ExecStop=-/usr/local/bin/$COIN_CLI -conf=$CONFIGFOLDER/$COIN_NAME.conf -datadir=$CONFIGFOLDER/ stop

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target" | sudo tee /lib/systemd/system/$COIN_NAME.service >/dev/null 2>&1


  sudo chown -R $USER:$USER ~/
  sudo systemctl daemon-reload >/dev/null 2>&1
  sleep 3
  sudo systemctl start $COIN_NAME.service >/dev/null 2>&1
  sudo systemctl enable $COIN_NAME.service >/dev/null 2>&1

  if [[ -z "$(ps axo cmd:100 | egrep $COIN_DAEMON)" ]]; then
    echo -e "${RED}$COIN_NAME is not running${NC}, please investigate. You should start by running the following commands :"
    echo -e "${GREEN}systemctl start $COIN_NAME.service"
    echo -e "systemctl status $COIN_NAME.service"
    echo -e "less /var/log/syslog${NC}"
    exit 1
  fi

echo
  echo -e "${GREEN}Starting $COIN_NAME service and initiating checks ${NC}"
echo
  sleep 20
}

function create_config() {
  #mkdir $CONFIGFOLDER >/dev/null 2>&1
  mkdir -p $CONFIGFOLDER; touch $CONFIGFOLDER/$CONFIG_FILE; sudo chmod 700 $CONFIGFOLDER
  RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
  RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)
  cat << EOF > $CONFIGFOLDER/$CONFIG_FILE
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcport=$RPC_PORT
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
port=$COIN_PORT
EOF

#test apply permissions to conf file
sudo chown -R $USER:$USER ~/

}

function grab_bootstrap() {
echo -e "${GREEN}Downloading $COIN_NAME Bootstrap${NC}"
cd $CONFIGFOLDER
  wget -q $COIN_BOOTSTRAP
}

function created_upgrade() {
#to run use $ bash upgrade.sh
cd
cat << EOF > upgrade.sh
  #!/bin/bash
  sudo apt update
  sudo apt -y dist-upgrade
  sudo apt -y autoremove
EOF
}

function enter_key() {
echo -e "Would you like to enter your own $COIN_NAME Masternode GEN Key [Y/n] : "
read -e USERGENKEY

if [[ ("$USERGENKEY" == "y" || "$USERGENKEY" == "Y" || "$USERGENKEY" == "") ]]; then
  echo -e "Please Enter your ${RED}$COIN_NAME ${GREEN}Masternode GEN Key${NC}."
  read -e COINKEY
fi

}

function enter_SSH_RSA_key() {

if [[ $ADVANCE == '1' ]]; then

echo -e "${GREEN}Would you like to secure your VPS and restrict log on with SSH-RSA key? [Y/n]${NC}"
read -e USERSSHKEY

if [[ ("$USERSSHKEY" == "y" || "$USERSSHKEY" == "Y" || "$USERSSHKEY" == "") ]]; then
echo -e "${GREEN}Please Enter your ${RED}PUBLIC Key ${GREEN}generated by PuTTY keygenerator.${NC}"
echo -e "${RED} PLEASE MAKE SURE YOU ENTER THE CORRECT DATA.${NC}"
echo -e "${RED} IF YOUR ENTER THE WRONG DATA YOU WILL NOT BE ABLE TO ACCEESS THE SERVER${NC}"
read -e SSH_RSA_KEY
fi
else
echo -e "${GREEN}skipping step, enable ADVANCE mode to include.${NC}"
fi
}

function secure_vps_ssh() {

  if [[ ("$USERSSHKEY" == "y" || "$USERSSHKEY" == "Y" || "$USERSSHKEY" == "") ]]; then

#check lenth of key greater than 0

    mkdir -p ~/.ssh; touch ~/.ssh/authorized_keys; chmod 700 ~/.ssh
    echo \
    "$SSH_RSA_KEY" |sudo tee ~/.ssh/authorized_keys >/dev/null 2>&1

    chmod 600 ~/.ssh/authorized_keys >/dev/null 2>&1

    #check if root user
    #disable root account
    if [[ $USER = "root" ]]; then
      #just put this in incase they have changed it before this script
      sudo sed -i  "s/.*PermitRootLogin no/PermitRootLogin yes/g" /etc/ssh/sshd_config >/dev/null 2>&1
    else
      #will disable root login
      sudo sed -i  "s/.*PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config >/dev/null 2>&1
    fi
    sudo sed -i  "s/.*PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config >/dev/null 2>&1
    sudo sed -i  "s/.*ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/g" /etc/ssh/sshd_config >/dev/null 2>&1
    sudo systemctl restart sshd >/dev/null 2>&1
    echo -e "${RED}VPS is Secured with SSH-RSA KEY. TEST access BEFORE you reboot${$NC}"

  fi

}

function create_key() {
  if [[ -z "$COINKEY" ]]; then
  $COIN_PATH$COIN_DAEMON -daemon
  sleep 30
  if [ -z "$(ps axo cmd:100 | grep $COIN_DAEMON)" ]; then
   echo -e "${RED}$COIN_NAME server couldn not start. Check /var/log/syslog for errors.${$NC}"
   exit 1
  fi
  COINKEY=$($COIN_PATH$COIN_CLI masternode genkey)
  if [ "$?" -gt "0" ];
    then
    echo -e "${RED}Wallet not fully loaded. Let us wait and try again to generate the GEN Key${NC}"
    sleep 30
    COINKEY=$($COIN_PATH$COIN_CLI masternode genkey)
  fi
  $COIN_PATH$COIN_CLI stop
fi
#clear
}

function update_config() {
  sed -i 's/daemon=1/daemon=0/' $CONFIGFOLDER/$CONFIG_FILE
  cat << EOF >> $CONFIGFOLDER/$CONFIG_FILE
logintimestamps=1
maxconnections=256
#bind=$NODEIP
masternode=1
externalip=$NODEIP:$COIN_PORT
masternodeprivkey=$COINKEY

#ADDNODES

#disable log for cheap VPS
printtodebuglog=0

EOF
}

function enable_firewall() {
  echo -e "${GREEN}Installing and setting up firewall for ${RED}$COIN_NAME ${NC}on port${RED} $COIN_PORT${NC}"
  sudo ufw allow $COIN_PORT/tcp comment "$COIN_NAME MN port" >/dev/null
  sudo ufw allow ssh comment "SSH" >/dev/null 2>&1
  sudo ufw limit ssh/tcp >/dev/null 2>&1
  sudo ufw default allow outgoing >/dev/null 2>&1
  echo "y" | ufw enable >/dev/null 2>&1
}

function get_ip() {
  declare -a NODE_IPS
  for ips in $(netstat -i | awk '!/Kernel|Iface|lo/ {print $1," "}')
  do
    NODE_IPS+=($(curl --interface $ips --connect-timeout 2 -s4 icanhazip.com))
  done

  if [ ${#NODE_IPS[@]} -gt 1 ]
    then
      echo -e "${GREEN}More than one IP. Please type 0 to use the first IP, 1 for the second and so on...${NC}"
      INDEX=0
      for ip in "${NODE_IPS[@]}"
      do
        echo ${INDEX} $ip
        let INDEX=${INDEX}+1
      done
      read -e choose_ip
      NODEIP=${NODE_IPS[$choose_ip]}
  else
    NODEIP=${NODE_IPS[0]}
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

## remove this check when not root
## WIP
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   #exit 1
   echo -e "${RED}$0 current user is not root.${NC}"
   pause
fi

#this will be tested/changed with next upgrade
if [ -n "$(pidof $COIN_DAEMON)" ] || [ -e "$COIN_DAEMOM" ] ; then
  echo -e "${RED}$COIN_NAME is already installed.${NC}"
  exit 1
fi
}

function prepare_system() {
echo -e "${GREEN}Preparing the VPS.${NC}"
echo -e "${GREEN}Estimated run time on a fresh VPS upto 5 min  ${NC}"
sudo DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null 2>&1
echo -e "${GREEN} Step 1 / 3 ${RED}apt-get update ${GREEN}done ${NC}"
sudo DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade >/dev/null 2>&1
echo -e "${GREEN} Step 2 / 3 ${RED}apt-get upgrade ${GREEN}done ${NC}"
sudo DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq dist-upgrade >/dev/null 2>&1
echo -e "${GREEN} Step 3 / 3 ${RED}apt dist-upgrade ${GREEN}done ${NC}"
sudo apt install -y software-properties-common >/dev/null 2>&1
echo -e "${GREEN} Adding bitcoin PPA repository"
sudo apt-add-repository -y ppa:bitcoin/bitcoin >/dev/null 2>&1
echo -e "${GREEN} Installing required packages. This may take some time to finish.${NC}"
sudo apt-get update >/dev/null 2>&1
sudo apt-get install libzmq3-dev -y >/dev/null 2>&1
sudo apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" make software-properties-common \
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

}

function enable_fail2ban() {
echo -e "${GREEN}Installing fail to ban${NC}"
sudo apt -y install fail2ban >/dev/null 2>&1
sudo systemctl enable fail2ban >/dev/null 2>&1
sudo systemctl start fail2ban >/dev/null 2>&1
}

function block_countdown() {
msg="The coin daemon is now processing the bootstrap. will retry in ...  "
msg1="The block count will only move once the bootstrap has been loaded into memory"
msg2="Currntly $vpsblock block's out of $netblock processed   "
clear

clear

#still need to play with this layout
  tput cup 10 5
  echo "$msg"
  echo ""
  echo "$msg1"
  echo ""
  echo "$msg2"

    l=${#msg}
  l=$(( l+5 ))

  for i in {30..01}
  do
  tput cup 10 $l
  echo -n "$i"
  sleep 1
  done
  echo
}

function sync_countdown() {
  # Waiting 30 sec to recheck
#sync_msg="Masternode sync status:$mnsync, will retry in ..."
clear
#test

tput cup 10 5
echo -n "$sync_msg"
echo ""
echo -n "$sync_msg2"
  l=${#sync_msg}
l=$(( l+5 ))

for i in {40..01}
do
tput cup 10 $l
echo -n "$i"
sleep 1
done
echo
}

function get_mn_count() {
wget -q http://explorer.sparkscoin.io/api/getmasternodecount -O getmasternodecount
mncount=$(cat "getmasternodecount")
mnpay="$(($mncount * 3 / 60))"
rm getmasternodecount
}

function check_blocks() {

cd
wget -q http://explorer.sparkscoin.io/api/getblockcount -O getblockcount
netblock=$(cat "getblockcount")
rm getblockcount
vpsblock=$($COIN_CLI getinfo | grep blocks)
vpsblock=${vpsblock#*:}
vpsblock=${vpsblock%,*}

if [ "$netblock" -gt "$vpsblock" ]; then
  block_countdown
else
STIL_BUSY="false"
fi
}

function walletloadedcheck() {
  sync_msg="loading wallet, will retry in ..."
  sync_countdown
  vpsversion=$($COIN_CLI getinfo | grep walletversion)
  vpsversion=${vpsversion#*:}
  vpsversion=${vpsversion%,*}
}

function check_mnsync() {
  mnsync=$($COIN_CLI mnsync status | grep IsSynced)
  mnsync=${mnsync#*:}
  mnsync=${mnsync%,*}

  if [ $mnsync = "false" ]; then
    sync_msg="Masternode sync status:$mnsync, will retry in ..."
    sync_msg2=""
    sync_countdown
  fi
}

function check_mnstart() {
  mnstart=$($COIN_CLI masternode status | grep status)
  mnstart=${mnstart#*:}
  mnstart=${mnstart%,*}
  mnstart=${mnstart//\"}
  mnstart=${mnstart//\ }

  if [[ $mnstart = "Masternodesuccessfullystarted" ]]; then
    clear
    echo -e "${GREEN}Masternode successfully started${NC}"
  else
    sync_msg="Masternode start status: Masternode not started , retry in ..."
    #sync_msg2="Press start alias in windows wallet $mnstart"
    sync_msg2="Press start alias in windows wallet"
    sync_countdown
  fi
}

function information() {
  cat << EOF >> $HOMEPATH/$COIN_NAME.info

.________._______ .______  .______  .____/\ .________
|    ___/: ____  |:      \ : __   \ :   /  \|    ___/
|___    \|    :  ||   .   ||  \____||.  ___/|___    \
|       /|   |___||   :   ||   :  \ |     \ |       /
|__:___/ |___|    |___|   ||   |___\|      \|__:___/
   :                  |___||___|    |___\  /   :
                                         \/ '
$COIN_NAME Infomation

$COIN_NAME Website  : https://www.sparkscoin.io/
$COIN_NAME Github   : https://github.com/SparksReborn/sparkspay
$COIN_NAME Discord  : https://discord.gg/6ktdN8Z
$COIN_NAME Telegram : https://t.me/SparksCoin
$COIN_NAME Offical explorer: http://explorer.sparkscoin.io/
$COIN_NAME Windows Wallet Guide. https://github.com/Sparks/master/README.md

Usefull Commands

Start $COIN_NAME service          : systemctl start $COIN_NAME.service
Stop $COIN_NAME service           : systemctl stop $COIN_NAME.service
Get $COIN_NAME masternode status  : $COIN_CLI masternode status
Get status of $COIN_NAME daemon   : $COIN_CLI getinfo
Get $COIN_NAME mnsync status      : $COIN_CLI mnsync status

At the time of configuring this $COIN_NAME masternode there were $mncount active masternodes.

First payment will only take place after roughly $mnpay hours and only after the colladeral
payment has a minimum $mncount confermations.

  Configuration file is : $CONFIGFOLDER/$CONFIG_FILE"
  VPS_IP                : $NODEIP:$COIN_PORT
  MASTERNODE GENKEY is  : $COINKEY$
  Sentinel is installed : $CONFIGFOLDER/sentinel"
  Sentinel logs         : $CONFIGFOLDER/sentinel.log"
  Sentinal test         : $sencheck
  Fail2ban logs         :
EOF

}

function sentinel_check() {
  cd $CONFIGFOLDER/sentinel
  sencheck=$(./venv/bin/py.test ./test | grep passed)
  sencheck=${sencheck//=}
  senpass="23"
    if [[ $sencheck  =~ $senpass ]];
    then
      echo -e "${GREEN}Sentinel installation passed all tests.${NC}"

          else
      echo -e "${RED}Sentinel did not pass all tests. Find help on discord${NC}"
    fi
}

function sync_node_blocks() {
  until [[ $vpsversion -eq $COIN_WALLET_VERSION ]]; do
    sleep 3
    walletloadedcheck
  done

  #check block count
  until [ $STIL_BUSY = "false" ]
  do
    check_blocks
  done
}

function sync_node_mnsync() {
  #check mnsync status
  until [ $mnsync = "true" ]
  do
    check_mnsync
  done
}

function sync_node_start() {
  #check mnsync status
  until [ $mnstart = "Masternodesuccessfullystarted" ]
  do
    check_mnstart
  done
}

function rebootVPS() {
  # Reboot the server after installation is done.
   read -r -p "Are you ready to reboot the VPS? [Y/n]" response
   response=${response,,}
   if [[ $response =~ ^(yes|y| ) ]] || [[ -z $response ]]; then
      /sbin/reboot
   fi
}

function setup_node() {
  get_ip
  create_config
  create_key
  update_config
  enable_firewall
  grab_bootstrap
  install_sentinel
  created_upgrade
  if [[ ("$USERSSHKEY" == "y" || "$USERSSHKEY" == "Y" || "$USERSSHKEY" == "") ]]; then
    secure_vps_ssh
  fi
  enable_fail2ban
  configure_systemd
}

##### Main #####
clear
defineuserpath
intro
enter_key
enter_SSH_RSA_key
purgeOldInstallation
##### checks #####
prepare_system
download_node
setup_node
#add pause in here process complete
#ask if user would like to do the done checks
sync_node_blocks
sync_node_mnsync
get_mn_count
sync_node_start
sentinel_check
information
clear
printf '%b\n' "$(cat $HOMEPATH/$COIN_NAME.info)"
rebootVPS
