#!/bin/bash

#############
#  opendkim
#############

if [ ! -d /etc/opendkim ]; then
  echo "INFO [opendkim] not running opendkim"
  exit 0
fi

cat >>/etc/supervisor/conf.d/supervisord.conf <<EOF

[program:opendkim]
command=/usr/sbin/opendkim -f
EOF

cat >>/etc/opendkim.conf <<EOF
AutoRestart             Yes
AutoRestartRate         10/1h
UMask                   002
Syslog                  yes
SyslogSuccess           Yes
LogWhy                  Yes

Canonicalization        relaxed/simple

ExternalIgnoreList      refile:/etc/opendkim/TrustedHosts
InternalHosts           refile:/etc/opendkim/TrustedHosts
KeyTable                refile:/etc/opendkim/KeyTable
SigningTable            refile:/etc/opendkim/SigningTable

Mode                    sv
PidFile                 /var/run/opendkim/opendkim.pid
SignatureAlgorithm      rsa-sha256

UserID                  opendkim:opendkim

Socket                  inet:12301@localhost
EOF
cat >>/etc/default/opendkim <<EOF
SOCKET="inet:12301@localhost"
EOF

# /etc/postfix/main.cf
postconf -e milter_protocol=2
postconf -e milter_default_action=accept
postconf -e smtpd_milters=inet:localhost:12301
postconf -e non_smtpd_milters=inet:localhost:12301

# setup dbs
if [ -f /etc/opendkim/TrustedHosts ]; then
  echo "INFO [opendkim] already have TrustedHosts then most probably have mounted /x/etc/opendkim on top of /etc/opendkim"
  exit 0
fi

cat >>/etc/opendkim/TrustedHosts <<EOF
127.0.0.1
localhost

$maildomain
*.$maildomain
EOF
cat >>/etc/opendkim/KeyTable <<EOF
${dkimselector:-default}._domainkey.$maildomain $maildomain:${dkimselector:-mail}:$(find /etc/opendkim/domainkeys -iname *.private)
EOF
cat >>/etc/opendkim/SigningTable <<EOF
*@$maildomain ${dkimselector:-default}._domainkey.$maildomain
EOF

chown opendkim:opendkim /etc/opendkim/domainkeys
chown opendkim:opendkim $(find /etc/opendkim/domainkeys -iname *.private)
chmod 400 $(find /etc/opendkim/domainkeys -iname *.private)
