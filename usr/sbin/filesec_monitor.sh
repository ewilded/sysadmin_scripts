#!/bin/bash
# weak files detecting script coded by ewilded
# links
# http://searchsecurity.techtarget.com/tip/Week-43-Permissions-How-world-WRITABLE-are-you
# http://mywiki.wooledge.org/DontReadLinesWithFor

# Add exceptions for NON readable list, so we can combine cases like non world readable /var/lib/mysql with /var/lib/mysql/mysql.sock exception
MAIL_ALERT=yes
MAIL_FROM=ewilded@gmail.com
MAIL_ADDR=(ewilded@gmail.com)
if [ -f /root/scripts/config.sh ]; then
	source /root/scripts/config.sh
	MAIL_ADDR=$EMAIL_ADDR
	MAIL_FROM=$EMAIL_FROM	
fi;
FILESEC_DIRS=(etc lib sbin usr bin dev mnt root var tmp)
#FILESEC_DIRS=(etc sbin tmp)
RKHUNTER_PATH=/usr/bin/rkhunter
SUGID_EXCEPTIONS=/etc/filesec_monitor/perms_monitor_sugid_exceptions
SUGID_EXCEPTIONS_CUSTOM=/etc/filesec_monitor/perms_monitor_sugid_exceptions_custom
WORLD_WRITABLE_EXCEPTIONS=/etc/filesec_monitor/perms_monitor_world_writable_exceptions
WORLD_WRITABLE_EXCEPTIONS_CUSTOM=/etc/filesec_monitor/perms_monitor_world_writable_exceptions_custom
NON_READABLE=/etc/filesec_monitor/perms_monitor_non_readable
NON_READABLE_CUSTOM=/etc/filesec_monitor/perms_monitor_non_readable_custom
RKHUNTER_WARNING_EXCEPTIONS=/etc/filesec_monitor/rkhunter_filesec_exceptions
## to avoid issues with PATH while running from cron:
export PATH='/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin'
HOSTNAME=`hostname`
HOSTNAME=`echo -n "$HOSTNAME "; uname -a`
ERROR_LOG="/var/log/filesec_mon"
## SUID/SGID
FILESEC_DIRS_CNT=${#FILESEC_DIRS[*]}
function file_checks_fsecmon()
{
	i=0
	while [ ${i} -lt ${FILESEC_DIRS_CNT} ];
	do
	 DIR=${FILESEC_DIRS[${i}]}
	 i=$[$i+1]
	 echo "Checking directory $DIR..."
	 
	 find /$DIR -type f \( -perm -4000 -o -perm -2000 \)|while IFS= read -r file; do
	 	 FILE_OK=NO
		while IFS= read -r exception; do
			echo $exception|egrep '^$'
			if [ "$?" == "0" ]; then
				continue
			fi;				
			IS_SUBPATH=`echo "$file"|egrep ^$exception`
	 		if [[ "$file" == "$exception" || -n $IS_SUBPATH ]]; then
				 FILE_OK="YES"
				#echo "Found $file as an exception ($exception) from suid/sgid!"
				break
			fi;
		 done < <(cat $SUGID_EXCEPTIONS $SUGID_EXCEPTIONS_CUSTOM)
		 if [ "$FILE_OK" == "NO" ]; then
		 	 echo "$file has SUID/SGID attribute on.">>$ERROR_LOG
			 echo "[SUIG/SGID] $file"
		 fi;
	 done;
	## WORLD WRITABLE
	 while IFS= read -r file; do
	 	  FILE_OK=NO	
		 # echo "Checking $file..."
	 	  while IFS= read -r exception; do
				echo $exception|egrep '^$'
	                        if [ "$?" == "0" ]; then
                                	continue
                       	   	fi;
				IS_SUBPATH=`echo "$file"|egrep ^$exception`
				if [[ "$file" == "$exception" || -n $IS_SUBPATH ]]; then
					 FILE_OK="YES"
				#	 echo "Found $file as the exception ($exception or $IS_SUBPATH) from writables! (FILE_OK=$FILE_OK)"
					 break
			 	fi;
		 	done < <(cat $WORLD_WRITABLE_EXCEPTIONS $WORLD_WRITABLE_EXCEPTIONS_CUSTOM)
		   if [ "$FILE_OK" == "NO" ]; then
					#echo "$file not ok! ERROR_LOG: $ERROR_LOG (FILE_OK=$FILE_OK)"
					echo "[WRITABLE] $file"
					owner=`ls -l $file | awk '//{print $3}'|head -n 1`
			 		if [ -d $file ]; then
						owner=`ls -al $file | awk '//{print $3}'|head -n 2|tail -n +2`
		 			fi;
		 	   		echo "$file (owned by $owner) is world writable.">>$ERROR_LOG
		 	fi;
	 done < <(find /$DIR -perm -2 ! -type l)
	 
	done;
	## NON READABLE FILES (and FILESEC_DIRS) - this should also include non executable files/FILESEC_DIRS
	## if the path is a directory - all files under it also are required to be nonreadable
	while IFS= read -r file; do ## /dev/kmem, /etc/shadow, /etc/shadow- for instance
		if [[ -f "$file" || -d "$file" ]]; then
			find "$file" -perm -o=r ! \( -type d -perm -o=t \) ! -type l|while IFS= read -r result; do
					echo "$result is world readable.">>$ERROR_LOG
					echo "[READABLE] $result"
			done;
		fi;
	done < <(cat $NON_READABLE $NON_READABLE_CUSTOM)
}
function rkhunter_fsecmon()
{
	## RKHUNTER CHECKS
	echo "rkhunter --cronjob --report-warnings-only -q"
	$RKHUNTER_PATH --cronjob --report-warnings-only -q
	echo "Done."
	RKHUNTER_LOG=/var/log/rkhunter.log
	if [ ! -f $RKHUNTER_LOG ]; then
		RKHUNTER_LOG=/var/log/rkhunter/rkhunter.log
	fi;
	if [ ! -f $RKHUNTER_LOG ]; then
		echo "[ERROR] no rkhunter.log was found!">>$ERROR_LOG
	else
		while IFS= read -r RKHUNTER_WARNING; do
			WARNING_OK=NO
			RKHUNTER_WARNING=`echo $RKHUNTER_WARNING|cut -b 12-`
			while IFS= read -r RKHUNTER_EXCEPTION; do
				#echo "Comparing $RKHUNTER_EXCEPTION with $RKHUNTER_WARNING"
					if [ "$RKHUNTER_EXCEPTION" == "$RKHUNTER_WARNING" ]; then
					WARNING_OK=YES
					#echo "$RKHUNTER_EXCEPTION is ok!!!!!!!!!!!!!!!!!!!"
					break
				fi;
			done < <(cat $RKHUNTER_WARNING_EXCEPTIONS)
			if [ "$WARNING_OK" == "NO" ]; then
				 echo "[RKHUNTER] $RKHUNTER_WARNING">>$ERROR_LOG
			fi;
		done < <(egrep 'Warning|possible' $RKHUNTER_LOG)
	fi;	
}

### MAIN
rm -rf $ERROR_LOG
touch $ERROR_LOG
chmod 600 $ERROR_LOG
file_checks_fsecmon
rkhunter_fsecmon

## if logfile is not empty
if [ -s "$ERROR_LOG" ]; then
	echo -e "\n\n[FILESEC MON] $HOSTNAME: Following security violations have been found on this system:\n"
	cat $ERROR_LOG
	if [ "$MAIL_ALERT" == "yes" ]; then
		echo -e "Subject:$HOSTNAME weak permissions alert\n">>/var/log/filesec_mon.mail
		cat $ERROR_LOG>>/var/log/filesec_mon.mail
		for MAILADDR in "${MAIL_ADDR[@]}"; do
			sendmail -f $MAIL_FROM $MAILADDR < /var/log/filesec_mon.mail
		done;
		rm -rf /var/log/filesec_mon.mail
	fi;
else
	echo "No problems found."
fi;