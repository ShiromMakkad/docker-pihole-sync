[![Docker Pulls](https://img.shields.io/docker/pulls/shirom/pihole-sync.svg?style=for-the-badge&logo=github)](https://hub.docker.com/repository/docker/shirom/pihole-sync)

# docker-pihole-sync
A Docker Container To Sync Two Piholes. 

## Introduction
A Pihole runs your entire network. If it goes down, your whole network goes down. If you have a family at home, they're going to be pretty annoyed that the wifi goes out everytime you want to do some maintainence. The only solution to this problem is to have a redundant pihole on your network, but you don't want to change your settings in two different places.

This repo allows you to synchronize between two piholes where one is the master and one is the slave. I'll be adding support for more piholes in future. Just update one pihole and the rest automatically update. It supports the `/etc/pihole/` and `/etc/dnsmasq.d/` directories, excluding some directories which should be client-independent.

It is based on Alpine 3.12 and utilizes `dumb-init`, `openssh`, `rsync`, `inotify-tools`, and `bash` for an image size of about 28 MB.

Because Pi-Hole Docker utilizes a UID/GID of 0:0 and 999:999, this presents a unique problem for sending files over SSH, as the only user who can receive the files and maintain the proper UID/GID flags is root. However, having a docker container SSH in to the root user of another host is undesirable for a number of security related reasons.

By utilizing a `sender` container node on one Pi and a `receiver` container node on the other Pi, we're able to solve the issue of securely opening a root user to SSH, by having the `sender` container node SSH into the `receiver` container node, rather than the host. If the container were to be infiltrated, the infiltrater would have access to root only in the receiver container, and its mounted volumes.

## Why Docker PiHole Sync

There are other options out there such as [pihole-cloudsync](https://github.com/stevejenkins/pihole-cloudsync) and [pihole-sync](https://github.com/simonwhitaker/pihole-sync), but this repo offers 4 unique features:

### 1. Docker Support
If you have a project based on docker, it doesn't make sense to have a single sync script running outside of docker. Your whole project should be started with docker-compose up and ended on docker-compose down (or a different command on swarm), and you can do that with this repo. Additionally, installing things like python or git inside a container is difficult because the container will be destroyed on shutdown. You could create volumes for the changed folders, but that's a hacky, difficult to maintain solution.  
### 2. Continuous Synchronization
The code will monitor the selected the folder for changes and immediately update the other Pihole. Great for updating the whitelist and seeing the website work immediately.
### 3. All Settings Are Transferred
Not only are your lists transferred, but all your other settings are transferred as well including your password, upstream DNS settings, etc.
### 4. Keeps Your Github Clean
Unlike [pihole-cloudsync](https://github.com/stevejenkins/pihole-cloudsync), we don't require a repository to sync to. This means that your Piholes don't have to connect to the internet, and you don't have a large number of commits going into a dummy repository. This is especially nice if you show private contributions on your profile and don't want a huge number of changes being published to your Github profile

#### NOTE: 
The 'sender' Pihole must be able to SSH into the 'receiver' Pihole. If that's a restriction (maybe your Piholes are behind different VPNs), use [pihole-cloudsync](https://github.com/stevejenkins/pihole-cloudsync). 

## Setup
### docker-compose.yml

This is the `docker-compose.yml` for the sender/master Pi-Hole:

```yaml
pihole:
    image: pihole/pihole:latest
    volumes:
        - /mnt/ext/pihole/etc-pihole:/etc/pihole
        - /mnt/ext/pihole/etc-dnsmasq-d:/etc/dnsmasq.d
    rest of pihole config...

pihole-sync-sender:
    image: shirom/pihole-sync:latest
    container_name: pihole-sync-sender
    volumes:
        - /mnt/ext/piholesync/root:/root
        - /mnt/ext/pihole/etc-pihole:/mnt/etc-pihole:ro
        - /mnt/ext/pihole/etc-dnsmasq.d:/mnt/etc-dnsmasq.d:ro
    environment:
        - "NODE=sender"
        - "REM_HOST=(IP address of remote Pi)"
        - "REM_SSH_PORT=22222"
```

This is the `docker-compose.yml` for the receiver/secondary Pi-Hole:

```yaml
pihole:
    image: pihole/pihole:latest
    volumes:
        - /mnt/ext/pihole/etc-pihole:/etc/pihole
        - /mnt/ext/pihole/etc-dnsmasq-d:/etc/dnsmasq.d
    rest of pihole config...

pihole-sync-receiver:
    image: shirom/pihole-sync:latest
    container_name: pihole-sync-receiver
    volumes:
        - /mnt/ext/piholesync/root:/root
        - /mnt/ext/piholesync/etc-ssh:/etc/ssh
        - /mnt/ext/pihole/etc-pihole:/mnt/etc-pihole
        - /mnt/ext/pihole/etc-dnsmasq.d:/mnt/etc-dnsmasq.d
    environment:
        - "NODE=receiver"
    ports:
        - 22222:22
```

### Volumes
Volume | Function 
--- | -------- 
`/mnt/ext/piholesync/root` | This is the directory in which the SSH key file and the known hosts file will be stored, so it needs to be persistent.<br />**Required on both nodes.**
`/mnt/ext/piholesync/etc-ssh` | This is the directory in which the SSH server key files and the SSH daemon config will be stored, so it needs to be persistent. Can be a volume rather than a bind path, if you prefer.<br />**Required on the `sender` node only.**
`/mnt/ext/pihole/etc-pihole` | This is the `/etc/pihole/` directory the Pi-Hole container writes to on the host filesystem. It is monitored and sychronized with the remote client directory. It should be set to the same as the /etc/pihole/ in the Pihole Docker container. See the compose file for details.<br />**Required on both nodes. Can be mounted read-only on the `sender` node.**
`/mnt/ext/pihole/etc-dnsmasq.d` | This is the `/etc/dnsmasq.d/` directory the Pi-Hole container writes to on the host filesystem. It is monitored and sychronized with the remote client directory. It should be set to the same as the /etc/dnsmasq.d/ in the Pihole Docker container. See the compose file for details.<br />**Required on both nodes. Can be mounted read-only on the `sender` node.**

### Environment Variables
Variable | Function
--- | --------
`NODE` | This is where you should define if the container is the `sender` or the `receiver`.<br />**Required on both nodes.**
`REM_HOST` | This is the IP address (or FQDN/Hostname) of the remote Pi that we're syncting to.<br />**Required on the `sender` node only.**
`REM_SSH_PORT` | This is the non-standard SSH port that should be exposed on the container. Default of 22222 is probably fine. However, if you change this on the `sender` node, be sure to change the exposed port forward on the `receiver` node.<br />**Required on the `sender` node only.**

### Ports
Port | Function
--- | --------
`22222` | This is the port you want to expose for rsync/ssh. Your host is likely using 22 for SSH already, so it should be a non-standard port. The default of 22222 is probably fine. However, if you change this on the `receiver` node, be sure to change the `REM_SSH_PORT` on the `sender` node.<br />**Required on the `receiver` node only.**

## Support Information
- Shell access while the container is running: `docker exec -it pihole-sync /bin/bash`
- Logs: `docker logs pihole-sync`

## Building Locally
If you want to make local modifications to this image for development purposes or just to customize the logic:
```
git clone https://github.com/ShiromMakkad/docker-pihole-sync.git
cd docker-pihole-sync
docker build -t shirom/docker-pihole-sync .
```
