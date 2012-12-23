#!/bin/bash
# This script is connected up just to let me know if the host has been restarted.
source /root/scripts/config.sh
CONTENT="$HOSTNAME boot up at "`date`
source /root/scripts/config.sh
for MAILADDR in "${EMAIL_ADDR[@]}"; do
	echo -e "Subject:$CONTENT\n$CONTENT"|sendmail -f $EMAIL_FROM $MAILADDR
done

