#!/usr/bin/env python
# -*- coding: utf-8 -*-

import pymysql
import time
from datetime import datetime

mysql_ip = "127.0.0.1"
mysql_account = "root"
mysql_password = "1234567890"
mysql_db_name = "ceph"
mysql_table_name = "stability_vdbench_concurrent"

file_directorys = ["1017-1020", "1021-1022", "1023-1026", "1027-1029"]
file_names = ["summary_client1.log", "summary_client2.log", "summary_client3.log", "summary_client4.log"]
test_types = ["bs_split", "olap", "random", "sequence"]

file_directory = "/home/yujiang/simth_vdbench_data/1027-1029/"
file_name = "summary_client4.log"
test_type = "sequence"

def mariadb_connect_test():
    db = pymysql.connect(mysql_ip, mysql_account, mysql_password, mysql_db_name)
    cursor = db.cursor()
    cursor.execute("SELECT VERSION()")
    data = cursor.fetchone()
    print "Database version : %s " % data
    db.close()

def parse_vdbench_result_file():
    table = []
    with open(file_directory + file_name, "r") as file:
        line = file.readline()
        while line:
            rs_data = line.strip('\n').split(' ')
            tmp_time = rs_data[0] + " " + rs_data[1].split('.')[0]
            del rs_data[0]
            del rs_data[0]
            rs_data.insert(0, tmp_time)
            table.append(rs_data)
            line = file.readline()
    return table
    
def batch_insertion(table):
    dt = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
    conn = pymysql.connect(mysql_ip, mysql_account, mysql_password, mysql_db_name)
    cur = conn.cursor()
    for data in table:
        print data
        cur.execute("INSERT INTO stability_vdbench_concurrent(id, datetime, outputinterval, iorate, MBsec, bytesio, readpct, resptime, readresp, writeresp, respmax, respstddev, queuedepth, cpupercentagesysu, cpupercentagesys, clustercapacitypercentage, operationtabledate, testcase, client_number) VALUES('NULL', '%s', %d, '%f', '%f', '%d', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%s', '%s', '%s')" % (data[0], int(data[1]), float(data[2]), float(data[3]), int(data[4]), float(data[5]), float(data[6]), float(data[7]), float(data[8]) ,float(data[9]) ,float(data[10]), float(data[11]), float(data[12]), float(data[13]), 0, dt, test_type, data[14]))
    conn.commit()
    cur.close()
    conn.close()

if __name__ == '__main__':
    mariadb_connect_test()
    table = parse_vdbench_result_file()
    batch_insertion(table)
