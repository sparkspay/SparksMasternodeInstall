#!/bin/bash
STIL_BUSY=true
mnsync=false
function check_blocks(){

cd
echo Getting current network block..
wget http://explorer.sparkscoin.io/api/getblockcount -O getblockcount
netblock=$(cat "getblockcount")
echo Net Block $netblock

vpsblock=$(sparks-cli getinfo | grep blocks)
vpsblock=${vpsblock#*:}
vpsblock=${vpsblock%,*}
#echo VPS Block $vpsblock
#vpsblock=$((vpsblock+2))
echo VPS Block $vpsblock
}

function block_countdown(){
  echo "Waiting 30 sec to recheck"
msg= -e "currntly $vpsblock block's out of $netblocks downloded, will retry in ..."
clear
tput cup 10 5
echo -n "$msg"
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

function mnsync_countdown(){
  echo "Waiting 30 sec to recheck"
mnsync_msg= -e "Masternode sync status: $mnsync, will retry in ..."
clear
tput cup 10 5
echo -n "$mnsync_msg"
  l=${#mnsync_msg}
l=$(( l+5 ))

for i in {30..01}
do
tput cup 10 $l
echo -n "$i"
sleep 1
done
echo
}

function block_loop_check() {
if [ "$netblock" -gt "$vpsblock" ]
then
  echo "Sparks Node still syncing with network "

block_countdown
else
STIL_BUSY=false
echo "system in sync, click start alias"
fi

}


#starting
#blocks
until [ ! STIL_BUSY ]
do
  check_blocks
  block_loop_check
done

function check_mnsync() {
  if $mnsync = false
  then
  mnsync=$(sparks-cli mnsync status | grep IsSynced)
  mnsync=${mnsync#*:}
  mnsync=${mnsync%,*}

else
  echo -e "Masternode sync status: $mnsync "
   mnsync=true
  fi

}

until [ mnsync ]
do
  check_mnsync

done


#masternode sync status
