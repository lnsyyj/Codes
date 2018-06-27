#!/bin/bash
set -x

COPY_SDS_DEPLOY_SHELL_NODE="192.168.100.220"
COPY_SSH_RSA_PUB_NODE=(192.168.100.220 192.168.100.221 192.168.100.222 192.168.100.223 192.168.100.224)
COPY_LICENSE_FILE_NAME="ThinkCloud_Storage_license_trial_2018-01-29.zip"
COPY_SDS_DEPLOY_SHELL_NAME="ovirt-deploy-sds.sh"

SSH_KNOWN_HOSTS_PATH="/root/.ssh/known_hosts"
SDS_PKG_URL="http://10.120.16.212/build/tcs_nfvi_centos7.5/"
SDS_PKG_NAME=$(curl http://10.120.16.212/build/tcs_nfvi_centos7.5/ | grep $(date +"%Y%m%d") | tail -1 | sed 's/.*\(deployment-standalone-daily_[0-9]*_[0-9]*.tar.gz\).*/\1/')

#DATE=`date +"%Y%m%d"`
DATE="20180622"

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

function sds_temp_release_address() {
        scp "root@10.100.47.161:/home/release/deployment-standalone-daily_${DATE}_1.tar.gz" /tmp/
}

function sds_temp_copy_release_pkg() {
        scp "/tmp/deployment-standalone-daily_${DATE}_1.tar.gz" "root@${COPY_SDS_DEPLOY_SHELL_NODE}:/root/"
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

delete_ssh_known_hosts
copy_ssh_rsa_pub
copy_shell_and_license_file_to_controller
# sds_temp_release_address
# sds_temp_copy_release_pkg
remote_down_pkg
sds_pkg_uzip
sds_install_dependent
sds_install_pkg