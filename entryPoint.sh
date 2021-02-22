#!/bin/bash
chmod +x /sync-dnsmasq.sh /sync-pihole.sh
hostOnly="${PIHOLECLIENTDIR#*@}"
hostOnly="${hostOnly%%:*}"
ssh-keyscan -H ${hostOnly} > /root/.ssh/known_hosts 2>/dev/null
bash -c "rsync -aP --exclude '01-pihole.conf' /mnt/dnsmasq/ ${DNSMASQCLIENTDIR} --delete"
bash -c "rsync -aP --exclude 'pihole-FTL.db' /mnt/pihole/ ${PIHOLECLIENTDIR} --delete"
( /sync-dnsmasq.sh ) &
/sync-pihole.sh
