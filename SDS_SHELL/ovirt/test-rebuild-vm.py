#!/usr/bin/python

import commands
import time
import logging
import logger

# vm status up down

# Initialize logger
#def setup_logger(name, log_file, level=logging.DEBUG, format=False):
#	handler = logging.FileHandler(log_file)
#	if format is True:
#		formatter = logging.Formatter('%(asctime)s %(levelname)s %(message)s')
#		handler.setFormatter(formatter)
#	logger = logging.getLogger(name)
#	logger.setLevel(level)
#	logger.addHandler(handler)
#	return logger
#
#logs = setup_logger("global log", "./rebuild.py.log", level=logging.DEBUG, format=True)

SDS_VM_LIST = ["avodev-controller", "avodev-ceph-1", "avodev-ceph-2", "avodev-ceph-3", "avodev-ceph-4"]
SDS_VM_TEMPLATE_PREFIX =  "Centos7.5-mini-kernel-update"

def check_existence_vm(vm_name):
	cmd = "ovirt-shell -l https://192.168.100.59/tchyp-engine/api -u admin@internal -I --execute-command=\"list vms --query name=\"" + vm_name + "\"\" | grep -v oVirt"
	print cmd
	status, result = commands.getstatusoutput(cmd)
	print result
	if result == "":
		return 0
	else:
		return 1

def check_vm_status(vm_name, expected_state):
	cmd = "ovirt-shell -l https://192.168.100.59/tchyp-engine/api -u admin@internal -I --execute-command=\"show vm " + vm_name + "\" | grep status-state | awk '{print $3}'"
	print cmd
	while 1:
		status, result = commands.getstatusoutput(cmd)
		print vm_name + " : " + result
		time.sleep(2)
		if result == expected_state:
			break
	return result

def up_vm(vm_name):
	cmd = "ovirt-shell -l https://192.168.100.59/tchyp-engine/api -u admin@internal -I --execute-command=\"action vm " + vm_name + " start\""
	print cmd
	status, result = commands.getstatusoutput(cmd)
	print result

def down_vm(vm_name):
	cmd = "ovirt-shell -l https://192.168.100.59/tchyp-engine/api -u admin@internal -I --execute-command=\"action vm " + vm_name + " shutdown\""
	print cmd
	status, result = commands.getstatusoutput(cmd)
	print result

def delete_vm(vm_name):
	cmd = "ovirt-shell -l https://192.168.100.59/tchyp-engine/api -u admin@internal -I --execute-command=\"action vm " + vm_name + " delete\""
	print cmd
	status, result = commands.getstatusoutput(cmd)
	print result

def create_vm(vm_name):
	#cmd = "ovirt-shell -l https://192.168.100.59/tchyp-engine/api -u admin@internal -I --execute-command=\"add vm --name "  + vm_name + " --template-name " + SDS_VM_TEMPLATE_PREFIX + vm_name + " " + "--cluster-name Default\""
	cmd = "ovirt-shell -l https://192.168.100.59/tchyp-engine/api -u admin@internal -I --execute-command=\"add vm --name "  + vm_name + " --template-name " + SDS_VM_TEMPLATE_PREFIX  + " " + "--cluster-name Default\""
	print cmd
	status, result = commands.getstatusoutput(cmd)
	print result

def process():
	# delete vms	
	for x in SDS_VM_LIST:
		result = check_existence_vm(x)
		if result == 1:
			down_vm(x)
			check_vm_status(x,"down")
			delete_vm(x)

	# create vms
	for x in SDS_VM_LIST:
		create_vm(x)
		check_vm_status(x,"down")

	# up vms
	for x in SDS_VM_LIST:
		up_vm(x)
		check_vm_status(x,"up")



if __name__ == '__main__':
	process()
