#!/bin/bash
# weak files detecting script coded by ewilded
# links
# http://searchsecurity.techtarget.com/tip/Week-43-Permissions-How-world-WRITABLE-are-you
# http://mywiki.wooledge.org/DontReadLinesWithFor

# Add exceptions for NON readable list, so we can combine cases like non world readable /var/lib/mysql with /var/lib/mysql/mysql.sock exception
MAIL_ALERT=yes
MAIL_FROM=ewilded@gmail.com
MAIL_ADDR=(ewilded@gmail.com)
if [ -f /etc/sysadmin_scripts/config.sh ]; then
	source /etc/sysadmin_scripts/config.sh
	MAIL_ADDR=$EMAIL_ADDR
	MAIL_FROM=$EMAIL_FROM	
fi;
FILESEC_DIRS=(etc lib sbin usr bin dev mnt root var tmp)
#FILESEC_DIRS=(etc sbin tmp)
RKHUNTER_PATH=/usr/bin/rkhunter
SUGID_EXCEPTIONS=/etc/sysadmin_scripts/filesec_monitor/perms_monitor_sugid_exceptions
SUGID_EXCEPTIONS_CUSTOM=/etc/sysadmin_scripts/filesec_monitor/perms_monitor_sugid_exceptions_custom
WORLD_WRITABLE_EXCEPTIONS=/etc/sysadmin_scripts/filesec_monitor/perms_monitor_world_writable_exceptions
WORLD_WRITABLE_EXCEPTIONS_CUSTOM=/etc/sysadmin_scripts/filesec_monitor/perms_monitor_world_writable_exceptions_custom
NON_READABLE=/etc/sysadmin_scripts/filesec_monitor/perms_monitor_non_readable
NON_READABLE_CUSTOM=/etc/sysadmin_scripts/filesec_monitor/perms_monitor_non_readable_custom
RKHUNTER_WARNING_EXCEPTIONS=/etc/sysadmin_scripts/filesec_monitor/rkhunter_filesec_exceptions
RKHUNTER_WARNING_EXCEPTIONS_CUSTOM=/etc/sysadmin_scripts/filesec_monitor/rkhunter_filesec_exceptions_custom
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
	 FOUND=0
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
		 	 if [ "$FOUND" == "0" ]; then
		 	 	echo "[SUID/SGID] The following files have SUID/SGID attributes on:">>$ERROR_LOG
		 	 	FOUND=1
		 	 fi;
		 	 echo "$file">>$ERROR_LOG
			 echo "$file"
		 fi;
	 done;
	## WORLD WRITABLE
	FOUND=0
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
					if [ "$FOUND" == "0" ]; then
						echo "[WRITABLE] Following files are world writable (owner path):">>$ERROR_LOG
						FOUND=1
					fi;
					echo "$file"
					owner=`ls -l $file | awk '//{print $3}'|head -n 1`
			 		if [ -d $file ]; then
						owner=`ls -al $file | awk '//{print $3}'|head -n 2|tail -n +2`
		 			fi;
		 	   		echo "$owner $file">>$ERROR_LOG
		 	fi;
	 done < <(find /$DIR -perm -2 ! -type l)
	 
	done;
	## NON READABLE FILES (and FILESEC_DIRS) - this should also include non executable files/FILESEC_DIRS
	## if the path is a directory - all files under it also are required to be nonreadable
	while IFS= read -r file; do ## /dev/kmem, /etc/shadow, /etc/shadow- for instance
		if [[ -f "$file" || -d "$file" ]]; then
			FOUND=0
			find "$file" -perm -o=r ! \( -type d -perm -o=t \) ! -type l|while IFS= read -r result; do
					if [ "$FOUND" == "0" ]; then
						echo "[READABLE]  Following files are world readable:">>$ERROR_LOG
						FOUND=1 
					fi;
					echo "$result">>$ERROR_LOG
					echo "$result"
			done;
		fi;
	done < <(cat $NON_READABLE $NON_READABLE_CUSTOM)
}
function rkhunter_fsecmon()
{
	## RKHUNTER CHECKS
	RKHUNTER_LOG=/var/log/rkhunter.fsecmon.log
	echo ''>$RKHUNTER_LOG
	echo "rkhunter --cronjob --report-warnings-only -q -l $RKHUNTER_LOG"
	$RKHUNTER_PATH --cronjob --report-warnings-only -q
	echo "Done."
	while IFS= read -r RKHUNTER_WARNING; do
		WARNING_OK=NO
		RKHUNTER_WARNING=`echo $RKHUNTER_WARNING|sed 's/\[[0-9]*:[0-9]*:[0-9]*\]//g'|sed 's/^ *//g'`
		while IFS= read -r RKHUNTER_EXCEPTION; do
				if [ "$RKHUNTER_EXCEPTION" == "$RKHUNTER_WARNING" ]; then
					WARNING_OK=YES
					break
				fi;
				if [[ $RKHUNTER_WARNING =~ $RKHUNTER_EXCEPTION ]]; then
					## added pattern matching to exclude things like /dev/shm/mpich2_temp72e2ed
					WARNING_OK=YES
				fi;
		done < <(cat $RKHUNTER_WARNING_EXCEPTIONS $RKHUNTER_WARNING_EXCEPTIONS_CUSTOM)
		if [ "$WARNING_OK" == "NO" ]; then
			 echo "[RKHUNTER] $RKHUNTER_WARNING">>$ERROR_LOG
		fi;
	done < <(egrep 'Warning|possible' $RKHUNTER_LOG)	
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