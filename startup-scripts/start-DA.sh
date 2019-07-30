#!/bin/bash

# initialize variables
DATABASE_AGENT_HOME=/config/appdynamics/database-agent
if [ -z $CONTROLLER_HOST ]; then
	CONTROLLER_HOST="localhost"
fi
if [ -z $CONTROLLER_PORT ]; then
	CONTROLLER_PORT="8090"
fi
if [ -z $CONTROLLER_KEY ]; then
	# Connect to Controller and obtain the AccessKey
	curl -s -c cookie.appd --user admin@customer1:appd -X GET http://$CONTROLLER_HOST:$CONTROLLER_PORT/controller/auth?action=login
	X_CSRF_TOKEN="$(grep X-CSRF-TOKEN cookie.appd | grep -oP '(X-CSRF-TOKEN\s)\K(.*)?(?=$)')"
	JSESSIONID_H=$(grep -oP '(JSESSIONID\s)\K(.*)?(?=$)' cookie.appd)
	CONTROLLER_KEY=$(curl http://$CONTROLLER_HOST:$CONTROLLER_PORT/controller/restui/user/account -H "X-CSRF-TOKEN: $X_CSRF_TOKEN" -H "Cookie: JSESSIONID=$JSESSIONID_H" | grep -oP '(?:accessKey\"\s\:\s\")\K(.*?)(?=\"\,)')
	rm cookie.appd
fi

if [ -z $ENABLE_CONTAINERIDASHOSTID ]; then
	ENABLE_CONTAINERIDASHOSTID="false"
fi
DA_PROPERTIES="-Dappdynamics.controller.hostName=${CONTROLLER_HOST}"
DA_PROPERTIES="$DA_PROPERTIES -Dappdynamics.controller.port=${CONTROLLER_PORT}"
#DA_PROPERTIES="$DA_PROPERTIES -Dappdynamics.agent.accountName=${ACCOUNT_NAME}"
DA_PROPERTIES="$DA_PROPERTIES -Dappdynamics.agent.accountAccessKey=${CONTROLLER_KEY}"
#DA_PROPERTIES="$DA_PROPERTIES -Dappdynamics.controller.ssl.enabled=${CONTROLLER_SSL_ENABLED}"
DA_PROPERTIES="$DA_PROPERTIES -Dappdynamics.docker.container.containerIdAsHostId.enabled=${ENABLE_CONTAINERIDASHOSTID}"

DA_FILE=/config/appdynamics/database-agent/bin/database-agent
if [ -f "$DA_FILE" ]; then
	echo "Starting Database Agent"
	# Start Database Agent
	echo java ${DA_PROPERTIES} -jar ${DATABASE_AGENT_HOME}/databaseagent.jar
	java ${DA_PROPERTIES} -jar ${DATABASE_AGENT_HOME}/databaseagent.jar
else
	echo "Database Agent File not found here - $DA_FILE"
fi