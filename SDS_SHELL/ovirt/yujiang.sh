#!/bin/bash
set -x


COPY_SSH_RSA_PUB_NODE=(192.168.100.228 192.168.100.229 192.168.100.230)

HA_NODE_IP=(2008:20c:20c:20c:20c:29ff:0:228 2008:20c:20c:20c:20c:29ff:0:229 2008:20c:20c:20c:20c:29ff:0:230)
SSH_KNOWN_HOSTS_PATH="/root/.ssh/known_hosts"
SDS_PKG_URL="http://10.120.16.212/build/tcs_nfvi_centos7.5/"
SDS_PKG_NAME=$(curl http://10.120.16.212/build/tcs_nfvi_centos7.5/ | grep deployment-standalone | tail -1 | sed 's/.*\(deployment-standalone-daily_[0-9]*_[0-9]*.tar.gz\).*/\1/')
SDS_PKG_DATE=$(echo ${SDS_PKG_NAME} | sed 's/.*deployment-standalone-daily_\([0-9]*_[0-9]*\).tar.gz.*/\1/')


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

function delete_ssh_known_hosts() {
        LEN=${#COPY_SSH_RSA_PUB_NODE[@]}
        for ((i=0; i<${LEN}; i++))
        do
                sed -i "/.*${COPY_SSH_RSA_PUB_NODE[${i}]}.*/d" ${SSH_KNOWN_HOSTS_PATH}
        done
}

function copy_shell_and_license_file_to_controller() {
        scp  /home/yujiang/${COPY_SDS_DEPLOY_SHELL_NAME}  /home/yujiang/${COPY_LICENSE_FILE_NAME} root@${COPY_SDS_DEPLOY_SHELL_NODE}:/root
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
# copy_shell_and_license_file_to_controller

# remote_down_pkg
# sds_pkg_uzip
# sds_install_dependent
# sds_install_pkg