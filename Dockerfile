FROM ubuntu:trusty

MAINTAINER Elliott Ye

# Set noninteractive mode for apt-get
ENV DEBIAN_FRONTEND noninteractive

# Update
RUN apt-get update

# Check OS type and install packages accordingly
RUN if grep "ubuntu" /etc/os-release > /dev/null ; then \
        apt-get -y install supervisor postfix sasl2-bin opendkim opendkim-tools; \
    elif grep "redhat" /etc/os-release > /dev/null ; then \
        yum -y update && \
        yum -y install epel-release && \
        yum -y install supervisor postfix cyrus-sasl cyrus-sasl-plain opendkim opendkim-tools ; \
    elif grep -i "rocky" /etc/os-release > /dev/null ; then \
        yum -y update && \
        yum -y install epel-release && \
        yum -y install supervisor postfix cyrus-sasl cyrus-sasl-plain opendkim opendkim-tools ; \
    elif grep "solaris" /etc/release > /dev/null ; then \
        pkg update -y && \
        pkg install -y supervisor postfix sasl opendkim ; \
    fi

# Add files
ADD assets/install.sh /opt/install.sh
ADD assets/update-firewall.sh /opt/update-firewall.sh

# Set executable permissions
RUN chmod +x /opt/update-firewall.sh

# Run
CMD /opt/install.sh;/usr/bin/supervisord -c /etc/supervisor/supervisord.conf; /opt/update-firewall.sh
