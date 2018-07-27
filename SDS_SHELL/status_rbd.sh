#!/bin/bash

#set -x

c=0
for file in `rbd ls -p datapool`
do
  RBDS[$c]=$file
  ((c++))
done

function rbd_status() {
    LEN=${#RBDS[@]}
    for ((i=0; i<${LEN}; i++))
    do
        echo ${RBDS[${i}]}
        rbd status datapool/${RBDS[${i}]}
    done
}

rbd_status
