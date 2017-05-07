import RESTFulAPITestScript as rfats


#rfats.batch_create_test_pool(pool_name="ceph-test-pool-",pool_num=3)
#rfats.batch_create_test_rbd(pool_name="ceph-test-pool-",pool_num=3,rbd_name="ceph-test-rbd-",rbd_num=3)
#rfats.batch_delete_test_rbd(pool_name="ceph-test-pool-",pool_num=3,rbd_name="ceph-test-rbd-",rbd_num=3)
#rfats.batch_delete_test_pool(pool_name="ceph-test-pool-",pool_num=3)

query_results = rfats.query_mysql("select * from testTable")
#query_results = rfats.query_mysql("select id,name from testTable where id=1")
print "result count: %d"%(len(query_results))
for list_data in query_results:
	print "%s %s "%(list_data['id'],list_data['name'])

#print query_results
