#!/bin/bash

cd /home

if [ ! -d "crontab" ];then
mkdir crontab
else
echo "文件夹已经存在"
fi

cd crontab
date=`date +%Y%m%d`
echo `date +%Y%m%d-%H%M`：开始备份 >> backup_db.log

echo "------ start backup db ------"

ssh root@192.168.0.3 -p 60920 \ "mkdir -p /home/backup/database/`date +%Y%m%d`"

echo `date +%Y%m%d-%H%M`：创建目录-$date >> backup_db.log

innobackupex --defaults-file=/etc/my.cnf --no-lock --user 'root' --password '123456' --stream=tar ./ | ssh root@192.168.0.3 -p 60920  \ "cat - > /home/backup/database/`date +%Y%m%d`/`date +%H-%M`-backup.tar"

echo `date +%Y%m%d-%H%M`：备份结束 >> backup_db.log

echo "------ end backup db ------"