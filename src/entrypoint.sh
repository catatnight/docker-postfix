#!/bin/bash

if [ -z "$maildomain" ]; then
  export maildomain=localhost
  echo "WARNING: setting maildomain to localhost"
fi

/app/bin/setup-supervisor.sh
/app/bin/setup-postfix.sh
/app/bin/setup-sasl.sh
/app/bin/setup-tls.sh
/app/bin/setup-opendkim.sh

if [ "$*" != "" ]; then
  exec "$@"
  exit $?
fi

/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
