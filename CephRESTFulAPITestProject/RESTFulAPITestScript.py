#!/usr/bin/env python
# -*- coding: utf-8 -*-

import requests				# pip install requests
import MySQLdb as mdb     	# pip install MySQL-python
import xlsxwriter         	# pip install XlsxWriter
import commands				# pip install command


# batch create pool operation
def batch_create_test_pool(pool_name,pool_num):
	operation_count = 1
	print "======================================================"
	for num in range(0,pool_num):
		create_poolname = "ceph osd pool create" + " " + pool_name + str( num + 1 ) + " " + "128" + " " + "128"
		print "batch create pool operation: " + str( operation_count )
		operation_count = operation_count + 1
		print "%s"%(create_poolname)
		exit_status,output_the_result = commands.getstatusoutput(create_poolname)
		print "exit_status: %s\noutput_the_result: %s\n"%(exit_status,output_the_result)
	print "======================================================\n"
	return

# batch delete pool operation
def batch_delete_test_pool(pool_name,pool_num):
	operation_count = 1
	for num in range(0,pool_num):
		del_poolname = "ceph osd pool delete " + pool_name + str( num + 1 ) + " " + pool_name + str( num + 1 ) + " " + "--yes-i-really-really-mean-it"
		print "batch delete pool operation: " + str( operation_count )
		operation_count = operation_count + 1
		print "%s"%(del_poolname)
		exit_status,output_the_result = commands.getstatusoutput(del_poolname)
		print "exit_status: %s\noutput_the_result: %s\n"%(exit_status,output_the_result)
	print "======================================================"

# batch create rbd operation
def batch_create_test_rbd(pool_name,pool_num,rbd_name,rbd_num):
	operation_count = 1
	for p_num in range(0,pool_num):
		for r_num in range(0,rbd_num):
			create_rbd = "rbd create --size 512" + " " + pool_name + str( p_num + 1 ) + "/" + rbd_name + str( r_num + 1 )
			print "batch create rbd operation: " + str( operation_count )
			operation_count = operation_count + 1
			print "%s"%(create_rbd)
			exit_status,output_the_result = commands.getstatusoutput(create_rbd)
			print "exit_status: %s\noutput_the_result: %s\n"%(exit_status,output_the_result)
	print "======================================================"

# batch delete rbd operation
def batch_delete_test_rbd(pool_name,pool_num,rbd_name,rbd_num):
	operation_count = 1
	for p_num in range(0,pool_num):
		for r_num in range(0,rbd_num):
			delete_rbd = "rbd rm" + " " + pool_name + str( p_num + 1 ) + "/" + rbd_name + str( r_num + 1 )
			print "batch delete rbd operation: " + str( operation_count )
			operation_count = operation_count + 1
			print "%s"%(delete_rbd)
			exit_status,output_the_result = commands.getstatusoutput(delete_rbd)
			print "exit_status: %s\noutput_the_result: %s\n"%(exit_status,output_the_result)
	print "======================================================"

#MySQL
def query_mysql(sql_statement):
	#mysql_conn = mdb.connect(host='127.0.0.1', port=3306, user='storage', passwd='lenovo', db='storagemgmt', charset='utf8')
	query_results = []
	mysql_conn = mdb.connect(host='127.0.0.1', port=3306, user='root', passwd='123456', db='testDB', charset='utf8')
	dict_cur = mysql_conn.cursor(mdb.cursors.DictCursor)
	dict_cur.execute(sql_statement)
	mysql_conn.commit()
	for data in dict_cur.fetchall():
		query_results.append(data)
	dict_cur.close()
	print "sql statement : %s"%(sql_statement)
	print query_results
	return query_results

def write_xlsx_file():
	# Create an new Excel file and add a worksheet.
	workbook = xlsxwriter.Workbook('demo.xlsx')
	worksheet = workbook.add_worksheet()
	
	worksheet.set_column('A:A', 20)
	worksheet.write('A1','')
	worksheet.set_column('B:B', 20)
	worksheet.write('B1','restAPI')
	worksheet.set_column('C:C', 20)
	worksheet.write('C1','sample')
	worksheet.set_column('D:D', 20)
	worksheet.write('D1','step')
	worksheet.set_column('E:E', 20)
	worksheet.write('E1','pass/fail')
	worksheet.set_column('F:F', 20)
	worksheet.write('F1','comments')

	workbook.close()
	return

#获取pool信息
def get_pool_info_http_request(url):
	result = requests.get(url)
	return result

def send_get_http_request():
	conn = httplib.HTTPSConnection("localhost",9999)
	conn.request("GET","/v1/clusters/1/pools")
	result = conn.getresponse()
	return result


#pre_pool_and_rbd()
#connect_mysql()
#write_xlsx_file()
#r = requests.get('http://127.0.0.1:9999/v1/clusters/1/pools')
#print r
#print r.text