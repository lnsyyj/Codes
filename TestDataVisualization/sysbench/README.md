sysbench log命名规则

```
目录名命名规则
sysbench	根目录固定sysbench

文件名命名规则
mysysbench_log_2018-10-30_12-27-00_vm-client-1    文件名_年-月-日_时-分-秒_vm-client-ID
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

