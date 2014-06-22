docker-postfix
==============

run postfix with smtp authentication (sasldb) in a docker container. 
TLS and OpenDKIM support are optional. 

## Requirement
+ Docker 1.0

## Usage
1. Clone the git repo
  
  ```bash
  $ git clone https://github.com/catatnight/docker-postfix.git
  $ cd docker-postfix
  ```
2. Configure

  ```bash
  $ vim Dockerfile 
  # edit Dockerfile
  ENV maildomain  mail.example.com
  ENV smtp_user   user1:pwd1,user2:pwd2,...,userN:pwdN
  ```
3. Enable TLS(587): save your SSL certificates ```.key``` and ```.crt``` in ```assets/certs/``` 
4. Enable OpenDKIM: save your domain key ```.private``` in ```assets/domainkeys/```
5. Build container and then manage it as root
  
  ```bash
  $ sudo ./build.sh
  $ sudo ./manage.py [create|start|stop|restart|delete]
  ```


## Note
+ You can assign the port of MTA on the host machine to one other than 25 ([postfix how-to](http://www.postfix.org/MULTI_INSTANCE_README.html))
+ Read the reference below to find out how to generate domain keys and add public key to the domain's DNS records 

## Reference
+ [Postfix SASL Howto](http://www.postfix.org/SASL_README.html)
+ [How To Install and Configure DKIM with Postfix on Debian Wheezy](https://www.digitalocean.com/community/articles/how-to-install-and-configure-dkim-with-postfix-on-debian-wheezy)
+ TBD
