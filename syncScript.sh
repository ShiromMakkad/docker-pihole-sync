#!/bin/bash
inotifywait -r -m -e close_write --format '%w%f' /mnt/pihole | while read MODFILE
do
    bash -c "rsync -aP /mnt/pihole/ $CLIENTDIR --delete"
done
