#!/bin/bash

############
#  postfix
############
cat >>/opt/postfix.sh <<EOF
#!/bin/bash
service postfix start
tail -f /var/log/mail.log
EOF

chmod +x /opt/postfix.sh

postconf -e myhostname=$maildomain
postconf -F '*/*/chroot = n'

if [ "${STRIP_RECEIVED_HEADERS}" = "1" ]; then
  echo "/^Received:.*/ IGNORE" >/etc/postfix/header_checks
  echo "header_checks = pcre:/etc/postfix/header_checks" >>/etc/postfix/main.cf
fi
