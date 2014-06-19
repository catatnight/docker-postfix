#!/usr/bin/python

import shlex, subprocess
import argparse

if __name__=="__main__":
  parser = argparse.ArgumentParser(description='Manage postfix container')
  parser.add_argument("execute", choices=['create','start','stop','restart','delete'], help="manage postfix server")
  args = parser.parse_args()

  class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'

  def _execute(signal):
    signal_dict = {"create" : "docker run -p 25:25 --name postfix -d catatnight/postfix", \
                   "start"  : "docker start   postfix", \
                   "stop"   : "docker stop    postfix", \
                   "restart": "docker restart postfix", \
                   "delete" : "docker rm -f   postfix"}
    process = subprocess.Popen(shlex.split(signal_dict[signal]), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if process.stdout.readline():
      if signal == "create": signal += " and start"
      print bcolors.OKGREEN + signal + " postfix successfully" + bcolors.ENDC
    else:
      _err = process.stderr.readline()
      if 'No such container' in _err:
        print bcolors.WARNING + "Please create postfix container first" + bcolors.ENDC
      else: print bcolors.WARNING + _err + bcolors.ENDC
    output = process.communicate()[0]

  _execute(args.execute)