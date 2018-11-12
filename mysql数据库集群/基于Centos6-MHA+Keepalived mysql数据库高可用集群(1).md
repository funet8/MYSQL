# 基于Centos6-MHA+Keepalived mysql数据库高可用集群

参考：
[MHA+keepalived 高可用MYSQL集群](http://www.178linux.com/70072)
[TOC]

一、MHA简介

二、试验环境及要求

三、部署MHA

四、测试MHA集群功能

## 一、MHA简介
MHA（Master High Availability）目前在MySQL高可用方面是一个相对成熟的解决方案。在MySQL故障切换过程中，MHA能做到在0~30秒之内手动或自动（结合脚本）完成数据库的故障切换操作，并且在进行故障切换的过程中，MHA能在最大程度上保证数据的一致性，以达到真正意义上的高可用性。

该软件由两部分组成：MHA Manager（管理节点）和MHA Node（数据节点）。MHA Manager可以单独部署在一台独立的机器上管理多个master-slave集群，也可以部署在一台slave节点上。MHA Node运行在每台MySQL服务器上，MHA Manager会定时探测集群中的master节点，当master出现故障时，它可以自动将最新数据的slave提升为新的master，然后将所有其他的slave重新指向新的master。整个故障转移过程对应用程序完全透明。
![MHA](http://img.funet8.com/mysql-mha2.jpg)


### 试验清单-centos6
节点 | 角色 | MYSQL | keepalived | MHA | IP | 备注
---|---|---|---|---|---|---
vm01 | MHA manager | ---- | --- | MHA-manager | 192.168.4.186 | -
vm02 | mysql master| MariaDB-10.0.35 | Keepalived v1.2 | MHA-node | 192.168.4.188 | -
vm03 | mysql slave | MariaDB-10.0.35 | Keepalived v1.2 | MHA-node | 192.168.4.189 | (备主)
vm04 | mysql slave | MariaDB-10.0.35 | --- | MHA-node | 192.168.4.191 | -
说明：VIP地址：192.168.4.190

## 一、安装Ansible
各个节点之间需通过主机名可互相通信，所有主机/etc/hosts文件添加
```
echo "192.168.4.186 vm01
192.168.4.188 vm02
192.168.4.189 vm03
192.168.4.191 vm04">> /etc/hosts
```

1.安装ansible
```
rpm -Uvh http://ftp.linux.ncsu.edu/pub/epel/6/i386/epel-release-6-8.noarch.rpm
# yum install ansible -y

# vi /etc/profile
添加：
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# source /etc/profile
```
2.配置
```
# cd /etc/ansible
# cp hosts hosts.bak
# cat /dev/null > hosts

```

```
# vi /etc/ansible/hosts
添加：
[MHA]
vm01:60920
vm02:60920
vm03:60920
vm04:60920
[MYSQL-NODE]
vm02:60920
vm03:60920
vm04:60920
```
配置各个服务器免密码登录，略



##二、部署MHA
### 1、确保各节点之间时间同步
```
[root@centos186 ansible]# ansible MYSQL-NODE -m shell -a "date"
vm03 | SUCCESS | rc=0 >>
Tue May 15 10:28:08 CST 2018
vm04 | SUCCESS | rc=0 >>
Tue May 15 10:28:04 CST 2018
vm02 | SUCCESS | rc=0 >>
Tue May 15 10:28:22 CST 2018
```
### 2、时间未同步、操作三台mysql服务器时间同步。
```
[root@centos186 ansible]# ansible MYSQL-NODE -m shell -a "date"
vm02 | SUCCESS | rc=0 >>
Tue May 15 10:37:41 CST 2018
vm04 | SUCCESS | rc=0 >>
Tue May 15 10:37:41 CST 2018
vm03 | SUCCESS | rc=0 >>
Tue May 15 10:37:41 CST 2018
```

### 3、配置mysql集群，确保主从复制正常

mysql-mastet节点(vm02)配置：
```
#vi /etc/my.cnf
[mysqld]
server-id=1
log-bin=mysql-log
relay-log=relay-log
```
#slave节点(vm03)配置：

```
#vi /etc/my.cnf
[mysqld]
server-id=2
log-bin=mysql-log
relay-log=relay-log
relay_log_purge=0
read_only=1
skip_name_resolve=1
innodb_file_per_table=1
```
#slave节点(vm04)配置：
```
#vi /etc/my.cnf
[mysqld]
server-id=3
log-bin=master-log
relay-log=relay-log
relay_log_purge=0
read_only=1
skip_name_resolve=1
innodb_file_per_table=1
```
重启mysql
```
[root@centos186 ansible]# ansible MYSQL-NODE -m service -a "name=mysql state=restarted"
vm04 | SUCCESS => {
    "changed": true, 
    "name": "mysql", 
    "state": "started"
}
vm03 | SUCCESS => {
    "changed": true, 
    "name": "mysql", 
    "state": "started"
}
vm02 | SUCCESS => {
    "changed": true, 
    "name": "mysql", 
    "state": "started"
}
```

主节点(vm02)授权repluser及mhaadmin用户：
```
MariaDB [(none)]> show master status\G
*************************** 1. row ***************************
            File: mysql-log.000002
        Position: 312
    Binlog_Do_DB: 
Binlog_Ignore_DB: 
1 row in set (0.00 sec)
MariaDB [(none)]> grant replication slave,replication client on *.* to 'repluser'@'192.168.4.%' identified by 'replpass' ;
Query OK, 0 rows affected (10.06 sec)
MariaDB [(none)]> grant all on *.* to 'mhaadmin'@'192.168.4.%' identified by 'mhapass' ;
Query OK, 0 rows affected (0.00 sec)

```
从节点(vm03和vm04)启动复制：master_log_file,master_log_pos 为刚刚在master查看的maser日志状态；
```
[root@centos189 ~]# mysql -p
MariaDB [(none)]> stop slave;
MariaDB [(none)]> reset slave;
MariaDB [(none)]> change master to master_host='192.168.4.188',master_user='repluser',master_port=61920,master_password='replpass',master_log_file='mysql-log.000006',master_log_pos=326;
MariaDB [(none)]> start slave; 
MariaDB [(none)]> show slave status\G
```
### 4、配置keepalived高可用VIP
在master(vm02)及备用master(vm03)节点安装keepalived
```
yum intall -y keepalived
```
配置keepalived，注意主备配置
```
vi /etc/keepalived/keepalived.conf 
填写一下：
! Configuration File for keepalived

global_defs {
notification_email {
	funet8@163.com
}
notification_email_from funet8@163.com
smtp_server 192.168.1.1
smtp_connect_timeout 30
router_id mysql
vrrp_mcast_group4 224.0.88.88 #组播地址
}

vrrp_script chk_mysqld {
script "killall -0 mysqld && exit 0 || exit 1"
interval 1
weight -5
fall 2
}

vrrp_instance VI_1 {
	state MASTER #角色主MASTER，备服务器改为BACKUP
	interface eth1
	virtual_router_id 8
	priority 100 #权重，jev2上的值要略低于100，但要高于100-weight，本例应为96-99
	advert_int 1
	nopreempt #不抢占模式，从节点上不必配置此项

	authentication {
		auth_type PASS
		auth_pass mysqlvipass
	}
	track_script {
		chk_mysqld
	}
	virtual_ipaddress {
		192.168.4.190/24 dev eth1 #高可用的VIP地址
	}
}
```
重启keepalived
```
service keepalived restart
```


## 三、安装配置MHA
在主节点上mha4mysql-manager及其mha4mysql-node两管理软件
https://downloads.mariadb.com/MHA/
vm01上执行
```
yum install -y https://downloads.mariadb.com/MHA/mha4mysql-manager-0.53-0.el6.noarch.rpm
yum install -y https://downloads.mariadb.com/MHA/mha4mysql-node-0.53-0.el6.noarch.rpm
```
vm2,vm3,vm4上执行
```
yum install -y https://downloads.mariadb.com/MHA/mha4mysql-node-0.53-0.el6.noarch.rpm
```

创建配置文件
```
# mkdir /etc/masterha/
# vi !$app1.cnf
vim /etc/masterha/app1.cnf
[server default]
user=mhaadmin
password=mhapass
manager_workdir=/data/masterha/app1
manager_log=/data/masterha/app1/manager.log
remote_workdir=/data/masterha/app1
ssh_user=root
repl_user=repluser
repl_password=replpass
ping_interval=1

[server1]
hostname=192.168.4.188
candidate_master=1

[server2]
hostname=192.168.4.189
candidate_master=1

[server3]
hostname=192.168.4.191

#mkdir -pv /data/masterha/app1
```

四、测试MHA集群功能

1、检查主机间SSH通讯及健康状态
检查主机之间ssh通讯状态，状态必须为All SSH connection tests passed successfully.才能进行后面操作；
```
[root@centos186 app1]# masterha_check_ssh --conf=/etc/masterha/app1.cnf
Tue May 15 15:39:18 2018 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Tue May 15 15:39:18 2018 - [info] Reading application default configurations from /etc/masterha/app1.cnf..
Undefined subroutine &MHA::NodeUtil::escape_for_shell called at /usr/local/share/perl5/MHA/Config.pm line 291.

Tue May 15 15:49:18 2018 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Tue May 15 15:49:18 2018 - [info] Reading application default configurations from /etc/masterha/app1.cnf..
Undefined subroutine &MHA::NodeUtil::escape_for_shell called at /usr/local/share/perl5/MHA/Config.pm line 291.

报错：

```

检查集群就看状态，状态必须为MySQL Replication Health is OK.才能进行后面操作；
```
[root@centos186 app1]# masterha_check_repl --conf=/etc/masterha/app1.cnf
Tue May 15 15:41:07 2018 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Tue May 15 15:41:07 2018 - [info] Reading application default configurations from /etc/masterha/app1.cnf..
Tue May 15 15:41:07 2018 - [error][/usr/local/share/perl5/MHA/MasterMonitor.pm, ln386] Error happend on checking configurations. Undefined subroutine &MHA::NodeUtil::escape_for_shell called at /usr/local/share/perl5/MHA/Config.pm line 291.
Tue May 15 15:41:07 2018 - [error][/usr/local/share/perl5/MHA/MasterMonitor.pm, ln482] Error happened on monitoring servers.
Tue May 15 15:41:07 2018 - [info] Got exit code 1 (Not master dead).

MySQL Replication Health is NOT OK!
报错：
```















































































