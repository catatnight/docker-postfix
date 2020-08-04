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

if [ "${STRIP_RECEIVED_HEADERS}" = "1" ]; then
  echo "/^Received:.*/ IGNORE" >/etc/postfix/header_checks
  if ! grep -q "header_checks = pcre:/etc/postfix/header_checks" /etc/postfix/main.cf; then
    echo "header_checks = pcre:/etc/postfix/header_checks" >>/etc/postfix/main.cf
  fi
fi
