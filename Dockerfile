From ubuntu:latest
MAINTAINER Elliott Ye

# Set noninteractive mode for apt-get
ENV DEBIAN_FRONTEND noninteractive

# Update
RUN apt-get update

# Start editing
#install package here for cache
RUN apt-get -y install supervisor 
RUN apt-get -y install postfix sasl2-bin opendkim opendkim-tools 
RUN apt-get -y install openssl libssl1.0.0

# Add files
#certs
ADD assets/certs /etc/postfix/certs
#domainkeys
ADD assets/domainkeys /etc/opendkim/domainkeys

# Configure
ENV maildomain  mail.example.com
ENV smtp_user   user1:pwd1,user2:pwd2,...,userN:pwdN

# Initialization 
ADD assets/install.sh /opt/install.sh
RUN /opt/install.sh 

# Run
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
