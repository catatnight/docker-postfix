#!/bin/bash

# Check OS type
if grep "ubuntu" /etc/os-release > /dev/null ; then
  # Ubuntu
  supervisor_config_file="/etc/supervisor/conf.d/supervisord.conf"
  postconf_cmd="postconf"
  yum_cmd=""
elif grep "redhat" /etc/os-release > /dev/null ; then
  # RHEL/CentOS
  supervisor_config_file="/etc/supervisord.conf"
  postconf_cmd="postconf -c /etc/postfix"
  yum_cmd="yum -y"
else
  echo "Unsupported OS. Exiting."
  exit 1
fi

#judgement
if [[ -a $supervisor_config_file ]]; then
  exit 0
fi

#supervisor
cat > $supervisor_config_file <<EOF
[supervisord]
nodaemon=true

[program:postfix]
command=/opt/postfix.sh

[program:rsyslog]
command=/usr/sbin/rsyslogd -n -c3
EOF

############
#  postfix
############
cat >> /opt/postfix.sh <<EOF
#!/bin/bash
service postfix start
tail -f /var/log/mail.log
EOF
chmod +x /opt/postfix.sh
$postconf_cmd -e myhostname=$maildomain
$postconf_cmd -F '*/*/chroot = n'

############
# SASL SUPPORT FOR CLIENTS
############
$postconf_cmd -e smtpd_sasl_auth_enable=yes
$postconf_cmd -e broken_sasl_auth_clients=yes
$postconf_cmd -e smtpd_recipient_restrictions=permit_sasl_authenticated,reject_unauth_destination
# smtpd.conf
cat >> /etc/postfix/sasl/smtpd.conf <<EOF
pwcheck_method: auxprop
auxprop_plugin: sasldb
mech_list: PLAIN LOGIN CRAM-MD5 DIGEST-MD5 NTLM
EOF
# sasldb2
echo $smtp_user | tr , \\n > /tmp/passwd
while IFS=':' read -r _user _pwd; do
  echo $_pwd | saslpasswd2 -p -c -u $maildomain $_user
done < /tmp/passwd
chown postfix.sasl /etc/sasldb2

############
# Enable TLS
############
if [[ -n "$(find /etc/postfix/certs -iname '*.crt')" && -n "$(find /etc/postfix/certs -iname '*.key')" ]]; then
  # /etc/postfix/main.cf
  $postconf_cmd -e smtpd_tls_cert_file=$(find /etc/postfix/certs -iname '*.crt')
  $postconf_cmd -e smtpd_tls_key_file=$(find /etc/postfix/certs -iname '*.key')
  chmod 400 /etc/postfix/certs/*.*
  # /etc/postfix/master.cf
  $postconf_cmd -M submission/inet="submission   inet   n   -   n   -   -   smtpd"
  $postconf_cmd -P "submission/inet/syslog_name=postfix/submission"
  $postconf_cmd -P "submission/inet/smtpd_tls_security_level=encrypt"
  $postconf_cmd -P "submission/inet/smtpd_sasl_auth_enable=yes"
  $postconf_cmd -P "submission/inet/milter_macro_daemon_name=ORIGINATING"
  $postconf_cmd -P "submission/inet/smtpd_recipient_restrictions=permit_sasl_authenticated,reject_unauth_destination"
fi

#############
#  opendkim
#############

if [[ -z "$(find /etc/opendkim/domainkeys -iname '*.private')" ]]; then
  exit 0
fi
cat >> $supervisor_config_file <<EOF

[program:opendkim]
command=/usr/sbin/opendkim -f
EOF
# /etc/postfix/main.cf
$postconf_cmd -e milter_protocol=2
$postconf_cmd -e milter_default_action=accept
$postconf_cmd -e smtpd_milters=inet:localhost:12301
$postconf_cmd -e non_smtpd_milters=inet:localhost:12301

cat >> /etc/opendkim.conf <<EOF
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
cat >> /etc/default/opendkim <<EOF
SOCKET="inet:12301@localhost"
EOF

cat >> /etc/opendkim/TrustedHosts <<EOF
127.0.0.1
localhost
192.168.0.1/24

*.$maildomain
EOF
cat >> /etc/opendkim/KeyTable <<EOF
mail._domainkey.$maildomain $maildomain:mail:$(find /etc/opendkim/domainkeys -iname '*.private')
EOF
cat >> /etc/opendkim/SigningTable <<EOF
*@$maildomain mail._domainkey.$maildomain
EOF
chown opendkim:opendkim $(find /etc/opendkim/domainkeys -iname '*.private')
chmod 400 $(find /etc/opendkim/domainkeys -iname '*.private')
