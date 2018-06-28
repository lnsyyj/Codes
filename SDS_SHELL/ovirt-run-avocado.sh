#!/bin/bash

AVOCADO_NODE="192.168.100.219"

function run_avocado() {
        ssh "root@${AVOCADO_NODE}" "pushd /root/avocado-cloudtest && git pull && python setup.py install && avocado run SDSMgmtRestAPITest && popd"
        # ssh "root@${AVOCADO_NODE}" "pushd /root/avocado-cloudtest && git pull && git reset --hard f9ecadc0d4032b3b67fd889c2060df3b37a373b9 && python setup.py install && avocado run SDSMgmtRestAPITest && popd"
}

run_avocado
