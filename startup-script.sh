#!/bin/bash

# Install Stackdriver logging agent
curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh
sudo bash install-logging-agent.sh

# Install or update needed software
sudo apt-get update
sudo apt-get install -yq git python3 python3-pip
pip3 install --upgrade pip virtualenv

# Download the MySQL GPG Public key
sudo apt install dirmngr
sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 5072E1F5

# write into mysql.list repository entries for mysql
sudo cat > /etc/apt/sources.list.d/mysql.list <<EOF
deb http://repo.mysql.com/apt/debian/ stretch mysql-5.7
deb http://repo.mysql.com/apt/debian/ stretch mysql-tools
#deb http://repo.mysql.com/apt/debian/ stretch mysql-tools-preview
deb-src http://repo.mysql.com/apt/debian/ stretch mysql-5.7
EOF

# update packages
sudo apt-get update

# Install debconf-utils to set debconf variable
sudo apt-get install debconf-utils

# set the root password for the server installation
echo "mysql-community-server mysql-community-server/root-pass password rootpassword" | sudo debconf-set-selections
echo "mysql-community-server mysql-community-server/re-root-pass password rootpassword" | sudo debconf-set-selections

# set the env var DEBIAN_FRONTEND to noninteractive then install MySQL noninteractively (no prompt)
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-server

# download sakila schema and data 
wget https://downloads.mysql.com/docs/sakila-db.tar.gz -O /tmp/sakila-db.tar.gz
# unzip
tar -zxvf /tmp/sakila-db.tar.gz
# create database schema
mysql -uroot -prootpassword -e "SOURCE sakila-db/sakila-schema.sql;"
# populate the database with data
mysql -uroot -prootpassword -e "SOURCE sakila-db/sakila-data.sql;"

APP_DIR=/usr/src/sakila-flask-app
# Fetch sakila-flask-app source code
git clone https://github.com/kakiang/sakila-flask-app.git $APP_DIR

# Python environment setup
virtualenv -p python3 $APP_DIR/env
source $APP_DIR/env/bin/activate
$APP_DIR/env/bin/pip install -r $APP_DIR/requirements.txt

# set env vars to run flask
export FLASK_APP=$APP_DIR/run.py
export FLASK_DEBUG=1
# run flask
flask run --host=0.0.0.0 --port=80
