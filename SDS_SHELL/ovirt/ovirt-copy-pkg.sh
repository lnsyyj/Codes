#!/bin/bash
set -x

COPY_SDS_DEPLOY_SHELL_NODE="192.168.100.220"
COPY_SSH_RSA_PUB_NODE=(192.168.100.220 192.168.100.221 192.168.100.222 192.168.100.223 192.168.100.224)
COPY_LICENSE_FILE_NAME="ThinkCloud_Storage_license_trial_2018-06-13.zip"
COPY_SDS_DEPLOY_SHELL_NAME="ovirt-deploy-sds.sh"

COPY_AVOCADO_NODE="192.168.100.219"
COPY_AVOCADO_PARAMETER_FILE_NAME="/home/yujiang/avocado_parameter"
COPY_AVOCADO_CHANGES_FILE_NAME="latest_changes.txt"

SSH_KNOWN_HOSTS_PATH="/root/.ssh/known_hosts"
SDS_PKG_URL="http://10.120.16.212/build/ThinkCloud-SDS/tcs_nfvi_centos7.5/"
SDS_PKG_NAME=$(curl http://10.120.16.212/build/ThinkCloud-SDS/tcs_nfvi_centos7.5/ | grep deployment-standalone | tail -1 | sed 's/.*\(deployment-standalone-daily_[0-9]*_[0-9]*.tar.gz\).*/\1/')
SDS_PKG_DATE=$(echo ${SDS_PKG_NAME} | sed 's/.*deployment-standalone-daily_\([0-9]*_[0-9]*\).tar.gz.*/\1/')

AVOCADO_NODE="192.168.100.219"

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
        scp  /home/yujiang/${COPY_SDS_DEPLOY_SHELL_NAME}  /home/yujiang/${COPY_LICENSE_FILE_NAME} root@${COPY_SDS_DEPLOY_SHELL_NODE}:/root
}

function delete_ssh_known_hosts() {
        LEN=${#COPY_SSH_RSA_PUB_NODE[@]}
        for ((i=0; i<${LEN}; i++))
        do
                sed -i "/.*${COPY_SSH_RSA_PUB_NODE[${i}]}.*/d" ${SSH_KNOWN_HOSTS_PATH}
        done
}

function remote_down_pkg() {
        ssh "root@${COPY_SDS_DEPLOY_SHELL_NODE}" "wget ${SDS_PKG_URL}${SDS_PKG_NAME}"
}

function sds_pkg_uzip() {
        ssh "root@${COPY_SDS_DEPLOY_SHELL_NODE}" "tar zxvf /root/${SDS_PKG_NAME}"
}

function sds_install_dependent() {
        ssh "root@${COPY_SDS_DEPLOY_SHELL_NODE}" "yum install -y expect"
}

function sds_install_pkg() {
        ssh "root@${COPY_SDS_DEPLOY_SHELL_NODE}" "/root/${COPY_SDS_DEPLOY_SHELL_NAME}"
}

function write_avocado_parameter() {
        echo "product_build_number=${SDS_PKG_NAME}" > ${WORKSPACE}/build_info.properties
        echo "sds_pkg_date=${SDS_PKG_DATE}" >> ${WORKSPACE}/build_info.properties
}

function down_avocado_latest_changes_file() {
        ssh "root@${COPY_AVOCADO_NODE}" "wget ${SDS_PKG_URL}${COPY_AVOCADO_CHANGES_FILE_NAME}"
}

function run_avocado() {
    ssh "root@${COPY_AVOCADO_NODE}" "pushd /root/avocado-cloudtest && git pull && python setup.py install && avocado run SDSMgmtRestAPITest --job-results-dir=${WORKSPACE} --product-build-number=${SDS_PKG_NAME} --jenkins-build-url=${BUILD_URL} --new-patch-file=/root/latest_changes.txt && popd"
}

delete_ssh_known_hosts
copy_ssh_rsa_pub
copy_shell_and_license_file_to_controller

remote_down_pkg
sds_pkg_uzip
sds_install_dependent
sds_install_pkg

write_avocado_parameter
down_avocado_latest_changes_file
# run_avocado
