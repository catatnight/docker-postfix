#!/bin/bash

############
# Enable TLS
############

# some better TLS defaults as of 2019-10
postconf -e tls_high_cipherlist=EECDH+AESGCM:EDH+AESGCM:kEECDH+AESGCM:kEDH+AESGCM:kEECDH:+kEECDH+SHA:kEDH:+kEDH+SHA:+kEDH+CAMELLIA:kECDH:+kECDH+SHA:kRSA:+kRSA+SHA:+kRSA+CAMELLIA:!aNULL:!eNULL:!SSLv2:!RC4:!MD5:!DES:!EXP:!SEED:!IDEA:!3DES
postconf -e tls_medium_cipherlist=EECDH+AESGCM:EDH+AESGCM:kEECDH+AESGCM:kEDH+AESGCM:kEECDH:+kEECDH+SHA:kEDH:+kEDH+SHA:+kEDH+CAMELLIA:kECDH:+kECDH+SHA:kRSA:+kRSA+SHA:+kRSA+CAMELLIA:!aNULL:!eNULL:!SSLv2:!MD5:!DES:!EXP:!SEED:!IDEA:!3DES
postconf -e tls_preempt_cipherlist=yes

# outgoing smtp TLS
postconf -e smtp_use_tls=no
postconf -e smtp_tls_loglevel=1
postconf -e smtp_tls_security_level=may
postconf -e smtp_tls_note_starttls_offer=yes
postconf -e smtp_tls_protocols=!SSLv2,!SSLv3
postconf -e smtp_tls_mandatory_protocols=!SSLv2,!SSLv3
postconf -e smtp_tls_exclude_ciphers=EXP, MEDIUM, LOW, DES, 3DES, SSLv2
postconf -e smtp_tls_ciphers=high
postconf -e smtp_send_xforward_command=yes

if [ ! -d /etc/postfix/certs ]; then
  echo "INFO [postfix] not enabling smtpd TLS"
  exit 0
fi

if [[ -n "$(find /etc/postfix/certs -iname *.crt)" && -n "$(find /etc/postfix/certs -iname *.key)" ]]; then
  # /etc/postfix/main.cf
  postconf -e smtpd_tls_cert_file=$(find /etc/postfix/certs -iname *.crt)
  postconf -e smtpd_tls_key_file=$(find /etc/postfix/certs -iname *.key)

  #postconf -e smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt

  postconf -e smtpd_use_tls=yes
  postconf -e smtpd_tls_loglevel=1
  postconf -e smtpd_tls_security_level=may
  postconf -e smtpd_tls_received_header=yes
  postconf -e smtpd_tls_protocols=!SSLv2,!SSLv3
  postconf -e smtpd_tls_mandatory_protocols=!SSLv2,!SSLv3
  postconf -e smtpd_tls_exclude_ciphers=EXP, MEDIUM, LOW, DES, 3DES, SSLv2
  postconf -e smtpd_tls_ciphers=high

  chmod 400 /etc/postfix/certs/*.*
  # /etc/postfix/master.cf
  postconf -M submission/inet="submission   inet   n   -   n   -   -   smtpd"
  postconf -P "submission/inet/syslog_name=postfix/submission"
  postconf -P "submission/inet/smtpd_tls_security_level=encrypt"
  postconf -P "submission/inet/smtpd_sasl_auth_enable=yes"
  postconf -P "submission/inet/milter_macro_daemon_name=ORIGINATING"
  postconf -P "submission/inet/smtpd_recipient_restrictions=permit_sasl_authenticated,reject_unauth_destination"
fi
