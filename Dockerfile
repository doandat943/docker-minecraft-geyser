FROM eclipse-temurin:21-jre

RUN apt update && \
    apt upgrade -y &&\
    apt install -y curl jq && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/apt/*

COPY plugins.json /
COPY server-icon.png /
COPY curl-impersonate-chrome /usr/bin/
COPY start.sh /
RUN chmod +x /start.sh

ENV Type=SPIGOT
ENV Version=LATEST
ENV Port=25565

EXPOSE 25565/tcp
EXPOSE 25565/udp

CMD ["/start.sh"]