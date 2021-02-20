#!/bin/bash
chmod +x /sync-dnsmasq.sh /sync-pihole.sh
( /sync-dnsmasq.sh ) &
/sync-pihole.sh
