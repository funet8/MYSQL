# MariaDB Galera Cluster 部署


在虚拟机中操作
名称 | IP | 系统 
---|---|---
MariaDB-node1 | 192.168.4.188 | CentOS 6.8 
MariaDB-node2 | 192.168.4.189 | CentOS 6.8 
MariaDB-node3 | 192.168.4.191 | CentOS 6.8 

## 操作步骤
### 一、关闭SELINUX和防火墙、绑定hosts
略
```
echo '# MariaDB Galera Cluste
192.168.4.188 node1 MariaDB-node1
192.168.4.189 node2 MariaDB-node2
192.168.4.191 node3 MariaDB-node3' >>  /etc/hosts
```

### 二、添加 MariaDB Repositories
For CentOS 6 – 64bit:
```
echo '[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.0/centos6-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1'>/etc/yum.repos.d/MariaDB.repo
```
For CentOS 6 – 32bit:
```
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.2/centos6-x86
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
```
清楚yum缓存
```
yum clean all
```

### 三、安装 MariaDB Galera Cluster software

如果你做了一个CentOS 6最小安装然后确保你安装socat包从EPEL存储库安装之前,MariaDB Galera集群10.0软件。
　　
您可以使用以下命令安装直接从EPEL socat包(x86_64):

```
# yum install http://dl.fedoraproject.org/pub/epel/6/x86_64/socat-1.7.2.3-1.el6.x86_64.rpm #链接失效
# yum install http://www.rpmfind.net/linux/epel/6/x86_64/Packages/s/socat-1.7.2.3-1.el6.x86_64.rpm -y
```
在CentOS7你可以用下面的命令安装socat包。

```
# yum install socat
```
安装MariaDB Galera集群软件在所有节点

条件：1、至少要三个节点；2、不能安装mariadb-server。

```
# yum install MariaDB-Galera-server MariaDB-client rsync galera
```
### 四、设置mysql密码
```
service mysql start
/usr/bin/mysql_secure_installation
```

###五、创建MariaDB Galera集群用户
　　
现在,我们需要创建一些用户必须能够访问数据库。
“sst_user”是用户的数据库节点将使用状态传输到另一个数据库节点进行身份验证的快照(SST)阶段，在MariaDB-node1，MariaDB-node2，MariaDB-node3节点下操作
```
mysql -u root -p123456
mysql> DELETE FROM mysql.user WHERE user='';
mysql> GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY '123456';
mysql> GRANT USAGE ON *.* to sst_user@'%' IDENTIFIED BY '123456';
mysql> GRANT ALL PRIVILEGES on *.* to sst_user@'%';
mysql> FLUSH PRIVILEGES;
mysql> quit
```
### 六、创建MariaDB Galera集群配置
　　
在所有节点:
```
# service mysql stop
```

接下来,我们将创建MariaDB Galera集群配置。以下命令在所有节点(对于node2以及node3特殊修改):
node1操作：
```
cat > /etc/my.cnf.d/server.cnf << EOF
[galera]
# Mandatory settings
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
wsrep_cluster_address="gcomm://node1,node2,node3"
wsrep_cluster_name='galera_cluster'
wsrep_node_address='node1'
wsrep_node_name='node1'
wsrep_sst_method=rsync
wsrep_sst_auth=sst_user:123456
binlog_format=row
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
innodb_locks_unsafe_for_binlog=1
query_cache_size=0
query_cache_type=0
bind-address=0.0.0.0
datadir=/var/lib/mysql
innodb_log_file_size=100M
innodb_file_per_table
innodb_flush_log_at_trx_commit=2
EOF
```
node2操作：
```
cat > /etc/my.cnf.d/server.cnf << EOF
[galera]
# Mandatory settings
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
wsrep_cluster_address="gcomm://node1,node2,node3"
wsrep_cluster_name='galera_cluster'
wsrep_node_address='node2'
wsrep_node_name='node2'
wsrep_sst_method=rsync
wsrep_sst_auth=sst_user:123456
binlog_format=row
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
innodb_locks_unsafe_for_binlog=1
query_cache_size=0
query_cache_type=0
bind-address=0.0.0.0
datadir=/var/lib/mysql
innodb_log_file_size=100M
innodb_file_per_table
innodb_flush_log_at_trx_commit=2
EOF
```

node3操作：
```
cat > /etc/my.cnf.d/server.cnf << EOF
[galera]
# Mandatory settings
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
wsrep_cluster_address="gcomm://node1,node2,node3"
wsrep_cluster_name='galera_cluster'
wsrep_node_address='node3'
wsrep_node_name='node3'
wsrep_sst_method=rsync
wsrep_sst_auth=sst_user:123456
binlog_format=row
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
innodb_locks_unsafe_for_binlog=1
query_cache_size=0
query_cache_type=0
bind-address=0.0.0.0
datadir=/var/lib/mysql
innodb_log_file_size=100M
innodb_file_per_table
innodb_flush_log_at_trx_commit=2
EOF
```

### 七、初始化第一个集群节点

在节点node1主节点集群的初始化:
```

/etc/init.d/mysql start --wsrep-new-cluster
```
node1检查运行状态:
```
# mysql -uroot -p123456 -e"show status like 'wsrep%'"
+------------------------------+-----------------------------------------------+
| Variable_name                | Value                                         |
+------------------------------+-----------------------------------------------+
| wsrep_local_state_uuid       | e2f25023-54f5-11e8-8866-b64425ca7c4e          |
| wsrep_protocol_version       | 8                                             |
| wsrep_last_committed         | 0                                             |
| wsrep_replicated             | 0                                             |
| wsrep_replicated_bytes       | 0                                             |
| wsrep_repl_keys              | 0                                             |
| wsrep_repl_keys_bytes        | 0                                             |
| wsrep_repl_data_bytes        | 0                                             |
| wsrep_repl_other_bytes       | 0                                             |
| wsrep_received               | 2                                             |
| wsrep_received_bytes         | 134                                           |
| wsrep_local_commits          | 0                                             |
| wsrep_local_cert_failures    | 0                                             |
| wsrep_local_replays          | 0                                             |
| wsrep_local_send_queue       | 0                                             |
| wsrep_local_send_queue_max   | 1                                             |
| wsrep_local_send_queue_min   | 0                                             |
| wsrep_local_send_queue_avg   | 0.000000                                      |
| wsrep_local_recv_queue       | 0                                             |
| wsrep_local_recv_queue_max   | 2                                             |
| wsrep_local_recv_queue_min   | 0                                             |
| wsrep_local_recv_queue_avg   | 0.500000                                      |
| wsrep_local_cached_downto    | 18446744073709551615                          |
| wsrep_flow_control_paused_ns | 0                                             |
| wsrep_flow_control_paused    | 0.000000                                      |
| wsrep_flow_control_sent      | 0                                             |
| wsrep_flow_control_recv      | 0                                             |
| wsrep_cert_deps_distance     | 0.000000                                      |
| wsrep_apply_oooe             | 0.000000                                      |
| wsrep_apply_oool             | 0.000000                                      |
| wsrep_apply_window           | 0.000000                                      |
| wsrep_commit_oooe            | 0.000000                                      |
| wsrep_commit_oool            | 0.000000                                      |
| wsrep_commit_window          | 0.000000                                      |
| wsrep_local_state            | 4                                             |
| wsrep_local_state_comment    | Synced                                        |
| wsrep_cert_index_size        | 0                                             |
| wsrep_causal_reads           | 0                                             |
| wsrep_cert_interval          | 0.000000                                      |
| wsrep_incoming_addresses     | node1:3306                                    |
| wsrep_desync_count           | 0                                             |
| wsrep_evs_delayed            |                                               |
| wsrep_evs_evict_list         |                                               |
| wsrep_evs_repl_latency       | 2.733e-06/1.25476e-05/3.211e-05/1.07544e-05/5 |
| wsrep_evs_state              | OPERATIONAL                                   |
| wsrep_gcomm_uuid             | e2e6ea8c-54f5-11e8-bb22-02c57941271a          |
| wsrep_cluster_conf_id        | 1                                             |
| wsrep_cluster_size           | 1                                             |
| wsrep_cluster_state_uuid     | e2f25023-54f5-11e8-8866-b64425ca7c4e          |
| wsrep_cluster_status         | Primary                                       |
| wsrep_connected              | ON                                            |
| wsrep_local_bf_aborts        | 0                                             |
| wsrep_local_index            | 0                                             |
| wsrep_provider_name          | Galera                                        |
| wsrep_provider_vendor        | Codership Oy <info@codership.com>             |
| wsrep_provider_version       | 25.3.23(r3789)                                |
| wsrep_ready                  | ON                                            |
| wsrep_thread_count           | 2                                             |
+------------------------------+-----------------------------------------------+
```

配置文件里面没有引用
如果wsrep_connected=ON且wsrep_ready=ON则说明节点成功接入集群。
检查配置

```
在主节点上启动（只在主节点）
--wsrep-new-cluster 这个参数只能在初始化集群使用，且只能在一个节点使用。

/etc/init.d/mysql start --wsrep-new-cluster
启动其它子节点
service mysql start
```
启动子节点报错
```
[root@centos189 mysql]# service mysql restart
 ERROR! MariaDB server PID file could not be found!
Starting MariaDB.180511 16:46:29 mysqld_safe Logging to '/var/lib/mysql/centos189.err'.
180511 16:46:29 mysqld_safe Starting mysqld daemon with databases from /var/lib/mysql
............... ERROR! 
 ERROR! Failed to restart server.
 查看错误日志。
```



### 八、在任意一个node节点上，创建数据库，表，添加数据。  停掉某个节点，再恢复。

验证集群的一致性和能否正常工作。

## 普及知识点：GALERA监控
1、常用指令

```
#查看版本：
> SHOW GLOBAL STATUS LIKE"wsrep_provider_version";
```

```
查看wsrep有关的所有变量：
> SHOW VARIABLES LIKE "wsrep%" \G
```
```
查看GALERA集群状态：
SHOW STATUS LIKE "wsrep%";
```


2、集群完整性检查
```
wsrep_local_state_uuid：在集群所有节点的值应该是相同的,有不同值的节点,说明其没有连接入集群
wsrep_cluster_conf_id：正常情况下所有节点上该值是一样的.如果值不同,说明该节点被临时”分区”了.当节点之间网络连接恢复的时候应该会恢复一样的值.
wsrep_cluster_status：集群组成的状态.如果不为”PRIMARY”,说明出现”分区”或是”split-brain”状况.
```


3、节点状态检查
```
wsrep_ready：该值为ON,则说明可以接受SQL负载.如果为Off,则需要检查wsrep_connected
wsrep_connected：如果该值为Off,且wsrep_ready的值也为Off,则说明该节点没有连接到集群.(可能是wsrep_cluster_address或wsrep_cluster_name等配置错造成的.具体错误需要查看错误日志)
wsrep_local_state_comment：如果wsrep_connected为ON,但wsrep_ready为OFF,则可以从该项查看原因
```

4、复制健康检查：
```
wsrep_flow_control_paused：表示复制停止了多长时间.即表明集群因为SLAVE延迟而慢的程度.值为0~1,越靠近0越好,值为1表示复制完全停止.可优化wsrep_slave_threads的值来改善
wsrep_cert_deps_distance：有多少事务可以并行应用处理.wsrep_slave_threads设置的值不应该高出该值太多.
wsrep_flow_control_sent：表示该节点已经停止复制了多少次
wsrep_local_recv_queue_avg：表示SLAVE事务队列的平均长度.slave瓶颈的预兆.
最慢的节点的wsrep_flow_control_sent和wsrep_local_recv_queue_avg这两个值最高.这两个值较低的话,相对更好.
```

5、检测慢网络问题:
```
  wsrep_local_send_queue_avg:网络瓶颈的预兆.如果这个值比较高的话,可能存在网络瓶
5）冲突或死锁的数目:
  wsrep_last_committed:最后提交的事务数目
  wsrep_local_cert_failures和wsrep_local_bf_aborts:回滚,检测到的冲突数目
```
```
Galera的状态快照转移（SST）

  SST允许新接入的节点使用定制的方法来获取最初的数据，当前mysql支持三种SST方法：
  1、mysqldump
    这需要接收服务器在转移前完全初始化和准备接收连接。此方法是通过定义阻塞，阻止修改自身状态转移的持续时间。这也是最慢的方式，可能会带来高负载的问题。
  2、rsync
   最快的方式，也是galera默认使用的方式。rsync脚本运行在发送和接收端上。在接收端，开启rsync服务模式，等待发送端连接。在发送端，开启rsync客户端模式，发送mysql数据目录内容到连接节点。这种方法也会阻塞，但是比mysqldump快。
  3、xtrabackup
   也很快，但需要额外安装。
```

### 搭建集群注意几个参数：
```
Binlog_format=ROW###日志格式必须为ROW
Default_storage_engine=INNODB
Innodb_autoinc_lock_mod2=2 ###指定innodb自增长列锁模式，2为交叉锁模式，多个语句能同时执行
INNODB_LOCKS_UNSAFE_FOR_BINLOG=1
 WSREP_CLUSTER_NAME=CLUSTER_NAME###CLUSTER的名字
WSREP_CLUSTER_ADDRESS=GCOMM://IP1,IP2###集群中所有的node-ip,貌似只写本地也没问题,就是启动的时候写第一节点的IP 即可
Wsrep_node_address=ip ---每个节点配置为自己的IP
WSREP_PROVIDER=/USR/LOCAL/LIB/LIBGALERA_SMM.SO##指定GALERA库文件，PXC自带该库文件，MARIADB GALERA 需要安装GALERA
WSREP_SST_METHOD=RSYNC/XTRABACKUP  #指定SST方式，支持RSYNC（最快，需要表锁），MYSQLDUMP和XTRABACKUP
WSREP_SST_AUTH=SST:123456     ----传输的用户
第一节点启动：不能用mysqld启动
应该为##./mysqld_safe –defaults-file=/etc/my.cnf –wsrep-cluster-address=”gcomm://”&
```


参考：

[How To Setup MariaDB Galera Cluster 10.0 On CentOS](https://www.unixmen.com/setup-mariadb-galera-cluster-10-0-centos/)

[CentOS6.5 64bit + MariaDB 10.0.30 + Galera Cluster 10.0.30 集群部署安装](http://blog.itpub.net/28624388/viewspace-2137268)

























