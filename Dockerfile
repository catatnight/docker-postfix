FROM debian:buster-slim

LABEL maintainer="source@kingsquare.nl"

RUN \
    DEBIAN_FRONTEND=noninteractive apt -yq update && \
    DEBIAN_FRONTEND=noninteractive apt -yq install \
        supervisor \
        ca-certificates \
        openssl \
        postfix \
        sasl2-bin \
        opendkim \
        opendkim-tools \
        rsyslog \
    && \
    apt -yq autoremove && \
    rm -rf /var/apt/lists/* && \
    rm -rf /usr/share/man/?? /usr/share/man/??_*

#EXPOSE 25 587 465

ADD src /app

ENTRYPOINT ["/app/entrypoint.sh"]
