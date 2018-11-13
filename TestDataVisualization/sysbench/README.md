sysbench log命名规则

```
目录名命名规则
sysbench_log	根目录固定sysbench_log

	文件名命名规则
	mysysbench_log_2018-10-30_12-27-00_vm-client-1    文件名_年-月-日_时-分-秒_vm-client-ID

[root@localhost ~]# tree /home/yujiang/sysbench_log/
/home/yujiang/sysbench_log/
├── mysysbench_log_2018-10-30_12-27-00_vm-client-1
├── mysysbench_log_2018-10-31_17-25-26_vm-client-1
├── mysysbench_log_2018-11-02_09-38-43_vm-client-1
├── mysysbench_log_2018-11-05_19-52-58_vm-client-1
├── mysysbench_log_2018-11-08_23-21-46_vm-client-1
└── mysysbench_log_2018-11-10_14-30-08_vm-client-1

0 directories, 6 files
```

安装依赖

```
pip install PyMySQL
```

sysbench version

```
sysbench 1.0.15 (using bundled LuaJIT 2.1.0-beta2)
```

sysbench cli

```
sysbench ./tests/include/oltp_legacy/oltp.lua --mysql-host=192.168.124.52 --mysql-port=3306 --mysql-user=root --mysql-password=123456 --oltp-test-mode=complex --oltp-tables-count=10 --oltp-table-size=100000 --threads=10 --time=172800 --report-interval=10 run >> /home/simth/mysysbench_log_`date "+%Y-%m-%d_%H-%M-%S"`_vm-client-<$clientid>
```

