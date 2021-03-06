#!/bin/bash
 
# -------------------------------------------------------------------------------
# Filename:    Source_Package_Install_MariaDB.sh
# -------------------------------------------------------------------------------
# Revision:    1.1
# Email:       liuxing007xing@163.com
# 功能：源码包安装mariadb-10.0.35 ，在centos6下测试成功。
# 20180517 第一版
#########################################################
#参考：https://www.linuxidc.com/Linux/2017-05/143291.htm
#下载mariadb或者是mysql5.6
#wget http://mirrors.neusoft.edu.cn/mariadb/mariadb-10.2.14/source/mariadb-10.2.14.tar.gz
#wget http://mirrors.neusoft.edu.cn/mariadb/mariadb-10.0.35/source/mariadb-10.0.35.tar.gz
#wget https://cdn.mysql.com/archives/mysql-5.6/mysql-5.6.35.tar.gz
#########################################################
####设置变量
#是否需要创建web目录
Filedir_yes=1
#MYSQL端口
Mysql_Port=61920
#MYSQL密码
Mysql_Password=123456

##########################################################

#解锁系统文件-非必须
chattr -i /etc/passwd
chattr -i /etc/group
chattr -i /etc/gshadow
chattr -i /etc/shadow
chattr -i /etc/services

### 1.安装开发环境
### 安装编译源码所需要工具及库
yum groupinstall "Development Tools"
yum install -y ncurses-devel openssl-devel openssl gcc gcc-c++ ncurses-devel perl

### 2.创建目录
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

### 3.安装cmake
cd /data/software
wget https://cmake.org/files/v3.8/cmake-3.8.1.tar.gz
tar -xf cmake-3.8.1.tar.gz 
cd cmake-3.8.1
./bootstrap 
make && make install

### 4.添加用户

#准备目录
mkdir -pv /data/mysql/$Mysql_Port/{data,logs/{binlog,relaylog}}
#添加用户
groupadd mysql
useradd -s /sbin/nologin -g mysql -M mysql 
chown mysql:mysql /data/mysql -R

### 5.编译安装
cd /data/software
wget http://mirrors.neusoft.edu.cn/mariadb/mariadb-10.0.35/source/mariadb-10.0.35.tar.gz
tar -xf mariadb-10.0.35.tar.gz
cd mariadb-10.0.35
cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/data/mysql/$Mysql_Port/data  -DSYSCONFDIR=/etc -DMYSQL_USER=mysql -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DWITH_SSL=system -DWITH_ZLIB=system -DWITH_LIBWRAP=0 -DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DENABLED_LOCAL_INFILE=1 -DWITH_PARTITION_STORAGE_ENGINE=1  -DWITH_DEBUG=0 -DWITHOUT_MROONGA_STORAGE_ENGINE=1 
make && make install
### 6.安装完环境准备
chmod +w /usr/local/mysql/ 
chown -R mysql:mysql /usr/local/mysql/


### 7.拷贝配置文件并修改
cp /data/software/mariadb-10.0.35/support-files/my-large.cnf /etc/my.cnf
wget -O /data/conf/my.cnf https://raw.githubusercontent.com/funet8/MYSQL/master/my.cnf/my61920_Source_Package.cnf

### 8.初始化mysql
/data/software/mariadb-10.0.35/scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql/ --datadir=/data/mysql/61920/data/ --defaults-file=/etc/my.cnf

### 9.启动服务

cp /data/software/mariadb-10.0.35/support-files/mysql.server /etc/rc.d/init.d/mysqld 
chmod +x /etc/rc.d/init.d/mysqld
chkconfig --add mysqld 
service mysqld start

### 10.添加环境变量
echo "export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin:/usr/local/mysql/bin" >> /etc/profile 
#重读环境变量
source /etc/profile

### 12.设置mysql root账号初始密码 $Mysql_Password
mysqladmin -uroot password $Mysql_Password


### 13.mysql命令行中删除匿名账户
mysql -p $Mysql_Password -e"delete  from mysql.user where user="";"
mysql -p $Mysql_Password -e"flush privileges;"

#移动mysql配置文件#########################################################################
cp -p /etc/my.cnf /etc/my.cnf.bak
mv /etc/my.cnf /data/conf/
ln -s /data/conf/my.cnf /etc/
echo "my.cnf move success"

#防火墙#########################################################################
/sbin/iptables -I INPUT -p tcp --dport $MYSQL_PORY -j ACCEPT
/etc/rc.d/init.d/iptables save
/etc/init.d/iptables restart

#/data/wwwroot/mysql_log为慢查询日志目录
chown mysql.mysql -R /data/wwwroot/mysql_log

#重启服务
service mysqld restart 



