FROM debian

RUN apt-get update -y
RUN apt-get install openssh-client -y
RUN apt-get install rsync -y
RUN apt-get install inotify-tools -y

ADD sync-dnsmasq.sh /sync-dnsmasq.sh
add sync-pihole.sh /sync-pihole.sh

ENTRYPOINT ["/entryPoint.sh"]
