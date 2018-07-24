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
SDS_VM_TEMPLATE_PREFIX =  "2018-06-22-IPv6-auto-"

def check_existence_vm(vm_name):
	cmd = "ovirt-shell -l https://192.168.100.59/tchyp-engine/api -u admin@internal -I --execute-command=\"list vms --query name=\"" + vm_name + "\"\" | grep -v oVirt"
	print cmd
	status, result = commands.getstatusoutput(cmd)
	print result
	if result == "":
		return False
	else:
		return True

def check_vm_status(vm_name, expected_state):
	cmd = "ovirt-shell -l https://192.168.100.59/tchyp-engine/api -u admin@internal -I --execute-command=\"show vm " + vm_name + "\" | grep status-state | awk '{print $3}'"
	print cmd
	fun_status = False
	start_time = long(time.time())
	while True:
		status, result = commands.getstatusoutput(cmd)
		print vm_name + " : " + result
		time.sleep(2)
		if result == expected_state:
			fun_status = True
			break
		if long(time.time()) - start_time >= 240:
			fun_status = False
			break
	return fun_status

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
	cmd = "ovirt-shell -l https://192.168.100.59/tchyp-engine/api -u admin@internal -I --execute-command=\"add vm --name "  + vm_name + " --template-name " + SDS_VM_TEMPLATE_PREFIX + vm_name + " " + "--cluster-name Default\""
	print cmd
	status, result = commands.getstatusoutput(cmd)
	print result

def check_vm_start(vm_start_status_list = []):
	result = True
	print str(vm_start_status_list)
	for x in vm_start_status_list:
		if x == False:
			result = False
	return result

def process():
	
	vm_start_result = False

	while True:
		vm_start_status = []
		# delete vms	
		for x in SDS_VM_LIST:
			result = check_existence_vm(x)
			if result == True:
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
			vm_start_status.append(check_vm_status(x,"up"))

		vm_start_result = check_vm_start(vm_start_status)
		if vm_start_result == True:
			break

if __name__ == '__main__':
	process()