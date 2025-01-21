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
COPY run.sh /
COPY start.sh /
RUN chmod +x /run.sh /start.sh /usr/bin/curl-impersonate-chrome

ENV Type=PAPER
ENV Version=LATEST
ENV Port=25565

EXPOSE 25565/tcp
EXPOSE 25565/udp

CMD ["/run.sh"]