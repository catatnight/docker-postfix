#!/bin/bash

#judgement
if [[ -e /etc/supervisor/conf.d/supervisord.conf ]]; then
  exit 0
fi

#supervisor
cat >/etc/supervisor/conf.d/supervisord.conf <<EOF
[supervisord]
nodaemon=true
loglevel = INFO
user=root

[unix_http_server]
username = "$(echo "${HOSTNAME}$(date)username" | sha256sum | awk '{print $1}')"
password = "$(echo "${HOSTNAME}$(date)password" | sha256sum | awk '{print $1}')"

[program:postfix]
command=/opt/postfix.sh

[program:rsyslog]
command=/usr/sbin/rsyslogd -n
EOF
