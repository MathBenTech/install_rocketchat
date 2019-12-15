#!/usr/bin/env bash

sudo apt-get -y update
sudo apt-get install -y dirmngr && sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
echo "deb http://repo.mongodb.org/apt/debian stretch/mongodb-org/4.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list

sudo apt-get -y update && sudo apt-get install -y curl && curl -sL https://deb.nodesource.com/setup_8.x | sudo bash -
sudo apt-get install -y build-essential mongodb-org nodejs graphicsmagick
sudo npm install -g inherits n && sudo n 8.11.4

curl -L https://releases.rocket.chat/latest/download -o /tmp/rocket.chat.tgz
tar -xzf /tmp/rocket.chat.tgz -C /tmp
cd /tmp/bundle/programs/server && npm install
sudo mv /tmp/bundle /opt/Rocket.Chat

sudo useradd -M rocketchat && sudo usermod -L rocketchat
sudo chown -R rocketchat:rocketchat /opt/Rocket.Chat

cat << EOF |sudo tee -a /lib/systemd/system/rocketchat.service
[Unit]
Description=The Rocket.Chat server
After=network.target remote-fs.target nss-lookup.target nginx.target mongod.target
[Service]
ExecStart=/usr/local/bin/node /opt/Rocket.Chat/main.js
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=rocketchat
User=rocketchat
Environment=MONGO_URL=mongodb://localhost:27017/rocketchat?replicaSet=rs01 MONGO_OPLOG_URL=mongodb://localhost:27017/local?replicaSet=rs01 ROOT_URL=http://localhost:3000/ PORT=3000
[Install]
WantedBy=multi-user.target
EOF

sudo sed -i "s/^#  engine:/  engine: mmapv1/"  /etc/mongod.conf
sudo sed -i "s/^#replication:/replication:\n  replSetName: rs01/" /etc/mongod.conf
sudo systemctl enable mongod && sudo systemctl start mongod
mongo --eval "printjson(rs.initiate())"
sudo systemctl enable rocketchat && sudo systemctl start rocketchat

sleep 5
sudo systemctl restart rocketchat

