# 基于Centos6-MHA+Keepalived mysql数据库高可用集群


目前MHA主流架构是一主多从，此次部署采用一主二从（一台充当master，一台充当备用master，一台充当从库）

架构图：
![mysql-MHA](http://img.funet8.com/mysql-mha.png)

4台centos6.8 私有云主机，VIP为192.168.4.251

主机名 | IP | 职能 | 部署软件
---|---|---|---
vm01 | 192.168.4.186 | MHA-Manager  | MHA-Manager,MHA-node
vm02 | 192.168.4.188 | mysql-master | MariaDB,MHA-node
vm03 | 192.168.4.189 | mysql-master-backup | MariaDB,MHA-node,keepalived
vm04 | 192.168.4.191 | mysql-slave | MariaDB,MHA-node,keepalived

所有主机/etc/hosts文件添加

```
echo "192.168.4.186 vm01
192.168.4.188 vm02
192.168.4.189 vm03
192.168.4.191 vm04">> /etc/hosts
```
## 一、服务器mysql环境部署
略
## 二、修改MYSQL配置文件

## vm02的配置，其他 server-id不同。
```
vi /etc/my.cnf
[client]

port		= 61920
socket		= /var/lib/mysql/mysql.sock

[mysqld]
port		= 61920
socket		= /var/lib/mysql/mysql.sock

skip-name-resolve
expire_logs_days=10

slow-query-log=1
slow-query-log-file=/data/wwwroot/mysql_log/slowQuery.log
long-query-time=1 
#log-queries-not-using-indexes
log-slow-admin-statements 


skip-external-locking
key_buffer_size = 100M
max_allowed_packet = 1M
table_open_cache = 1024
sort_buffer_size = 2M
read_buffer_size = 2M
read_rnd_buffer_size = 8M
myisam_sort_buffer_size = 64M
thread_cache_size = 8
query_cache_size = 32M
thread_concurrency = 1

log-bin=mysql-bin

server-id	= 1

max_connections = 1000
interactive_timeout = 15
wait_timeout = 15
tmp_table_size=300M
max_heap_table_size=300M

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash
# Remove the next comment character if you are not familiar with SQL
#safe-updates

[myisamchk]
key_buffer_size = 256M
sort_buffer_size = 256M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout
```

## 三、配置主从半同步复制
在mysql master(vm02)上创建主从复制账号
```
mysql -uroot -p
> grant replication slave on *.* to 'repl'@'192.168.4.%' identified by '654321';

```
备份mysql master上数据库(或者直接物理备份到slave上也行） 
其中–master-data=2代表备份时刻记录master的Binlog位置和Position，–single-transaction意思是获取一致性快照，-R意思是备份存储过程和函数，–triggres的意思是备份触发器，-A代表备份所有的库。
```
[root@vm02 ~]# mysqldump -uroot -p --master-data=2 --single-transaction --default-character-set=utf8mb4 -R --triggers -A >/root/master_data.sql
```
将备份的数据传送到vm03,vm04服务器
```
[root@vm02 ~]# hosts="vm03 vm04"
[root@vm02 ~]# for host in ${hosts[*]};do rsync -e 'ssh -p 60920' -avzP /root/master_data.sql $host:/root;done; #ssh端口为60920 改为实际
```
在vm03,vm04上恢复数据

```
[root@vm03 src]# mysql -uroot -p123456 </root/master_data.sql
[root@vm04 src]# mysql -uroot -p123456 </root/master_data.sql 
```
在vm03(mysql-master-backup)上配置主从同步，此master备机上也需开启bin-log
```
查看数据库偏移量：
head -n30 /root/master_data.sql 
-- CHANGE MASTER TO MASTER_LOG_FILE='mysql-bin.000006', MASTER_LOG_POS=502;
```
```
[root@vm03 src]# mysql -uroot -p123456
> change master to master_host='192.168.4.188',master_port=61920,master_user='repl',master_password='654321',master_log_file='mysql-bin.000006',master_log_pos=502;
Query OK, 0 rows affected (0.02 sec)
> start slave;
> show slave status\G;
```
vm04(slave)操作与vm03操作相同，由于这台只做从库，只需要修改server id即可,不需要开启log-bin。
```
[root@vm04 src]# mysql -uroot -p123456
> change master to master_host='192.168.4.188',master_port=61920,master_user='repl',master_password='654321',master_log_file='mysql-bin.000006',master_log_pos=502;
Query OK, 0 rows affected (0.02 sec)
> start slave;
> show slave status\G
```
MySQL复制默认是异步复制，Master将事件写入binlog，但并不知道Slave是否或何时已经接收且已处理。在异步复制的机制的情况下，如果Master宕机，事务在Master上已提交，但很可能这些事务没有传到任何的Slave上。假设有Master->Salve故障转移的机制，此时Slave也可能会丢失事务。

半同步复制的功能要在Master，Slave都开启，半同步复制才会起作用；否则，只开启一边，它依然为异步复制。

mysql5.5及更高版本才有半同步复制功能。在MySQL上安装插件需要数据库支持动态载入。检查是否支持，用如下检测：
```
> show global variables like 'have_dynamic_loading';
+----------------------+-------+
| Variable_name        | Value |
+----------------------+-------+
| have_dynamic_loading | YES   |
+----------------------+-------+
1 row in set (0.00 sec)
```
半同步复制是基于复制的环境。也就是说配置半同步复制前，已有复制的环境。

在所有mysql节点(主，从)安装半同步插件

```
mysql> INSTALL PLUGIN rpl_semi_sync_master SONAME 'semisync_master.so';
Query OK, 0 rows affected (0.04 sec)
mysql> INSTALL PLUGIN rpl_semi_sync_slave SONAME 'semisync_slave.so';
Query OK, 0 rows affected (0.02 sec)
```
如果不清楚Plugin的目录，用如下查找：
```
mysql>  show global variables like 'plugin_dir';
```
检查Plugin是否已正确安装
```
mysql> show plugins;
或者
mysql> select * from information_schema.plugins where PLUGIN_NAME like "rpl_semi_sync%";

```
在Master上执行：
```
SET GLOBAL rpl_semi_sync_master_enabled = 1;
```
在所有Slave上执行(包括master备机)： 
```
mysql> show variables like "rpl_semi_sync_slave_enabled";
mysql> SET GLOBAL rpl_semi_sync_slave_enabled = 1;
mysql> show variables like "rpl_semi_sync_slave_enabled";
```
如果在一个正在运行的Slave上开启半同步复制的功能，必须先停止Slave I/O,将其启用半同步后，再开启Slave I/O.
```
mysql> STOP SLAVE IO_THREAD; START SLAVE IO_THREAD;
```
如果不这样做，Slave还是会以异步的方式进行复制。 
正如大家所知，如果不将变量的设置写到配置文件，下次重启数据库，将失效。写入配置文件：

Master上：
```
[mysqld]
#mysql半同步复制
rpl_semi_sync_master_enabled=1
rpl_semi_sync_master_timeout=10000  # 10秒（默认）
```

所有Slave上：
```
[mysqld]
rpl_semi_sync_slave_enabled=1
```

## 四、配置ssh免密码登录
配置MHA-Manager(vm01)到所有MHA-node(vm02,vm03,vm04)
```
[root@vm01 ~]# ssh-keygen -t rsa         #一直回车
[root@vm01 ~]# hosts="vm02 vm03 vm04"
[root@vm01 ~]# for host in ${hosts[*]};do ssh-copy-id -i /root/.ssh/id_rsa.pub "-p 60920  $host";done; #ssh端口为60920 改为实际
```
验证：
```
[root@vm01 ~]#  ssh -p60920 vm03
```
配置mysql master(vm02)到所有MHA-node(vm01,vm03,vm04)
```
[root@vm02 ~]# ssh-keygen -t rsa         #一直回车
[root@vm02 ~]# hosts="vm01 vm03 vm04"
[root@vm02 ~]# for host in ${hosts[*]};do ssh-copy-id -i /root/.ssh/id_rsa.pub "-p 60920  $host";done; #ssh端口为60920 改为实际
```
配置mysql slave(vm03,vm04)到所有MHA-node
```
[root@vm03 ~]# ssh-keygen -t rsa         #一直回车
[root@vm03 ~]# hosts="vm01 vm02 vm04"       
[root@vm03 ~]# for host in ${hosts[*]};do ssh-copy-id -i /root/.ssh/id_rsa.pub "-p 60920  $host";done; #ssh端口为60920 改为实际

[root@vm04 ~]# ssh-keygen -t rsa         #一直回车
[root@vm04 ~]# hosts="vm01 vm02 vm03"       
[root@vm04 ~]# for host in ${hosts[*]};do ssh-copy-id -i /root/.ssh/id_rsa.pub "-p 60920  $host";done; #ssh端口为60920 改为实际

```
## 五、在mysql master数据库中创建mha管理用户
```
mysql> grant all privileges on *.* to 'mha'@'192.168.4.%' identified by 'mha@password';
Query OK, 0 rows affected (0.01 sec)

mysql> flush privileges;
Query OK, 0 rows affected (0.00 sec)
```
在从库上检察是否同步
```
> select host,user,password from mysql.user;
+-----------------------+----------+-------------------------------------------+
| host                  | user     | password                                  |
+-----------------------+----------+-------------------------------------------+
| localhost             | root     | *6BB4837EB74329105EE4568DDA7DC67ED2CA2AD9 |
| localhost.localdomain | root     | *6BB4837EB74329105EE4568DDA7DC67ED2CA2AD9 |
| 127.0.0.1             | root     | *6BB4837EB74329105EE4568DDA7DC67ED2CA2AD9 |
| ::1                   | root     | *6BB4837EB74329105EE4568DDA7DC67ED2CA2AD9 |
| %                     | root     | *6BB4837EB74329105EE4568DDA7DC67ED2CA2AD9 |
| %                     | sst_user | *6BB4837EB74329105EE4568DDA7DC67ED2CA2AD9 |
| 192.168.4.%           | repl     | *2A032F7C5BA932872F0F045E0CF6B53CF702F2C5 |
| 192.168.4.%           | mha      | *792262F3BDF0EAA8F94DA7C5FA717730EF732632 |
+-----------------------+----------+-------------------------------------------+
8 rows in set (0.00 sec)
```
## 六、安装MHA
MHA特点： 
MHA监控复制架构的主服务器，一旦检测到主服务器故障，就会自动进行故障转移。即使有些从服务器没有收到最新的relay log，MHA自动从最新的从服务器上识别差异的relay log并把这些日志应用到其他从服务器上，因此所有的从服务器保持一致性了。MHA通常在几秒内完成故障转移，9-12秒可以检测出主服务器故障，7-10秒内关闭故障的主服务器以避免脑裂，几秒中内应用差异的relay log到新的主服务器上，整个过程可以在10-30s内完成。还可以设置优先级指定其中的一台slave作为master的候选人。由于MHA在slaves之间修复一致性，因此可以将任何slave变成新的master，而不会发生一致性的问题，从而导致复制失败。 
mha下载及文档地址: https://code.google.com/p/mysql-master-ha/
国内访问谷歌需要翻墙。

所有服务器配置epel的yum源，安装相关依赖包
```
rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
sed -i 's/^#baseurl/baseurl/g' /etc/yum.repos.d/epel.repo
sed -i 's/^mirrorlist/#mirrorlist/g' /etc/yum.repos.d/epel.repo

sed -i 's/^#baseurl/baseurl/g' /etc/yum.repos.d/epel-testing.repo
sed -i 's/^mirrorlist/#mirrorlist/g' /etc/yum.repos.d/epel-testing.repo
```
在所有运行MySQL服务的服务器上安装运行MHA-Node，无论是master还是slave。由于MHA-Manager需要MHA-Node，因此在运行MHA-Manager的服务器上也需要安装MHA-Node

安装mha-manager依赖

```
#yum install -y perl-Config perl-Log-Dispatch perl-Parallel-ForkManager perl-Time-HiRes cpan
有一个报错：
No package perl-Config available.
```

mha4mysql-manager和mha4mysql-node下载地址：
```
https://downloads.mariadb.com/MHA/
```
安装mha-manager
```
wget https://downloads.mariadb.com/MHA/mha4mysql-manager-0.55.tar.gz
# tar zxf mha4mysql-manager-0.55.tar.gz
# cd mha4mysql-manager-0.55
# perl Makefile.PL 
# make && make install
```
安装完成后，会在/usr/local/bin目录下生成以下脚本文件
```
# ls /usr/local/bin/masterha_*
/usr/local/bin/masterha_check_repl    /usr/local/bin/masterha_conf_host       /usr/local/bin/masterha_master_switch
/usr/local/bin/masterha_check_ssh     /usr/local/bin/masterha_manager         /usr/local/bin/masterha_secondary_check
/usr/local/bin/masterha_check_status  /usr/local/bin/masterha_master_monitor  /usr/local/bin/masterha_stop

```
此外，mha-manager源码包解压出来，会有一些脚本模板可供参考(因为这些脚本不完整，需要自己修改，这是软件开发着留给我们自己发挥的，如果开启下面的任何一个脚本对应的参数，而对应这里的脚本又没有修改，则会抛错，可能会被坑的很惨)

1、master_ip_failover是自动切换时vip管理的脚本，不是必须，如果我们使用keepalived的，我们可以自己编写脚本完成对vip的管理，比如监控mysql，如果mysql异常，我们停止keepalived就行，这样vip就会自动漂移
```
[root@vm01 scripts]# ls -l /usr/local/src/mha4mysql-manager-0.55/samples/scripts/master_ip_failover 
-rwxr-xr-x 1 root root 3648 Dec 13  2012 /usr/local/src/mha4mysql-manager-0.55/samples/scripts/master_ip_failover
```
2、master_ip_online_change是在线切换时vip的管理，不是必须，同样可以可以自行编写简单的shell完成
```
[root@vm01 scripts]# ls -l /usr/local/src/mha4mysql-manager-0.55/samples/scripts/master_ip_online_change
-rwxr-xr-x 1 root root 9568 Dec 13  2012 /usr/local/src/mha4mysql-manager-0.55/samples/scripts/master_ip_online_change
```
3、power_manager故障发生后关闭主机的脚本，不是必须
```
[root@vm01 scripts]# ls -l /usr/local/src/mha4mysql-manager-0.55/samples/scripts/power_manager
-rwxr-xr-x 1 root root 11867 Dec 13  2012 /usr/local/src/mha4mysql-manager-0.55/samples/scripts/power_manager
```
安装mha-node依赖
```
[root@vm01 src]# yum install -y perl-DBD-MySQL perl-Module-Install cpan
```
```
[root@vm01 src]# wget https://downloads.mariadb.com/MHA/mha4mysql-node-0.54-0.el6.noarch.rpm
[root@vm01 src]# rpm -ivh mha4mysql-node-0.54-0.el6.noarch.rpm 
Preparing...                ########################################### [100%]
   1:mha4mysql-node         ########################################### [100%]
```
其它服务器(vm02,vm03,vm04)安装mha-node及其依赖和vm01安装完全一样。
## 七、配置MHA 
源码包里有配置文件模板，可参考: mha4mysql-manager-0.55源码压缩包里samples/conf目录下的模板配置文件。
创建mha配置文件目录
```
[root@vm01 src]# mkdir -p /data/mha/app1
```
mha配置文件app1.conf 
（在软件包解压后的目录里面有样例配置文件）
```
vi /data/mha/app1/app1.conf 

# default 全局配置
manager_workdir=/data/mha/app1   #设置manager的工作目录
manager_log=/data/mha/app1/manager.log  #设置manager的日志
master_binlog_dir= /data/mysql #设置master保存binlog的位置，以便MHA可以找到master的日志，我这里的也就是mysql的数据目录
ssh_user=root  # 设置ssh的登录用户名
user=mha   # 设置mha监控用户
password=mha@password  #mha监控用户的密码
repl_user=repl  # 主从复制账号
repl_password=654321  # 主从复制账号的密码
secondary_check_script= /usr/local/bin/masterha_secondary_check -s 192.168.4.189 -s 192.168.1.191  # 一旦MHA到master的监控之间出现问题，MHA Manager将会尝试从192.168.4.189登录到master
ping_interval=3  # 设置监控主库，发送ping包的时间间隔，默认是3秒，尝试三次没有回应的时候自动进行failover

master_ip_failover_script= /data/mha/app1/master_ip_failover #设置自动failover时候的切换脚本
#shutdown_script= /data/mha/app1/masterha/power_manager
#report_script= /data/mha/app1/send_report
#master_ip_online_change_script= /data/mha/app1/master_ip_online_change   #设置手动切换时候的切换脚本

[server1]
# vm02 master
hostname=192.168.4.188
port=61920
candidate_master=1 

[server2]
# vm03 master-backup
hostname=192.168.4.189
port=61920
candidate_master=1 # 设置为候选master，如果设置该参数以后，发生主从切换以后将会将此从库提升为主库，即使这个主库不是集群中事件最新的slave
check_repl_delay=0  # 默认情况下如果一个slave落后master 100M的relay logs的话，MHA将不会选择该slave作为一个新的master，因为对于这个slave的恢复需要花费很长时间，通过设置check_repl_delay=0,MHA触发切换在选择一个新的master的时候将会忽略复制延时，这个参数对于设置了candidate_master=1的主机非常有用，因为这个候选主在切换的过程中一定是新的master

[server3]
# vm04 mysql slave
hostname=192.168.4.191
port=61920
no_master=1

```
所有slave服务器上 设置定时任务清理relay log

注意： 
MHA在发生切换的过程中，从库的恢复过程中依赖于relay log的相关信息，所以这里要将relay log的自动清除设置为OFF（已将relay_log_purge=0写入到了my.cnf配置文件），采用手动清除relay log的方式。在默认情况下，从服务器上的中继日志会在SQL线程执行完毕后被自动删除。但是在MHA环境中，这些中继日志在恢复其他从服务器时可能会被用到，因此需要禁用中继日志的自动删除功能。定期清除中继日志需要考虑到复制延时的问题。在ext3的文件系统下，删除大的文件需要一定的时间，会导致严重的复制延时。为了避免复制延时，需要暂时为中继日志创建硬链接，因为在linux系统中通过硬链接删除大文件速度会很快。（在mysql数据库中，删除大表时，通常也采用建立硬链接的方式）
```
[root@vm03 ~]# cat /etc/cron.d/purge_relay_logs
0 7 * * * /usr/bin/purge_relay_logs --user=root --password=123456 --disable_relay_log_purge  --port=61920 --workdir=/data/mysql/ >>/data/mha/app1/purge_relay_logs.log 2>&1

参数说明：
--user=root              # mysql用户名
--password=123456        # mysql用户密码
--port=3306              # mysql端口号
--workdir=/data/mysql/data    # 指定创建relay log的硬链接的位置，默认是/var/tmp，由于系统不同分区创建硬链接文件会失败，故需要执行硬链接具体位置，成功执行脚本后，硬链接的中继日志文件被删除
--disable_relay_log_purge     # 默认情况下，如果relay_log_purge=1，脚本会什么都不清理，自动退出，通过设定这个参数，当relay_log_purge=1的情况下会将relay_log_purge设置为0。清理relay log之后，最后将参数设置为OFF。
```

故障转移脚本，虚拟ip(vip）配置为自己的：192.168.4.251
```
vi /home/data/mha/app1/master_ip_failover
#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Getopt::Long;

my (
    $command,          $ssh_user,        $orig_master_host, $orig_master_ip,
    $orig_master_port, $new_master_host, $new_master_ip,    $new_master_port
);

my $vip = '192.168.4.251/24';  # Virtual IP
my $key = "1";
my $ssh_start_vip = "/sbin/ifconfig eth1:$key $vip";
my $ssh_stop_vip = "/sbin/ifconfig eth1:$key down";
$ssh_user = "root";

GetOptions(
    'command=s'          => \$command,
    'ssh_user=s'         => \$ssh_user,
    'orig_master_host=s' => \$orig_master_host,
    'orig_master_ip=s'   => \$orig_master_ip,
    'orig_master_port=i' => \$orig_master_port,
    'new_master_host=s'  => \$new_master_host,
    'new_master_ip=s'    => \$new_master_ip,
    'new_master_port=i'  => \$new_master_port,
);

exit &main();

sub main {

    print "\n\nIN SCRIPT TEST====$ssh_stop_vip==$ssh_start_vip===\n\n";

    if ( $command eq "stop" || $command eq "stopssh" ) {

        # $orig_master_host, $orig_master_ip, $orig_master_port are passed.
        # If you manage master ip address at global catalog database,
        # invalidate orig_master_ip here.
        my $exit_code = 1;

        #eval {
        #    print "Disabling the VIP on old master: $orig_master_host \n";
        #    &stop_vip();
        #    $exit_code = 0;
        #};


        eval {
                print "Disabling the VIP on old master: $orig_master_host \n";
                #my $ping=`ping -c 1 10.0.0.13 | grep "packet loss" | awk -F',' '{print $3}' | awk '{print $1}'`;
                #if ( $ping le "90.0%" && $ping gt "0.0%" ){
                #$exit_code = 0;
                #}
                #else {

                &stop_vip();

                # updating global catalog, etc
                $exit_code = 0;

                #}
        };


        if ($@) {
            warn "Got Error: $@\n";
            exit $exit_code;
        }
        exit $exit_code;
    }
    elsif ( $command eq "start" ) {

        # all arguments are passed.
        # If you manage master ip address at global catalog database,
        # activate new_master_ip here.
        # You can also grant write access (create user, set read_only=0, etc) here.
        my $exit_code = 10;
        eval {
            print "Enabling the VIP - $vip on the new master - $new_master_host \n";
            &start_vip();
            $exit_code = 0;
        };
        if ($@) {
            warn $@;
            exit $exit_code;
        }
        exit $exit_code;
    }
    elsif ( $command eq "status" ) {
        print "Checking the Status of the script.. OK \n";
        `ssh $ssh_user\@$orig_master_ip \" $ssh_start_vip \"`;
        exit 0;
    }
    else {
        &usage();
        exit 1;
    }
}

# A simple system call that enable the VIP on the new master
sub start_vip() {
    `ssh $ssh_user\@$new_master_host \" $ssh_start_vip \"`;
}

# A simple system call that disable the VIP on the old_master
sub stop_vip() {
    `ssh $ssh_user\@$orig_master_host \" $ssh_stop_vip \"`;
}

sub usage {
    print
    "Usage: master_ip_failover --command=start|stop|stopssh|status --orig_master_host=host --orig_master_ip=ip --orig_master_port=port --new_master_host=host --new_master_ip=ip --new_master_port=port\n";
}

# the end.
```
```
chmod +x /home/data/mha/app1/master_ip_failover
```

backup master & slave 设置read_only防止被误写

master备机和slave都要设置read_only=1，如果master自动切换后，会由mha设置原master备机为read_only=0 
从库对外提供读服务，之所以没有写进配置文件，是因为随时slave会提升为master
```
# mysql -u root -p123456 -e "select @@read_only;"
+-------------+
| @@read_only |
+-------------+
|           0 |
+-------------+

mysql> set global read_only=1;
Query OK, 0 rows affected (0.00 sec)

mysql> select @@read_only;
+-------------+
| @@read_only |
+-------------+
|           1 |
+-------------+
1 row in set (0.00 sec)
```
MHA维护 
创建软连接(在所有mysql上都执行) 没有操作此步骤
```
ln -s /data/mysql/bin/mysqlbinlog /usr/bin/mysqlbinlog
ln -s /data/mysql/bin/mysql /usr/bin/mysql
```
检查主从复制情况 masterha_check_repl –conf=/data/mha/app1/app1.conf
```
[root@vm01 app1]# masterha_check_repl --conf=/data/mha/app1/app1.conf 
报错了：
```
检查ssh连接情况 masterha_check_ssh –conf=/data/mha/app1/app1.conf
```
[root@vm01 app1]# masterha_check_ssh --conf=/data/mha/app1/app1.conf 
```

## 八、启动mha
vm01服务器上启动mha
```
[root@vm01 app1]# nohup /usr/local/bin/masterha_manager --conf=/data/mha/app1/app1.conf --ignore_fail_on_start > /data/mha/app1/mha_manager.log < /dev/null 2>&1 &
[1] 10980
[root@vm01 app1]# ps -ef|grep masterha_manager
报错：

```



[Mysql半同步复制+MHA+Keepalived部署](https://blog.csdn.net/lilingzj/article/details/71516603)

[MySQL高可用架构之MHA](http://www.cnblogs.com/gomysql/p/3675429.html)



