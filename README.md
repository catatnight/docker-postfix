[![Docker Build Status](https://img.shields.io/docker/cloud/build/kingsquare/postfix?style=flat-square)](https://hub.docker.com/r/kingsquare/postfix/builds)
[![Docker Cloud Automated build](https://img.shields.io/docker/cloud/automated/kingsquare/postfix?style=flat-square)](https://hub.docker.com/r/kingsquare/postfix/builds)
[![GitHub Tag](https://img.shields.io/github/v/tag/kingsquare/docker-postfix?style=flat-square)](https://github.com/kingsquare/docker-postfix)
[![GitHub License](https://img.shields.io/github/license/kingsquare/docker-postfix?style=flat-square)](https://github.com/kingsquare/docker-postfix)
[![GitHub language count](https://img.shields.io/github/languages/count/kingsquare/docker-postfix?style=flat-square)](https://github.com/kingsquare/docker-postfix)
[![GitHub top language](https://img.shields.io/github/languages/top/kingsquare/docker-postfix?style=flat-square)](https://github.com/kingsquare/docker-postfix)
[![Docker Pulls](https://img.shields.io/docker/pulls/kingsquare/postfix?style=flat-square)](https://hub.docker.com/r/kingsquare/postfix)
[![Docker Stars](https://img.shields.io/docker/stars/kingsquare/postfix?style=flat-square)](https://hub.docker.com/r/kingsquare/postfix)

# docker-postfix

Postfix in a container with optional SMTP authentication (sasldb), DKIM support, TLS support.

## Installation

Pull from docker hub

    docker pull kingsquare/postfix

Build local image from repo

    docker build -t kingsquare/postfix https://github.com/kingsquare/docker-postfix.git

## Usage

1. Create postfix container with smtp authentication

	```bash
	docker run \
	    -p 25:25 \
        -p 587:587 \
        -e maildomain=mail.example.com \
        -e smtp_user=user:pwd \
        --name postfix \
        -d kingsquare/postfix

	# Set multiple user credentials: -e smtp_user=user1:pwd1,user2:pwd2,...,userN:pwdN
	```

1. Create postfix container with smtp authentication

	```bash
	docker run \
	    -p 25:25 \
        -p 587:587 \
        -e maildomain=mail.example.com \
        -e smtp_user=/etc/postfix/smtp_user \
        --name postfix \
        -d kingsquare/postfix

	# Set multiple user credentials: -e smtp_user=user1:pwd1,user2:pwd2,...,userN:pwdN

	# Set multiple user credentials from file: -v /some/file:/etc/postfix/smtp_users

1. Enable OpenDKIM: save your domain key `.private` in `/path/to/domainkeys`

	```bash
	docker run \
	    -p 25:25 \
        -p 587:587 \
        -e maildomain=mail.example.com \
        -e smtp_user=user:pwd \
        -e dkimselector=mail \
        -v /path/to/domainkeys:/etc/opendkim/domainkeys \
        --name postfix \
        -d kingsquare/postfix
	```

1. Enable OpenDKIM: override all config with custom directory

	```bash
	docker run \
	    -p 25:25 \
	    -p 587:587 \
        -e maildomain=mail.example.com \
        -e smtp_user=user:pwd \
        -e dkimselector=mail \
        -v /path/to/etc/opendkim:/etc/opendkim \
        --name postfix \
        -d kingsquare/postfix
	```

1. Enable TLS: add your SSL certificates `.key` and `.crt` files to  `/path/to/certs`.
    If you have a combined crt+key file then make sure it's extension is `.crt`

    ```bash
    docker run \
	    -p 25:25 \
        -p 587:587 \
        -e maildomain=mail.example.com \
        -e smtp_user=user:pwd \
        -v /path/to/certs:/etc/postfix/certs \
        --name postfix \
        -d kingsquare/postfix
    ```

1. Optional Postfix configuration passed using environment variables:

    - `inet_protocols`

      this allows postfix to limit the outgoing internet protocols to the given param (`ipv4`, `ipv6`, `all` (=default))

    - `message_size_limit`

      To in-/decrease the message size limit, set this to the required amount in **bytes** (default: `10240000` = 10MB)

  To use this i.e. `-e message_size_limit=51200000` to increase the limit to 50MB

## Notes

+ Login credential should be set to (`username@mail.example.com`, `password`) in SMTP Client
+ You can assign the port of MTA on the host machine to one other than 25 ([postfix how-to](http://www.postfix.org/MULTI_INSTANCE_README.html))
+ Read the reference below to find out how to generate domain keys and add public key to the domain's DNS records

## Reference
+ [Postfix SASL Howto](http://www.postfix.org/SASL_README.html)
+ [How To Install and Configure DKIM with Postfix on Debian Wheezy](https://www.digitalocean.com/community/articles/how-to-install-and-configure-dkim-with-postfix-on-debian-wheezy)
+ Based on [catatnight/docker-postfix](https://github.com/catatnight/docker-postfix)

