docker-postfix
==============

run postfix with smtp authentication (sasldb) in a docker container.
TLS and OpenDKIM support are optional.

This image also supports relaying, per
http://www.postfix.org/STANDARD_CONFIGURATION_README.html and
https://linode.com/docs/email/postfix/postfix-smtp-debian7/

## Requirement
+ Docker 1.0

## Installation
1. Build image

	```bash
	$ sudo docker pull catatnight/postfix
	```

## Usage
1. Create postfix container with smtp authentication

	```bash
	$ sudo docker run -p 25:25 \
			-e maildomain=mail.example.com -e origin=example.com \
			-e smtp_user=user:pwd \
			-e networks="10.0.0.0/8" -e relay_host=some.relay.host \
			-e relay_user=tony:banana \
			--name postfix -d vivvo/postfix-relay
	# Set multiple user credentials: -e smtp_user=user1:pwd1,user2:pwd2,...,userN:pwdN
	```

Note that the following were in the original repository, but I haven't tried them out on this one.

2. Enable OpenDKIM: save your domain key ```.private``` in ```/path/to/domainkeys```

	```bash
	$ sudo docker run -p 25:25 \
			-e maildomain=mail.example.com -e smtp_user=user:pwd \
			-v /path/to/domainkeys:/etc/opendkim/domainkeys \
			--name postfix -d vivvo/postfix-relay
	```
3. Enable TLS(587): save your SSL certificates ```.key``` and ```.crt``` to  ```/path/to/certs```

	```bash
	$ sudo docker run -p 587:587 \
			-e maildomain=mail.example.com -e smtp_user=user:pwd \
			-v /path/to/certs:/etc/postfix/certs \
			--name postfix -d vivvo/postfix-relay
	```

## Note
+ Login credential should be set to (`username@mail.example.com`, `password`) in Smtp Client
+ You can assign the port of MTA on the host machine to one other than 25 ([postfix how-to](http://www.postfix.org/MULTI_INSTANCE_README.html))
+ Read the reference below to find out how to generate domain keys and add public key to the domain's DNS records

## Reference
+ [Postfix SASL Howto](http://www.postfix.org/SASL_README.html)
+ [How To Install and Configure DKIM with Postfix on Debian Wheezy](https://www.digitalocean.com/community/articles/how-to-install-and-configure-dkim-with-postfix-on-debian-wheezy)
+ TBD
