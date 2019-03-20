#!/bin/bash

#'.________._______ .______  .______  .____/\ .________
#|    ___/: ____  |:      \ : __   \ :   /  \|    ___/
#|___    \|    :  ||   .   ||  \____||.  ___/|___    \
#|       /|   |___||   :   ||   :  \ |     \ |       /
#|__:___/ |___|    |___|   ||   |___\|      \|__:___/
#   :                  |___||___|    |___\  /   :
#  v 1.0.3                                \/ '

#ChangeLOG
#V 1.0.3
##updated to SparksPay v0.12.3.6
#changed sentinel crontab method
#added sentinel repo check
#added 32/64 bit checks


#V 1.0.2
#updated to SparksPay v0.12.3.5

#V 1.0.1
#updated COIN_VERSION
#updated COIN_TGZ
#ADDED Upgrade / Fresh instrall checks and options
#added clean up COIN_EPATH
#removed root user check
#updated to new GIT
#added basic SSH Key validation

#V1.0.0
#first releases
#added fail to FailtoBan
#added creation of upgrade.sh because i am LAZY :D
#added checks
#changed install for root or non root user
#added option to secure with SSH-RSA-KEY
#added elevated privileges for non root install
#added info file
#some code from Real_Bit_Yoda's sparks intall script

#USERNAME=
#useradd -m -s /bin/bash -G adm,systemd-journal,sudo $USERNAME && passwd $USERNAME
#su $USERNAME
#cd ~/

USER=$USER
TMP_FOLDER=$(mktemp -d)
CONFIG_FILE='sparks.conf'
COIN_DAEMON='sparksd'
COIN_VERSION='120306'
####check
COIN_WALLET_VERSION='61000'
COIN_PROTOCAL_VERSION='70210'
###
COIN_CLI='sparks-cli'
COIN_PATH='/usr/local/bin/'
COIN_REPO='https://github.com/sparkspay/sparks.git'
COIN_TGZx86_64='https://github.com/sparkspay/sparks/releases/download/v0.12.3.6/sparkscore-0.12.3.6-x86_64-linux-gnu.tar.gz'
COIN_TGZx86_32='https://github.com/sparkspay/sparks/releases/download/v0.12.3.6/sparkscore-0.12.3.6-i686-pc-linux-gnu.tar.gz'
COIN_EPATH='sparkscore-0.12.3/bin'
# beta testing url COIN_TGZ='sparkscore-0.12.4-x86_64-linux-gnu.tar.gz'
# beta testing COIN_EPATH='sparkscore-0.12.4/bin'
COIN_BOOTSTRAP='https://github.com/sparkspay/sparks/releases/download/bootstrap/bootstrap.dat'
COIN_ZIP=$(echo $COIN_TGZ | awk -F'/' '{print $NF}')
SENTINEL_REPO='https://github.com/sparkspay/sentinel.git'
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
UPGRADESPARKS='false'
CLEANSPARKS='false'
ADVANCE='1'
MACHINE_TYPE=uname -m

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
   Auto Installer v1.0.2                   \/ '

  echo -e "${GREEN}This script will prepare your VPS and install the latest version of ${RED}$COIN_NAME${NC}"
  echo -e "${GREEN}After the installation is completed, the script run a series of tests   "
  echo
  echo -e "${GREEN}The complete process will take appoximately 20+ minutes ${NC}"
  echo -e "${GREEN}Important configuration information and commands can be found ${NC}"
  echo -e "${GREEN}in${RED} $CONFIGFOLDER/$COIN_NAME.info ${NC}"
  echo
  echo -e "${NC}When the ${RED}$COIN_NAME${NC} masternode is synced you will be prompted to  ${NC}"
  echo -e "${NC}start the master node in the windows wallet. ${NC}"
  echo
  echo -e "${RED}The script will clear your crontab, please backup custom information before you continue ${NC}"
  echo -e "${RED}Press CTR+C to exit now if you need to backup info in your crontab ${NC}"
  echo
  echo -e "${YELLOW}Let's get started, Press [Enter] key to continue..."
  echo
pause
}

purgeOldInstallation() {
    echo -e "${GREEN}Looking for and Cleaning up old files${NC}"
    #kill wallet daemon
    sudo systemctl stop $COIN_NAME.service > /dev/null 2>&1
    sudo killall $COIN_DAEMON > /dev/null 2>&1
    #remove old files
	  sudo rm $CONFIGFOLDER/bootstrap.dat.old > /dev/null 2>&1
	  cd /usr/local/bin && sudo rm $COIN_CLI $COIN_DAEMON > /dev/null 2>&1 && cd
    cd /usr/bin && sudo rm $COIN_CLI $COIN_DAEMON > /dev/null 2>&1 && cd
    # remove old extracted files
    sudo rm -rf $COIN_EPATH >/dev/null 2>&1
    sudo mv $HOMEPATH/$COIN_NAME.info $HOMEPATH/$COIN_NAME.info.old >/dev/null 2>&1

    if [[ $CLEANSPARKS='true' ]] ; then
      #remove old ufw port allow
      sudo ufw delete allow 8890/tcp > /dev/null 2>&1
      #remove old Service
      sudo rm /lib/systemd/system/$COIN_NAME.service > /dev/null 2>&1
      #sudo rm ~/$CONFIGFOLDER/$COIN_NAME.service > /dev/null 2>&1
      #delete whole sparks folder
      sudo rm -rf /$CONFIGFOLDER > /dev/null 2>&1

    fi

}

function install_sentinel() {
  echo -e "${GREEN}Installing sentinel.${NC}"
  sudo apt-get -y install python-virtualenv virtualenv >/dev/null 2>&1
  git clone $SENTINEL_REPO $CONFIGFOLDER/sentinel >/dev/null 2>&1
  sudo chown -R $USER:$USER $CONFIGFOLDER/sentinel
  cd $CONFIGFOLDER/sentinel
    virtualenv ./venv >/dev/null 2>&1
  ./venv/bin/pip install -r requirements.txt >/dev/null 2>&1
  #echo  "* * * * * cd $CONFIGFOLDER/sentinel && ./venv/bin/python bin/sentinel.py >> $CONFIGFOLDER/sentinel.log 2>&1" > $CONFIGFOLDER/$COIN_NAME.cron
  #crontab $CONFIGFOLDER/$COIN_NAME.cron
  #rm $CONFIGFOLDER/$COIN_NAME.cron >/dev/null 2>&1

#BETA FUNCTION
#full test still required

#maybe ned to test for sparks in the crontab as well and remove it?

croncmd="cd $CONFIGFOLDER/sentinel && ./venv/bin/python bin/sentinel.py >> $CONFIGFOLDER/sentinel.log 2>&1"
cronjob="* * * * * $croncmd"
#add
( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -
#remove
#( crontab -l | grep -v -F "$croncmd" ) | crontab -

cat << EOF > $CONFIGFOLDER/sentinel/sentinel.conf
# specify path to sparks.conf or leave blank
# default is the same as SparksCore
#sparks_conf=/home/evan82/.sparkscore/sparks.conf
sparks_conf=$CONFIGFOLDER/$CONFIG_FILE

# valid options are mainnet, testnet (default=mainnet)
network=mainnet
#network=testnet

# database connection details
db_name=database/sentinel.db
db_driver=sqlite

EOF

}

function download_node() {
  #download and install
  echo -e "${GREEN}Downloading and Installing $COIN_NAME Daemon${NC}"
  cd $TMP_FOLDER >/dev/null 2>&1
  wget -q $COIN_TGZ
  compile_error
  tar xvzf $COIN_ZIP >/dev/null 2>&1

  cd $COIN_EPATH

  chmod +x $COIN_DAEMON $COIN_CLI
  sudo cp $COIN_DAEMON $COIN_CLI $COIN_PATH
  cd ~ >/dev/null 2>&1
  rm -rf $TMP_FOLDER >/dev/null 2>&1
  rm -rf $COIN_EPATH >/dev/null 2>&1
  #clear
  echo -e "${GREEN}$COIN_NAME Daemon is installed${NC}"
}

function configure_systemd() {
  echo -e "${GREEN}Configuring $COIN_NAME system service${NC}"
###New
cd ~/
touch $CONFIGFOLDER/$COIN_NAME.service
cat << EOF > $CONFIGFOLDER/$COIN_NAME.service
[Unit]
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
WantedBy=multi-user.target
EOF

sudo chown -R $USER:$USER ~/
sudo cp $CONFIGFOLDER/$COIN_NAME.service /lib/systemd/system/$COIN_NAME.service
#>/dev/null 2>&1
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
  sleep 30
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

sudo chown -R $USER:$USER ~/

}

function grab_bootstrap() {
echo -e "${GREEN}Downloading $COIN_NAME Bootstrap${NC}"
cd $CONFIGFOLDER
  wget -q $COIN_BOOTSTRAP
}

function created_upgrade() {
#use this upgrasde script to keep your VPS up to date
#to run -> $ bash upgrade.sh
#cd
#cd && sudo rm upgrade.sh >/dev/null 2>&1
cat << EOF > upgrade.sh
  #!/bin/bash
  sudo apt-get clean -y
  sudo apt -y autoremove --purge
  sudo apt update
  sudo apt -y dist-upgrade --purge
EOF
}

function enter_key() {
echo -e "Would you like to enter your own $COIN_NAME Masternode GEN Key [Y/n] : "
read -e USERGENKEY

if [[ ("$USERGENKEY" == "y" || "$USERGENKEY" == "Y" || "$USERGENKEY" == "") ]]; then
  echo -e "Please Enter your ${RED}$COIN_NAME ${GREEN}Masternode GEN Key${NC}."
  read -e COINKEY
#add check to verify masternode key lenth

fi

}

function enter_SSH_RSA_key() {

if [[ $ADVANCE == '1' ]]; then

#check if there is already a ~/.ssh/authorized_keys file and skip
#fresh upgrade option

  if [ -e ~/.ssh/authorized_keys ]; then
    echo -e "${GREEN}skipping step, SSH authorized_keys file was found.${NC}"
  else
    echo -e "${GREEN}Would you like to secure your VPS and restrict log on with a SSH-RSA key? [Y/n]${NC}"
    echo -e ""
    echo -e "${RED}IF YOU DO NOT KNOW WHAT THIS IS PRESS N/n${NC}"

    read -e USERSSHKEY

    if [[ ("$USERSSHKEY" == "y" || "$USERSSHKEY" == "Y" || "$USERSSHKEY" == "") ]]; then

        echo -e "${RED}PLEASE MAKE SURE YOU ENTER THE CORRECT DATA.${NC}"
        echo -e "${RED}IF YOUR ENTER THE WRONG DATA YOU WILL NOT BE ABLE TO ACCESS THE SERVER${NC}"
        echo -e "${YELLOW}IF YOUR ENTER THE WRONG DATA YOU WILL NOT BE ABLE TO ACCESS THE SERVER${NC}"
        echo -e ""
        echo -e "${RED}Press CTR+C to exit now if you need are NOT sure ${NC}"
        echo -e ""
        echo -e "${GREEN}Please Enter your ${RED}RSA-SSH Key ${GREEN}generated by PuTTY keygenerator.${NC}"
        read -e SSH_RSA_KEY

        mkdir -p ~/.ssh; touch ~/.ssh/authorized_keys; chmod 700 ~/.ssh
        echo "$SSH_RSA_KEY" |sudo tee ~/.ssh/authorized_keys >/dev/null 2>&1
        chmod 600 ~/.ssh/authorized_keys >/dev/null 2>&1

#check file and rollback if fail
#####
#vaildssh=$(ssh-keygen -l -f provisioning.log)
        vaildssh=$(ssh-keygen -l -f ~/.ssh/authorized_keys)
#    if the lenth of the var is 0 then key not valid
#basic test of authorized_keys file
        if [ ${#vaildssh} -ge 6 ]; then
          echo -e ""
          echo -e "${GREEN}RSA-SSH passed basic validation${NC}"
          ssh-keygen -l -f ~/.ssh/authorized_keys
          echo -e ""
          echo -e "${RED}THE SSH-RSA KEY has been configured. TEST access BEFORE you disconnect${NC}"
          echo -e "${GREEN}Do not close this window, Open a new window and test that you can connect with the SSH KEY${NC}"
          #echo -e "${RED}After you have tested conncting with the SSH-RSA KEY ${NC}"
          echo -e ""
          #echo -e "${GREEN}Press [Enter] key to continue or [U] to undo  ... ${NC}"
          #add undo option if test fails
          echo -e "${RED}Can you connect using the SSH key [Y/n]${NC}"
          #pause
          read -e SSHCONNECT
        else
          echo -e ""
          echo -e "${RED}The RSA-SSA Key is not valid${NC}"
          echo -e "${GREEN}Skipping Please manually secure the VPS.${NC}"
          SSHCONNECT="N"
        fi
    else
    echo -e "${GREEN}skipping step, enable ADVANCE mode to include VPS SSH security steps.${NC}"
    fi
  fi
fi
}

function secure_vps_ssh() {
if [[ $ADVANCE == '1' ]]; then
  if [[ ("$USERSSHKEY" == "y" || "$USERSSHKEY" == "Y" || "$USERSSHKEY" == "") ]]; then
    if [[ ("$SSHCONNECT" == "y" || "$SSHCONNECT" == "Y" ) ]]; then
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
    fi
  fi
fi

}

function create_key() {
  if [[ -z "$COINKEY" ]]; then
  $COIN_PATH$COIN_DAEMON -daemon
  sleep 30
  if [ -z "$(ps axo cmd:100 | grep $COIN_DAEMON)" ]; then
   echo -e "${RED}$COIN_NAME server could not start. Check /var/log/syslog for errors.${$NC}"
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
disablewallet=1
#ADDNODES

#disable log for cheap VPS
#printtodebuglog=0

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
  if [[ $(lsb_release -d) != *18.04* ]]; then
  echo -e "${RED}You are not running Ubuntu 16.04 or Ubuntu 18.04 Installation is cancelled.${NC}"
  exit 1
  fi
fi
}

if [ ${MACHINE_TYPE} == 'x86_64' ]; then
  COIN_TGZ=$COIN_TGZx86_64
else
  COIN_TGZ=$COIN_TGZx86_32
fi


function prepare_system() {
echo -e "${GREEN}Preparing the VPS.${NC}"
echo -e "${GREEN}Estimated run time for the following three steps is 5 min  ${NC}"
sudo DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null 2>&1
echo -e "${GREEN} Step 1 / 3 ${RED}apt update ${GREEN}done ${NC}"
sudo DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade >/dev/null 2>&1
echo -e "${GREEN} Step 2 / 3 ${RED}apt upgrade ${GREEN}done ${NC}"
sudo DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq dist-upgrade >/dev/null 2>&1
echo -e "${GREEN} Step 3 / 3 ${RED}apt dist-upgrade ${GREEN}done ${NC}"
sudo apt install -y software-properties-common >/dev/null 2>&1
echo -e "${GREEN} Adding bitcoin PPA repository"
sudo apt-add-repository -y ppa:bitcoin/bitcoin >/dev/null 2>&1
echo -e "${GREEN} Installing or upgrading required packages. This may take some time to finish.${NC}"
sudo apt-get update >/dev/null 2>&1
sudo apt-get install libzmq3-dev -y >/dev/null 2>&1
sudo apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" make software-properties-common \
build-essential libtool autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev \
libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git wget curl libdb4.8-dev bsdmainutils libdb4.8++-dev \
libminiupnpc-dev libgmp3-dev ufw pkg-config libevent-dev  libdb5.3++ unzip libzmq5 >/dev/null 2>&1

if [ $CLEANSPARKS = "false" ] ; then
if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
    echo "apt update"
    echo "apt -y install software-properties-common"
    echo "apt-add-repository -y ppa:bitcoin/bitcoin"
    echo "apt update"
    echo "apt install -y make build-essential libtool software-properties-common autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev \
libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git curl libdb4.8-dev \
bsdmainutils libdb4.8++-dev libminiupnpc-dev libgmp3-dev ufw pkg-config libevent-dev libdb5.3++ unzip libzmq5"
 exit 1
fi
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
msg2="Currently $vpsblock block's out of $netblock processed   "
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

for i in {30..01}
do
tput cup 10 $l
echo -n "$i"
sleep 1
done
echo
}

function get_mn_count() {
wget -q http://explorer.sparkspay.io/api/getmasternodecount -O getmasternodecount
mncount=$(cat "getmasternodecount" | grep "total")
mncount=${mncount#*:}
mncount=${mncount%,*}

mnpay="$(($mncount * 3 / 60))"
rm getmasternodecount
}

function check_blocks() {

cd
wget -q http://explorer.sparkspay.io/api/getblockcount -O getblockcount
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

function spk_versioncheck() {
  clear
  if [ -e $CONFIGFOLDER/$CONFIG_FILE ]; then
    spk_version=$($COIN_CLI getinfo | grep -w version)
    spk_version=${spk_version#*:}
    spk_version=${spk_version%,*}

        if [[ $spk_version -lt $COIN_VERSION ]]; then
          #wouyld you like to upgrade or complete a fresh install
          echo -e ""
          echo -e "${RED}$COIN_NAME ${NC}version${RED}$spk_version ${NC}is already installed.${NC}"
          echo -e ""
          echo -e "Would you like to ${GREEN}upgrade[U]${RED}$COIN_NAME ${NC} or perform a ${GREEN}fresh install[f]${NC} [U/f] : "
          echo -e ""
          echo -e "An upgrade will keep the current blockchain, sentinel and $COIN_NAME configuration "
          echo -e "Ubuntu and only the ${RED}$COIN_NAME${NC} daemon/CLI will be upgraded"
          echo -e ""
          echo -e "A fresh install [f] will completely remove the old installation folder and configuration"
          echo -e "as well as remove all ${RED}$COIN_NAME ${NC}files, Make sure you have backed up your data "
          echo -e "The masternode private key will be saved and used in the new installation"
          echo -e ""
          echo -e "Upgrade[U] ${RED}$COIN_NAME ${NC}or Fresh install [f] [U/f] : "
          read -e FRESHUPGRADE
        else
          echo -e "${RED}The latest version of $COIN_NAME ($spk_version) is already installed.${NC}"
          echo -e "Press [f] to complete a fresh install or [e] to exit [e/n] : "
          read -e FRESHUPGRADE
        fi
        if [[ ("$FRESHUPGRADE" == "u" || "$FRESHUPGRADE" == "U" || "$FRESHUPGRADE" == "") ]]; then
          COINKEY=$(cat $CONFIGFOLDER/$CONFIG_FILE | grep masternodeprivkey)
          COINKEY=${COINKEY#*=}
          #could read and reuse the masternodeprivkey before removing it
          #should verify the lenth of key if fails then create new key
          #should/could back up the wallet
          UPGRADESPARKS="true"
    #     if [ -e $CONFIGFOLDER/$COIN_NAME.service ]; then
          #fi
          #check if the sparks.service file is there
          #if not suggest a fresh install
        fi
        if [[ ("$FRESHUPGRADE" == "f" || "$FRESHUPGRADE" == "F") ]]; then
          echo -e "${RED}Are you sure that you have backed up your data? [Y/n] "
          read -e AREYOUSURE
            if [[ ("$AREYOUSURE" == "y" || "$AREYOUSURE" == "Y") ]]; then
              CLEANSPARKS='true'
              COINKEY=$(cat $CONFIGFOLDER/$CONFIG_FILE | grep masternodeprivkey)
              COINKEY=${COINKEY#*=}
              #could read and reuse the masternodeprivkey before removing it
              #should verify the lenth of key if fails then create new key
              #should/could back up the wallet
            else
              echo -e "${RED}you must be sure to continue with a fresh install "
              exit 1
            fi
        fi
        if [[ ("$FRESHUPGRADE" == "e" || "$FRESHUPGRADE" == "E") ]]; then
          echo -e "${RED}$0 Script aborted.${NC}"
          exit 1
        fi
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
  clear
  cat << EOF >> $HOMEPATH/$COIN_NAME.info
.________._______ .______  .______  .____/\ .________
|    ___/: ____  |:      \ : __   \ :   /  \|    ___/
|___    \|    :  ||   .   ||  \____||.  ___/|___    \
|       /|   |___||   :   ||   :  \ |     \ |       /
|__:___/ |___|    |___|   ||   |___\|      \|__:___/
   :                  |___||___|    |___\  /   :
                                            \/ '

$COIN_NAME Infomation
$COIN_NAME Website  : http://sparkspay.io/
$COIN_NAME Github   : https://github.com/SparksPay
$COIN_NAME Discord  : https://discord.gg/6ktdN8Z
$COIN_NAME Telegram : https://t.me/SparksCoin
$COIN_NAME Facebook : https://www.facebook.com/sparkspay.io/
$COIN_NAME Twitter  : https://twitter.com/sparkspayio
$COIN_NAME Medium   : https://medium.com/sparkspay
$COIN_NAME Reddit   : https://www.reddit.com/r/SparksCoin
$COIN_NAME Instagram: https://www.instagram.com/sparkspay/?hl=en
$COIN_NAME Block explorer: http://explorer.sparkspay.io/
$COIN_NAME Windows Wallet Guide. TBA

Usefull Commands

Start $COIN_NAME service          : systemctl start $COIN_NAME.service
Stop $COIN_NAME service           : systemctl stop $COIN_NAME.service
Get $COIN_NAME masternode status  : $COIN_CLI masternode status
Get status of $COIN_NAME daemon   : $COIN_CLI getinfo
Get $COIN_NAME mnsync status      : $COIN_CLI mnsync status

At the time of configuring this $COIN_NAME masternode there were$mncount active masternodes.

First payment will only take place after roughly $mnpay hours and only after the collateral
payment has a minimum$mncount confirmations.

  Configuration file is : $CONFIGFOLDER/$CONFIG_FILE
  VPS_IP                : $NODEIP:$COIN_PORT
  MASTERNODE GENKEY is  : $COINKEY$
  Sentinel is installed : $CONFIGFOLDER/sentinel
  Sentinel logs         : $CONFIGFOLDER/sentinel.log
  Sentinal test         : $sencheck
  Fail2ban logs         :
EOF

}

function sentinel_check() {
  cd $CONFIGFOLDER/sentinel
  sleep 15
  #git config --get remote.origin.url
  sencheck=$(./venv/bin/py.test ./test | grep passed)
  sencheck=${sencheck//=}
  senpass="24"
    if [[ $sencheck  =~ $senpass ]];
    then
      echo -e "${GREEN}Sentinel installation passed all tests.${NC}"

          else
      echo -e "${RED}Sentinel did not pass all tests. Find help on discord${NC}"
      #exit 1
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
    sudo /sbin/reboot
   fi
}

function setup_node() {
  get_ip
  create_config
  if [ $CLEANSPARKS = "false" ]; then
    #else
    create_key
  fi
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

function upgrade_node() {
if [[ $ADVANCE == '1' ]]; then
  echo -e "${GREEN}Upgrading the VPS.${NC}"
  echo -e "${GREEN}Estimated run time for the following three steps is 5 min  ${NC}"
#Free up space before upgrade
# sudo apt -y autoremove --purge
  sudo DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq autoremove --purge >/dev/null 2>&1
  sudo DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null 2>&1
  echo -e "${GREEN} Step 1 / 3 ${RED}apt-get update ${GREEN}done ${NC}"
  sudo DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade >/dev/null 2>&1
  echo -e "${GREEN} Step 2 / 3 ${RED}apt-get upgrade ${GREEN}done ${NC}"
  sudo DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq dist-upgrade >/dev/null 2>&1
  echo -e "${GREEN} Step 3 / 3 ${RED}apt dist-upgrade ${GREEN}done ${NC}"
  echo -e " "
  echo -e "${GREEN}Ubuntu Upgrade Complete! ${NC}"
  echo -e " "
else
echo -e "${GREEN}Skipping Ubuntu Upgrade! ${NC}"
fi
  echo -e "${GREEN}Start clean up ${NC}"
  sudo systemctl stop $COIN_NAME.service > /dev/null 2>&1
  sudo killall $COIN_DAEMON > /dev/null 2>&1
  #remove some old files
  sudo rm $CONFIGFOLDER/bootstrap.dat.old > /dev/null 2>&1
  #remove old daemon and cli
  cd /usr/local/bin && sudo rm $COIN_CLI $COIN_DAEMON > /dev/null 2>&1 && cd
  cd /usr/bin && sudo rm $COIN_CLI $COIN_DAEMON > /dev/null 2>&1 && cd
  # remove old extracted files if they were not cleaned up before
  sudo rm -rf $COIN_EPATH >/dev/null 2>&1
  #rename the info file for info
  sudo mv $HOMEPATH/$COIN_NAME.info $HOMEPATH/$COIN_NAME.info.old >/dev/null 2>&1

  #Remove old sentinel and install from new repo
  #check sentinel repository
  cd $CONFIGFOLDER/sentinel > /dev/null 2>&1
  sentinelreposotory=$(git config --get remote.origin.url) > /dev/null 2>&1
  if [[ $sentinelreposotory == 'https://github.com/sparkspay/sentinel.git' ]]; then
    echo -e "${GREEN}Skipping sentinel Repo Upgrade! ${NC}"
    #git pull
  else
    sudo rm -rf $CONFIGFOLDER/sentinel > /dev/null 2>&1
    install_sentinel
  fi

  download_node
  sudo systemctl start $COIN_NAME.service >/dev/null 2>&1
}

function pause(){
   read -p "$*"
}

##### Main #####
clear
defineuserpath
intro
spk_versioncheck

##
if [ $UPGRADESPARKS = "true" ]; then
  clear
  upgrade_node
  fi

#do if CLEANSPARKS
if [ $CLEANSPARKS = "true" ]; then
  clear
  #enter_key

  if [ -e ~/.ssh/authorized_keys ]; then
      echo -e "${GREEN}skipping step, SSH authorized_keys file was found.${NC}"
  else
      enter_SSH_RSA_key
  fi

  purgeOldInstallation
  prepare_system
  download_node
  setup_node

fi

if [ $UPGRADESPARKS = "false" ]; then
#do if upgrade  and clean false
if [ $CLEANSPARKS = "false" ]; then
  clear
  enter_key
  enter_SSH_RSA_key
  purgeOldInstallation
  prepare_system
  download_node
  setup_node
fi
fi

#do all checks
#change in protocolversion requires that the node is started in hot wallet

get_mn_count
sentinel_check
information
sync_node_blocks
sync_node_mnsync
#
sync_node_start
#
clear
printf '%b\n' "$(cat $HOMEPATH/$COIN_NAME.info)"
rebootVPS
