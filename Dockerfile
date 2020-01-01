FROM debian

RUN apt-get update -y
RUN apt-get install openssh-client -y
RUN apt-get install rsync -y
RUN apt-get install inotify-tools -y

ADD syncScript.sh /syncScript.sh

ENTRYPOINT ["/syncScript.sh"]
