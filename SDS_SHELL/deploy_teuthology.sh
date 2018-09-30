#!/bin/bash
set -x

PUBLIC_IP="10.121.8.93"

NETWORK_DEVICE_NAME="eth0"
IP=$(ifconfig ${NETWORK_DEVICE_NAME} | sed -n '/inet /p' | sed 's/inet \([0-9.]\+\) .*$/\1/' | sed 's/\ //g')
echo ${IP}
HOST_NAME=`hostname -s`

CEPH_NODE_HOSTNAME=(plana003 plana004 plana005 plana006)
CEPH_NODE_HOSTIP=(192.168.0.17 192.168.0.25 192.168.0.15 192.168.0.24)
CEPH_NODE_PASSWORD="yujiang2"

PIP_TIMEOUT="600"

function modify_dns() {
	if ! grep -q "nameserver.*10.96.1.18" /etc/resolv.conf; then
		echo "nameserver 10.96.1.18" > /etc/resolv.conf
	fi
}

function modify_hostname() {
	echo "${HOST_NAME}.test.lenovo.com" > /etc/hostname
}

function modify_hosts_file() {
	echo "${IP} ${HOST_NAME} ${HOST_NAME}.test.lenovo.com" >> /etc/hosts
	LEN=${#CEPH_NODE_HOSTNAME[@]}
	for ((i=0; i<${LEN}; i++))
	do
		echo "${CEPH_NODE_HOSTIP[${i}]} ${CEPH_NODE_HOSTNAME[${i}]} ${CEPH_NODE_HOSTNAME[${i}]}.test.lenovo.com" >> /etc/hosts
	done
}

function mutual_trust_between_nodes() {
	LEN=${#CEPH_NODE_HOSTIP[@]}
	for ((i=0; i<${LEN}; i++))
	do
		expect -c "
		set timeout 2000
		spawn ssh-copy-id root@${CEPH_NODE_HOSTIP[${i}]}
		expect {
			\"*Are you sure you want to continue connecting (yes/no)*\" { send \"yes\r\";exp_continue }
			\"*root@* password:*\" { send \"${CEPH_NODE_PASSWORD}\r\";exp_continue }
		}
		expect eof
		"
	done
}

function remote_create_user() {
	LEN=${#CEPH_NODE_HOSTNAME[@]}
	for ((i=0; i<${LEN}; i++))
	do
		ssh root@${CEPH_NODE_HOSTIP[${i}]} "useradd ubuntu -m -G root -g root -s /bin/bash"
		ssh root@${CEPH_NODE_HOSTIP[${i}]} "echo ubuntu:ubuntu | chpasswd"
		ssh root@${CEPH_NODE_HOSTIP[${i}]} "echo \"ubuntu   ALL=(ALL)         NOPASSWD: ALL\" >> /etc/sudoers"
	done
}

function install_dependent() {
	sudo yum install -y wget expect curl git python-virtualenv python-devel postgresql postgresql-contrib postgresql-devel postgresql-server openssh-server net-tools gcc 
	curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
	python get-pip.py --timeout ${PIP_TIMEOUT}
	python -m pip install -U pip --timeout ${PIP_TIMEOUT}
	pip install --upgrade setuptools --timeout ${PIP_TIMEOUT}
	pip install supervisor --timeout ${PIP_TIMEOUT}
	pip install bottle --timeout ${PIP_TIMEOUT}
}

function stop_firewall() {
	systemctl stop firewalld.service
	systemctl disable firewalld.service
	setenforce 0
	sed -i "s/\(SELINUX=\).*/\1disabled/g" /etc/selinux/config
}

function generate_sshkey() {
	expect -c "
	set timeout 2000
	spawn ssh-keygen
	expect {
		\"*Enter file in which to save the key*\" { send \"\r\";exp_continue }
		\"*Enter passphrase*\" { send \"\r\";exp_continue }
		\"*Enter same passphrase again*\" { send \"\r\";exp_continue }
		\"*Overwrite*\" { send \"n\r\";exp_continue }
	}
	expect eof
	"
}

function teuthology_user_generate_sshkey() {
	expect -c "
	set timeout 2000
	spawn su - teuthology -c ssh-keygen
	expect {
		\"*Enter file in which to save the key*\" { send \"\r\";exp_continue }
		\"*Enter passphrase*\" { send \"\r\";exp_continue }
		\"*Enter same passphrase again*\" { send \"\r\";exp_continue }
		\"*Overwrite*\" { send \"n\r\";exp_continue }
	}
	expect eof
	"
}

function teuthworker_user_generate_sshkey() {
	expect -c "
	set timeout 2000
	spawn su - teuthworker -c ssh-keygen
	expect {
		\"*Enter file in which to save the key*\" { send \"\r\";exp_continue }
		\"*Enter passphrase*\" { send \"\r\";exp_continue }
		\"*Enter same passphrase again*\" { send \"\r\";exp_continue }
		\"*Overwrite*\" { send \"n\r\";exp_continue }
	}
	expect eof
	"
}

function create_paddles_user() {
	useradd -m paddles -g root -G root
	echo paddles:1q2w3e | chpasswd
}

function create_pulpito_user() {
	useradd -m pulpito -g root -G root
	echo pulpito:1q2w3e | chpasswd
}

function create_teuthology_user() {
	useradd -m teuthology -g root -G root
	echo teuthology:1q2w3e | chpasswd
}

function create_teuthworker_user() {
	useradd -m teuthworker -g root -G root
	echo teuthworker:1q2w3e | chpasswd
}

function add_sudoer() {
	if ! grep -q "teuthology.*" /etc/sudoers; then
		echo "teuthology   ALL=(ALL)         NOPASSWD: ALL" >> /etc/sudoers
	fi

	if ! grep -q "teuthworker.*" /etc/sudoers; then
		echo "teuthworker  ALL=(ALL)         NOPASSWD: ALL" >> /etc/sudoers
	fi
}

function config_postgresql() {
	service postgresql initdb
	service postgresql start
	chkconfig postgresql on
	systemctl enable postgresql.service
	netstat -anlp | grep 5432

	su - postgres -c "psql -c \"ALTER USER postgres PASSWORD '1q2w3e'\""
	su - postgres -c "psql -c \"create database paddles\""
	su - postgres -c "psql -c \"\l\""

	POSTGRES_CONF_FILE_NAME="/var/lib/pgsql/data/pg_hba.conf"
	sed -i "s/\(host\ *all\ *all\ *127\.0\.0\.1\/32\ *\).*/\1md5/g" ${POSTGRES_CONF_FILE_NAME}
	sed -i "s/\(host\ *all\ *all\ *::1\/128\ *\).*/\1md5/g" ${POSTGRES_CONF_FILE_NAME}
	if ! grep -q "local\ *all\ *postgres\ *peer" ${POSTGRES_CONF_FILE_NAME}; then
		echo "local   all             postgres                                peer" >> ${POSTGRES_CONF_FILE_NAME}
	fi

	service postgresql restart
}

function install_paddles() {
	su - paddles -c "mkdir github"
	su - paddles -c "pushd github;git clone https://github.com/ceph/paddles.git;popd"
	su - paddles -c "pushd github/paddles;virtualenv ./virtualenv;popd"

	su - paddles -c "pushd github/paddles;cp config.py.in config.py;popd"

	sed -i "s/\(\ *'host'\:\ '\)127\.0\.0\.1\(.*\)/\1${IP}\2/g" "/home/paddles/github/paddles/config.py"
	sed -i "s/\(\ *'host'\:\ '\)example\.com\(.*\)/\1${HOST_NAME}\.test\.lenovo\.com\2/g" "/home/paddles/github/paddles/config.py"
	sed -i "s/\(\ *'url'\:\ '\)sqlite:\/\/\/dev\.db\(.*\)/\1postgresql:\/\/postgres\:1q2w3e@localhost\/paddles\2/g" "/home/paddles/github/paddles/config.py"

	su - paddles -c "pushd github/paddles;cp alembic.ini.in alembic.ini;popd"
	sed -i "s/\(sqlalchemy\.url\ =\ \)postgresql+psycopg2\:\/\/paddles\:changeme@localhost\/paddles/\1postgresql\:\/\/postgres\:1q2w3e@localhost\/paddles/g" "/home/paddles/github/paddles/alembic.ini"

	sed -i "s/\(job_log_href_templ\ =\ '\)http\:\/\/qa-proxy\.ceph\.com\/teuthology\/{run_name}\/{job_id}\/teuthology\.log\(.*\)/\1http\:\/\/${PUBLIC_IP}\/teuthworker\/{run_name}\/{job_id}\/teuthology.log\2/g" "/home/paddles/github/paddles/config.py"

	su - paddles -c "pushd github/paddles;source virtualenv/bin/activate;python -m pip install -U pip;pip install --upgrade setuptools;pip install -r requirements.txt --timeout ${PIP_TIMEOUT};python setup.py develop;pecan populate config.py;popd"
}

function install_pulpito() {
	su - pulpito -c "mkdir github"
	su - pulpito -c "pushd github;git clone https://github.com/ceph/pulpito.git;popd"
	su - pulpito -c "pushd github/pulpito;virtualenv ./virtualenv;popd"

	su - pulpito -c "pushd github/pulpito;cp config.py.in prod.py;popd"
	sed -i "s/\(paddles_address\ =\ '\)http\:\/\/sentry\.front\.sepia\.ceph\.com\:8080\('\)/\1http:\/\/${IP}\:8080\2/g" "/home/pulpito/github/pulpito/prod.py"

	# sed -i "s///g" "/home/pulpito/github/pulpito/requirements.txt"
	su - pulpito -c "pushd github/pulpito;source virtualenv/bin/activate;python -m pip install -U pip;pip install --upgrade setuptools;pip install -r requirements.txt --timeout ${PIP_TIMEOUT};popd"
}



function install_supervisor() {
	echo_supervisord_conf > /etc/supervisord.conf
	if ! grep -q "files\ =\ \/etc\/supervisor\/\*\.conf" /etc/supervisord.conf; then
		echo "[include]" >> /etc/supervisord.conf
		echo "files = /etc/supervisor/*.conf" >> /etc/supervisord.conf
	fi
	pushd /etc/ && mkdir supervisor && pushd supervisor && cd && pwd
	touch /etc/supervisor/paddles.conf 
	echo "[program:paddles]
user=paddles
environment=HOME="/home/paddles/github/paddles",USER="paddles"
directory=/home/paddles/github/paddles
command=/home/paddles/github/paddles/virtualenv/bin/gunicorn_pecan -c /home/paddles/github/paddles/gunicorn_config.py /home/paddles/github/paddles/config.py
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile = /home/paddles/github/paddles/paddles.out.log
stderr_logfile = /home/paddles/github/paddles/paddles.err.log" > /etc/supervisor/paddles.conf 

	touch /etc/supervisor/pulpito.conf
	echo "[program:pulpito]
user= pulpito
environment=HOME="/home/pulpito/github/pulpito/virtualenv/bin",USER="pulpito"
directory=/home/pulpito/github/pulpito
command=/home/pulpito/github/pulpito/virtualenv/bin/python /home/pulpito/github/pulpito/run.py
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile = /home/pulpito/github/pulpito/pulpito.out.log
stderr_logfile = /home/pulpito/github/pulpito/pulpito.err.log" > /etc/supervisor/pulpito.conf

	touch /etc/systemd/system/supervisord.service
	echo "# supervisord service for systemd (CentOS 7.0+)
# by ET-CS (https://github.com/ET-CS)
[Unit]
Description=Supervisor daemon
[Service]
Type=forking
ExecStart=/usr/bin/supervisord -c /etc/supervisord.conf
ExecStop=/usr/bin/supervisorctl $OPTIONS shutdown
ExecReload=/usr/bin/supervisorctl $OPTIONS reload
KillMode=process
Restart=on-failure
RestartSec=42s
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/supervisord.service

	systemctl enable supervisord.service
	supervisord -c /etc/supervisord.conf
	supervisorctl reload
	supervisorctl restart all
	supervisorctl status
	ps aux | grep supervisord
	netstat -nalp | grep 8080
	netstat -nalp | grep 8081
}

function install_beanstalkd() {
	yum install libevent-devel libvirt-python openssl-devel mysql-libs libffi-devel libyaml-devel redhat-lsb python-pip mariadb-devel libev-devel libvirt-devel ansible -y
	pushd /home/ && mkdir beanstalkd && pushd beanstalkd && git clone https://github.com/kr/beanstalkd.git && pushd beanstalkd && make && cp beanstalkd /usr/bin/beanstalkd && mkdir /var/lib/beanstalkd && cd
	touch /etc/systemd/system/beanstalkd.service
	echo "[Unit]
Description=Beanstalkd is a simple, fast work queue

[Service]
User=root
ExecStart=/usr/bin/beanstalkd -b /var/lib/beanstalkd

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/beanstalkd.service

	systemctl enable beanstalkd && systemctl start beanstalkd
	ps ax | grep beanstalkd
}

function install_and_conf_nginx() {
	sudo rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
	yum install nginx -y
	nginx -v
	if ! grep -q "\        proxy_pass\ http\:\/\/${PUBLIC_IP}\:8081\/;" /etc/nginx/conf.d/default.conf; then
		sed -i -e "/\ *location\ \/\ {/a\\        proxy_pass\ http\:\/\/${PUBLIC_IP}\:8081\/;" /etc/nginx/conf.d/default.conf
	fi
	service nginx start
	chkconfig nginx on
}

function generate_teuthology_conf() {
	touch /etc/teuthology.yaml
	echo "lab_domain: test.lenovo.com
# paddles所在服务器
lock_server: http://${IP}:8080
# paddles所在服务器
results_server: http://${IP}:8080
# beanstalkd队列服务器，第一步安装的，就在我们本地，默认端口是11300
queue_host: 127.0.0.1
queue_port: 11300
results_email: lnsyyj@hotmail.com
results_sending_email: teuthology@test.lenovo.com
# 本地归档，直接放在执行者的家目录下
archive_base: /home/teuthworker/archive
verify_host_keys: false
# 官方的是：http://github.com/ceph/，就是我们下载各种需要的组件源码的路径
# 这里暂时使用github上的，之后我们将搭建一个完整的git服务器替代它
ceph_git_base_url: https://github.com/lnsyyj/
ceph_qa_suite_git_url: https://github.com/lnsyyj/ceph-qa-suite.git
ceph_git_url: https://github.com/lnsyyj/ceph.git
# 就是前面搭的gitbuilder的地址
gitbuilder_host: 'gitbuilder.ceph.com'
reserve_machines: 1
# 归档目录，直接写本机的地址加/teuthology即可
archive_server: http://${PUBLIC_IP}/
results_ui_server: http://${PUBLIC_IP}/
max_job_time: 86400
suite_verify_ceph_hash: False" > /etc/teuthology.yaml
}

function install_teuthology() {
	su - teuthology -c "sudo yum -y install epel-release && sudo yum -y install python-pip wget"
	su - teuthology -c "mkdir ~/src && git clone https://github.com/lnsyyj/teuthology.git src/teuthology_master && pushd src/teuthology_master/ && ./bootstrap && ./bootstrap install && popd && cd"
	su - teuthology -c "wget https://raw.githubusercontent.com/ceph/teuthology/master/docs/_static/create_nodes.py"
	sed -i "s/\(paddles_url\ =\ 'http\:\/\/\)paddles\.example\.com\/nodes\/\(.*\)/\1${IP}\:8080\2/g" "/home/teuthology/create_nodes.py"
	sed -i "s/\(machine_type\ =\ '\)typica\(.*\)/\1plana\2/g" "/home/teuthology/create_nodes.py"
	sed -i "s/\(lab_domain\ =\ '\)example\.com\(.*\)/\1test\.com\2/g" "/home/teuthology/create_nodes.py"
	MACHINE_UPPER_LIMIT="7"
	sed -i "s/\(machine_index_range\ =\ range(3,\ \)192\(.*\)/\1${MACHINE_UPPER_LIMIT}\2/g" "/home/teuthology/create_nodes.py"
	cp "/home/teuthology/create_nodes.py" "/home/teuthology/src/teuthology_master"
}

function install_teuthworker() {
	su - teuthworker -c "mkdir ~/src && git clone https://github.com/lnsyyj/teuthology.git src/teuthology_master"
	su - teuthworker -c "pushd src/teuthology_master/;./bootstrap;popd"
	su - teuthworker -c "mkdir ~/bin;wget -O ~/bin/worker_start https://raw.githubusercontent.com/ceph/teuthology/master/docs/_static/worker_start.sh;"
	su - teuthworker -c "echo PATH=\"$HOME/src/teuthology_master/virtualenv/bin:$PATH\" >> ~/.profile && source ~/.profile"
	su - teuthworker -c "mkdir -p ~/archive/worker_logs"
	su - teuthworker -c "pushd bin/ && chmod 777 *"

	chmod 777 /home/
	chmod 777 /home/teuthworker/
	chmod 777 -R /home/teuthworker/archive/
}

STARTTIME=`date +'%Y-%m-%d %H:%M:%S'`

modify_dns
modify_hostname
modify_hosts_file
install_dependent
stop_firewall
generate_sshkey
mutual_trust_between_nodes
remote_create_user
create_teuthology_user
create_teuthworker_user
add_sudoer

teuthology_user_generate_sshkey
teuthworker_user_generate_sshkey

create_paddles_user
create_pulpito_user

config_postgresql
install_paddles
install_pulpito
install_supervisor
install_beanstalkd
install_and_conf_nginx
generate_teuthology_conf
install_teuthology
install_teuthworker

ENDTIME=`date +'%Y-%m-%d %H:%M:%S'`
START_SECONDS=$(date --date="${STARTTIME}" +%s)
END_SECONDS=$(date --date="${ENDTIME}" +%s)
echo "本次运行时间： "$((END_SECONDS-START_SECONDS))"s"

# 1.手动添加主机（teuthology节点执行）
# su - teuthology
# cd src/teuthology_master/
# source virtualenv/bin/activate
# ssh-copy-id ubuntu@plana003.test.lenovo.com
# ssh-copy-id ubuntu@plana004.test.lenovo.com
# ssh-copy-id ubuntu@plana005.test.lenovo.com
# ssh-copy-id ubuntu@plana006.test.lenovo.com
# python create_nodes.py

# 2.手动解锁主机（teuthology节点执行）
# su - teuthology
# cd src/teuthology_master/
# source virtualenv/bin/activate
# teuthology-lock --owner initial@setup --unlock plana003.test.lenovo.com
# teuthology-lock --owner initial@setup --unlock plana004.test.lenovo.com
# teuthology-lock --owner initial@setup --unlock plana005.test.lenovo.com
# teuthology-lock --owner initial@setup --unlock plana006.test.lenovo.com

# 3.手动（teuthology节点执行）
# su - teuthworker
# cd src/teuthology_master
# source virtualenv/bin/activate
# ssh-copy-id ubuntu@plana003.test.lenovo.com
# ssh-copy-id ubuntu@plana004.test.lenovo.com
# ssh-copy-id ubuntu@plana005.test.lenovo.com
# ssh-copy-id ubuntu@plana006.test.lenovo.com

# 4.ceph节点需要设置selinux
# vi /etc/selinux/config
# SELINUX=permissive

# 5.几台ceph节点必须可以连接外网

# 6.几个ceph节点
# su - ubuntu
# ssh-keygen

# 7.手动（teuthology节点执行）
# sudo vi /home/teuthworker/bin/worker_start
# #function start_all {
# #   start_workers_for_tube plana 3
# #   start_workers_for_tube mira 50
# #   start_workers_for_tube vps 80
# #   start_workers_for_tube burnupi 10
# #   start_workers_for_tube tala 5
# #   start_workers_for_tube saya 10
# #   start_workers_for_tube multi 100
# #} 
# 
# su - teuthworker
# source src/teuthology_master/virtualenv/bin/activate
# cd bin/ && ./worker_start

# 8.测试
# (virtualenv) [teuthology@yujiang-teuthology teuthology_master]$ cat test.yaml 
# check-locks: false
# use_existing_cluster: true
# roles:
# - [mon.a, osd.0, client.0]
# tasks:
# - install:
# tasks:
# - exec:
#     client.0:
#       - sudo ls
#       - sudo pwd
# overrides:
#   selinux:
#      whitelist:
#       - 'name="cephtest"'
#       - 'dmidecode'
#       - 'comm="logrotate"'
#       - 'comm="idontcare"'
#       - 'comm="sshd"'
#       - 'comm="load_policy"'
#       - 'comm="useradd"'
#       - 'comm="groupadd"'
#       - 'comm="unix_chkpwd"'
#       - 'comm="auditd"'
# targets:
# ubuntu@plana003.test.com: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqlVCQnkp3m8FEI52W62ZUY/FokA443m4PCPqYbxR7ejA2IcVCpnHb50X3VMuOqz/o4KDPxahL7u1OP98ziZ+3F1ciK/21xEOKen6RL2WAqg3CT2FWvdhupPwZsW5Cn655Y8J7mjPzoZE7GDi0j/O1hhTw5qiGOrLoKOWAKOcIduITTYcH4XFHxrxjb2WzV+x6OIs5OTs53wuvJyNsoBJelv9vk/EAkjWVG1Ytf9qEP3UMqTZTfnfJrDHWdWB871PTsFlR7P2x7Ca68FpXAU+Mgk4GvBkF2QdL/8cQC4BgFXcjXOTOqO+4+n2VeKLIid5ywI4LsrI2QLAhDGtZ2JF1
#
# su - teuthology
# source src/teuthology_master/virtualenv/bin/activate
# cd src/teuthology_master/
# teuthology-schedule --name yujiang test.yaml



#
# vi /etc/nginx/conf.d/default.conf   添加如下
#       location /teuthworker {
#            allow all;
#            autoindex on;
#            alias /home/teuthworker/archive;
#            default_type text/plain;
#        }
#
#
#