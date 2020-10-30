import getopt
import sys
import re
import subprocess
import time
import json
import os
from jinja2 import Template

#template_udev_content = Template('KERNEL=="sd*",ACTION=="remove", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ENV{ID_SERIAL}=="{{ VAR_ID_SERIAL }}", RUN+="/bin/sh -c \'/usr/bin/python /etc/udev/rules.d/udev_stop_osd.py $name 2>/var/log/ceph/ceph-remove-udev.log 1>&2\'"')

template_udev_content = Template('KERNEL=="sd*",ACTION=="remove", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ENV{ID_SERIAL}=="{{ VAR_ID_SERIAL }}", RUN+="/bin/sh -c \'systemctl stop ceph-osd@{{ VAR_OSD_ID }}.service 2>/var/log/ceph/ceph-remove-udev.log 1>&2\'"')
#template_udev_content_add = Template('KERNEL=="sd*",ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ENV{ID_SERIAL}=="{{ VAR_ID_SERIAL }}", RUN+="/bin/sh -c \'sleep 60;systemctl reset-failed;systemctl start ceph-osd@{{ VAR_OSD_ID }}.service;systemctl reset-failed;systemctl start ceph-osd@{{ VAR_OSD_ID }}.services;\'"')

template_udev_file_name_prefix = Template('80-ceph-osd-remove-{{ VAR_DEVICES_NAME }}.rules')
#template_udev_add_file_name_prefix = Template('80-ceph-osd-add-{{ VAR_DEVICES_NAME }}.rules')

def usage(filename):
  print('usage: python {} [-h | --help]'.format(filename))
  print('usage: python {} [-g | --generate]    Generate all disk devices udev rule'.format(filename))

def generate_disk_udev_rule():
  cmd = "ceph-volume lvm list --format json"
  osd_id = ""
  devices_name = ""
  serial_id = ""
  result, _ = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True).communicate()
  result_json = json.loads(result)
  for key in result_json:
    for devices in result_json[key]:
      osd_id = key
      devices_name = ''.join(devices["devices"]).strip()
      print("osd id: %s  devices_name:%s" %(osd_id,devices_name))
      cmd_udevadm = 'udevadm info --query=all --name={cmd_devices_name} '.format(cmd_devices_name=devices_name)  + "| grep -w ID_SERIAL "  + " | awk -F \"=\" \'{print $2}\'"
      result_cmd_udevadm, _ = subprocess.Popen(cmd_udevadm, stdout=subprocess.PIPE, shell=True).communicate()
      print result_cmd_udevadm.strip().replace("\n", "")
      #content = template_udev_content.render(VAR_ID_SERIAL=result_cmd_udevadm.strip().replace("\n", ""))
      content = template_udev_content.render(VAR_ID_SERIAL=result_cmd_udevadm.strip().replace("\n", ""), VAR_OSD_ID=osd_id)
      devices_name = devices_name.split('/')[-1]
      print devices_name
      file_name = template_udev_file_name_prefix.render(VAR_DEVICES_NAME=devices_name)
      with open(file_name,'w') as fp:
            fp.write(content)

#      content = template_udev_content_add.render(VAR_ID_SERIAL=result_cmd_udevadm.strip().replace("\n", ""), VAR_OSD_ID=osd_id)
#      file_name = template_udev_add_file_name_prefix.render(VAR_DEVICES_NAME=devices_name)
#      with open(file_name,'w') as fp:
#            fp.write(content)

def reload_udev_rule():
  cmd = "udevadm control --reload"
  subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True).communicate()

def main(filename, *argv):
  opts, args = getopt.getopt(argv, 'hg', ['help', 'generate'])

  for opt, arg in opts:
    if opt in ('-h', '--help'):
      usage(filename)
      return 0
    if opt in ('-g', '--generate'):
      generate_disk_udev_rule()
      reload_udev_rule()
      return 0
  return 0

if __name__ == '__main__':
  sys.exit(main(*sys.argv))
