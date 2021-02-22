#!/bin/bash
inotifywait -r -m -e close_write --format '%w%f' /mnt/pihole | while read MODFILE
do
    bash -c "rsync -aP --exclude 'pihole-FTL.db' /mnt/pihole/ ${PIHOLECLIENTDIR} --delete"
    if [[ "${?}" -ne "0" ]]; then
        touch /fail
    fi
done
