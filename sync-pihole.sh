#!/bin/bash
inotifywait -r -m -e close_write --exclude '((setupVars|setupVars|pihole-FTL)\.(conf|conf\.update\.bak|db)|local(branche|version)s|dhcp\.leases)' --format '%w%f' /mnt/etc-pihole/ | while read MODFILE
do
    rsync -a -P --exclude 'install.log' --exclude 'pihole-FTL.conf' --exclude 'versions' --exclude 'dhcp.leases' --exclude 'setupVars.conf' --exclude 'setupVars.conf.update.bak' --exclude 'pihole-FTL.db' -e "ssh -p ${REM_SSH_PORT}" /mnt/etc-pihole/ root@${REM_HOST}:/mnt/etc-pihole/ --delete
    if [[ "${?}" -ne "0" ]]; then
        touch /fail
    elif [[ -f "/fail" ]]; then
	rm -f /fail
    fi
done
