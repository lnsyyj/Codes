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
mysql_table_name = "stability_vdbench_concurrent"

file_directory = "/Users/yujiang/vdbench_log/vdbench_log/"
vdbench_output_interval = 5

def mariadb_connect_test():
    db = pymysql.connect(mysql_ip, mysql_account, mysql_password, mysql_db_name)
    cursor = db.cursor()
    cursor.execute("SELECT VERSION()")
    data = cursor.fetchone()
    print "Database version : %s " % data
    db.close()

def date_conversion(vdb_datetime):
    #vdb_datetime = datetime.datetime.strptime(vdb_datetime, '%Y-%m-%d %H:%M:%S') + timedelta(seconds=int(vdbench_output_interval))
    a = vdb_datetime = datetime.datetime.strptime(vdb_datetime, '%Y-%m-%d %H:%M:%S')
    vdb_datetime = a + timedelta(seconds=int(vdbench_output_interval))
    return vdb_datetime
 
def parse_vdbench_result_file(file_name):
    table = []
    tmp_start_date = ""
    tmp_start_time = ""

    date_pattern = re.compile(r'(.*, \d{4})  interval.*')
    line_pattern = re.compile(r'\d+:\d+:\d+\.\d+\s+\d+\s+\d+.\d+\s+\d+.\d+\s+\d+\s+\d+.\d+\s+\d+.\d+\s+\d+.\d+\s+\d+.\d+\s+\d+.\d+\s+\d+.\d+\s+\d+.\d+\s+\d+.\d+\s+\d+.\d+')
    date_pattern_first_time = re.compile(r'(\d+:\d+:\d+)\.\d+\s+1\s+\d+.\d+\s+\d+.\d+\s+\d+\s+\d+.\d+\s+\d+.\d+\s+\d+.\d+\s+\d+.\d+\s+\d+.\d+\s+\d+.\d+\s+\d+.\d+\s+\d+.\d+\s+\d+.\d+')
    with open(file_name, "r") as file:
        tmp_start_date = ""
        tmp_start_time = ""

        line = file.readline()
        while line:
            if date_pattern.findall(line) and tmp_start_date == "":
                tmp_start_date = date_pattern.findall(line)[0].strip()
                if tmp_start_date == "":
                    break

            if date_pattern_first_time.findall(line) and tmp_start_time == "":
                tmp_start_time = date_pattern_first_time.findall(line)[0].strip()
                if tmp_start_time == "":
                    break

            tmp_start_date_time = tmp_start_date + " " + tmp_start_time

            if line_pattern.findall(line):
                c = datetime.datetime.strptime(tmp_start_date_time, '%b %d, %Y %H:%M:%S')
                start_time = c.strftime('%Y-%m-%d %H:%M:%S')
                result = line_pattern.findall(line)[0].strip()
                tmp_data = parse_vdbench_results(start_time, result, file_name)
                table.append(tmp_data)

            line = file.readline()
    return table

def parse_vdbench_results(vdb_datetime, result, file_name):
    # parsing
    tmp_result = result.split( )

    # parsing testcase
    # /home/yujiang/vdbench_log/myvdbench_log_2018-11-02_07-32-07_vm-client-1/log-10/bs_split/c
    pattern = re.compile(r'.*/log-\d+/(.*)/summary.html')
    testcase = pattern.findall(file_name)[0].strip()

    # parsing client number
    pattern = re.compile(r'.*/myvdbench_log_.*(vm-client-\d+)/.*')
    client_number = pattern.findall(file_name)[0].strip()

    # combination time
    tmp_vdb_datetime = datetime.datetime.strptime(vdb_datetime, '%Y-%m-%d %H:%M:%S') + timedelta(seconds=(vdbench_output_interval * int(tmp_result[1])))
    tmp_vdb_datetime = tmp_vdb_datetime.strftime('%Y-%m-%d %H:%M:%S')
    return [tmp_vdb_datetime, tmp_result[1], tmp_result[2], tmp_result[3], tmp_result[4], tmp_result[5], tmp_result[6], tmp_result[7], tmp_result[8], tmp_result[9], tmp_result[10], tmp_result[11], tmp_result[12], tmp_result[13], testcase, client_number]
    
def batch_insertion(table):
    dt = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
    conn = pymysql.connect(mysql_ip, mysql_account, mysql_password, mysql_db_name)
    cur = conn.cursor()
    for data in table:
        print data
        cur.execute("INSERT INTO stability_vdbench_concurrent(id, datetime, outputinterval, iorate, MBsec, bytesio, readpct, resptime, readresp, writeresp, respmax, respstddev, queuedepth, cpupercentagesysu, cpupercentagesys, clustercapacitypercentage, operationtabledate, testcase, client_number) VALUES('NULL', '%s', %d, '%f', '%f', '%d', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%s', '%s', '%s')" % (data[0], int(data[1]), float(data[2]), float(data[3]), int(data[4]), float(data[5]), float(data[6]), float(data[7]), float(data[8]) ,float(data[9]) ,float(data[10]), float(data[11]), float(data[12]), float(data[13]), 0, dt, data[14], data[15]))
    conn.commit()
    cur.close()
    conn.close()

def get_the_files_in_the_directory():
    files_table = []
    file_pattern = re.compile(r'summary.html')
    dirpath_pattern = re.compile(r'log-\d+')
    for dirpath, dirs, files in os.walk(file_directory):
        for file_name in files:
            if dirpath_pattern.findall(dirpath) and file_pattern.findall(file_name):
                tmp_file_name = file_pattern.findall(file_name)[0].strip()
                files_table.append(dirpath + "/" + tmp_file_name)
    return files_table

if __name__ == '__main__':
    #mariadb_connect_test()
    files_table = get_the_files_in_the_directory()
    for value in files_table:
        table = parse_vdbench_result_file(value)
        for x in table:
            print x
        #print table
        # batch_insertion(table)