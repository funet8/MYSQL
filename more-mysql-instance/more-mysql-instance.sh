#!/bin/bash
##################################
#使用RPM包离线安装MariaDB#########
#时间：20161212			#########
#作者：star				#########
#
#20190904增加my.cnf配置
#1.必须已安装mysql服务
#centos7 安装 MariaDB-10.2.9


#MySQL多端口####################
MYSQL_PORY='61920 61921 61922 61923 61924'

#数据库目录####################
mkdir -p /data/mysql/{61920,61921,61922,61923,61924}
#binlog目录####################
mkdir -p /data/mysql/mysqlbinlog/{61920,61921,61922,61923,61924}
#配置目录####################
mkdir -p /data/mysql/etc/my.cnf.d
#慢查询目录和权限
mkdir -p /data/mysql/slowQuery/
chmod 777 -R /data/mysql/slowQuery/
####################

#初始化实例-循环
for  port in  $MYSQL_PORY
do
	mysql_install_db --basedir=/usr --datadir=/data/mysql/$port --user=mysql
done

cd /data/mysql/etc/
wget 1.sh

cd /data/mysql/etc/my.cnf.d
wget 1.sh


chown mysql.mysql -R /data/mysql/etc/ /data/mysql/mysqlbinlog/

#开机启动
echo '/usr/bin/mysqld_safe --defaults-file=/data/mysql/etc/61920.cnf &
/usr/bin/mysqld_safe --defaults-file=/data/mysql/etc/61921.cnf &
/usr/bin/mysqld_safe --defaults-file=/data/mysql/etc/61922.cnf &
/usr/bin/mysqld_safe --defaults-file=/data/mysql/etc/61923.cnf &
/usr/bin/mysqld_safe --defaults-file=/data/mysql/etc/61924.cnf &' >> /etc/rc.local



