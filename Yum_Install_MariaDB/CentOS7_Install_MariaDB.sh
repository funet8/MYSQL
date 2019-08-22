#!/bin/bash
 
# -------------------------------------------------------------------------------
# Filename:    CentOS7_Install_MariaDB.sh
# -------------------------------------------------------------------------------
# Revision:    1.2
# Email:       liuxing007xing@163.com
# -------------------------------------------------------------------------------
#20180308
#CENTOS7 yum安装mariadb
#20190621
#CENTOS7 解决移动目录之后的问题

####变量定义####
MYSQL_PORY='61920'  #MySQL访问端口
Mysql_Password='123456' # mysql root密码

#解锁系统文件#########################################################################
chattr -i /etc/passwd 
chattr -i /etc/group
chattr -i /etc/shadow
chattr -i /etc/gshadow
chattr -i /etc/services
#MariaDB,则卸载########################################################
yum -y remove  MariaDB*

#安装支持###################################################
yum -y install libaio perl perl-DBI perl-Module-Pluggable perl-Pod-Escapes perl-Pod-Simple perl-libs perl-version php-mysql php-gd



#Importing the MariaDB Signing Key####################################################
rpm --import http://yum.mariadb.org/RPM-GPG-KEY-MariaDB

#########使用yum安装MariaDB https://mariadb.com/kb/zh-cn/installing-mariadb-with-yum/#yummariadb
#########官方参考网站：
#########https://downloads.mariadb.org/mariadb/repositories/#mirror=shanghai-university&distro=CentOS&distro_release=centos7-amd64--centos7&version=10.4
#########官方YUM源（速度非常慢、非常慢，推荐使用国内源）：
#Adding the MariaDB YUM Repository####################################################
#echo '# MariaDB 10.2 CentOS repository list - created 2018-05-11 02:15 UTC
# http://downloads.mariadb.org/mariadb/repositories/
#[mariadb]
#name = MariaDB
#baseurl = http://yum.mariadb.org/10.2/centos6-amd64
#gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
#gpgcheck=1'>/etc/yum.repos.d/MariaDB.repo

#########使用国内YUM源
echo '# MariaDB 10.4 CentOS repository list - created 2019-06-21 08:55 UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = https://mirrors.ustc.edu.cn/mariadb/yum/10.4/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1'>/etc/yum.repos.d/MariaDB.repo

yum clean all
rm -rf /var/cache/yum
yum makecache
#Installing MariaDB with YUM##########################################################
yum install -y MariaDB-server MariaDB-client
#加入启动项###########################################################################
systemctl enable mariadb
#start MariaDB########################################################################
#systemctl start mysql
#设置mysql密码及相关设置##############################################################
# mysql_secure_installation
### 设置mysql root账号初始密码 $Mysql_Password
mysqladmin -uroot password $Mysql_Password

### mysql命令行中删除匿名账户
#mysql -p $Mysql_Password -e"delete  from mysql.user where user="";"
#mysql -p $Mysql_Password -e"flush privileges;"

systemctl stop mysql
#配置文件目录设置######################################################################

mkdir -p /data/mysql/$MYSQL_PORY
mkdir -p /data/mysql/etc/my.cnf.d

mysql_install_db --basedir=/usr --datadir=/data/mysql/$MYSQL_PORY --user=mysql

#配置文件
echo "[client]
port=$MYSQL_PORY
socket=/data/mysql/$MYSQL_PORY/mysql$MYSQL_PORY.sock

[mysqld]
datadir=/data/mysql/$MYSQL_PORY
port=$MYSQL_PORY
server_id=1
socket=/data/mysql/$MYSQL_PORY/mysql$MYSQL_PORY.sock
slow-query-log-file=/data/wwwroot/mysql_log/slowQuery_$MYSQL_PORY.log

!includedir /data/mysql/etc/my.cnf.d/
">/data/mysql/etc/$MYSQL_PORY.cnf

echo '[mysqld]
skip-name-resolve
lower_case_table_names=1
innodb_file_per_table=1
back_log=50
max_connections=10000
max_connect_errors=3000
table_open_cache=2048
max_allowed_packet=16M
binlog_cache_size=2M
max_heap_table_size=64M
sort_buffer_size=2M
join_buffer_size=2M
thread_cache_size=64
thread_concurrency=8
query_cache_size=64M
query_cache_limit=2M
ft_min_word_len=4
default-storage-engine=innodb
thread_stack=192K
transaction_isolation=REPEATABLE-READ
tmp_table_size=64M
log-bin=mysql-bin
binlog_format=row
slow_query_log
long_query_time=1
server-id=1
key_buffer_size=8M
read_buffer_size=2M
read_rnd_buffer_size=2M
bulk_insert_buffer_size=64M
myisam_sort_buffer_size=128M
myisam_max_sort_file_size=10G
myisam_repair_threads=1
myisam_recover
[mysqldump]
quick
max_allowed_packet=256M
[mysql]
no-auto-rehash
[myisamchk]
key_buffer_size=512M
sort_buffer_size=512M
read_buffer=8M
write_buffer=8M
[mysqlhotcopy]
interactive-timeout
[mysqld_safe]
open-files-limit=8192
'>/data/mysql/etc/my.cnf.d/my.cnf

chown mysql.mysql -R /data/mysql/etc/

#启动实例
/usr/bin/mysqld_safe --defaults-file=/data/mysql/etc/$MYSQL_PORY.cnf &

#开机启动
echo "/usr/bin/mysqld_safe --defaults-file=/data/mysql/etc/$MYSQL_PORY.cnf &" >> /etc/rc.local

#进入实例
#mysql -u root -S /data/mysql/$MYSQL_PORY/mysql$MYSQL_PORY.sock

#关闭实例
# mysqladmin -uroot  -p $Mysql_Password -S /data/mysql/$MYSQL_PORY/mysql$MYSQL_PORY.sock shutdown

#开启防火墙##################################
iptables -I INPUT -p tcp --dport $MYSQL_PORY -j ACCEPT
service iptables save
systemctl restart iptables.service

#/data/wwwroot/mysql_log为慢查询日志目录
mkdir -p /data/wwwroot/mysql_log
chown mysql.mysql -R /data/wwwroot/mysql_log

#重启mysql##################################
systemctl restart mysql


######################################################################
######################################################################
#进入实例：
#mysql -u root -S /data/mysql/61920/mysql61920.sock -p123456
#关闭实例：
#mysqladmin -uroot  -p 123456 -S /data/mysql/61920/mysql61920.sock shutdown
#导出数据库
#mysqldump -u root  -S /data/mysql/61920/mysql61920.sock -p DBNAME > /tmp/DBNAME.sql
#导入数据库
#mysql -u root -S /data/mysql/61920/mysql61920.sock -p123456 DBNAME < /tmp/DBNAME.sql


######################################################################
######################################################################
#配置端口为 61921 的数据库实例
#cp -a /data/mysql/etc/61920.cnf /data/mysql/etc/61921.cnf
#将端口改为 61921
#vi /data/mysql/etc/61921.cnf
#mkdir -p /data/mysql/61921
#mysql_install_db --basedir=/usr --datadir=/data/mysql/61921 --user=mysql
#/usr/bin/mysqld_safe --defaults-file=/data/mysql/etc/61921.cnf &
#mysql -u root -S /data/mysql/61921/mysql61921.sock -p<密码为空>
#iptables -I INPUT -p tcp --dport 61921 -j ACCEPT
#service iptables save
#systemctl restart iptables.service

#开机启动
#echo "/usr/bin/mysqld_safe --defaults-file=/data/mysql/etc/$61921.cnf &" >> /etc/rc.local
######################################################################

