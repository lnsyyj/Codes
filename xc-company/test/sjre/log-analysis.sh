#!/bin/bash
# set -x



FILE_NAME=2022-09-22



for i in {1..9}
do
    echo "=================================================="
    echo "${i}000ms - $((i+1))000ms"
    cat ${FILE_NAME} | awk '$2>"00:00:00" && $2<"23:59:59"'| egrep "实际为时间为:[${i}-${i}][0-9]{3}" | wc -l 

    for j in {0..23}
    do
        start=`echo ${j} | awk '{printf("%02d",$0)}'`
        end=$((j+1))
        end=`echo $end | awk '{printf("%02d",$0)}'`

        if [ ${j} -eq 23 ]
        then
            echo "${start}:00:00 - 23:59:59" 
            cat ${FILE_NAME} | awk '$2>"'${start}':00:00" && $2<"23:59:59"' | egrep "实际为时间为:[${i}-${i}][0-9]{3}" | wc -l 
        else
            echo "${start}:00:00 - ${end}:00:00" 
            cat ${FILE_NAME} | awk '$2>"'${start}':00:00" && $2<"'${end}':00:00"' | egrep "实际为时间为:[${i}-${i}][0-9]{3}" | wc -l 
        fi
    done
done

# for i in {1..9}
# do
#     echo "${i}000ms - $((i+1))000ms"
#     cat ${FILE_NAME} | awk '$2>"00:00:00" && $2<"23:59:59"'| egrep "实际为时间为:[${i}-${i}][0-9]{3}" | wc -l 
# done
