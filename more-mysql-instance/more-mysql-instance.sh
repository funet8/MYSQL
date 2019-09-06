#!/bin/bash
##################################
#使用RPM包离线安装MariaDB#########
#时间：20161212			#########
#作者：star				#########
#
#20190904增加my.cnf配置
#1.必须已安装mysql服务
#centos7 安装 MariaDB-10.2.9

#安装 wget https://raw.githubusercontent.com/funet8/MYSQL/master/more-mysql-instance/more-mysql-instance.sh
# sh more-mysql-instance.sh

#MySQL多端口####################
MYSQL_PORY='61920 61921 61922 61923 61924'

for  port in  $MYSQL_PORY
do
	#数据库目录####################
	mkdir -p /data/mysql/$port
	#binlog目录####################
	mkdir -p /data/mysql/mysqlbinlog/$port
	#初始化实例
	mysql_install_db --basedir=/usr --datadir=/data/mysql/$port --user=mysql
done

#配置目录####################
mkdir -p /data/mysql/etc/
#慢查询目录和权限
mkdir -p /data/mysql/slowQuery/
chmod 777 -R /data/mysql/slowQuery/

cd /data/mysql/etc/
for  port in  $MYSQL_PORY
do
	wget https://raw.githubusercontent.com/funet8/MYSQL/master/more-mysql-instance/conf/$port.cnf
done

chown mysql.mysql -R /data/mysql/etc/ /data/mysql/mysqlbinlog/


for  port in  $MYSQL_PORY
do
	#启动实例
	/usr/bin/mysqld_safe --defaults-file=/data/mysql/etc/$port.cnf &
	#防火墙开放端口
	iptables -I INPUT -p tcp --dport $port -j ACCEPT
	#开机启动
	echo "/usr/bin/mysqld_safe --defaults-file=/data/mysql/etc/${port}.cnf &" >> /etc/rc.local
done

service iptables save
systemctl restart iptables



#进入实例
#mysql -u root -S /data/mysql/61920/mysql61920.sock

#新建最高权限，删除默认root用户
#新建用户 star
#密码 123456
## mysql -u root -S /data/mysql/61921/mysql61921.sock
#mysql>CREATE USER 'star'@'%' IDENTIFIED BY '123456';
#mysql>GRANT  all privileges ON * . * TO 'star'@'%' IDENTIFIED BY '123456';   #此命令GRANT权限没有赋予用户
#mysql>GRANT ALL PRIVILEGES ON * . * TO 'star'@'%' WITH GRANT OPTION MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0 ;
#mysql>flush privileges;
#使用新用户登录
#mysql -u star -h127.0.0.1  -P 61921 -p123456

#关闭数据库
#mysqladmin -uroot -S /data/mysql/61921/mysql61921.sock shutdown
#mysqladmin -ustar -p123456 -S /data/mysql/61921/mysql61921.sock shutdown
#启动数据库
#/usr/bin/mysqld_safe --defaults-file=/data/mysql/etc/61921.cnf &







