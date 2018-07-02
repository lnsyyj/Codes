# -*- coding:utf-8 -*-
#!/usr/bin/python

import commands
import time
import logging
import logger
import os

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
SDS_VM_IP = ["192.168.100.220", "192.168.100.221", "192.168.100.222", "192.168.100.223", "192.168.100.224"]
SDS_VM_DICT = {"avodev-controller": "192.168.100.220", "avodev-ceph-1": "192.168.100.221", "avodev-ceph-2": "192.168.100.222", "avodev-ceph-3": "192.168.100.223", "avodev-ceph-4": "192.168.100.224"}
# SDS_VM_DICT = {"avodev-controller": "192.168.100.225", "avodev-ceph-1": "192.168.100.225", "avodev-ceph-2": "192.168.100.225", "avodev-ceph-3": "192.168.100.225", "avodev-ceph-4": "192.168.100.225"}
# SDS_VM_TEMPLATE_PREFIX = "2018-06-25-IPv6-auto-"
SDS_VM_TEMPLATE_PREFIX = "2018-06-30-IPv6-auto-"
OVIRT_CONTROLLER_IP = "192.168.100.59"

def check_existence_vm(vm_name):
	cmd = "ovirt-shell -l https://" + OVIRT_CONTROLLER_IP + "/tchyp-engine/api -u admin@internal -I --execute-command=\"list vms --query name=\"" + vm_name + "\"\" | grep -v oVirt"
	print cmd
	status, result = commands.getstatusoutput(cmd)
	print result
	if result == "":
		return False
	else:
		return True

def check_vm_status(vm_name, expected_state):
	cmd = "ovirt-shell -l https://" + OVIRT_CONTROLLER_IP + "/tchyp-engine/api -u admin@internal -I --execute-command=\"show vm " + vm_name + "\" | grep status-state | awk '{print $3}'"
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
	cmd = "ovirt-shell -l https://" + OVIRT_CONTROLLER_IP + "/tchyp-engine/api -u admin@internal -I --execute-command=\"action vm " + vm_name + " start\""
	print cmd
	status, result = commands.getstatusoutput(cmd)
	print result

def down_vm(vm_name):
	cmd = "ovirt-shell -l https://" + OVIRT_CONTROLLER_IP + "/tchyp-engine/api -u admin@internal -I --execute-command=\"action vm " + vm_name + " shutdown\""
	print cmd
	status, result = commands.getstatusoutput(cmd)
	print result

def delete_vm(vm_name):
	cmd = "ovirt-shell -l https://" + OVIRT_CONTROLLER_IP + "/tchyp-engine/api -u admin@internal -I --execute-command=\"action vm " + vm_name + " delete\""
	print cmd
	status, result = commands.getstatusoutput(cmd)
	print result

def create_vm(vm_name):
	cmd = "ovirt-shell -l https://" + OVIRT_CONTROLLER_IP + "/tchyp-engine/api -u admin@internal -I --execute-command=\"add vm --name "  + vm_name + " --template-name " + SDS_VM_TEMPLATE_PREFIX + vm_name + " " + "--cluster-name Default\""
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

def check_vm_network(vm_ip):
	cmd = "ping" + " " + "-c 10" + " " + vm_ip
	print cmd
	status, result = commands.getstatusoutput(cmd)
	print "status : " + str(status)
	print "result : " + str(result)
	if status == 0:
		return True
	else:
		return False

def process():
	
	# vm_start_result = False

	# while True:
	# 	vm_start_status = []
	# 	# delete vms	
	# 	for x in SDS_VM_LIST:
	# 		result = check_existence_vm(x)
	# 		if result == True:
	# 			down_vm(x)
	# 			check_vm_status(x,"down")
	# 			delete_vm(x)



	# 	# create vms
	# 	for x in SDS_VM_LIST:
	# 		create_vm(x)
	# 		check_vm_status(x,"down")

	# 	# up vms
	# 	for x in SDS_VM_LIST:
	# 		up_vm(x)
	# 		vm_start_status.append(check_vm_status(x,"up"))

	# 	vm_start_result = check_vm_start(vm_start_status)
	# 	if vm_start_result == True:
	# 		break
	# =============================================================================
	for x in SDS_VM_DICT.keys():
		while True:
			while check_existence_vm(x):
				down_vm(x)
				check_vm_status(x,"down")
				delete_vm(x)
			
			create_vm(x)
			check_vm_status(x,"down")
			up_vm(x)
			vm_start_status = check_vm_status(x,"up")
			if vm_start_status == True and check_vm_network(SDS_VM_DICT[x]) == True:
				break
	# =============================================================================

	# for x in SDS_VM_DICT.keys():
	# 	print x
	# 	check_vm_network(SDS_VM_DICT[x])



if __name__ == '__main__':
	process()