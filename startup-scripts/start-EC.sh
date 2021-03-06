#!/bin/bash

PA_FILE=$APPD_INSTALL_DIR/appdynamics/enterprise-console/platform-admin/bin/platform-admin.sh
if [ -f "$PA_FILE" ]; then
	echo "Starting Enterprise Console"
	cd $APPD_INSTALL_DIR/appdynamics/enterprise-console/platform-admin/bin/
	./platform-admin.sh login --user-name admin --password appd
	./platform-admin.sh start-platform-admin
else
	echo "Platform Admin not found here - $PA_FILE"
fi
