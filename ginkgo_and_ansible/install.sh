#!/bin/bash

ANSIBLE_VERSION="ansible-2.4.2.0"
GOLANG_VERSION="go1.11.4.linux-amd64.tar.gz"
ENVIRONMENT_FILE_PATH="/etc/profile"

function install_ansible() {
  yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
  yum install -y ${ANSIBLE_VERSION}
}

function modify_hosts_file() {
  echo "151.101.228.249 http://global-ssl.fastly.Net" >> /etc/hosts
  echo "192.30.253.113  http://github.com" >> /etc/hosts
}

function install_golang() {
  yum install -y wget
  wget https://dl.google.com/go/${GOLANG_VERSION} && tar zxf ${GOLANG_VERSION}
  pushd go/
  GOLANG_PATH=$(pwd)
  popd

  mkdir gocodes
  pushd gocodes/
    GO_PATH=$(pwd)
  popd

  echo "export PATH=$PATH:${GOLANG_PATH}/bin:${GO_PATH}/bin" >> ${ENVIRONMENT_FILE_PATH}
  echo "export GOPATH=${GO_PATH}" >> ${ENVIRONMENT_FILE_PATH}

  source ${ENVIRONMENT_FILE_PATH}
}

function install_ginkgo() {
  go get -v -u github.com/onsi/ginkgo/ginkgo

  mkdir -p $GOPATH/src/golang.org/x/
  git clone https://github.com/golang/net.git $GOPATH/src/golang.org/x/net
  git clone https://github.com/golang/text.git $GOPATH/src/golang.org/x/text

  go get -v -u github.com/onsi/gomega/...

  go get -v -u github.com/go-resty/resty
  go get -v -u github.com/tidwall/gjson
}

install_ansible
install_golang
modify_hosts_file
install_ginkgo
