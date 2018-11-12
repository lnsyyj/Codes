#!/usr/bin/env python
# -*- coding: utf-8 -*-

import pymysql
import time
import re
from datetime import datetime

mysql_ip = "127.0.0.1"
mysql_account = "root"
mysql_password = "123456789"
mysql_db_name = "ceph"
mysql_table_name = "stability_sysbench"

file_directory = "/home/yujiang/simth_vdbench_data/"
file_name = "total.log"

def mariadb_connect_test():
    db = pymysql.connect(mysql_ip, mysql_account, mysql_password, mysql_db_name)
    cursor = db.cursor()
    cursor.execute("SELECT VERSION()")
    data = cursor.fetchone()
    print "Database version : %s " % data
    db.close()

def parse_sysbench_results(str):
    table = []
    # parsing datetime
    pattern = re.compile(r'\d+-\d+-\d+ \d+:\d+:\d+')
    datetime = pattern.findall(str)[0].strip()
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
    return [datetime, interval, thds, tps, qps, qps_r, qps_w, qps_o, lat, lat_unit, lat_percentage, err, reconn]

def parse_vdbench_result_file():
    table = []
    with open(file_directory + file_name, "r") as file:
        line = file.readline()
        while line:
            tmp_data = parse_sysbench_results(line)
            table.append(tmp_data)
            line = file.readline()
    return table
    
def batch_insertion(table):
    dt = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
    print dt
    conn = pymysql.connect(mysql_ip, mysql_account, mysql_password, mysql_db_name)
    cur = conn.cursor()
    for data in table:
        print data
        cur.execute("INSERT INTO stability_sysbench(id, datetime, outputinterval, thds, tps, qps, qps_r, qps_w, qps_o, lat, lat_unit, lat_percentage, err, reconn, operationtabledate) VALUES('NULL', '%s', '%d', '%d', '%f', '%f', '%f', '%f', '%f', '%f', '%s', '%f', '%f', '%f', '%s')" % (data[0], int(data[1]), int(data[2]), float(data[3]), float(data[4]), float(data[5]), float(data[6]), float(data[7]), float(data[8]), data[9], float(data[10]), float(data[11]), float(data[12]), dt))
    conn.commit()
    cur.close()
    conn.close()

if __name__ == '__main__':
    # mariadb_connect_test()
    table = parse_vdbench_result_file()
    print table
    # batch_insertion(table)
