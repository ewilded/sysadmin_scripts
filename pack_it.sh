#!/bin/bash
chown -R root:root .
rm -rf sysadm_scripts.tar.bz2
rm -rf sysadm_scripts/*
cp -v *.sh sysadm_scripts/
rm -v sysadm_scripts/pack_it.sh
cp -v crontab sysadm_scripts/
cp -av filesec_monitor sysadm_scripts
tar -cf sysadm_scripts.tar sysadm_scripts
bzip2 sysadm_scripts.tar
echo "sysadm_scripts.tar.bz2 is ready."

