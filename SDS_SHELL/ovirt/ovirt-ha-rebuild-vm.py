# -*- coding:utf-8 -*-
#!/usr/bin/python

import commands
import time
import os

SDS_VM_DICT = {"avodev-controller-1": "192.168.100.228", "avodev-controller-2": "192.168.100.229", "avodev-controller-3": "192.168.100.230"}
SDS_VM_TEMPLATE_PREFIX = "2018-07-01-IPv6-auto-"
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
		if long(time.time()) - start_time >= 600:
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

if __name__ == '__main__':
	process()