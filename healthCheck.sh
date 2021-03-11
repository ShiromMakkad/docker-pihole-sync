#!/bin/bash

if [[ "${NODE,,}" == "sender" ]]; then
    if [[ -e "/fail" ]]; then
        exit 1
    fi
elif [[ "${NODE,,}" == "receiver" ]]; then
    netstat -plant | grep -q :22
    if [[ "${?}" -ne "0" ]]; then
        exit 2
    fi
fi
