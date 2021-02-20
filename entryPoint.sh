#!/bin/bash
chmod +x /sync-dnsmasq.sh /sync-pihole.sh
/sync-dnsmasq.sh > /dev/null 2>&1 &
/sync-pihole.sh > /dev/null 2>&1 &
