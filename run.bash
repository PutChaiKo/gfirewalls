#!/bin/bash

# run in root
if [ "$(id -u)" != "0" ]; then
   echo "this script must be run as root or sudo permissions" 1>&2
   exit 1
fi

# check ufw
if command -v ufw >/dev/null 2>&1; then 
  echo 'run ufw enable'
  ufw enable
else 
  echo 'ufw no exists, maybe you can install ufw like this: sudo apt install ufw'
  exit 1
fi

# check java
if command -v /usr/bin/java >/dev/null 2>&1; then 
  echo 'run java -version, gfirewalls need java 11 in /usr/bin/java'
  /usr/bin/java -version
else 
  echo '/usr/bin/java no exists, please install java 11 to /usr/bin/java'
  exit 1
fi

read -p "select gfirewalls potr (1000-9999): " PORT
until
[ $PORT -gt 999 -a $PORT -lt 10000 ]
do
read -p "$PORT value error, please enter number between 1000 to 9999: " PORT
done

# gfirewalls dir
DIR_NAME=/root/.gfirewalls
if [ ! -d $DIR_NAME  ];then
  mkdir $DIR_NAME
else
  echo gfirewalls dir exist
fi
echo "the gfirewalls dir is $DIR_NAME"

NOW=`date +'%Y%m%d_%H-%M-%S'`

# backup user.rules 
cp /etc/ufw/user.rules $DIR_NAME/user.rules.$NOW.backup
cp /etc/ufw/user6.rules $DIR_NAME/user.user6.$NOW.backup

NAME=gfirewalls
SERVICE_NAME=$NAME.service
# stop running
systemctl stop $SERVICE_NAME

cp ./target/gfirewalls.jar $DIR_NAME
START_COMMAND="/usr/bin/java -jar $DIR_NAME/gfirewalls.jar --server.port=$PORT"

SER_STR="[Unit]
Description=$NAME Server Service
After=network.target

[Service]
Type=simple
User=root
RuntimeMaxSec=86400
Restart=on-failure
RestartSec=5s
ExecStart=$START_COMMAND

[Install]
WantedBy=multi-user.target"

printf '%s\n' "$SER_STR" > /etc/systemd/system/$SERVICE_NAME

systemctl daemon-reload
systemctl start $SERVICE_NAME
systemctl enable $SERVICE_NAME
systemctl status $SERVICE_NAME