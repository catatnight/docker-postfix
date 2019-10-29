FROM debian:buster-slim

LABEL maintainer="source@kingsquare.nl"

# Set noninteractive mode for apt-get
ENV DEBIAN_FRONTEND noninteractive

# Update
RUN \
    apt -yq update && \
    apt -yq install \
        supervisor \
        ca-certificates \
        openssl \
        postfix \
        sasl2-bin \
        opendkim \
        opendkim-tools \
    && \
    apt -yq autoremove && \
    rm -rf /var/apt/lists/* && \
    rm -rf /usr/share/man/?? /usr/share/man/??_*

ENV DEBIAN_FRONTEND ""

# Expose port(s)
#EXPOSE 25 587 465

# Add files
ADD assets/install.sh /opt/install.sh

# Run
CMD /opt/install.sh;/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
