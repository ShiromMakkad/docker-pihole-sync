#!/bin/bash
inotifywait -r -m -e close_write --exclude '01-pihole.conf' --format '%w%f' /mnt/dnsmasq | while read MODFILE
do
    bash -c "rsync -aP --exclude '01-pihole.conf' /mnt/dnsmasq/ $CLIENTDIR --delete"
    if [[ "${?}" -ne "0" ]]; then
        touch /fail
    fi
done
