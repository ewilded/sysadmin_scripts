#!/bin/bash
source /etc/sysadmin_scripts/config.sh
yum -yq upgrade
if [ "$REBOOT_AFTER_UPGRADE" == "YES" ]; then
	init 6
else
	ERROR_LOG=""
	for SERVICE in `chkconfig --list --level 5 | awk '//{if($7=="5:on") {print $1}}'`; do
		STATUS=`service $SERVICE status|grep running`
		if [ -n "$STATUS" ]; then
			service $SERVICE restart 
			STATUSNEW=`service $SERVICE status|grep running`
			if [ "$STATUSNEW" == "" ]; then
				ERROR_LOG="$ERROR_LOG$SERVICE failed to start after upgrade!\n"
			fi;
		fi;
	done;
	if [ "$ERROR_LOG" != "" ]; then
		for MAILADDR in "${EMAIL_ADDR[@]}"; do
			echo -e "Subject:$HOSTNAME autoupdate error report.\n$ERROR_LOG"|sendmail -f $EMAIL_FROM $MAILADDR
		done;
	fi;
fi;
