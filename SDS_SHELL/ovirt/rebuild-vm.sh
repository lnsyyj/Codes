#!/bin/bash
set -x
SDS_VM_LIST=(avodev-controller avodev-ceph-1 avodev-ceph-2 avodev-ceph-3 avodev-ceph-4)
AVOCADO=(avodev-avocado)
#VM_STATUS_STATUS_G=

function check_existence_vm() {
  QUERY=`ovirt-shell -l https://192.168.100.59/tchyp-engine/api -u admin@internal -I --execute-command='list vms --query "name=avodev-*"' | grep -v oVirt`
  if [ "${QUERY}" = "" ]; then
    echo "check_existence_vm()  no vms, is NULL"
    return 0
  else
    echo "check_existence_vm() have vms, not NULL"
    return 1
  fi
}

function check_vm_status() {
  VM_NAME=$1
  RESULT=`ovirt-shell -l https://192.168.100.59/tchyp-engine/api -u admin@internal -I --execute-command="show vm ${VM_NAME}" | grep status-state | awk '{print $3}'`
  echo "check_vm_status ${VM_NAME} : ${RESULT}"
  return RESULT
}

function up_vms() {
  echo "up_vms()"
  LEN=${#SDS_VM_LIST[@]}
  for ((i=0; i<${LEN}; i++))
  do
    ovirt-shell -l https://192.168.100.59/tchyp-engine/api -u admin@internal -I --execute-command="action vm ${SDS_VM_LIST[${i}]} start"
  done
}

function down_vms() {
  echo "down_vms()"
  LEN=${#SDS_VM_LIST[@]}
  for ((i=0; i<${LEN}; i++))
  do
    ovirt-shell -l https://192.168.100.59/tchyp-engine/api -u admin@internal -I --execute-command="action vm ${SDS_VM_LIST[${i}]} shutdown"
  done
}

function process() {
  check_existence_vm
  CHECK_EXISTENCE_VM_RESULT=$?
  if [ ${CHECK_EXISTENCE_VM_RESULT} -eq 0 ]; then
    echo "process() CHECK_EXISTENCE_VM_RESULT is 0, No vms"
  else
    echo "process() CHECK_EXISTENCE_VM_RESULT is not 0, have vms"
    LEN=${#SDS_VM_LIST[@]}
    for ((i=0; i<${LEN}; i++))
    do
      #ovirt-shell -l https://192.168.100.59/tchyp-engine/api -u admin@internal -I --execute-command="action vm ${SDS_VM_LIST[${i}]} delete"
      echo ${SDS_VM_LIST[${i}]}
      check_vm_status ${SDS_VM_LIST[${i}]}
      VM_STATUS_RESULT=$?
      echo "process ${VM_STATUS_RESULT}"
    done
  fi
}

process
