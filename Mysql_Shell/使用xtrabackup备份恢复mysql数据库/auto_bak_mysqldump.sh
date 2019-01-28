#!/bin/bash
id="root" 						#用户名
pwd="123456" 					#密码
dbname="zabbix aaa" 			#数据库名字的列表，多个数据库用空格分开。
backuppath="/backup/mysqlbackup" 	#保存备份的位置
day=15  						#保留最近几天的备份
[ ! -d $backuppath ] && mkdir -p $backuppath  			#判断备份目录是否存在，不存时新建目录。
cd $backuppath											#转到备份目录，这句话可以省略。可以直接将路径到命令的也行。

backupname=mysql_$(date +%Y-%m-%d)  				#生成备份文件的名字的前缀，不带后缀。
for db in $dbname;  								#dbname是一个数据名字的集合。遍历所有的数据。
do
  mysqldump -u$id -p$pwd -S /var/lib/mysql/mysql.sock $db >$backupname_$db.sql  #备份单个数据为.sql文件。放到当前位置
  if [ "$?" == "0" ]  															#$?得到上一个shell命令的执行的返回值。0表示执行成功。其他错误将结果写入到日志。
  then
      echo $(date +%Y-%m-%d)" $db  mysqldump sucess">>mysql.log 
  else
      echo $(date +%Y-%m-%d)"  $db mysql dump failed">>mysql.log
      exit 0
  fi
done
tar -czf $backupname.tar.gz *.sql 												#压缩所有sql文件
if [ "$?" == "0" ]
then
  echo $(date +%Y-%m-%d)" tar sucess">>mysql.log
else
  echo $(date +%Y-%m-%d)" tar failed">>mysql.log
  exit 0
fi
rm -f *.sql  												#删除所有的sql文件
delname=mysql_$(date -d "$day day ago" +%Y-%m-%d).tar.gz    #得到要删除的太旧的备份的名字。
rm -f $delname  											#删除文件。