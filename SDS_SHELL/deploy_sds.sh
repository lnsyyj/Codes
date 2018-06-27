#!/bin/bash

IP=`/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6 | awk '{print $2}' | tr -d "addr:"`
HOSTNAME=`hostname -f`

SDS_PKG_URL="http://******/builds/daily/thinkcloud_sds/master/"
SDS_TAR_PKG="deployment-standalone-daily_20180619_1.tar.gz"

CEPH_NODE_HOST_USER="root"
CEPH_NODE_HOST_PASSWORD="1234567890"

CEPH_NODE_NAME=(plana010 plana011 plana012 plana013)
CEPH_PUBLIC_IP=(192.168.100.98 192.168.100.99 192.168.100.100 192.168.100.101)
CEPH_CLUSTER_IP=(192.168.100.98 192.168.100.99 192.168.100.100 192.168.100.101)
CEPH_MANAGER_IP=(192.168.100.98 192.168.100.99 192.168.100.100 192.168.100.101)


function install_dependent(){
	sudo yum install -y wget expect curl
        curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
        python get-pip.py
        python -m pip install -U pip
        pip install --upgrade setuptools
}

function modify_hosts_file(){
	if ! grep -q "${IP}.*api.inte.lenovo.com" /etc/hosts; then
		echo "${IP}	api.inte.lenovo.com" >> /etc/hosts
	fi
}

function modify_dns(){
	if ! grep -q "nameserver.*10.96.1.18" /etc/resolv.conf; then
		echo "nameserver 10.96.1.18" > /etc/resolv.conf
	fi
}

function download_sds(){
	wget ${SDS_PKG_URL}${SDS_TAR_PKG}
}

function uzip_and_install_sds(){
	tar zxvf ${SDS_TAR_PKG}
	pushd deployment
	
	expect -c "
	set timeout 2000
	spawn ./standalone-setup.sh install
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

function put_license(){
	LOCAL_PATH=`pwd`
	# TOKEN=`keystone token-get | grep "\ id" | awk '{print $4}'`
	# curl -H "LOG_USER: admin" -H "X-Auth-Token: ${TOKEN}" -H "Content-type:application/json"  -X GET http://localhost:9999/v1/license/
	# sleep 5
	source /root/localrc
	echo "${LOCAL_PATH}/ThinkCloud_Storage_license_trial_2018-01-29.zip"
	cephmgmtclient update-license -l "ThinkCloud_Storage_license_trial_2018-01-29.zip"
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

#modify_hosts_file
#modify_dns
#install_dependent
#download_sds
#uzip_and_install_sds
#sleep 5
#put_license
#sleep 5
#create_ceph_cluster
#sleep 5
#add_host_to_cluster
#sleep 130
deploy_ceph_cluster

ENDTIME=`date +'%Y-%m-%d %H:%M:%S'`
START_SECONDS=$(date --date="${STARTTIME}" +%s)
END_SECONDS=$(date --date="${ENDTIME}" +%s)
echo "本次运行时间： "$((END_SECONDS-START_SECONDS))"s"
