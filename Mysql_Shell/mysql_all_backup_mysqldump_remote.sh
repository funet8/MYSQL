#!/bin/sh 
# Name:mysql_all_backup_mysqldump_remote.sh
##############################################
#根据 mysql_all_backup_mysqldump.sh修改 远程备份
# mysqlhotcopy 只支持MyISAM 引擎！！！！！！
# mysqldump 是采用SQL级别的备份机制，它将数据表导成 SQL 脚本文件，数据库大时，占用系统资源较多，支持常用的MyISAM，innodb

###########20170628#########################
#将mysqlhotcopy方法改为mysqldump
###########20190109#########################
#增加远程备份mysql脚本

###########20190110#########################
#增加使用命令获取数据库名

###########20190109#########################
#localbackupuser用户权限： SELECT，TRIGGER，SHOW DATABASES，LOCK TABLES
#赋权命令：
# create user localbackupuser@'192.168.20.%' identified by '123456yxkj303';
# GRANT EVENT , SELECT ,SHOW DATABASES, RELOAD , LOCK TABLES , REPLICATION CLIENT ON * . * TO 'localbackupuser'@'192.168.20.%' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0 ;
# flush privileges;
####################################

########################################################################
#每天自动备份
#echo "00 04 * * *  root /data/conf/shell/mysql_all_backup_mysqldump_remote.sh" >>  /etc/crontab
#service crond restart
########################################################################

########################################################################
##1.指定变量
########################################################################
#备份数据库的用户名和密码 
mysqlUser='localbackupuser'
mysqlPWD='123456yxkj303'
#数据库地址、端口 
Mysql_hosts='192.168.1.6'
Mysql_Prot='3306'
#备份的数据库名 
#Mysql_NAMES='mysql cloudreve_7477_me xshd_hander_com'
Mysql_NAMES=`mysql -h$Mysql_hosts -u$mysqlUser -p$mysqlPWD -P$Mysql_Prot -e "show databases\G" |grep 'Database'|awk -F'Database: ' '{print $2}' |grep -v 'mysql\|information_schema\|performance_schema'`

Today=`date -I` 
tmpBackupDir='/data/tmp/mysqlblackup' 	#临时目录
backupDir=/backup/mysql-$Mysql_hosts/$Today	#备份之后的目录
MySQLBackup_Log=$backupDir/MySQLBackup_Log_$Mysql_hosts.log		#日志

########################################################################
##2.创建目录
########################################################################
if [[ -e $tmpBackupDir ]]; then 
	rm -rf $tmpBackupDir/* 
else 
	mkdir -p $tmpBackupDir 
fi 
# 如果备份目录不存在则创建它 
if [[ ! -e $backupDir ]];then 
	mkdir -p $backupDir
fi 
########################################################################
##3.备份数据库
######################################################################## 
for databases in $Mysql_NAMES;
do
	dateTime=`date "+%Y.%m.%d %H:%M:%S"` 
	echo "$dateTime START backup $databases!" >>$MySQLBackup_Log
	/usr/bin/mysqldump -h$Mysql_hosts -P$Mysql_Prot -u$mysqlUser --skip-lock-tables -p"$mysqlPWD" $databases > $tmpBackupDir/$databases.sql
	dateTime=`date "+%Y.%m.%d %H:%M:%S"` 
	echo "$dateTime Database:$databases backup success!" >>$MySQLBackup_Log
done 

########################################################################
##4.压缩备份文件
######################################################################## 
for databases in $Mysql_NAMES;
do
	date=`date -I` 
	cd $tmpBackupDir 
	tar czf $backupDir/$databases-$date.tar.gz ./$databases.sql
done

########################################################################
##5.删除过期备份
######################################################################## 
ndays="6" 									#保留ndays+1天前的文件
#wheredir="/backup/mysql"
logfiledate="$backupDir/Del_Bakfile_Log.log"

#删除过期的全备
echo -e "........................start waiting......................" >> $logfiledate
for efile in $(/usr/bin/find $backupDir -mtime +$ndays)
do
	if [ -d ${efile} ]; then
	rm -rf "${efile}"
	echo -e "删除过期文件文件夹:${efile}" >> $logfiledate
	elif [ -f ${efile} ]; then
	rm -rf "${efile}"
	echo -e "删除过期文件:${efile}" >> $logfiledate	
	fi;
done

echo "完成于: `date +%F' '%T' '%w`" >> $logfiledate
exit 0


