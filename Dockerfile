FROM eclipse-temurin:21-jre

RUN apt update && \
    apt upgrade -y &&\
    apt install -y curl jq && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/apt/*

COPY server-icon.png /
COPY plugins.json /
COPY curl-impersonate-chrome /usr/bin/
COPY start.sh /
RUN chmod +x /start.sh

ENV Version=
ENV Port=25565

EXPOSE 25565/tcp
EXPOSE 25565/udp

CMD ["/start.sh"]