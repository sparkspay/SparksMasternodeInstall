#!/bin/bash


USER=$USER
if [[ $USER = "root" ]]; then
HOMEPATH='/root/'
CONFIGFOLDER='/root/.sparkscore'
else
HOMEPATH='/home/'$USER'/'
CONFIGFOLDER='/home/'$USER'/.sparkscore'
fi

#SPARKS_LOC='/root/.sparkscore'

rm -r $CONFIGFOLDER/sentinel > /dev/null 2>&1
echo -e "${GREEN}do quick cleanup${NC}"
rm $CONFIGFOLDER/sentinel.log > /dev/null 2>&1


#apt-get -y install python-virtualenv virtualenv >/dev/null 2>&1
cd $CONFIGFOLDER
git clone https://github.com/sparkspay/sentinel.git $CONFIGFOLDER/sentinel >/dev/null 2>&1
cd $CONFIGFOLDER/sentinel
virtualenv ./venv >/dev/null 2>&1
./venv/bin/pip install -r requirements.txt >/dev/null 2>&1


mv $CONFIGFOLDER/sentinel/sentinel.conf /root/.sparkscore/sentinel/sentinel.OLD
touch $CONFIGFOLDER/sentinel/sentinel.conf >/dev/null 2>&1
cat << EOF > $CONFIGFOLDER/sentinel/sentinel.conf
# specify path to dash.conf or leave blank
# default is the same as DashCore
#dash_conf=/root/.sparkscore/sparks.conf
sparks_conf=$CONFIGFOLDER/sparks.conf

# valid options are mainnet, testnet (default=mainnet)
network=mainnet
#network=testnet

# database connection details
db_name=database/sentinel.db
db_driver=sqlite

#DrWeez was here

EOF
