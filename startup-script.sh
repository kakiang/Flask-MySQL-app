#!/bin/bash
sudo apt-get update
# Install Stackdriver logging agent
curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh
sudo bash install-logging-agent.sh

# Install or update needed software
sudo apt-get update
sudo apt-get install -yq git python python-pip
pip install --upgrade pip virtualenv

sudo cat > /etc/apt/sources.list.d/mysql.list <<EOF
# Use command 'dpkg-reconfigure mysql-apt-config' as root for modifications.
deb http://repo.mysql.com/apt/debian/ stretch mysql-apt-config
deb http://repo.mysql.com/apt/debian/ stretch mysql-5.7
deb http://repo.mysql.com/apt/debian/ stretch mysql-tools
#deb http://repo.mysql.com/apt/debian/ stretch mysql-tools-preview
deb-src http://repo.mysql.com/apt/debian/ stretch mysql-5.7
EOF

sudo apt-get install debconf-utils
# echo "mysql-apt-config mysql-apt-config/select-preview select Disabled" | sudo debconf-set-selections
# echo "mysql-apt-config mysql-apt-config/repo-codename select xenial" | sudo debconf-set-selections
# echo "mysql-apt-config mysql-apt-config/select-product select Ok" | sudo debconf-set-selections
# echo "mysql-apt-config mysql-apt-config/repo-distro select ubuntu" | sudo debconf-set-selections
# echo "mysql-apt-config mysql-apt-config/tools-component string mysql-tools" | sudo debconf-set-selections
# echo "mysql-apt-config mysql-apt-config/unsupported-platform select ubuntu xenial" | sudo debconf-set-selections
# echo "mysql-apt-config mysql-apt-config/preview-component string" | sudo debconf-set-selections
# echo "mysql-apt-config mysql-apt-config/select-server select mysql-5.7" | sudo debconf-set-selections
# echo "mysql-apt-config mysql-apt-config/select-tools select Enabled" | sudo debconf-set-selections
# echo "mysql-apt-config mysql-apt-config/repo-url string http://repo.mysql.com/apt" | sudo debconf-set-selections
# echo "mysql-apt-config mysql-apt-config/dmr-warning note" | sudo debconf-set-selections
echo "mysql-community-server mysql-community-server/root-pass password rootpassword" | sudo debconf-set-selections
echo "mysql-community-server mysql-community-server/re-root-pass password rootpassword" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password rootpassword" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password password rootpassword" | sudo debconf-set-selections
echo "mysql-server-5.7 mysql-server/root_password password rootpassword" | sudo debconf-set-selections
echo "mysql-server-5.7 mysql-server/root_password_again password rootpassword" | sudo debconf-set-selections

# export DEBIAN_FRONTEND=noninteractive
# wget https://dev.mysql.com/get/mysql-apt-config_0.8.14-1_all.deb
# sudo dpkg -i mysql-apt-config_0.8.14-1_all.deb
sudo apt-get update
sudo apt-get install -y --allow-unauthenticated mysql-community-server

# download sakila schema and data 
wget https://downloads.mysql.com/docs/sakila-db.tar.gz -O /tmp/sakila-db.tar.gz
# unzip
tar -zxvf /tmp/sakila-db.tar.gz
# create database schema
mysql -uroot -prootpassword -e "SOURCE sakila-db/sakila-schema.sql;"
# populate the database with data
mysql -uroot -prootpassword -e "SOURCE sakila-db/sakila-data.sql;"

# Fetch source code
git clone https://github.com/kakiang/sakila-flask-app.git /opt/apps/sakila-flask-app

# Python environment setup
virtualenv -p python3 /opt/apps/sakila-flask-app/env
source /opt/apps/sakila-flask-app/env/bin/activate
/opt/apps/sakila-flask-app/env/bin/pip install -r /opt/apps/sakila-flask-app/requirements.txt

sudo sed -i 's/127\.0\.0\.1/0\.0\.0\.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf
mysql -uroot -prootpassword -e 'USE mysql; UPDATE `user` SET `Host`="%" WHERE `User`="root" AND `Host`="localhost"; DELETE FROM `user` WHERE `Host` != "%" AND `User`="root"; FLUSH PRIVILEGES;'

sudo service mysql restart
# set env vars to run flask
export FLASK_APP=/opt/apps/sakila-flask-app/run.py
export FLASK_DEBUG=1
# run flask
flask run --host=0.0.0.0 --port=80
# ~/.local/bin/gunicorn -b 0.0.0.0:5000 /opt/apps/sakila-flask-app/run:app
