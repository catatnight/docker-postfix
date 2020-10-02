#!/bin/bash

############
#  postfix
############
cat > /opt/postfix.sh <<EOF
#!/bin/bash
service postfix start
tail -f /var/log/mail.log
EOF

chmod +x /opt/postfix.sh

postconf -e myhostname=$maildomain
postconf -F '*/*/chroot = n'

if [ "${inet_protocols}" != "" ]; then
  postconf -e inet_protocols=$inet_protocols
fi

if [ "${message_size_limit}" != "" ]; then
  postconf -e message_size_limit=$message_size_limit
fi

if [ "${STRIP_RECEIVED_HEADERS}" = "1" ]; then
  echo "/^Received:.*/ IGNORE" >/etc/postfix/header_checks
  postconf -e header_checks=pcre:/etc/postfix/header_checks
fi

if [ "${STRICT}" = "1" ]; then
  STRICT_REJECT=1
fi

if [ "${STRICT_REJECT}" = "1" ]; then
  # reduce backscatter
  # taken from https://willem.com/blog/2019-09-10_fighting-backscatter-spam-at-server-level/
  postconf -e smtpd_helo_required=yes
  postconf -e invalid_hostname_reject_code=554
  postconf -e multi_recipient_bounce_reject_code=554
  postconf -e non_fqdn_reject_code=554
  postconf -e relay_domains_reject_code=554
  postconf -e unknown_address_reject_code=554
  postconf -e unknown_client_reject_code=554
  postconf -e unknown_hostname_reject_code=554
  postconf -e unknown_local_recipient_reject_code=554
  postconf -e unknown_relay_recipient_reject_code=554
#  postconf -e unknown_sender_reject_code = 554 ## TODO unknown option in postfix?
  postconf -e unknown_virtual_alias_reject_code=554
  postconf -e unknown_virtual_mailbox_reject_code=554
  postconf -e unverified_recipient_reject_code=554
  postconf -e unverified_sender_reject_code=554
fi
