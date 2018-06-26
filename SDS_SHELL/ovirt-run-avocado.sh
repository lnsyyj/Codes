#!/bin/bash

AVOCADO_NODE="192.168.100.219"

function run_avocado() {
        ssh "root@${AVOCADO_NODE}" "pushd /root/avocado-cloudtest && git pull && avocado run SDSMgmtRestAPITest && popd"
        # ssh "root@${AVOCADO_NODE}" "pushd /root/avocado-cloudtest && pwd && ls && popd && pwd"
}

run_avocado
