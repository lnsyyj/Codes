#!/bin/bash
set -x

COPY_SDS_DEPLOY_SHELL_NODE="192.168.100.220"
COPY_SSH_RSA_PUB_NODE=(192.168.100.220 192.168.100.221 192.168.100.222 192.168.100.223 192.168.100.224)
COPY_LICENSE_FILE_NAME="ThinkCloud_Storage_license_trial_2018-01-29.zip"
COPY_SDS_DEPLOY_SHELL_NAME="ovirt-deploy-sds.sh"

function copy_ssh_rsa_pub() {
        LEN=${#COPY_SSH_RSA_PUB_NODE[@]}
        for ((i=0; i<${LEN}; i++))
        do
                expect -c "
                set timeout 2000
                spawn ssh-copy-id root@${COPY_SSH_RSA_PUB_NODE[${i}]}
                expect {
                        \"*Are you sure you want to continue connecting (yes/no)*\" { send \"yes\r\";exp_continue }
                        \"*root@192.168.100.* password:*\" { send \"1234567890\r\";exp_continue }
                }
                expect eof
                "
        done
}

function copy_shell_and_license_file_to_controller() {
        scp ${COPY_SDS_DEPLOY_SHELL_NAME} ${COPY_LICENSE_FILE_NAME} root@${COPY_SDS_DEPLOY_SHELL_NODE}:/root
}

copy_ssh_rsa_pub
copy_shell_and_license_file_to_controller
