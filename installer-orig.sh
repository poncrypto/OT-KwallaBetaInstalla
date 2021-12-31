#!/bin/bash

OS_VERSION=$(lsb_release -sr)
INSTALLER_NAME="OT-KwallaBetaInstalla"
GRAPHDB_FILE="/root/graphdb-free-9.10.1-dist.zip"
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
#echo -e "${GREEN}ALREADY STOPPED${NC}"

echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
echo -e "${GREEN}Checking that the OS is Ubuntu 20.04 ONLY${NC}"
echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
if [[ $OS_VERSION != 20.04 ]]; then
    echo "$INSTALLER_NAME requires Ubuntu 20.04. Destroy this VPS and remake using Ubuntu 20.04."
    exit 1
fi

echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
echo -e "${GREEN}Checking that the GraphDB file is present in /root${NC}"
echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
if [[ ! -f $GRAPHDB_FILE ]]; then
    echo -e "${RED}The graphdb file needs to be downloaded to /root. Please create an account at https://www.ontotext.com/products/graphdb/graphdb-free/ and click the standalone version link in the email.${NC}"
    exit 1
fi

cd

echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
echo -e "${GREEN}Checking to make sure we are in /root directory${NC}"
echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
CURRENT_DIR=$(pwd)
if [[ $CURRENT_DIR != /root ]]; then
    echo -e "${RED}You need to be root to install the beta. Please login as root and rerun the installer.${NC}"
    exit 1
fi

apt update && apt upgrade -y

echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
echo -e "${GREEN}Installing default-jre${NC}"
echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
apt install default-jre unzip jq -y

if [[ $? -eq 1 ]]; then
    echo -e "${RED}There was an error installing default-jre.${NC}"
    exit 1
fi

echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
echo -e "${GREEN}Unzipping GraphDB${NC}"
echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
unzip $GRAPHDB_FILE

echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
echo -e "${GREEN}Starting the GraphDB${NC}"
echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
nohup /root/graphdb-free-9.10.1/bin/graphdb &

GRAPH_STARTED=$(cat nohup.out | grep 'Started GraphDB' | wc -l)

if [[$GRAPH_STARTED ! -eq 1 ]]; then
    echo -e "${RED}There was a problem starting the GraphDB. Exiting.${NC}"
    exit 1
fi

echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
echo -e "${GREEN}Downloading and setting up Node.js v14${NC}"
echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
curl -sL https://deb.nodesource.com/setup_14.x -o setup_14.sh
if [[ $? -eq 1 ]]; then
    echo -e "${RED}There was an error installing nodejs setup.${NC}"
    exit 1
fi

sh ./setup_14.sh

echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
echo -e "${GREEN}Installing aptitude${NC}"
echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
apt update && apt install aptitude -y
if [[ $? -eq 1 ]]; then
    echo -e "${RED}There was an error installing aptitude.${NC}"
    exit 1
fi

echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
echo -e "${GREEN}Installing nodejs and npm${NC}"
echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
aptitude install nodejs npm -y
if [[ $? -eq 1 ]]; then
    echo -e "${RED}There was an error installing nodejs/npm.${NC}"
    exit 1
fi

echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
echo -e "${GREEN}Installing forever${NC}"
echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
npm install forever -g

echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
echo -e "${GREEN}Installing tcllib and mysql-server${NC}"
echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
apt install tcllib mysql-server -y

echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
echo -e "${GREEN}Creating a local operational database${NC}"
echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
mysql -u root  -e "CREATE DATABASE operationaldb /*\!40100 DEFAULT CHARACTER SET utf8 */;"
mysql -u root -e "update mysql.user set plugin = 'mysql_native_password' where User='root';"
mysql -u root -e "flush privileges;"

echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
echo -e "${GREEN}Commenting out max_binlog_size${NC}"
echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
sed -i 's|max_binlog_size|#max_binlog_size|' /etc/mysql/mysql.conf.d/mysqld.cnf

echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
echo -e "${GREEN}Disabling binary logs${NC}"
echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
echo "disable_log_bin" >> /etc/mysql/mysql.conf.d/mysqld.cnf

echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
echo -e "${GREEN}Restarting mysql${NC}"
echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
systemctl restart mysql

echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
echo -e "${GREEN}Installing git and cloning the v6 beta repo${NC}"
echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
apt install git -y

git clone https://github.com/OriginTrail/ot-node
cd ot-node
git checkout v6/release/testnet

npm install

echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
echo -e "${GREEN}Opening firewall ports 22, 8900,9000 and enabling firewall${NC}"
echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
ufw allow 22/tcp && ufw allow 8900 && ufw allow 9000 && yes | ufw enable

echo "NODE_ENV=testnet" > .env

echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
echo -e "${GREEN}Creating default noderc config${NC}"
echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"

read -p "Enter the operational wallet address: " NODE_WALLET
echo "Node wallet: $NODE_WALLET"

read -p "Enter the private key: " NODE_PRIVATE_KEY
echo "Node wallet: $NODE_PRIVATE_KEY"

cp .origintrail_noderc_example .origintrail_noderc

jq --arg newval "$NODE_WALLET" '.blockchain[].publicKey |= $newval' .origintrail_noderc >> origintrail_noderc_temp
mv origintrail_noderc_temp .origintrail_noderc

jq --arg newval "$NODE_PRIVATE_KEY" '.blockchain[].privateKey |= $newval' .origintrail_noderc >> origintrail_noderc_temp
mv origintrail_noderc_temp .origintrail_noderc

echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
echo -e "${GREEN}Running DB migrations${NC}"
echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
npx sequelize --config=./config/sequelizeConfig.js db:migrate

echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
echo -e "${GREEN}Starting the node${NC}"
echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
forever start -a -o out.log -e out.log index.js

echo "*****************************************************"
echo "*****************************************************"
echo "*****************************************************"
echo -e "${GREEN}Logs will be displayed. Press ctrl+c to exit the logs. The node WILL stay running after you return to the command prompt.${NC}"
echo " "
read -p "Press enter to continue..."

tail -f -n100 out.log

