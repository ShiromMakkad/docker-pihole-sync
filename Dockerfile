FROM debian

RUN apt-get update -y
RUN apt-get install openssh-client rsync inotify-tools -y

ADD sync-dnsmasq.sh /sync-dnsmasq.sh
ADD sync-pihole.sh /sync-pihole.sh
ADD healthCheck.sh /healthCheck.sh
ADD entryPoint.sh /entryPoint.sh

ENTRYPOINT ["/entryPoint.sh"]

HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD /healthCheck.sh
