#!/usr/bin/python3
import os
from creds import *

os.system(f"sudo docker pull catatnight/postfix")
os.system(f"sudo docker run -p 25:25 -e maildomain=floreana.colorado.edu -e smtp_user={user}:{password} --name postfix -d catatnight/postfix")
os.system(f"sudo docker run -p 25:25 -e maildomain=mail.example.com -e smtp_user={user}:{password} -v /path/to/domainkeys:/etc/opendkim/domainkeys --name postfix -d catatnight/postfix")
os.system(f"sudo docker run -p 587:587 -e maildomain=mail.example.com -e smtp_user={user}:{password} -v /etc/:/etc/postfix/certs --name postfix -d catatnight/postfix")
