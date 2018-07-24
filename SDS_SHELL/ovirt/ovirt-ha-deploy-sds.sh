#!/bin/bash

CEPH_NODE_HOST_USER="root"
CEPH_NODE_HOST_PASSWORD="1234567890"

VIP="2008:20c:20c:20c:20c:29ff:0:231"
CEPH_NODE_NAME=(avodev-ceph-1 avodev-ceph-2 avodev-ceph-3)
CEPH_PUBLIC_IP=(2008:20c:20c:20c:20c:29ff:0:228 2008:20c:20c:20c:20c:29ff:0:229 2008:20c:20c:20c:20c:29ff:0:230)
CEPH_CLUSTER_IP=(2008:20c:20c:20c:20c:29ff:0:228 2008:20c:20c:20c:20c:29ff:0:229 2008:20c:20c:20c:20c:29ff:0:230)
CEPH_MANAGER_IP=(2008:20c:20c:20c:20c:29ff:0:228 2008:20c:20c:20c:20c:29ff:0:229 2008:20c:20c:20c:20c:29ff:0:230)

function install_sds(){
	pushd deployment
	
	expect -c "
	set timeout 2000
	spawn ./standalone-setup.sh install -ipv6 -s
	expect {
		\"*Please enter the mysql root password*\" { send \"SDS_Passw0rd\r\";exp_continue }
		\"*Please enter the zabbix db user zabbix* password\" { send \"SDS_Passw0rd\r\";exp_continue }
		\"*Please enter the keystone db user keystone* password*\" { send \"SDS_Passw0rd\r\";exp_continue }
		\"*Please enter the system user admin* password*\" { send \"Admin_123456\r\";exp_continue }
		\"*Please enter the Rabbit user storage* password*\" { send \"SDS_Passw0rd\r\";exp_continue }
		\"*Please enter the storagemgmt db user storage* password*\" { send \"SDS_Passw0rd\r\" }
	}
	expect eof
	"

	popd
}

function conf_ha() {
	pushd deployment/ha_config
	sed -i "s/\(ManageNetwork=\).*/\1\"2008:20c:20c:20c:20c:29ff:0:220\"/g" install_config
	sed -i "s/\(PublicNetwork=\).*/\1\"2008:20c:20c:20c:20c:29ff:0:220\"/g" install_config
	cat install_config
	./all_in_one.sh
	popd
}

function put_license(){
	LOCAL_PATH=`pwd`
	source /root/localrc
	echo "${LOCAL_PATH}/ThinkCloud_Storage_license_trial_2018-06-13.zip"
	cephmgmtclient update-license -l "ThinkCloud_Storage_license_trial_2018-06-13.zip"
}

function create_ceph_cluster(){
	source /root/localrc
	cephmgmtclient create-cluster --name ceph-cluster-1 --addr vm
}

function add_host_to_cluster(){
	source /root/localrc
	LEN=${#CEPH_NODE_NAME[@]}
	for ((i=0; i<${LEN}; i++))
	do
		cephmgmtclient create-server --id 1 --name ${CEPH_NODE_NAME[${i}]} --publicip ${CEPH_PUBLIC_IP[${i}]} --clusterip ${CEPH_CLUSTER_IP[${i}]} --managerip ${CEPH_MANAGER_IP[${i}]}  --server_user ${CEPH_NODE_HOST_USER} --server_pass ${CEPH_NODE_HOST_PASSWORD} --rack_id 1
	done
}

function deploy_ceph_cluster(){
	source /root/localrc
	cephmgmtclient deploy-cluster 1
}

STARTTIME=`date +'%Y-%m-%d %H:%M:%S'`

# install_sds
# sleep 5
# conf_ha
# sleep 5
put_license
sleep 5
create_ceph_cluster
sleep 5
add_host_to_cluster
sleep 300
deploy_ceph_cluster
sleep 300

ENDTIME=`date +'%Y-%m-%d %H:%M:%S'`
START_SECONDS=$(date --date="${STARTTIME}" +%s)
END_SECONDS=$(date --date="${ENDTIME}" +%s)
echo "本次运行时间： "$((END_SECONDS-START_SECONDS))"s"
