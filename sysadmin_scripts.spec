Summary: Handy set of sysadmin scripts for auto upgrading and filesystem attributes scanning integrated with rkhunter. 
Name: sysadmin_scripts
Version: 1
Release: 0
License: GPL
Group: Applications/Security
Source: sysadmin_scripts.tar.bz2
BuildRoot: /var/tmp/%{name}-buildroot

%description
Package contains:
global config (for watched disks and e-mail addresses)
alert_on_reboot.sh - script attached to /etc/rc.local, it simply sends an e-mail to all configured address on each boot, sometimes it's useful
auto_upgrade.sh - upgrades system with yum and restarts affected services (set it up to cron)
diskspace_monitor.sh - simple script for e-mail alerting when one of the disks reaches adjusted limit of used space (conenct it up in cron)
filesec_monitor.sh - script for scanning local system for weak permissions, integraded with rkhunter scan with customizable list of exceptions and reporting via e-mail
example crontab entries

%prep
%setup -q

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/sbin
mkdir -p $RPM_BUILD_ROOT/usr/share/sysadmin_scripts/{doc,scripts}
mkdir -p $RPM_BUILD_ROOT/etc/sysadmin_scripts/filesec_monitor

install -m 644 README $RPM_BUILD_ROOT/usr/share/doc/sysadmin_scripts/README
install -m 644 LICENSE $RPM_BUILD_ROOT/usr/share/doc/sysadmin_scripts/LICENSE
install -m 744 alert_on_reboot.sh $RPM_BUILD_ROOT/usr/sbin/alert_on_reboot.sh
install -m 744 diskspace_monitor.sh $RPM_BUILD_ROOT/usr/sbin/diskspace_monitor.sh
install -m 744 filesec_monitor.sh $RPM_BUILD_ROOT/usr/sbin/filesec_monitor.sh
install -m 744 auto_upgrade.sh $RPM_BUILD_ROOT/usr/sbin/auto_upgrade.sh
install -m 744 config.sh $RPM_BUILD_ROOT/etc/sysadmin_scripts/config.sh
install -m 644 perms_monitor_sugid_exceptions_custom $RPM_BUILD_ROOT/etc/sysadmin_scripts/filesec_monitor/perms_monitor_sugid_exceptions_custom
install -m 644 perms_monitor_sugid_exceptions $RPM_BUILD_ROOT/etc/sysadmin_scripts/filesec_monitor/perms_monitor_sugid_exceptions
install -m 644 perms_monitor_world_writable_exceptions $RPM_BUILD_ROOT/etc/sysadmin_scripts/filesec_monitor/perms_monitor_world_writable_exceptions
install -m 644 perms_monitor_world_writable_exceptions_custom $RPM_BUILD_ROOT/etc/sysadmin_scripts/filesec_monitor/perms_monitor_world_writable_exceptions_custom
install -m 644 perms_monitor_non_readable $RPM_BUILD_ROOT/etc/sysadmin_scripts/filesec_monitor/perms_monitor_non_readable
install -m 644 perms_monitor_non_readable_custom $RPM_BUILD_ROOT/etc/sysadmin_scripts/filesec_monitor/perms_monitor_non_readable_custom
install -m 644 rkhunter_filesec_exceptions $RPM_BUILD_ROOT/etc/sysadmin_scripts/filesec_monitor/rkhunter_filesec_exceptions
install -m 644 rkhunter_filesec_exceptions_custom $RPM_BUILD_ROOT/etc/sysadmin_scripts/filesec_monitor/rkhunter_filesec_exceptions_custom


%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%config(noreplace) /etc/sysadmin_scripts/config.sh
%config(noreplace) /etc/sysadmin_scripts/filesec_monitor/perms_monitor_sugid_exceptions_custom
%config(noreplace) /etc/sysadmin_scripts/filesec_monitor/perms_monitor_world_writable_exceptions_custom
%config(noreplace) /etc/sysadmin_scripts/filesec_monitor/perms_monitor_non_readable_custom
%config(noreplace) /etc/sysadmin_scripts/filesec_monitor/rkhunter_filesec_exceptions_custom
/usr/sbin/alert_on_reboot.sh
/usr/sbin/auto_upgrade.sh
/usr/sbin/diskspace_monitor.sh
/usr/sbin/filesec_monitor.sh
/etc/sysadmin_scripts/filesec_monitor/rkhunter_filesec_exceptions
/etc/sysadmin_scripts/filesec_monitor/perms_monitor_sugid_exceptions
/etc/sysadmin_scripts/filesec_monitor/perms_monitor_world_writable_exceptions
/etc/sysadmin_scripts/filesec_monitor/perms_monitor_non_readable
/usr/share/sysadmin_scripts/doc/README
/usr/share/sysadmin_scripts/doc/LICENSE 
