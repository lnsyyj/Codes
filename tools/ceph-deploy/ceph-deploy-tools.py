import getopt
import sys
import re
import subprocess
import time
import json
import os
import socket

hostname = socket.gethostname()

def usage(filename):
  print('usage: python {} [-h | --help]'.format(filename))
  print('usage: python {} [-i | --installcephdeploy]    Install ceph-deploy on this machine'.format(filename))
  print('usage: python {} [-c | --copycephkeyring]    copy ceph keyring  this machine'.format(filename))

def print_info(stdout, stderr):
  if stderr:
    print stderr
  if stdout:
    print stdout

def install_cephdeploy():
  cmd = "apt-get install ./ceph-deploy_2.0.1_all.deb"
  stdout, stderr = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True).communicate()
  print_info(stdout, stderr)

def copy_cephkeyring():
  ceph_mon_keyring_cmd = "cp " + "/var/lib/ceph/mon/ceph-" + hostname + "/keyring" + " ./ceph.mon.keyring"
  ceph_bootstrap_mds_keyring_cmd = "cp " + "/var/lib/ceph/bootstrap-mds/ceph.keyring" + " ./ceph.bootstrap-mds.keyring"
  ceph_bootstrap_mgr_keyring_cmd = "cp " + "/var/lib/ceph/bootstrap-mgr/ceph.keyring" + " ./ceph.bootstrap-mgr.keyring"
  ceph_bootstrap_osd_keyring_cmd = "cp " + "/var/lib/ceph/bootstrap-osd/ceph.keyring" + " ./ceph.bootstrap-osd.keyring"
  ceph_bootstrap_rgw_keyring_cmd = "cp " + "/var/lib/ceph/bootstrap-rgw/ceph.keyring" + " ./ceph.bootstrap-rgw.keyring"
  cmd = [
    'cp /etc/ceph/ceph.conf ./ceph.conf',
    'cp /etc/ceph/ceph.client.admin.keyring ./ceph.client.admin.keyring',
  ]
  cmd.append(ceph_mon_keyring_cmd)
  cmd.append(ceph_bootstrap_mds_keyring_cmd)
  cmd.append(ceph_bootstrap_mgr_keyring_cmd)
  cmd.append(ceph_bootstrap_osd_keyring_cmd)
  cmd.append(ceph_bootstrap_rgw_keyring_cmd)

  for i in cmd:
    stdout, stderr = subprocess.Popen(i, stdout=subprocess.PIPE, shell=True).communicate()
    print_info(stdout, stderr)

def main(filename, *argv):
  opts, args = getopt.getopt(argv, 'hic', ['help', 'installcephdeploy', 'copycephkeyring'])

  for opt, arg in opts:
    if opt in ('-h', '--help'):
      usage(filename)
    if opt in ('-i', '--installcephdeploy'):
      install_cephdeploy()
    if opt in ('-c', '--copycephkeyring'):
      copy_cephkeyring()

if __name__ == '__main__':
  sys.exit(main(*sys.argv))
