#!/bin/bash
#mysql主从监控脚本
#check MySQL_Slave Status
#crontab time 00:10


MYSQLPORT=`netstat -na|grep "LISTEN"|grep "3306"|awk -F[:" "]+ '{print $4}'`

MYSQLIP=`ifconfig | grep inet |grep -v 'inet6'|grep -v '127.0.0.1'|awk -F ' ' '{print $2}'`
STATUS=$(mysql -u root -pXXX -e "show slave status\G" | grep -i "running") 
IO_env=`echo $STATUS | grep IO | awk ' {print $2}'`
SQL_env=`echo $STATUS | grep SQL | awk '{print $2}'`
DATA=`date +"%y%m%d-%H:%M:%S"`

if [ "$MYSQLPORT" == "3306" ]
then
 echo "mysql is running"
else
 mail -s "warn!server: $MYSQLIP mysql is down" huangwb@fslgz.com
fi
if [ "$IO_env" = "Yes" -a "$SQL_env" = "Yes" ]
then
 echo "Slave is running!"
else
 echo "####### $DATA #########">> /home/check_mysql_slave.log
 echo "Slave is not running!" >> /home/check_mysql_slave.log
 echo "Slave is not running!" | mail -s "warn!$MYSQLIP MySQL Slave is not running" huangwb@fslgz.com
fi