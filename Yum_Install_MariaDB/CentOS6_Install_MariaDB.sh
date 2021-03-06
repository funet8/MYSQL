#!/bin/bash
 
# -------------------------------------------------------------------------------
# Filename:    CentOS6_Install_MariaDB.sh
# Revision:    1.0
# Date:        2015-6-15
# Author:      star
# Email:       liuxing007xing@163.com
# Description: CentOS6.3+Nginx+PHP(系统默认稳定版)+MariaDB及相关扩展安装脚本
# Notes:       需要切换到root运行,版本针对64位系统，操作系统为CentOS6.3
# -------------------------------------------------------------------------------

# -------------------------------------------------------------------------------
#Version 1.0
#2015-09-01 star 初始版本建立
#
# -------------------------------------------------------------------------------

####变量定义####
MYSQL_PORY='61920'  #MySQL访问端口
Filedir_yes='0' 	#是否创建web目录
Mysql_Password='123456' # mysql root密码

#解锁系统文件#########################################################################
chattr -i /etc/passwd 
chattr -i /etc/group
chattr -i /etc/shadow
chattr -i /etc/gshadow
chattr -i /etc/services
#MariaDB,则卸载########################################################
yum -y remove  MariaDB*

#是否创建目录############################################################################
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
	mkdir /data/conf/sites-available
	mkdir /data/software
	mkdir /backup
	ln -s /backup /data/
fi

#安装支持###################################################
yum -y install libaio perl perl-DBI perl-Module-Pluggable perl-Pod-Escapes perl-Pod-Simple perl-libs perl-version php-mysql php-gd

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
baseurl = https://mirrors.ustc.edu.cn/mariadb/yum/10.2/centos6-amd64/
gpgkey=https://mirrors.ustc.edu.cn/mariadb/yum/RPM-GPG-KEY-MariaDB
gpgcheck=1'>/etc/yum.repos.d/MariaDB.repo

#Installing MariaDB with YUM##########################################################
yum clean all
yum -y install MariaDB-server MariaDB-client
#加入启动项###########################################################################
chkconfig --levels 235 mysql on
#start MariaDB########################################################################
/etc/init.d/mysql start
### 设置mysql root账号初始密码 $Mysql_Password
mysqladmin -uroot password $Mysql_Password

### mysql命令行中删除匿名账户
mysql -p $Mysql_Password -e"delete  from mysql.user where user="";"
mysql -p $Mysql_Password -e"flush privileges;"

#/etc/init.d/mysql stop
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

#my.cnf配置#########################################################################
#wget -O /data/conf/my.cnf https://raw.githubusercontent.com/funet8/MYSQL/master/my.cnf/my61920.cnf
wget -O /data/conf/my.cnf https://raw.githubusercontent.com/funet8/MYSQL/master/my.cnf/my$MYSQL_PORY.cnf

#开启防火墙
iptables -I INPUT -p tcp --dport $MYSQL_PORY -j ACCEPT
/etc/rc.d/init.d/iptables save
/etc/init.d/iptables restart

#/data/wwwroot/mysql_log为慢查询日志目录
chown mysql.mysql -R /data/wwwroot/mysql_log
	
#重启mysql
/etc/init.d/mysql restart