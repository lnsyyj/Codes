#!/usr/bin/env python
# -*- coding: utf-8 -*-

import pymysql
import time
import re
import os
import datetime
from datetime import timedelta

mysql_ip = "127.0.0.1"
mysql_account = "root"
mysql_password = "1234567890"
mysql_db_name = "ceph"
mysql_table_name = "stability_sysbench_concurrent"

# file_directory = "/home/yujiang/simth_vdbench_data/"
file_directory = "/home/yujiang/sysbench_log/"
#file_name = "total.log"

def mariadb_connect_test():
    db = pymysql.connect(mysql_ip, mysql_account, mysql_password, mysql_db_name)
    cursor = db.cursor()
    cursor.execute("SELECT VERSION()")
    data = cursor.fetchone()
    print "Database version : %s " % data
    db.close()

def date_conversion(sys_datetime, interval):
    sys_datetime = sys_datetime.replace("_"," ")
    tmp_date = sys_datetime.split(" ")
    tmp_date[1] = tmp_date[1].replace("-",":")
    sys_datetime = tmp_date[0] + " " + tmp_date[1]
    sys_datetime = datetime.datetime.strptime(sys_datetime, '%Y-%m-%d %H:%M:%S') + timedelta(seconds=int(interval))
    sys_datetime = sys_datetime.strftime('%Y-%m-%d %H:%M:%S')
    return sys_datetime

def parse_sysbench_results(str, file_name):
    # parsing datetime
    pattern = re.compile(r'mysysbench_log_(\d+-\d+-\d+_\d+-\d+-\d+)_vm-client-\d+')
    sys_datetime = pattern.findall(file_name)[0].strip()
    # parsing interval
    pattern = re.compile(r'\[ (.*)s \]')
    interval = pattern.findall(str)[0].strip()
    # parsing thds
    pattern = re.compile(r'thds: (\d+)')
    thds = pattern.findall(str)[0].strip()
    # parsing tps
    pattern = re.compile(r'tps: (\d+\.\d+)')
    tps = pattern.findall(str)[0].strip()
    # parsing qps
    pattern = re.compile(r'qps: (\d+\.\d+)')
    qps = pattern.findall(str)[0].strip()
    # parsing qps_r
    pattern = re.compile(r'qps: \d+\.\d+ \(r/w/o: (\d+\.\d+)/')
    qps_r = pattern.findall(str)[0].strip()
    # parsing qps_w
    pattern = re.compile(r'qps: \d+\.\d+ \(r/w/o: \d+\.\d+/(\d+\.\d+)')
    qps_w = pattern.findall(str)[0].strip()
    # parsing qps_o
    pattern = re.compile(r'qps: \d+\.\d+ \(r/w/o: \d+\.\d+/\d+\.\d+/(\d+\.\d+)\)')
    qps_o = pattern.findall(str)[0].strip()
    # parsing lat
    pattern = re.compile(r'lat \(.*\): (\d+\.\d+)')
    lat = pattern.findall(str)[0].strip()
    # parsing lat_unit
    pattern = re.compile(r'lat \((.*),.*\)')
    lat_unit = pattern.findall(str)[0].strip()
    # parsing lat_percentage
    pattern = re.compile(r'lat \(.*,(.*)%\)')
    lat_percentage = pattern.findall(str)[0].strip()
    # parsing err
    pattern = re.compile(r'err/s: (\d+\.\d+)')
    err = pattern.findall(str)[0].strip()
    # parsing reconn
    pattern = re.compile(r'reconn/s: (\d+\.\d+)')
    reconn = pattern.findall(str)[0].strip()
    # parsing client_number
    pattern = re.compile(r'(vm-client-\d+)')
    client_number = pattern.findall(file_name)[0].strip()

    sys_datetime = date_conversion(sys_datetime, interval)
    return [sys_datetime, interval, thds, tps, qps, qps_r, qps_w, qps_o, lat, lat_unit, lat_percentage, err, reconn, client_number]
    
def batch_insertion(table):
    dt = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
    print dt
    conn = pymysql.connect(mysql_ip, mysql_account, mysql_password, mysql_db_name)
    cur = conn.cursor()
    for data in table:
        print data
        cur.execute("INSERT INTO stability_sysbench_concurrent(id, datetime, outputinterval, thds, tps, qps, qps_r, qps_w, qps_o, lat, lat_unit, lat_percentage, err, reconn, operationtabledate, client_number) VALUES('NULL', '%s', '%d', '%d', '%f', '%f', '%f', '%f', '%f', '%f', '%s', '%f', '%f', '%f', '%s', '%s')" % (data[0], int(data[1]), int(data[2]), float(data[3]), float(data[4]), float(data[5]), float(data[6]), float(data[7]), float(data[8]), data[9], float(data[10]), float(data[11]), float(data[12]), dt, data[13]))
    conn.commit()
    cur.close()
    conn.close()

def get_the_files_in_the_directory():
    files_table = []
    file_name = ""
    files = os.listdir(file_directory)
    for value in files:
        pattern = re.compile(r'mysysbench_log_\d+-\d+-\d+_\d+-\d+-\d+_vm-client-\d+')
        if pattern.findall(value):
            file_name = pattern.findall(value)[0]
        if file_name:
            files_table.append(file_name)
    return files_table

def parse_vdbench_result_file(file_name):
    table = []
    pattern = re.compile(
        r'\[ \d+s \] thds: \d+ tps: \d+\.\d+ qps: \d+\.\d+ \(r/w/o: \d+\.\d+/\d+\.\d+/\d+\.\d+\) lat \(.*\): \d+\.\d+ err/s: \d+\.\d+ reconn/s: \d+\.\d+')
    with open(file_directory + file_name, "r") as file:
        line = file.readline()
        while line:
            if pattern.findall(line):
                result = pattern.findall(line)[0].strip()
                tmp_data = parse_sysbench_results(result, file_name)
                table.append(tmp_data)
            line = file.readline()
    return table

if __name__ == '__main__':
    files_table = get_the_files_in_the_directory()
    for value in files_table:
        table = parse_vdbench_result_file(value)
        batch_insertion(table)

    # mariadb_connect_test()
    # table = parse_vdbench_result_file()
    # print table
    # batch_insertion(table)
