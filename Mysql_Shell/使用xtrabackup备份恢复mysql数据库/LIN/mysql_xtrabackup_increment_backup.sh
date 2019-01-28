#!/bin/bash

# -------------------------------------------------------------------------------
# Filename:    mysql_xtrabackup_increment_backup.sh
# Revision:    1.0
# Date:        2015-1-5
# Author:      三木
# Email:       linmaogan#gmail.com
# Website:     www.3mu.me
# Description: 使用XtraBackup增量备份MySQL
# Notes:       1、变量设置中Database项目前无效，除非在命令innobackupex中添加此项参数；
#              2、增量备份最高频率只能为一天一次，如果一天增量备份多次，就会造成
#                 /backup/mysql/increment/2.txt中的目录（备份生成的目录）数超过一个，在还原备份时，
#                 使选项“--incremental-basedir”的路径为多个目录的连接而造成目录路径不正确，使还原备份失败
# -------------------------------------------------------------------------------
# Copyright:   2014 (c) 三木
# License:     GPL
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# you should have received a copy of the GNU General Public License
# along with this program (or with Nagios);
#
# Credits go to Ethan Galstad for coding Nagios
# If any changes are made to this script, please mail me a copy of the changes
# -------------------------------------------------------------------------------
#Version 1.0
#2015-1-5 三木 初始版本建立
# -------------------------------------------------------------------------------

#脚本定时执行的方法###################################################################
# 设置crontab任务，每天执行备份脚本，周一到周六凌晨4:00做增量备份
#echo "0 4 * * 1-6 root /data/shell/mysql_backup/mysql_xtrabackup_increment_backup.sh >/dev/null 2>&1" >> /etc/crontab

#变量设置#############################################################################
DATE=`date "+%F"`
User="ghss_lmg" 
Passwd="jFFEQ0kPtMZRPUrjMEfwZALugQnaTfyn"
Host="localhost"
Port=61920
mysql_cnf_path="/etc/my.cnf"
data_bak_dir="/backup/mysql/increment/$DATE"   #备份的目录
eMailFile=/backup/mysql/increment/email.txt
eMail=linmaogan@qq.com
logFile=/backup/mysql/increment/logs/mysql-$DATE.log
#Database="test 3mu" # 同时备份test 和 3mu 这两个数据库，如果要备份所有数据库，将备份语句中的“--database="$Database"”项删除即可，默认备份所有数据库
#str=data-$(date +%Y-%m-%d_%H-%M-%S).tar.gz
FDIR1=`cat /backup/mysql/full/1.txt`
FDIR2=`cat /backup/mysql/full/2.txt`

#执行备份#############################################################################
if [ ! -d $data_bak_dir ] ; then
  mkdir -p $data_bak_dir
fi

echo "     " > $eMailFile
echo "---------------------------------" >> $eMailFile
echo $(date +"%y-%m-%d %H:%M:%S") >> $eMailFile


# 备份不压缩
/usr/bin/innobackupex --user=$User --password=$Passwd --defaults-file=$mysql_cnf_path  --incremental-force-scan --incremental $data_bak_dir --incremental-basedir=$FDIR1/$FDIR2/ >> $eMailFile 2>&1

# 备份指定数据库
#/usr/bin/innobackupex --user=$User --password=$Passwd --database="$Database" --incremental $data_bak_dir --incremental-basedir=$FDIR1/$FDIR2/ >> $eMailFile 2>&1

# 备份并压缩，缺点，压缩后，还原备份时找不到上一次备份相应的备份信息
#/usr/bin/innobackupex --user=$User --password=$Passwd --host=$Host --port=$Port --defaults-file=$mysql_cnf_path --database="$Database" --stream=tar   $data_bak_dir 2> $eMailFile | gzip 1>$data_bak_dir/$str   

ls -d /backup/mysql/increment/$DATE > /backup/mysql/increment/1.txt # 把增量备份存放的根目录记录到文件
ls /backup/mysql/increment/$DATE > /backup/mysql/increment/2.txt    # 把增量备份生成的目录存放到文件

if [[ $? == 0 ]]; then
    echo "BackupFileName:$Database" >> $eMailFile
    echo "DataBase Increment Backup Success" >> $eMailFile
    else
    echo "DataBase Increment Backup Fail!" >> $eMailFile
    mail -s " DataBase Increment Backup Fail " $eMail < $eMailFile  #如果备份不成功发送邮件通知
fi

if [ ! -d '/backup/mysql/increment/logs/' ] ; then
  mkdir -p '/backup/mysql/increment/logs/'
fi

echo "--------------------------------------------------------" >> $logFile
cat $eMailFile >> $logFile
find /backup/mysql/increment/ -name "*" -mtime +30 |xargs rm -rf

#echo "/usr/bin/innobackupex --user=$User --password=$Passwd --incremental $data_bak_dir --incremental-basedir=$FDIR1/$FDIR2/ >> $eMailFile 2>&1"

#参考资料#############################################################################
# MySQL备份工具XtraBackup安装及全量和增量备份与恢复测试：http://www.3mu.me/mysql%E5%A4%87%E4%BB%BD%E5%B7%A5%E5%85%B7xtrabackup%E5%AE%89%E8%A3%85%E5%8F%8A%E5%85%A8%E9%87%8F%E5%92%8C%E5%A2%9E%E9%87%8F%E5%A4%87%E4%BB%BD%E4%B8%8E%E6%81%A2%E5%A4%8D%E6%B5%8B%E8%AF%95/#i-7
#xtrabackup对MySQL进行备份和恢复的全过程：http://blog.chinaunix.net/uid-23914782-id-3353945.html