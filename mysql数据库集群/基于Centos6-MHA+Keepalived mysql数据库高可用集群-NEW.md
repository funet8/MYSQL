[TOC]

# 基于Centos6-MHA+Keepalived mysql数据库高可用集群

## 一、MHA简介
MHA（Master High Availability）目前在MySQL高可用方面是一个相对成熟的解决方案。在MySQL故障切换过程中，MHA能做到在0~30秒之内手动或自动（结合脚本）完成数据库的故障切换操作，并且在进行故障切换的过程中，MHA能在最大程度上保证数据的一致性，以达到真正意义上的高可用性。

该软件由两部分组成：MHA Manager（管理节点）和MHA Node（数据节点）。MHA Manager可以单独部署在一台独立的机器上管理多个master-slave集群，也可以部署在一台slave节点上。MHA Node运行在每台MySQL服务器上，MHA Manager会定时探测集群中的master节点，当master出现故障时，它可以自动将最新数据的slave提升为新的master，然后将所有其他的slave重新指向新的master。整个故障转移过程对应用程序完全透明。


## 二、试验清单-centos6
节点 | 角色 | MYSQL | keepalived | MHA | IP | 备注
---|---|---|---|---|---|---
vm02 | MHA manager | ---- | --- | MHA-manager | 192.168.1.2 | -
vm03 | mysql master| MariaDB-10.0.35 | Keepalived v1.2 | MHA-node | 192.168.1.3 | -
vm04 | mysql slave | MariaDB-10.0.35 | Keepalived v1.2 | MHA-node | 192.168.1.4 | (备主)
vm05 | mysql slave | MariaDB-10.0.35 | --- | MHA-node | 192.168.1.5 | -
**VIP地址：192.168.1.8**

**ssh端口为60920**

**mysql端口为:61920**
# 具体安装步骤
## 一、配置mysql半同步方式
### 1.安装mysql（vm03、vm04、vm05上安装）
具体安装步骤省略

### 2.配置hosts环境

2.各个节点之间需通过主机名可互相通信，所有主机/etc/hosts文件添加
在vm01上操作：
```
echo "192.168.1.2 vm02 mha.mysqlmha.com
192.168.1.3 vm03 mysql.mysqlmha.com
192.168.1.4 vm04 slave1.mysqlmha.com
192.168.1.5 vm05 slave2.mysqlmha.com">> /etc/hosts
```
```
for i in 3 4 5 ; do scp -P 60920 /etc/hosts 192.168.1.$i:/etc/hosts;done
```

### 3.安装MYSQL主从半同步
所有MYSQL 数据库都需要安装半同步插件：
```
mysql> INSTALL PLUGIN rpl_semi_sync_master SONAME 'semisync_master.so';
Query OK, 0 rows affected (0.04 sec)
mysql> INSTALL PLUGIN rpl_semi_sync_slave SONAME 'semisync_slave.so';
Query OK, 0 rows affected (0.02 sec)
或者：
mysql -p123456 -e"INSTALL PLUGIN rpl_semi_sync_master SONAME 'semisync_master.so';"
mysql -p123456 -e"INSTALL PLUGIN rpl_semi_sync_slave SONAME 'semisync_slave.so';"
```
配置my.cnf
三台机器上都需要开启半同步功能，其中参数配置仅server-id不同
```
[mysqld]
#mysql半同步复制
rpl_semi_sync_master_enabled=1
rpl_semi_sync_master_timeout=1000
rpl_semi_sync_slave_enabled=1
relay_log_purge=0
skip-name-resolve
server-id=1 # vm03为1，其他随意
log-bin=mysql-bin
read_only=1
slave-skip-errors=1396
```
查看半同步状态：
```
mysql -p123456 -e"show variables like '%sync%';"

```
```
mysql -p123456 -e"show status like '%sync%';"
```


### 4.配置ssh免密码登录

配置MHA-Manager(vm02)到所有MHA-node(vm03,vm04,vm05)
```
[root@vm02 ~]# ssh-keygen -t rsa         #一直回车
[root@vm02 ~]# hosts="vm03 vm04 vm05"
[root@vm02 ~]# for host in ${hosts[*]};do ssh-copy-id -i /root/.ssh/id_rsa.pub "-p 60920  $host";done; #ssh端口为60920 改为实际
验证：
[root@vm02 ~]#  ssh -p60920 vm03
```
vm03、vm04、vm05上同样操作

### 5.配置数据库主从
主节点(vm03)授权repluser及mhaadmin用户：
```
授权： 
MariaDB [(none)]> grant replication slave,replication client on *.* to 'repluser'@'192.168.1.%' identified by 'replpass' ;
MariaDB [(none)]> grant all on *.* to 'mhaadmin'@'192.168.1.%' identified by 'mhapass' ;
MariaDB [(none)]> show master status\G
*************************** 1. row ***************************
            File: mysql-bin.000001
        Position: 312
    
```
从节点(vm04和vm05)启动复制：master_log_file,master_log_pos 为刚刚在master查看的maser日志状态；
```
# mysql -p123456
MariaDB [(none)]> stop slave;
MariaDB [(none)]> reset slave;
MariaDB [(none)]> change master to master_host='192.168.1.3',master_user='repluser',master_port=61920,master_password='replpass',master_log_file='mysql-bin.000001',master_log_pos=312;
MariaDB [(none)]> start slave; 
MariaDB [(none)]> show slave status\G
```
### 6、配置keepalived高可用VIP
在master(vm03)及备用master(vm04)节点安装keepalived
```
yum install -y keepalived
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
	interface eth2
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
		192.168.1.8/24 dev eth2 #高可用的VIP地址
	}
}
```
重启keepalived
```
chkconfig keepalived on
service keepalived restart
```


## 三、安装配置MHA
在主节点上mha4mysql-manager及其mha4mysql-node两管理软件

下载地址：
https://downloads.mariadb.com/MHA/
https://pan.baidu.com/s/1b4JxE2
本次安装 mha4mysql-manager-0.53.tar.gz 和 mha4mysql-node-0.53.tar.gz 


vm02上执行安装 mha4mysql-manager

```
rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
yum clean all
yum makecache
rpm --import /etc/pki/rpm-gpg/*
```

安装MHA manager
```
#安装依耐项
yum -y install  perl-DBD-mysql perl-Config-Tiny perl-Log-Dispatch perl-Parallel-ForkManager perl-Config-IniFiles ncftp perl-Params-Validate perl-CPAN perl-TEST-MOCK-LWP.noarch perl-LWP-Authen-Negotiate.noarch perl-devel perl-ExtUtils-CBuilder perl-ExtUtils-MakeMaker

wget https://raw.githubusercontent.com/funet8/MYSQL/master/High_Availability/MHA_Keepalived/mha4mysql-manager-0.53.tar.gz
tar -zxvf mha4mysql-manager-0.53.tar.gz 
cd mha4mysql-manager-0.53
perl Makefile.PL 
make && make install
```
安装MHA node
```
#安装依耐项
yum -y install  perl-DBD-mysql perl-Config-Tiny perl-Log-Dispatch perl-Parallel-ForkManager perl-Config-IniFiles ncftp perl-Params-Validate perl-CPAN perl-TEST-MOCK-LWP.noarch perl-LWP-Authen-Negotiate.noarch perl-devel perl-ExtUtils-CBuilder perl-ExtUtils-MakeMaker

wget https://raw.githubusercontent.com/funet8/MYSQL/master/High_Availability/MHA_Keepalived/mha4mysql-node-0.53.tar.gz
tar -zxvf mha4mysql-node-0.53.tar.gz 
cd mha4mysql-node-0.53
perl Makefile.PL 
make && make install
```

vm2 MHA manager节点上操作
```
mkdir /etc/masterha/
mkdir -p /master/app1
mkdir -p /scripts
cp /root/mha4mysql-manager-0.53/samples/scripts/* /scripts
cp /root/mha4mysql-manager-0.53/samples/conf/* /etc/masterha
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

参考：
[MHA+keepalived 高可用MYSQL集群](http://www.178linux.com/70072)















































































