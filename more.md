
# Relaying according to the Linode Guide

https://linode.com/docs/email/postfix/postfix-smtp-debian7/

`myhostname = ` parameter specifies the hostname of the server. 

`/etc/postfix/sasl_passwd` is a text file that maps hostnames to
`username:password` credentials to use. This is used later on for
relaying and should contain something like:

```
[mail.isp.example]:587 username:password
```

The port is only necessary if we're not going to use port 25 to connect.

To generate a hash file for this, use `postmap
/etc/postfix/sasl_passwd`. This will create a file along-side it at
`/etc/postfix/sasl_passwd.db`.

To enable the relaying, we use this in `/etc/postfix/main.cf`:

```
relayhost = [mail.isp.example]:587
```

And then, to configure authentication against this relayhost, we use
something like this:

```
# enable SASL authentication
smtp_sasl_auth_enable = yes
# disallow methods that allow anonymous authentication.
smtp_sasl_security_options = noanonymous
# where to find sasl_passwd
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
# Enable STARTTLS encryption
smtp_use_tls = yes
# where to find CA certificates
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
```

# Additional bits from the existing docker initialization script

Supervisord is used to run the postfix server and rsyslog next to
it. Supervisor configuration is in `/etc/supervisor/conf.d`. It runs
`/opt/postfix.sh` and `/usr/sbin/rsyslogd`.

The `/opt/postfix.sh` is super simple:

```
#!/bin/bash
service postfix start
tail -f /var/log/mail.log
```

This follows the standard docker convention of exposing logs to
STDOUT.

The script also sets a couple of settings in `/etc/postfix/main.cf`:

```
postconf -e myhostname=$maildomain
postconf -F '*/*/chroot = n'
postconf -e smtpd_sasl_auth_enable=yes
postconf -e broken_sasl_auth_clients=yes
postconf -e smtpd_recipient_restrictions=permit_sasl_authenticated,reject_unauth_destination
```

And in `/etc/postfix/sasl/smtpd.conf`:

```
cat >> /etc/postfix/sasl/smtpd.conf <<EOF
pwcheck_method: auxprop
auxprop_plugin: sasldb
mech_list: PLAIN LOGIN CRAM-MD5 DIGEST-MD5 NTLM
EOF
```

The incoming user accounts (i.e. what our Java apps will login with)
are written out using `saslpasswd2`, which appears to know where to
store them (`/etc/sasldb2`):

```
echo $smtp_user | tr , \\n > /tmp/passwd
while IFS=':' read -r _user _pwd; do
  echo $_pwd | saslpasswd2 -p -c -u $maildomain $_user
done < /tmp/passwd
chown postfix.sasl /etc/sasldb2
```

TODO: can we get rsyslog here to forward somewhere else?


