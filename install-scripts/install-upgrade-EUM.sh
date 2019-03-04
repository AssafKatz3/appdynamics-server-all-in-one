#!/bin/bash

# check if EUM Server is installed
if [ -f /config/appdynamics/EUM/eum-processor/bin/eum.sh ]; then
  INSTALLED_VERSION=$(grep -oP '(Monitoring\s)\K(.*?)(?=$)' /config/appdynamics/EUM/.install4j/response.varfile)
  echo "EUM Server: $INSTALLED_VERSION is installed"
  # check for upgrade <code to be inserted>, however upgrade path needs to be followed EC > ES > EUM > Controller
else
  # Check latest EUM server version on AppDynamics
  cd /config
  echo "Checking EUM server version"
  curl -s -L -o tmpout.json "https://download.appdynamics.com/download/downloadfile/?version=&apm=&os=linux&platform_admin_os=&events=&eum=linux"
  EUMDOWNLOAD_PATH=$(grep -oP '(?:\"download_path\"\:\")(?!.*dmg)\K(.*?)(?=\"\,\")' tmpout.json)
  EUMFILENAME=$(grep -oP '(?:\"filename\"\:\")(?!.*dmg)\K(.*?)(?=\"\,\")' tmpout.json)
  rm -f tmpout.json
  # check if user downloaded latest EUM server binary
  if [ -f /config/$EUMFILENAME ]; then
    echo "Found latest EUM Server '$EUMFILENAME' in /config/ "
  else
    echo "Didn't find '$EUMFILENAME' in /config/ - downloading"
    NEWTOKEN=$(curl -X POST -d '{"username": "'$AppdUser'","password": "'$AppdPass'","scopes": ["download"]}' https://identity.msrv.saas.appdynamics.com/v2.0/oauth/token | grep -oP '(\"access_token\"\:\s\")\K(.*?)(?=\"\,\s\")')
    curl -L -O -H "Authorization: Bearer ${NEWTOKEN}" ${EUMDOWNLOAD_PATH}
    echo "file downloaded"
  fi
  chmod +x ./$EUMFILENAME
  
  echo "Installing EUM server"
  VARFILE=/your-platform-install/install-scripts/response-eum.varfile
  if [ -f "$VARFILE" ];then 
    ./$EUMFILENAME -q -varfile $VARFILE
    # assuming install went fine
    rm -f ./$EUMFILENAME
  else
    echo "Couldn't find $VARFILE"
  fi
  
  EUM_POST_CONF_FILE=/your-platform-install/install-scripts/post-install-EUM-Config.sh
  if [ -f "$EUM_POST_CONF_FILE" ]; then
	chmod +x $EUM_POST_CONF_FILE
	sh $EUM_POST_CONF_FILE
  else
	echo "EUM Server post-config file not found here - $EUM_POST_CONF_FILE"
  fi
fi