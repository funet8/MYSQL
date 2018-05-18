#!/bin/sh
##################################
#使用RPM包离线安装MariaDB#########
#时间：20161212			#########
#作者：star				#########
#
#20170508增加my.cnf配置

MYSQL_PORY='61920' #MySQL访问端口
Mariadb_File='/data/software/'	#Mariadb的RPM文件路径
#解锁系统文件
chattr -i /etc/passwd
chattr -i /etc/group
chattr -i /etc/gshadow
chattr -i /etc/shadow
chattr -i /etc/services

#是否有rpm文件 0没有文件需要下载，其他为有
Mariadb_File_yes=1
#是否需要创建web目录
Filedir_yes=1

#首先先上传RPM包#########################################################################
mkdir -p ${Mariadb_File}
#先把rpm包上传到"/data/software/"文件夹中
cd ${Mariadb_File}
if [ $Mariadb_File_yes = "0" ]
then
	wget http://yum.mariadb.org/10.0.28/centos6-amd64/rpms/MariaDB-10.0.28-centos6-x86_64-server.rpm
	wget http://yum.mariadb.org/10.0.28/centos6-amd64/rpms/MariaDB-10.0.28-centos6-x86_64-client.rpm
	wget http://yum.mariadb.org/10.0.28/centos6-amd64/rpms/MariaDB-10.0.28-centos6-x86_64-common.rpm
	wget http://yum.mariadb.org/10.0.28/centos6-amd64/rpms/MariaDB-10.0.28-centos6-x86_64-compat.rpm
	
	#wget http://img.funet8.com/centos/mariadb/MariaDB-10.0.28-centos6-x86_64/MariaDB-10.0.28-centos6-x86_64-server.rpm
	#wget http://img.funet8.com/centos/mariadb/MariaDB-10.0.28-centos6-x86_64/MariaDB-10.0.28-centos6-x86_64-client.rpm
	#wget http://img.funet8.com/centos/mariadb/MariaDB-10.0.28-centos6-x86_64/MariaDB-10.0.28-centos6-x86_64-common.rpm
	#wget http://img.funet8.com/centos/mariadb/MariaDB-10.0.28-centos6-x86_64/MariaDB-10.0.28-centos6-x86_64-compat.rpm
fi

#是否新建目录
if [ $Filedir_yes = "0" ]
then
	mkdir /home/data
	ln -s /home/data /data
	mkdir /data
	mkdir /www
	mkdir /data/wwwroot
	ln -s /data/wwwroot /www/
	mkdir -p /data/wwwroot/{web,log,mysql_log}
	mkdir /data/conf
	mkdir /data/mysql
	mkdir /data/conf/sites-available
	mkdir /data/software
	mkdir /backup
	ln -s /backup /data/
fi

#安装依赖包#########################################################################
yum -y install libaio perl perl-DBI perl-Module-Pluggable perl-Pod-Escapes perl-Pod-Simple perl-libs perl-version php-mysql php-gd

#移除所有原有的mysql软件包和配置文件#########################################################################
yum remove -y mysql* MariaDB*
rm -rf /var/lib/mysql*
rm -rf /data/mysql
rm -rf /data/conf/my.cnf
rm -rf /etc/my.cnf*

#创建用户和用户组#########################################################################
groupadd mysql
useradd -s /sbin/nologin -g mysql -M mysql

#安装MariaDB#########################################################################
rpm -i ${Mariadb_File}/MariaDB*
chown -R mysql:mysql  /var/lib/mysql
chkconfig mysql on
service mysql start

#配置mysql#########################################################################
mysql_secure_installation

#创建网站相关目录#########################################################################

mkdir /data/wwwroot/log_mysql/
chown mysql.mysql -R /data/wwwroot/log_mysql/

#移动mysql配置文件#########################################################################
cp -p /etc/my.cnf /etc/my.cnf.bak
mv /etc/my.cnf /data/conf/
ln -s /data/conf/my.cnf /etc/
echo "my.cnf move success"  

#移动mysql数据库#########################################################################
  cp -rp /var/lib/mysql /var/lib/mysql-bak
  mv /var/lib/mysql /data/
  ln -s /data/mysql /var/lib/
  echo "mysql database move success"
  
#my.cnf配置#########################################################################
echo '#password	= your_password
[client]
port		= 61920
socket		= /var/lib/mysql/mysql.sock
[mysqld]
port		= 61920
socket		= /var/lib/mysql/mysql.sock

#skip-name-resolve
expire_logs_days=10

slow-query-log=1
slow-query-log-file=/data/wwwroot/log_mysql/slowQuery.log
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
thread_concurrency = 8
# Point the following paths to a dedicated disk
#tmpdir		= /tmp/
#skip-networking
# Replication Master Server (default)
# binary logging is required for replication
log-bin=mysql-bin
server-id	= 1
binlog_format=mixed
# Uncomment the following if you are using InnoDB tables
#innodb_data_home_dir = /var/lib/mysql
#innodb_data_file_path = ibdata1:2000M;ibdata2:10M:autoextend
#innodb_log_group_home_dir = /var/lib/mysql
# You can set .._buffer_pool_size up to 50 - 80 %
# of RAM but beware of setting memory usage too high
#innodb_buffer_pool_size = 384M
#innodb_additional_mem_pool_size = 20M
# Set .._log_file_size to 25 % of buffer pool size
#innodb_log_file_size = 100M
#innodb_log_buffer_size = 8M
#innodb_flush_log_at_trx_commit = 1
#innodb_lock_wait_timeout = 50
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
interactive-timeout'>/data/conf/my.cnf

#防火墙#########################################################################
/sbin/iptables -I INPUT -p tcp --dport $MYSQL_PORY -j ACCEPT
/etc/rc.d/init.d/iptables save
/etc/init.d/iptables restart
#重启服务
/etc/init.d/mysql restart
