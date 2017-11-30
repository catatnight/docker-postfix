docker-postfix
==============

Modified from catatnight/postfix to add virtualhost support

run postfix with smtp authentication (sasldb) in a docker container.
TLS and OpenDKIM support are optional.

## Requirement
+ Docker 1.0

## Installation
1. Build image

	```bash
	$ ./build.sh
	```

## Usage
1. Create postfix container with smtp authentication

	```bash
	$ sudo docker run -p 25:25 \
			-e maildomain=mail.example.com -e smtp_user=user:pwd \
			--name postfix -d benxo/postfix
	# Set multiple user credentials: -e smtp_user=user1:pwd1,user2:pwd2,...,userN:pwdN
	```
2. Enable OpenDKIM: save your domain key ```.private``` in ```/path/to/domainkeys```

	```bash
	$ sudo docker run -p 25:25 \
			-e maildomain=mail.example.com -e smtp_user=user:pwd \
			-v /path/to/domainkeys:/etc/opendkim/domainkeys \
			--name postfix -d ben-o/postfix
	```
3. Enable TLS(587): save your SSL certificates ```.key``` and ```.crt``` to  ```/path/to/certs```

	```bash
	$ sudo docker run -p 587:587 \
			-e maildomain=mail.example.com -e smtp_user=user:pwd \
			-v /path/to/certs:/etc/postfix/certs \
			--name postfix -d benxo/postfix
	```

4. Full example (where you have symlinked certs from letsencrypt into /etc/postfix/certs):

	``` bash
    docker run -p 25:25 -p 587:587 \
        -e maildomain=mail.example.com -e smtp_user=user:pwd \
        -e virtual_domains="mail.example.com test.example.com etc.example.com" \
        -v /etc/postfix/virtual:/etc/postfix/virtual \
        -v /etc/letsencrypt/live:/etc/letsencrypt/live \
        -v /etc/letsencrypt/archive:/etc/letsencrypt/archive \
        -v /etc/postfix/certs:/etc/postfix/certs \
        --name postfix -d benxo/postfix
    ```


## Note
+ Login credential should be set to (`username@mail.example.com`, `password`) in Smtp Client
+ You can assign the port of MTA on the host machine to one other than 25 ([postfix how-to](http://www.postfix.org/MULTI_INSTANCE_README.html))
+ Read the reference below to find out how to generate domain keys and add public key to the domain's DNS records
+ If you want a persistent queue between restarts, you will need to extract an empty spool from /var/spool/postfix inside the container, preserving IDs and permissions!

## Reference
+ [Postfix SASL Howto](http://www.postfix.org/SASL_README.html)
+ [How To Install and Configure DKIM with Postfix on Debian Wheezy](https://www.digitalocean.com/community/articles/how-to-install-and-configure-dkim-with-postfix-on-debian-wheezy)
+ TBD
