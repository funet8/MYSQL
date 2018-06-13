#!/bin/sh 
# Name:mysql_all_backup_mysqldump.sh
# PS:MySQL DataBase Backup,Use mysqlhotcopy script. 
# 定义变量，请根据具体情况修改
# mysqlhotcopy 只支持MyISAM 引擎！！！！！！
# mysqldump 是采用SQL级别的备份机制，它将数据表导成 SQL 脚本文件，数据库大时，占用系统资源较多，支持常用的MyISAM，innodb
###########20170628#########################
#将mysqlhotcopy方法改为mysqldump
###########20170629#########################
#localbackupuser用户权限： SELECT，TRIGGER，SHOW DATABASES，LOCK TABLES
#命令：
#create user localbackupuser@'localhost' identified by '123456yxkj303';
#GRANT EVENT , SELECT ,SHOW DATABASES, RELOAD , LOCK TABLES , REPLICATION CLIENT ON * . * TO 'localbackupuser'@'localhost' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0 ;
####################################

#每天0:00自动备份
#echo "00 05 * * *  root /data/conf/shell/mysql_all_backup_mysqldump.sh" >>  /etc/crontab
#service crond restart


####################################
# 数据库的数据目录
dataDir=/data/mysql/
# 数据备份目录 
tmpBackupDir=/tmp/mysqlblackup  	#临时目录
backupDir=/backup/mysql
# 用来备份数据库的用户名和密码 
mysqlUser=localbackupuser
mysqlPWD='123456yxkj303'	
####################################

# 如果临时备份目录存在，清空它，如果不存在则创建它 
if [[ -e $tmpBackupDir ]]; then 
rm -rf $tmpBackupDir/* 
else 
mkdir $tmpBackupDir 
fi 
# 如果备份目录不存在则创建它 
if [[ ! -e $backupDir ]];then 
mkdir $backupDir 
fi 
# 得到数据库备份列表，在此可以过滤不想备份的数据库 
#for databases in `find $dataDir -type d | \
#sed -e "s/\/data\/mysql\///" | \
#sed -e "s/test//"`;
for databases in `find $dataDir -type d | sed -e "s/\/data\/mysql\///"`;
do
if [[ $databases == "" ]]; then 
continue 
else 
# 备份数据库修改方法
#/usr/bin/mysqlhotcopy --user=$mysqlUser --password=$mysqlPWD -q "$databases" $tmpBackupDir
/usr/bin/mysqldump -u$mysqlUser -p"$mysqlPWD" "$databases" > $tmpBackupDir/"$databases".sql

dateTime=`date "+%Y.%m.%d %H:%M:%S"` 
echo "$dateTime Database:$databases backup success!" >>$backupDir/MySQLBackup.log 
fi

done 
# 压缩备份文件 
date=`date -I` 
cd $tmpBackupDir 
tar czf $backupDir/mysql-$date.tar.gz ./
#End完成 



################自动删除n天前的文件#########################
ndays="6" 									#保留ndays+1天前的文件
wheredir="/backup/mysql"
logfiledate="/backup/mysql/del_bakfile_log.log"

#删除过期的全备
echo -e "........................start waiting......................" >> $logfiledate
for efile in $(/usr/bin/find $wheredir -mtime +$ndays)
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
