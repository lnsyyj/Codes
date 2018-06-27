#!/bin/bash

AVOCADO_NODE="192.168.100.219"

function run_avocado() {
        ssh "root@${AVOCADO_NODE}" "pushd /root/avocado-cloudtest && git pull && python setup.py install && avocado run SDSMgmtRestAPITest && popd"
}

run_avocado
