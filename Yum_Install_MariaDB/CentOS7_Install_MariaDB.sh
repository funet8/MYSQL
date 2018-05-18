#!/bin/bash
 
# -------------------------------------------------------------------------------
# Filename:    CentOS7_Install_MariaDB.sh
# -------------------------------------------------------------------------------
# Revision:    1.1
# Email:       liuxing007xing@163.com
# -------------------------------------------------------------------------------
#20180308
#CENTOS7 yum安装mariadb

#start变量定义#############################################################################
MYSQL_PORY='61920' 			#MySQL访问端口，可自定义
DONE="DONE" 

#如果已安装Apache和PHP，则卸载########################################################
yum -y remove mysql*
yum -y remove mariadb*

#Importing the MariaDB Signing Key####################################################
rpm --import http://yum.mariadb.org/RPM-GPG-KEY-MariaDB

#########使用yum安装MariaDB https://mariadb.com/kb/zh-cn/installing-mariadb-with-yum/#yummariadb
#########官方参考网站：
#########https://downloads.mariadb.org/mariadb/repositories/#mirror=neusoft&distro=CentOS&distro_release=centos6-amd64--centos6&version=10.2
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
echo '# MariaDB 10.2 CentOS repository list - created 2017-12-01 11:36 UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = https://mirrors.ustc.edu.cn/mariadb/yum/10.2/centos7-amd64
gpgkey=https://mirrors.ustc.edu.cn/mariadb/yum/RPM-GPG-KEY-MariaDB
gpgcheck=1'>/etc/yum.repos.d/MariaDB.repo

yum clean all
rm -rf /var/cache/yum
yum makecache
#Installing MariaDB with YUM##########################################################
yum install -y MariaDB-server MariaDB-client
#加入启动项###########################################################################
systemctl enable mariadb
#start MariaDB########################################################################
systemctl start mysql
#设置mysql密码及相关设置##############################################################
mysql_secure_installation

#####################################################################################
#####################################################################################
#目录设置############################################################################
#创建网站相关目录####################################################################
mkdir -p /data/wwwroot/mysql_log
chown mysql.mysql -R /data/wwwroot/mysql_log

systemctl stop mysql
#配置文件目录设置######################################################################
#移动mysql配置文件
if [ -s /data/conf/my.cnf ]; then  
  echo "my.cnf already move"  
else  
	cp -p /etc/my.cnf /etc/my.cnf.bak
	mv /etc/my.cnf /data/conf/
	ln -s /data/conf/my.cnf /etc/
	echo "my.cnf move success"  
fi

#移动mysql数据库
if [ -d /data/mysql ]; then  
  echo "mysql database already move"  
else  
  cp -rp /var/lib/mysql /var/lib/mysql-bak
  mv /var/lib/mysql /data/
  ln -s /data/mysql /var/lib/
  echo "mysql database move success"  
fi

#修改mysql配置
echo '
[client]
port		= 61920
socket		= /var/lib/mysql/mysql.sock
[mysqld]
port		= 61920
socket		= /var/lib/mysql/mysql.sock

#skip-name-resolve
expire_logs_days=10

slow-query-log=1
slow-query-log-file=/data/wwwroot/mysql_log/slowQuery.log
long-query-time=1 
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
#thread_concurrency应设为CPU核数的2倍
#thread_concurrency = 8
log-bin=mysql-bin

server-id	= 1

binlog_format=mixed

max_connections = 2000
interactive_timeout = 30
wait_timeout = 30
tmp_table_size=300M
max_heap_table_size=300M

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash


[myisamchk]
key_buffer_size = 256M
sort_buffer_size = 256M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout
 '> /data/conf/my.cnf

#开启防火墙##################################
/sbin/iptables -I INPUT -p tcp --dport $MYSQL_PORY -j ACCEPT
service iptables save
systemctl restart iptables.service


#重启mysql##################################
systemctl restart mysql
