#!/bin/bash

##慢查询日志分析

### 判断是否有慢查询日志
if [ ! -n "$1" ] ;then
	echo '请输入需要分析的慢查询数据库(slowQuery187 或 slowQuery188)'
	exit 0
fi

#一、同步慢查询日志：
### 初始化变量
SFILE187="/data/wwwroot/mysql_log/slowQuery.log"
slowQuery187="/data/tmp/mysql_slowquery/slowQuery187.log"

SFILE188="/data/wwwroot/log/mysql/slowQuery.log"
slowQuery188="/data/tmp/mysql_slowquery/slowQuery188.log"

SFILE189="/data/wwwroot/log/mysql/slowQuery.log"
slowQuery189="/data/tmp/mysql_slowquery/slowQuery189.log"

SFILE190="/data/wwwroot/mysql_log/slowQuery.log"
slowQuery190="/data/tmp/mysql_slowquery/slowQuery190.log"

SFILE201="/data/wwwroot/mysql_log/slowQuery.log"
slowQuery201="/data/tmp/mysql_slowquery/slowQuery201.log"

SFILE202="/data/wwwroot/mysql_log/slowQuery.log"
slowQuery202="/data/tmp/mysql_slowquery/slowQuery202.log"

FenXi_slowQuery187="/data/tmp/mysql_slowquery/FenXi_slowQuery187.log"
FenXi_slowQuery188="/data/tmp/mysql_slowquery/FenXi_slowQuery188.log"
FenXi_slowQuery189="/data/tmp/mysql_slowquery/FenXi_slowQuery189.log"
FenXi_slowQuery190="/data/tmp/mysql_slowquery/FenXi_slowQuery190.log"
FenXi_slowQuery201="/data/tmp/mysql_slowquery/FenXi_slowQuery201.log"
FenXi_slowQuery202="/data/tmp/mysql_slowquery/FenXi_slowQuery202.log"

##分析187日志：
function slowQuery187(){
	/usr/bin/rsync -ahqzt -e "ssh -p 60920"  --delete  backupall@192.168.20.187:${SFILE187} ${slowQuery187}
	
	echo "###########187MYSQL-执行时间最慢的前10条######################" >> $FenXi_slowQuery187
	/usr/bin/mysqldumpslow -s t -t 10 ${slowQuery187} >> $FenXi_slowQuery187
	echo "###########187MYSQL-锁表时间最长的前10条######################">> $FenXi_slowQuery187
	/usr/bin/mysqldumpslow -s l -t 10 ${slowQuery187} >> $FenXi_slowQuery187
	echo "###########187MYSQL-慢查询次数最多的前10条######################">> $FenXi_slowQuery187
	/usr/bin/mysqldumpslow -s c -t 10 ${slowQuery187} >> $FenXi_slowQuery187
}
function slowQuery188(){
	/usr/bin/rsync -ahqzt -e "ssh -p 60920"  --delete  backupall@192.168.20.188:${SFILE188} ${slowQuery188}
	
	echo "###########188MYSQL-执行时间最慢的前10条######################" >> $FenXi_slowQuery188
	/usr/bin/mysqldumpslow -s t -t 10 ${slowQuery188} >> $FenXi_slowQuery188
	echo "###########188MYSQL-锁表时间最长的前10条######################">> $FenXi_slowQuery188
	/usr/bin/mysqldumpslow -s l -t 10 ${slowQuery188} >> $FenXi_slowQuery188
	echo "###########188MYSQL-慢查询次数最多的前10条######################">> $FenXi_slowQuery188
	/usr/bin/mysqldumpslow -s c -t 10 ${slowQuery188} >> $FenXi_slowQuery188
}
function slowQuery189(){
	/usr/bin/rsync -ahqzt -e "ssh -p 60920"  --delete  backupall@192.168.20.189:${SFILE189} ${slowQuery189}

	echo "###########189MYSQL-执行时间最慢的前10条######################" >> $FenXi_slowQuery189
	/usr/bin/mysqldumpslow -s t -t 10 ${slowQuery189} >> $FenXi_slowQuery189
	echo "###########189MYSQL-锁表时间最长的前10条######################">> $FenXi_slowQuery189
	/usr/bin/mysqldumpslow -s l -t 10 ${slowQuery189} >> $FenXi_slowQuery189
	echo "###########189MYSQL-慢查询次数最多的前10条######################">> $FenXi_slowQuery189
	/usr/bin/mysqldumpslow -s c -t 10 ${slowQuery189} >> $FenXi_slowQuery189
}
function slowQuery190(){
	/usr/bin/rsync -ahqzt -e "ssh -p 60920"  --delete  backupall@192.168.20.190:${SFILE190} ${slowQuery190}
	
	echo "###########190MYSQL-执行时间最慢的前10条######################" >> $FenXi_slowQuery190
	/usr/bin/mysqldumpslow -s t -t 10 ${slowQuery190} >> $FenXi_slowQuery190
	echo "###########190MYSQL-锁表时间最长的前10条######################">> $FenXi_slowQuery190
	/usr/bin/mysqldumpslow -s l -t 10 ${slowQuery190} >> $FenXi_slowQuery190
	echo "###########190MYSQL-慢查询次数最多的前10条######################">> $FenXi_slowQuery190
	/usr/bin/mysqldumpslow -s c -t 10 ${slowQuery190} >> $FenXi_slowQuery190
}
function slowQuery201(){
	/usr/bin/rsync -ahqzt -e "ssh -p 60920"  --delete  backupall@192.168.20.201:${SFILE201} ${slowQuery201}
	
	echo "###########201MYSQL-执行时间最慢的前10条######################" >> $FenXi_slowQuery201
	/usr/bin/mysqldumpslow -s t -t 10 ${slowQuery201} >> $FenXi_slowQuery201
	echo "###########201MYSQL-锁表时间最长的前10条######################">> $FenXi_slowQuery201
	/usr/bin/mysqldumpslow -s l -t 10 ${slowQuery201} >> $FenXi_slowQuery201
	echo "###########201MYSQL-慢查询次数最多的前10条######################">> $FenXi_slowQuery201
	/usr/bin/mysqldumpslow -s c -t 10 ${slowQuery201} >> $FenXi_slowQuery201
}
function slowQuery202(){
	/usr/bin/rsync -ahqzt -e "ssh -p 60920"  --delete  backupall@192.168.20.201:${SFILE202} ${slowQuery202}

	echo "###########202MYSQL-执行时间最慢的前10条######################" >> $FenXi_slowQuery202
	/usr/bin/mysqldumpslow -s t -t 10 ${slowQuery202} >> $FenXi_slowQuery202
	echo "###########202MYSQL-锁表时间最长的前10条######################">> $FenXi_slowQuery202
	/usr/bin/mysqldumpslow -s l -t 10 ${slowQuery202} >> $FenXi_slowQuery202
	echo "###########202MYSQL-慢查询次数最多的前10条######################">> $FenXi_slowQuery202
	/usr/bin/mysqldumpslow -s c -t 10 ${slowQuery202} >> $FenXi_slowQuery202
}

$1





