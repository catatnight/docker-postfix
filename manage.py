#!/usr/bin/python

import shlex, subprocess
import argparse

if __name__=="__main__":
  app_name = 'postfix'
  
  parser = argparse.ArgumentParser(description='Manage %s container' % app_name)
  parser.add_argument("execute", choices=['create','start','stop','restart','delete'], help='manage %s server' % app_name)
  args = parser.parse_args()

  class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'

  def _execute(signal):
    signal_dict = {"create" : "docker run --net=host --name {0} -d catatnight/{0}".format(app_name), \
                   "start"  : "docker start   %s" % app_name, \
                   "stop"   : "docker stop    %s" % app_name, \
                   "restart": "docker restart %s" % app_name, \
                   "delete" : "docker rm -f   %s" % app_name}
    process = subprocess.Popen(shlex.split(signal_dict[signal]), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if process.stdout.readline():
      if signal == "create": signal += " and start"
      print bcolors.OKGREEN + signal + " %s successfully" % app_name + bcolors.ENDC
    else:
      _err = process.stderr.readline()
      if 'No such container' in _err:
        print bcolors.WARNING + "Please create %s container first" % app_name + bcolors.ENDC
      else: print bcolors.WARNING + _err + bcolors.ENDC
    output = process.communicate()[0]

  _execute(args.execute)