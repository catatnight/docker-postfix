FROM ubuntu:trusty
MAINTAINER Elliott Ye

# Set noninteractive mode for apt-get
ENV DEBIAN_FRONTEND noninteractive

# Update
RUN apt-get update

# Check OS type
RUN if grep "ubuntu" /etc/os-release > /dev/null ; \
    then apt-get -y install supervisor postfix sasl2-bin opendkim opendkim-tools; \
    elif grep "redhat" /etc/os-release > /dev/null ; \
    then yum -y install supervisor postfix cyrus-sasl cyrus-sasl-plain opendkim opendkim-tools; \
    fi

# Add files
ADD assets/install.sh /opt/install.sh

# Run
CMD /opt/install.sh;/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
