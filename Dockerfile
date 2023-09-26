FROM ubuntu:latest

MAINTAINER Alex Noel

# Set noninteractive mode for apt-get
ENV DEBIAN_FRONTEND noninteractive

# Update
RUN apt-get update
RUN apt-get install -y python3

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
ADD assets/export.bash /opt/SMTPINFO.bash
add assets/creds.py /opt/creds.py
ADD assets/build.py /opt/build.py

# Set executable permissions
RUN chmod +x /opt/update-firewall.sh
RUN chmod +x /opt/build.py
RUN chmod +x /opt/SMTPINFO.bash
RUN chmod +x /opt/creds.py

# Run
CMD /opt/install.sh && \
    /usr/bin/supervisord -c /etc/supervisor/supervisord.conf && \
    /opt/update-firewall.sh && \
    source /opt/SMTPINFO.bash && \
    python /opt/build.py && \
    rm /opt/export.bash

