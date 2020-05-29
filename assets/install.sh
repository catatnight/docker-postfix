#!/bin/bash

#judgement
if [[ -a /etc/supervisor/conf.d/supervisord.conf ]]; then
  exit 0
fi

#supervisor
cat > /etc/supervisor/conf.d/supervisord.conf <<EOF
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

if [[ -z "$mailhostname" ]]; then
  mailhostname=$maildomain
fi

postconf -e myhostname=$mailhostname
postconf -F '*/*/chroot = n'

# set up some email security as per https://ssl-tools.net/mailservers/ and 
# https://serverfault.com/questions/670348/how-to-force-a-own-set-of-ciphers-in-postfix-2-11#670359 and
# https://blog.tinned-software.net/harden-the-ssl-configuration-of-your-mailserver/

postconf -e tls_ssl_options=NO_COMPRESSION

postconf -e smtp_use_tls=yes
postconf -e smtp_tls_security_level=may
postconf -e "smtp_tls_protocols = !SSLv2, !SSLv3"
postconf -e "smtp_tls_mandatory_protocols = !SSLv2, !SSLv3"
postconf -e "smtp_tls_exclude_ciphers = DES-CBC3-SHA, EDH-RSA-DES-CBC3-SHA, RC2, RC4, aNULL"
postconf -e smtp_tls_loglevel=1

postconf -e smtpd_tls_security_level=may
# postconf -e smtpd_tls_auth_only=yes
postconf -e "smtpd_tls_protocols = !SSLv2, !SSLv3"
postconf -e "smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3"
postconf -e smtpd_tls_ciphers=high
postconf -e smtpd_tls_mandatory_ciphers=high
postconf -e "smtpd_tls_exclude_ciphers = DES-CBC3-SHA, EDH-RSA-DES-CBC3-SHA, RC2, RC4, aNULL"
postconf -e smtpd_tls_eecdh_grade=ultra

# include 172.16/12 for docker
postconf -e "mynetworks=127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 172.16.0.0/12"


############
# SASL SUPPORT FOR CLIENTS
# The following options set parameters needed by Postfix to enable
# Cyrus-SASL support for authentication of mail clients.
############
# /etc/postfix/main.cf

# this is enabled separately for smpt 25 and submission 587
#postconf -e smtpd_sasl_auth_enable=yes

postconf -e broken_sasl_auth_clients=yes
postconf -e smtpd_sasl_security_options=noanonymous
postconf -e "smtpd_recipient_restrictions=permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination"
postconf -e "smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination"

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
# Virtual Domain support
############
if [[ "$virtual_domains" != "" ]]; then
  postconf -e virtual_alias_maps=hash:/etc/postfix/virtual
  postconf -e "virtual_alias_domains=$virtual_domains"
  postmap /etc/postfix/virtual
fi

############
# Enable TLS
############

if [[ -n "$(find /etc/postfix/certs -iname *.crt)" && -n "$(find /etc/postfix/certs -iname *.key)" ]]; then
  SMTPD_TLS_CERT_FILE=$(find /etc/postfix/certs -iname *.crt)
  SMTPD_TLS_KEY_FILE=$(find /etc/postfix/certs -iname *.key)
fi

# for letsencrypt
if [[ -n "$(find /etc/postfix/certs -iname *.pem)" ]]; then
  SMTPD_TLS_CERT_FILE=$(find /etc/postfix/certs -iname *full*.pem)
  SMTPD_TLS_KEY_FILE=$(find /etc/postfix/certs -iname *priv*.pem)
fi

if [[ "$SMTPD_TLS_CERT_FILE" != "" ]]; then
  # /etc/postfix/main.cf
  postconf -e smtpd_tls_cert_file=$SMTPD_TLS_CERT_FILE
  postconf -e smtpd_tls_key_file=$SMTPD_TLS_KEY_FILE
  chmod 400 /etc/postfix/certs/*.*
  # /etc/postfix/master.cf
  #postconf -M submission/inet="submission   inet   n   -   n   -   -   smtpd -v" # enable for debugging auth on 587
  postconf -M submission/inet="submission   inet   n   -   n   -   -   smtpd"
  postconf -P "submission/inet/syslog_name=postfix/submission"
  postconf -P "submission/inet/smtpd_tls_security_level=encrypt" # comment out to test AUTH
  postconf -P "submission/inet/smtpd_sasl_auth_enable=yes"
  postconf -P "submission/inet/milter_macro_daemon_name=ORIGINATING"
  postconf -P "submission/inet/smtpd_recipient_restrictions=permit_sasl_authenticated,reject_unauth_destination"
  postconf -P "submission/inet/tls_preempt_cipherlist=yes"

  # only allow login from port 587
  postconf -P "smtp/inet/smtpd_sasl_auth_enable=no"
fi

#############
#  opendkim
#############

if [[ -z "$(find /etc/opendkim/domainkeys -iname *.private)" ]]; then
  exit 0
fi
cat >> /etc/supervisor/conf.d/supervisord.conf <<EOF

[program:opendkim]
command=/usr/sbin/opendkim -f
EOF
# /etc/postfix/main.cf
postconf -e milter_protocol=2
postconf -e milter_default_action=accept
postconf -e smtpd_milters=inet:localhost:12301
postconf -e non_smtpd_milters=inet:localhost:12301

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
172.16.0.0/12

*.$maildomain
EOF

for d in $virtual_domains; do
  echo >> /etc/opendkim/TrustedHosts "*.$d"
done

cat >> /etc/opendkim/KeyTable <<EOF
mail._domainkey.$maildomain $maildomain:mail:$(find /etc/opendkim/domainkeys/$maildomain -iname *.private)
EOF

for d in $virtual_domains; do
  echo >> /etc/opendkim/KeyTable "mail._domainkey.$d $d:mail:$(find /etc/opendkim/domainkeys/$d -iname *.private)"
done

cat >> /etc/opendkim/SigningTable <<EOF
*@$maildomain mail._domainkey.$maildomain
EOF

for d in $virtual_domains; do
  echo >> /etc/opendkim/SigningTable "*@$d mail._domainkey.$d"
done


chown opendkim:opendkim $(find /etc/opendkim/domainkeys -iname *.private)
chmod 400 $(find /etc/opendkim/domainkeys -iname *.private)
