FROM alpine:3.12

RUN apk -U update
RUN apk add --no-cache dumb-init openssh-client openssh-server rsync inotify-tools bind-tools bash

ADD sync-dnsmasq.sh /sync-dnsmasq.sh
ADD sync-pihole.sh /sync-pihole.sh
ADD entryPoint.sh /entryPoint.sh
ADD sshd_config /
ADD healthCheck.sh /healthCheck.sh

ENTRYPOINT ["dumb-init", "/entryPoint.sh"]

HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD /healthCheck.sh
