#!/bin/bash
inotifywait -r -m -e close_write --exclude '01-pihole\.conf' --format '%w%f' /mnt/etc-dnsmasq.d/ | while read MODFILE
do
    rsync -a -P --exclude '01-pihole.conf' /mnt/etc-dnsmasq.d/ -e "ssh -p ${REM_SSH_PORT}" ${REM_USER}@${REM_HOST}:/mnt/etc-dnsmasq.d/ --delete
    if [[ "${?}" -ne "0" ]]; then
        touch /fail
    fi
done
