#!/bin/bash
set -x

COPY_SDS_DEPLOY_SHELL_NODE="192.168.100.220"
COPY_SSH_RSA_PUB_NODE=(192.168.100.228 192.168.100.229 192.168.100.230)
VIP=2008:20c:20c:20c:20c:29ff:0:231
COPY_SSH_RSA_PUB_NODE_IPV6_HOST_NAME=(ha-avodev-controller-1 ha-avodev-controller-2 ha-avodev-controller-3)
COPY_SSH_RSA_PUB_NODE_IPV6=(2008:20c:20c:20c:20c:29ff:0:228 2008:20c:20c:20c:20c:29ff:0:229 2008:20c:20c:20c:20c:29ff:0:230)

COPY_LICENSE_FILE_NAME="ThinkCloud_Storage_license_trial_2018-06-13.zip"
COPY_SDS_DEPLOY_SHELL_NAME="ovirt-ha-deploy-sds.sh"

COPY_AVOCADO_NODE="192.168.100.219"
COPY_AVOCADO_PARAMETER_FILE_NAME="/home/yujiang/avocado_parameter"
COPY_AVOCADO_CHANGES_FILE_NAME="latest_changes.txt"

SSH_KNOWN_HOSTS_PATH="/root/.ssh/known_hosts"
SDS_PKG_URL="http://10.120.16.212/build/ThinkCloud-SDS/tcs_nfvi_centos7.5/"
SDS_PKG_NAME=$(curl http://10.120.16.212/build/ThinkCloud-SDS/tcs_nfvi_centos7.5/ | grep deployment-standalone | tail -1 | sed 's/.*\(deployment-standalone-daily_[0-9]*_[0-9]*.tar.gz\).*/\1/')
SDS_PKG_DATE=$(echo ${SDS_PKG_NAME} | sed 's/.*deployment-standalone-daily_\([0-9]*_[0-9]*\).tar.gz.*/\1/')

function delete_ssh_known_hosts() {
        LEN=${#COPY_SSH_RSA_PUB_NODE[@]}
        for ((i=0; i<${LEN}; i++))
        do
                sed -i "/.*${COPY_SSH_RSA_PUB_NODE[${i}]}.*/d" ${SSH_KNOWN_HOSTS_PATH}
        done
}

function copy_ssh_rsa_pub() {
        LEN=${#COPY_SSH_RSA_PUB_NODE[@]}
        for ((i=0; i<${LEN}; i++))
        do
                expect -c "
                set timeout 2000
                spawn ssh-copy-id root@${COPY_SSH_RSA_PUB_NODE[${i}]}
                expect {
                        \"*Are you sure you want to continue connecting*\" { send \"yes\r\";exp_continue }
                        \"*root@192.168.100.* password:*\" { send \"1234567890\r\";exp_continue }
                }
                expect eof
                "
        done
}

function remote_down_sds_tar_pkg() {
        LEN=${#COPY_SSH_RSA_PUB_NODE[@]}
        for ((i=0; i<${LEN}; i++))
        do
            ssh "root@${COPY_SSH_RSA_PUB_NODE[${i}]}" "wget ${SDS_PKG_URL}${SDS_PKG_NAME}"
        done
}

function remote_sds_pkg_uzip() {
        LEN=${#COPY_SSH_RSA_PUB_NODE[@]}
        for ((i=0; i<${LEN}; i++))
        do
            ssh "root@${COPY_SSH_RSA_PUB_NODE[${i}]}" "tar zxvf /root/${SDS_PKG_NAME}"
        done
}

function copy_shell_and_license_file_to_controller() {
        LEN=${#COPY_SSH_RSA_PUB_NODE[@]}
        for ((i=0; i<${LEN}; i++))
        do
            scp  /home/yujiang/${COPY_SDS_DEPLOY_SHELL_NAME}  /home/yujiang/${COPY_LICENSE_FILE_NAME} root@${COPY_SSH_RSA_PUB_NODE[${i}]}:/root
        done
}

function remote_sds_install_dependent() {
        LEN=${#COPY_SSH_RSA_PUB_NODE[@]}
        for ((i=0; i<${LEN}; i++))
        do
            ssh "root@${COPY_SSH_RSA_PUB_NODE[${i}]}" "yum install -y expect"
        done
}

function remote_sds_install_pkg() {
        LEN=${#COPY_SSH_RSA_PUB_NODE[@]}
        for ((i=0; i<${LEN}; i++))
        do
            ssh "root@${COPY_SSH_RSA_PUB_NODE[${i}]}" "/root/deployment/standalone-setup.sh install -ipv6 -s"
        done
}

function generate_sshkey() {
        LEN=${#COPY_SSH_RSA_PUB_NODE[@]}
        for ((i=0; i<${LEN}; i++))
        do
                expect -c "
                set timeout 2000
                spawn ssh root@${COPY_SSH_RSA_PUB_NODE[${i}]} ssh-keygen
                expect {
                    \"*Enter file in which to save the key*\" { send \"\r\";exp_continue }
                    \"*Enter passphrase*\" { send \"\r\";exp_continue }
                    \"*Enter same passphrase again*\" { send \"\r\";exp_continue }
                    \"*Overwrite*\" { send \"n\r\";exp_continue }
                }
                expect eof
                "
        done
}

function remote_mutual_trust_between_nodes() {
        LEN=${#COPY_SSH_RSA_PUB_NODE[@]}
        for ((i=0; i<${LEN}; i++))
        do
                expect -c "
                set timeout 2000
                spawn ssh root@${COPY_SSH_RSA_PUB_NODE[${i}]} ssh-copy-id root@${COPY_SSH_RSA_PUB_NODE_IPV6[${i}]}
                expect {
                    \"*Are you sure you want to continue connecting (yes/no)*\" { send \"yes\r\";exp_continue }
                    \"*root@192.168.100.* password:*\" { send \"1234567890\r\";exp_continue }
                }
                expect eof
                "
        done
}

function remote_modify_hosts_file() {
        LEN=${#COPY_SSH_RSA_PUB_NODE[@]}
        for ((i=0; i<${LEN}; i++))
        do
            for ((j=0; j<${LEN}; j++))
            do
                ssh "root@${COPY_SSH_RSA_PUB_NODE[${i}]}" "echo ${COPY_SSH_RSA_PUB_NODE_IPV6[${j}]} ${COPY_SSH_RSA_PUB_NODE_IPV6_HOST_NAME[${j}]} >> /etc/hosts"
            done
        done
}

function remote_modify_sds_all_in_one_conf() {
        LEN=${#COPY_SSH_RSA_PUB_NODE[@]}
        for ((i=0,j=${LEN}-1; i<${LEN}; i++,j--))
        do
            ssh "root@${COPY_SSH_RSA_PUB_NODE[${i}]}" "pushd deployment/ha_config;sed -i \"s/\(HA_flag=\).*/\1\"YES\"/g\" install_config;sed -i \"s/\(ManageNetwork=\).*/\1\"${VIP}\"/g\" install_config;sed -i \"s/\(PublicNetwork=\).*/\1\"${VIP}\"/g\" install_config;popd"
            ssh "root@${COPY_SSH_RSA_PUB_NODE[${i}]}" "pushd deployment/ha_config;sed -i \"s/\(this_node=\).*/\1${COPY_SSH_RSA_PUB_NODE_IPV6[${i}]}/g\" install_config;popd"
            ssh "root@${COPY_SSH_RSA_PUB_NODE[${i}]}" "pushd deployment/ha_config;sed -i \"s/\(VIP1=\).*/\1\"${VIP}\"/g\" install_config;popd"
            ssh "root@${COPY_SSH_RSA_PUB_NODE[${i}]}" "pushd deployment/ha_config;sed -i \"s/\(CIDR1=\).*/\1\"64\"/g\" install_config;popd"
        done
        # ha-node-1
        ssh "root@${COPY_SSH_RSA_PUB_NODE[0]}" "pushd deployment/ha_config;ls;sed -i \"s/\(other_node2=\).*/\1${COPY_SSH_RSA_PUB_NODE_IPV6[1]}/g\" install_config;popd"
        ssh "root@${COPY_SSH_RSA_PUB_NODE[0]}" "pushd deployment/ha_config;ls;sed -i \"s/\(other_node3=\).*/\1${COPY_SSH_RSA_PUB_NODE_IPV6[2]}/g\" install_config;popd"
        # ha-node-2
        ssh "root@${COPY_SSH_RSA_PUB_NODE[1]}" "pushd deployment/ha_config;ls;sed -i \"s/\(other_node2=\).*/\1${COPY_SSH_RSA_PUB_NODE_IPV6[0]}/g\" install_config;popd"
        ssh "root@${COPY_SSH_RSA_PUB_NODE[1]}" "pushd deployment/ha_config;ls;sed -i \"s/\(other_node3=\).*/\1${COPY_SSH_RSA_PUB_NODE_IPV6[2]}/g\" install_config;popd"
        # ha-node-3
        ssh "root@${COPY_SSH_RSA_PUB_NODE[2]}" "pushd deployment/ha_config;ls;sed -i \"s/\(other_node2=\).*/\1${COPY_SSH_RSA_PUB_NODE_IPV6[0]}/g\" install_config;popd"
        ssh "root@${COPY_SSH_RSA_PUB_NODE[2]}" "pushd deployment/ha_config;ls;sed -i \"s/\(other_node3=\).*/\1${COPY_SSH_RSA_PUB_NODE_IPV6[1]}/g\" install_config;popd"

}

function remote_exec_all_in_one() {
    ssh "root@${COPY_SSH_RSA_PUB_NODE[0]}" "pushd deployment/ha_config;./all_in_one.sh;popd"
}

function remote_import_sds_license() {
    ssh "root@${COPY_SSH_RSA_PUB_NODE[0]}" "source /root/localrc;"
}

function remote_galera_start_manual() {
    ssh "root@${COPY_SSH_RSA_PUB_NODE[0]}" "/root/deployment/ha_config/ha_files/galera_start_manual.sh"
}

function remote_deploy_ceph() {
    ssh "root@${COPY_SSH_RSA_PUB_NODE[0]}" "/root/${COPY_SDS_DEPLOY_SHELL_NAME}"
}

function write_avocado_parameter() {
        echo "product_build_number=${SDS_PKG_NAME}" > ${WORKSPACE}/build_info.properties
        echo "sds_pkg_date=${SDS_PKG_DATE}" >> ${WORKSPACE}/build_info.properties
}

function down_avocado_latest_changes_file() {
        ssh "root@${COPY_AVOCADO_NODE}" "wget ${SDS_PKG_URL}${COPY_AVOCADO_CHANGES_FILE_NAME}"
}

# delete_ssh_known_hosts
# copy_ssh_rsa_pub
# copy_shell_and_license_file_to_controller
# remote_sds_install_dependent
# generate_sshkey
# remote_mutual_trust_between_nodes
# remote_modify_hosts_file
# remote_down_sds_tar_pkg
# remote_sds_pkg_uzip
# remote_modify_sds_all_in_one_conf
# remote_sds_install_pkg

# remote_exec_all_in_one
remote_galera_start_manual
# remote_deploy_ceph