#!/bin/bash
# diskspsce monitor coded by ewilded
# configure here (space separated list of device:maximum_safe_use_percentage)
source /root/scripts/config.sh
for DEV in "${DEVICES[@]}";     do
        DEVNAME=`echo $DEV|perl -e 'my @str=split(/:/,<STDIN>); print $str[0];'`
        MAXIMUM_ALLOWED_PERCENTAGE=`echo $DEV|perl -e 'my @str=split(/:/,<STDIN>); print $str[1];'`
        USAGE=`df -P -h  | grep $DEVNAME | awk '//{print $5}'|sed s/%//`
        if [ "$USAGE" -gt "$MAXIMUM_ALLOWED_PERCENTAGE" ]; then
                  CONTENT="WARNING $HOSTNAME diskspace on $DEVNAME is $USAGE% full (safe limit is set to $MAXIMUM_ALLOWED_PERCENTAGE)!"
		  for MAILADDR in "${EMAIL_ADDR[@]}"; do
	                  echo -e "Subject:$CONTENT\n$CONTENT"|sendmail -f $EMAIL_FROM $MAILADDR
		  done;
        fi;
done
