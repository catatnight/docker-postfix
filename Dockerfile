FROM ubuntu:xenial
MAINTAINER Elliott Ye

# Set noninteractive mode for apt-get
ENV DEBIAN_FRONTEND="noninteractive"

RUN apt-get update && apt-get install -y \
    supervisor \
    postfix \
    sasl2-bin \
    opendkim \
    opendkim-tools \
 && rm -rf /var/lib/apt/lists/*

# Add files
ADD assets/install.sh /opt/install.sh

# Run
CMD /opt/install.sh;/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
