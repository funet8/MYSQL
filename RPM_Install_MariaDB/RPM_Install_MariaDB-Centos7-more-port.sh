#!/bin/bash
##################################
#使用RPM包离线安装MariaDB#########
#时间：20161212			#########
#作者：star				#########
#
#20190808增加my.cnf配置
# centos7 安装 MariaDB-10.2.9

Mariadb_File='/data/software/'	#Mariadb的RPM文件路径
#解锁系统文件
chattr -i /etc/passwd
chattr -i /etc/group
chattr -i /etc/gshadow
chattr -i /etc/shadow
chattr -i /etc/services

#是否有rpm文件 0没有文件需要下载，其他为有
Mariadb_File_yes=1

#首先先上传RPM包#########################################################################
mkdir -p ${Mariadb_File}
#先把rpm包上传到"/data/software/"文件夹中

#安装依赖包#########################################################################
yum -y install libaio perl perl-DBI perl-Module-Pluggable perl-Pod-Escapes perl-Pod-Simple perl-libs perl-version php-mysql php-gd galera lsof rsync
yum remove -y mariadb-libs

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
rpm -ivh ${Mariadb_File}/MariaDB-10.2.9-centos7-x86_64-*


iptables -I INPUT -p tcp --dport 3306 -j ACCEPT

service iptables save
systemctl restart iptables

systemctl start mariadb
systemctl enable mariadb
