#!/bin/bash

#Get docker env timezone and set system timezone
echo "setting the correct local time"
echo $TZ > /etc/timezone
export DEBCONF_NONINTERACTIVE_SEEN=true DEBIAN_FRONTEND=noninteractive
dpkg-reconfigure tzdata
cd /config
if [ ! -z $VERSION ]; then
  echo "Manual version override:" $VERSION
else
  #Check the latest version on appdynamics
  curl -s -L -o tmpout.json "https://download.appdynamics.com/download/downloadfile/?version=&apm=&os=linux&platform_admin_os=linux&events=&eum="
  VERSION=$(grep -oP '(\"version\"\:\")\K(.*?)(?=\"\,\")' tmpout.json)
  DOWNLOAD_PATH=$(grep -oP '(\"download_path\"\:\")\K(.*?)(?=\"\,\")' tmpout.json)
  VERSION=${VERSION:1}
  echo "Latest version on appdynamics is" $VERSION
fi

if [ ! -f /config/appdynamics-"$VERSION"/ ]; then
  echo "Installing version '$VERSION'"
  TOKEN=$(curl -X POST -d '{"username": "$appd-user","password": "appd-pass","scopes": ["download"]}' https://identity.msrv.saas.appdynamics.com/v2.0/oauth/token | grep -oP '(\"access_token\"\:\s\")\K(.*?)(?=\"\,\s\")')
  curl -L -O -H "Authorization: Bearer ${TOKEN}" https://download.appdynamics.com/download/prox/download-file/enterprise-console/4.5.6.17299/platform-setup-x64-linux-4.5.6.17299.sh
  wget ${DOWNLOAD_PATH}
  echo "file downloaded"
else
  echo "Using existing version '$VERSION'"
fi
echo "Setting correct permissions"
chown -R nobody:users /config

ADDPARAM="-Dupnp.config.address=$SERVERIP -Dserver.port=$SERVERPORT"
echo -e "Parameters used:\nServer IP : $SERVERIP\nServer Port : $SERVERPORT"

echo "System Started"