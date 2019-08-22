# MariaDB Galera Cluster 部署（如何快速部署MariaDB集群）


https://blog.csdn.net/luoxq111/article/details/54944973

## 环境搭建
### 在docker中做测试

```
暴露端口
docker run -itd --name MariaDB-node1 -p 61951:3306 -p 60921:22 registry.cn-shenzhen.aliyuncs.com/funet8/centos7.2-base:v1
docker run -itd --name MariaDB-node2 -p 61952:3306 -p 60922:22 registry.cn-shenzhen.aliyuncs.com/funet8/centos7.2-base:v1
docker run -itd --name MariaDB-node3 -p 61953:3306 -p 60923:22 registry.cn-shenzhen.aliyuncs.com/funet8/centos7.2-base:v1
```

分别进入容器查看ip
```
docker exec -it MariaDB-node1 /bin/bash
docker exec -it MariaDB-node2 /bin/bash
docker exec -it MariaDB-node3 /bin/bash
```

名称 | IP
---|---
MariaDB-node1 | 172.17.0.2
MariaDB-node2 | 172.17.0.3
MariaDB-node3 | 172.17.0.4

操作步骤
### 一、关闭SELINUX和防火墙

### 二、设置mariadb的yum源并安装（所有节点都要）
```
修改yum源文件 
 vi /etc/yum.repos.d/mariadb.repo
--------------------------------------------------
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
enabled=0
```

**mariadb官方镜像非常慢、非常慢。使用国内的镜像：**
```
[mariadb]
name = MariaDB
baseurl = https://mirrors.ustc.edu.cn/mariadb/yum/10.3/centos7-amd64
gpgkey=https://mirrors.ustc.edu.cn/mariadb/yum/RPM-GPG-KEY-MariaDB
gpgcheck=1
```
### 三、安装数据及服务组件

```
yum --enablerepo=mariadb -y install MariaDB-server galera  MariaDB-client rsync
```
### 四、配置 第一个节点[MariaDB-node1]

1、建立Cluster使用者，密码及用户(现用默认root用户，设置远程登录)
```
# /etc/init.d/mysql start
# mysqladmin -u root flush-privileges password '123456'
# mysql -uroot -p
MariaDB [(none)]> use mysql;
MariaDB [mysql]> grant all privileges on *.* to root@'%' identified by '123456';
```
2、主节点的配置文件server.cnf

```
# cp /etc/my.cnf.d/server.cnf /etc/my.cnf.d/server_bak.cnf
# vi /etc/my.cnf.d/server.cnf

#
# * Galera-related settings
#
[galera]
# Mandatory settings
wsrep_on=ON  ##开启wsrep服务
wsrep_provider=/usr/lib64/galera/libgalera_smm.so  ##加入/usr/lib64/galera/libgalera_smm.so
wsrep_cluster_address="gcomm://"   
binlog_format=row
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
#
# Allow server to accept connections on all interfaces.
#
bind-address=0.0.0.0
#
# Optional setting
#wsrep_slave_threads=1
#innodb_flush_log_at_trx_commit=0

# add follows
# cluster name
wsrep_cluster_name="MariaDB_Cluster"
# own IP address（当前节点的IP）
wsrep_node_address="172.17.0.2"
wsrep_node_name='radiusone'
# replication provider
wsrep_sst_method=rsync

```
3、启动集群：/bin/galera_new_cluster 
```
# /bin/galera_new_cluster
```







## 结论：不适应本公司业务生成环境

1.在生产环境下应该避免使用大事务，不建议在高并发写入场景下使用Galera Cluster架构，会导致集群限流，从而引起整个集群hang住，出现生产故障。针对这种情况可以考虑主从，实现读写分离等手段。

2. 对数据一致性要求较高，并且数据写入不频繁，数据库容量也不大（50GB左右），网络状况良好的情况下，可以考虑使用Galera方案







参考：
MariaDB Galera Cluster 部署（如何快速部署MariaDB集群）
http://www.linuxidc.com/Linux/2015-07/119512.htm

在CentOS7上配置MariaDB-Galera-Cluster过程全记录
https://www.cnblogs.com/cured/p/7636480.html

CentOS 7.2部署MariaDB Galera Cluster(10.1.21-MariaDB) 3主集群环境
https://blog.csdn.net/jiangshouzhuang/article/details/62468778

MariaDB Galera Cluster集群优缺点
https://blog.csdn.net/educast/article/details/78678152

Centos7下安装最新的MariaDB 10.2
http://blog.csdn.net/junehappylove/article/details/78690743

Galera将死——MySQL Group Replication正式发布
http://www.kejixun.com/article/161214/260357.shtml







