#!/bin/bash

# initialize variables
MACHINE_AGENT_HOME=$APPD_INSTALL_DIR/appdynamics/machine-agent
cd $MACHINE_AGENT_HOME

if [ -z $CONTROLLER_HOST ]; then
	CONTROLLER_HOST=$HOSTNAME
fi
if [ -z $CONTROLLER_PORT ]; then
	CONTROLLER_PORT="8090"
fi
if [ -z $EVENTS_SERVICE_HOST ]; then 
	EVENTS_SERVICE_HOST=$CONTROLLER_HOST
fi
if [ -z $EVENTS_SERVICE_PORT ]; then
	EVENTS_SERVICE_PORT="9080"
fi
if [ -z $CONTROLLER_KEY ]; then
	# Connect to Controller and obtain the AccessKey
	curl -s -c cookie.appd --user admin@customer1:appd -X GET http://$CONTROLLER_HOST:$CONTROLLER_PORT/controller/auth?action=login
	if [ -f "cookie.appd" ]; then
		X_CSRF_TOKEN="$(grep X-CSRF-TOKEN cookie.appd | grep -oP '(X-CSRF-TOKEN\s)\K(.*)?(?=$)')"
		JSESSIONID_H=$(grep -oP '(JSESSIONID\s)\K(.*)?(?=$)' cookie.appd)
		CONTROLLER_KEY=$(curl -s http://$CONTROLLER_HOST:$CONTROLLER_PORT/controller/restui/user/account -H "X-CSRF-TOKEN: $X_CSRF_TOKEN" -H "Cookie: JSESSIONID=$JSESSIONID_H" | grep -oP '(?:accessKey\"\s\:\s\")\K(.*?)(?=\"\,)')
		rm cookie.appd
	fi
fi
if [ -z $GLOBAL_ACCOUNT_NAME ]; then
	# Connect to Controller and obtain the AccessKey
	curl -s -c cookie.appd --user admin@customer1:appd -X GET http://$CONTROLLER_HOST:$CONTROLLER_PORT/controller/auth?action=login
	if [ -f "cookie.appd" ]; then
		X_CSRF_TOKEN="$(grep X-CSRF-TOKEN cookie.appd | grep -oP '(X-CSRF-TOKEN\s)\K(.*)?(?=$)')"
		JSESSIONID_H=$(grep -oP '(JSESSIONID\s)\K(.*)?(?=$)' cookie.appd)
		GLOBAL_ACCOUNT_NAME=$(curl -s http://$CONTROLLER_HOST:$CONTROLLER_PORT/controller/restui/user/account -H "X-CSRF-TOKEN: $X_CSRF_TOKEN" -H "Cookie: JSESSIONID=$JSESSIONID_H" | grep -oP '(?:globalAccountName\"\s\:\s\")\K(.*?)(?=\"\,)')
		rm cookie.appd
	fi
fi


AA_FILE=$MACHINE_AGENT_HOME/monitors/analytics-agent/conf/analytics-agent.properties
if [ ! -z $GLOBAL_ACCOUNT_NAME ]; then
	if [ -f "$AA_FILE" ]; then
		echo "Setting analytics-agent.properties"
		sed -i s,http.event.endpoint=.*,http.event.endpoint=http://$EVENTS_SERVICE_HOST:$EVENTS_SERVICE_PORT, $AA_FILE
		sed -i s,ad.controller.url=.*,ad.controller.url=http://$CONTROLLER_HOST:$CONTROLLER_PORT, $AA_FILE
		sed -i s,http.event.accountName=.*,http.event.accountName=$GLOBAL_ACCOUNT_NAME, $AA_FILE
		sed -i s,http.event.accessKey=.*,http.event.accessKey=$CONTROLLER_KEY, $AA_FILE
	else
		echo "Analytics Agent File not found here - $AA_FILE"
	fi 
	MONITOR_FILE=$MACHINE_AGENT_HOME/monitors/analytics-agent/monitor.xml
	if [ -f "$MONITOR_FILE" ]; then
		sed -i 's,<enabled>false</enabled>.*,<enabled>true</enabled>,' $MONITOR_FILE
	else
		echo "Analytics Monitor File not found here - $MONITOR_FILE"
	fi 
fi

PID_FILE=$MACHINE_AGENT_HOME/monitors/analytics-agent/analytics-agent.id
# remove pid file if exists
if [ -f "$PID_FILE" ]; then
	echo "removing PID File ${PID_FILE}"
	rm $PID_FILE
fi 