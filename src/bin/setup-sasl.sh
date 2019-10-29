#!/bin/bash

############
# SASL SUPPORT FOR CLIENTS
# The following options set parameters needed by Postfix to enable
# Cyrus-SASL support for authentication of mail clients.
############

# /etc/postfix/main.cf
postconf -e smtpd_sasl_auth_enable=yes
postconf -e broken_sasl_auth_clients=yes
postconf -e smtpd_recipient_restrictions=permit_sasl_authenticated,reject_unauth_destination
postconf -e smtp_sasl_security_options=noanonymous

# smtpd.conf
cat >>/etc/postfix/sasl/smtpd.conf <<EOF
pwcheck_method: auxprop
auxprop_plugin: sasldb
mech_list: PLAIN LOGIN CRAM-MD5 DIGEST-MD5 NTLM
EOF

# sasldb2
if [ ! -z "$smtp_user" ]; then
  echo $smtp_user | tr , \\n >/tmp/passwd
  while IFS=':' read -r _user _pwd; do
    echo $_pwd | saslpasswd2 -p -c -u $maildomain $_user
  done </tmp/passwd
  rm -rf /tmp/passwd
fi

chown postfix.sasl /etc/sasldb2
