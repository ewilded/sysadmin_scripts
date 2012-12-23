#!/bin/bash
# this is a config file for ewilded's administrative scripts set (diskspace monitor, alert on reboot, filesec monitor, backup, upgrade & reset and so on)
# this scripts have to be located under /root/scripts directory.
export HOSTNAME=`hostname`
export EMAIL_ADDR=(you@example.com anotheryou@example.com)
export EMAIL_FROM=you@example.com
# this list COULD be retrieved from chkconfig list|grep on
## these are example devices (for diskspace monitor) - /dev/file:critical_percentage_treshold, put here names and limits corresponding to your system and needs
export DEVICES=(/dev/sda1:90 /dev/mapper/VolGroup-lv_root:50)
export REBOOT_AFTER_UPGRADE="NO"
