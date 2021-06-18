#!/bin/bash

fail="1"
if [[ -z "${NODE,,}" ]]; then
    fail="0"
elif [[ "${NODE,,}" == "sender" ]]; then
    fail="0"
elif [[ "${NODE,,}" == "receiver" ]]; then
    fail="0"
elif ! grep -q "/mnt/etc-pihole" /etc/mtab; then
    echo "Please define a /mnt/etc-pihole config path."
    echo "This should be a physical path, such as:"
    echo "-v \"~/etc-pihole:/mnt/etc-pihole\""
    fail="1"
elif ! grep -q "/mnt/etc-dnsmasq.d" /etc/mtab; then
    echo "Please define a /mnt/etc-dnsmasq.d config path."
    echo "This should be a physical path, such as:"
    echo "-v \"~/etc-dnsmasq.d:/mnt/etc-dnsmasq.d\""
    fail="1"
fi
if [[ "${fail}" -eq "1" ]]; then
    echo "Please set environmental flag 'NODE=[sender|receiver]'"
    exit 1
fi

if [[ "${NODE,,}" == "sender" ]]; then
    if ! grep -q "/root" /etc/mtab; then
        echo "Please define a root config path."
        echo "This should be a physical path, such as:"
        echo "-v \"~/piholesync/root:/root\""
        exit 2
    fi
    if ! [[ -e "/root/.ssh/id_ed25519" ]]; then
        ssh-keygen -b 2048 -t ed25519 -f /root/.ssh/id_ed25519 -q -N ""
        chmod 400 "/root/.ssh/id_ed25519"
        echo ""
        echo "On the receiver node, create an authorized_keys file in the config directory"
        echo ""
        echo "For example, if your 'config' volume mount on the receiver is:"
        echo "-v /docker/config/piholesync/root:/root"
        echo ""
        echo "Then you would create a file at:"
        echo "/docker/config/piholesync/root/.ssh/authorized_keys"
        echo ""
        echo "Copy/paste the contents between the ##### markers into that authorized_keys file:"
        echo ""
        echo "####### COPY BELOW THIS LINE, BUT NOT THIS LINE ########"
        cat "/root/.ssh/id_ed25519.pub"
        echo "####### COPY ABOVE THIS LINE, BUT NOT THIS LINE ########"
        echo ""
        echo "Once done, re-start this conatiner."
        exit 0
    fi
    if ! [[ -e "/root/.ssh/known_hosts" ]]; then
        ssh-keyscan -p ${REM_SSH_PORT} ${REM_HOST} > /root/.ssh/known_hosts 2>/dev/null
        if [[ "${?}" -ne "0" || "$(wc -l "/root/.ssh/known_hosts" | awk '{print $1}')" -eq "0" ]]; then
            echo "Unable to initiate keyscan. Is the receiver online?"
            rm "/root/.ssh/known_hosts"
            exit 3
        fi
    fi
    rsync -a -P --exclude '01-pihole.conf' /mnt/etc-dnsmasq.d/ -e "ssh -p ${REM_SSH_PORT}" root@${REM_HOST}:/mnt/etc-dnsmasq.d/ --delete
    if [[ "${?}" -ne "0" ]]; then
        echo "Unable to initiate dnsmasq.d rsync. Is the receiver online?"
        exit 4
    fi
    rsync -a -P --exclude 'localbranches' --exclude 'localversions' --exclude 'setupVars.conf' --exclude 'setupVars.conf.update.bak' --exclude 'pihole-FTL.db' -e "ssh -p ${REM_SSH_PORT}" /mnt/etc-pihole/ root@${REM_HOST}:/mnt/etc-pihole/ --delete
    if [[ "${?}" -ne "0" ]]; then
        echo "Unable to initiate dnsmasq.d rsync. Is the receiver online?"
        exit 5
    fi
    chmod +x /sync-dnsmasq.sh /sync-pihole.sh
    ( /sync-dnsmasq.sh ) &
    /sync-pihole.sh
fi

if [[ "${NODE,,}" == "receiver" ]]; then
    if ! grep -q "/etc/ssh" /etc/mtab; then
        echo "Please define an /etc/ssh config path."
        echo "This should be a physical path, such as:"
        echo "-v \"~/piholesync/etc-ssh:/etc/ssh\""
        exit 6
    fi
    if ! grep -q "/root" /etc/mtab; then
        echo "Please define a root config path."
        echo "This should be a physical path, such as:"
        echo "-v \"~/piholesync/root:/root\""
        exit 7
    fi
    if ! [[ -e "/root/.ssh/authorized_keys" ]]; then
        echo "Please obtain the 'authorized_keys' file from the sender,"
        echo "and add it at your root/.ssh/authorized_keys path"
        exit 8
    fi
    sshKeyArr=("ssh_host_dsa_key" "ssh_host_dsa_key.pub" "ssh_host_ecdsa_key" "ssh_host_ecdsa_key.pub" "ssh_host_ed25519_key" "ssh_host_ed25519_key.pub" "ssh_host_rsa_key" "ssh_host_rsa_key.pub")
    for i in "${sshKeyArr[@]}"; do
        if ! [[ -e "/etc/ssh/${i}" ]]; then
            ssh-keygen -A
        fi
    done
    mv /sshd_config /etc/ssh/sshd_config
    # We can't SSH into the root user if it doesn't have a password set
    # Set a random 36 character string as the password
    rootPass="$(date +%s | sha256sum | base64 | head -c 36)"
    echo "root:${rootPass}" | chpasswd
    # Ensure permissions are correct on the root directory, or it won't let
    # us rsync/ssh in as the root user
    chmod 700 /root
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/authorized_keys
    /usr/sbin/sshd -D -e
fi
