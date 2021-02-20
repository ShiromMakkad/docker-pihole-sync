FROM debian

RUN apt-get update -y
RUN apt-get install openssh-client -y
RUN apt-get install rsync -y
RUN apt-get install inotify-tools -y

ADD sync-dnsmasq.sh /sync-dnsmasq.sh
ADD sync-pihole.sh /sync-pihole.sh
ADD healthCheck.sh /healthCheck.sh

ENTRYPOINT ["/entryPoint.sh"]

HEALTHCHECK --interval=60s --timeout=10s --retries=3 CMD /healthCheck.sh
