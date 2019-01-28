#!/bin/bash

# 第一次执行它的时候它会检查是否有完全备份,否则先创建一个全库备份
# 当你再次运行它的时候，它会根据脚本中的设定来基于之前的全备或增量备份进行增量备份
# 来源参考：http://blog.csdn.net/yangzhawen/article/details/44857097/

# 每小时执行一次，如果数据库文件太大，建议6小时备份一次。
# echo "0 * * * * root /data/conf/shell/auto_bak_mysql_xtrabackup.sh" >> /etc/crontab
# 0 */6 * * * root /data/conf/shell/auto_bak_mysql_xtrabackup.sh	每六小时执行一次。
# service crond restart
# 备份存放的目录/backup/mysqlbackup  生成/backup/mysqlbackup/full全量备份、/backup/mysqlbackup/incre增量备份。

##########################
#	创建用户			 #
##########################
#mysql> create user 'backup_user'@'localhost' identified by '123456';     							#创建用户并设置密码
#mysql> revoke all privileges,grant option from 'backup_user'@'localhost';							#去掉用户的所有默认权限
#mysql> grant reload,lock tables,replication client,event on *.* to 'backup_user'@'localhost';  		#重新为用户授权
#mysql> flush privileges;   																			#刷新使其重新授权表

##########################
#	恢复的方法			 #
##########################
#参考：http://www.funet8.com/2633.html 全量备份+增量备份+增量恢复
#cp -a /data/mysql/ /data/mysql_bak    
#rm -rf /data/mysql/*
#/etc/init.d/mysql stop
#innobackupex --apply-log --redo-only --defaults-file=/etc/my.cnf --user=root /全量目录/
#innobackupex --apply-log --redo-only --defaults-file=/etc/my.cnf --user=root /全量目录/ --incremental-dir=/增量一目录/
#innobackupex --apply-log --redo-only --defaults-file=/etc/my.cnf --user=root /全量目录/ --incremental-dir=/增量二目录/
#有几个增量就操作几个增量
#innobackupex --apply-log /backup/全量目录/
#innobackupex --copy-back /backup/全量目录/
#chown -R mysql.mysql /data/mysql/
#/etc/init.d/mysql start


INNOBACKUPEX_PATH=innobackupex  #INNOBACKUPEX的命令
INNOBACKUPEXFULL=/usr/bin/$INNOBACKUPEX_PATH  #INNOBACKUPEX的命令路径

#mysql目标服务器以及用户名和密码
MYSQL_CMD="--host=localhost --user=backup_user --password=123456 --port=61920"

TMPLOG="/tmp/innobackupex.log"
MY_CNF=/etc/my.cnf 											#mysql的配置文件
MYSQL=/usr/bin/mysql 
MYSQL_ADMIN=/usr/bin/mysqladmin
BACKUP_DIR=/backup/mysqlbackup 								# 备份的主目录
#BACKUP_DIR=/data/mysql_backup
FULLBACKUP_DIR=$BACKUP_DIR/full 							# 全库备份的目录
INCRBACKUP_DIR=$BACKUP_DIR/incre 							# 增量备份的目录
FULLBACKUP_INTERVAL="86400" 								# 全库备份的间隔周期，时间：86400秒=24小时 
KEEP_FULLBACKUP="1" 										# 至少保留几个全库备份
KEEP_DAY="1440"												# 单位小时 24x60=1440（一天）
logfiledate=backup.`date +%Y%m%d%H%M`.txt					
#开始时间
STARTED_TIME=`date +%s`

#############################################################################
# 显示错误并退出
#############################################################################
mkdir -p $BACKUP_DIR
error()
{
    echo "$1" 1>&2
    exit 1
}
# 检查执行环境
if [ ! -x $INNOBACKUPEXFULL ]; then
  error "$INNOBACKUPEXFULL未安装或未链接到/usr/bin."
fi

if [ ! -d $BACKUP_DIR ]; then
  error "备份目标文件夹:$BACKUP_DIR不存在."
fi

mysql_status=`netstat -nl | awk 'NR>2{if ($4 ~ /.*:61920/) {print "Yes";exit 0}}'`
if [ "$mysql_status" != "Yes" ];then
    error "MySQL 没有启动运行."
fi

if ! `echo 'exit' | $MYSQL -s $MYSQL_CMD` ; then
 error "提供的数据库用户名或密码不正确!"
fi

# 备份的头部信息
echo "----------------------------"
echo
echo "$0: MySQL备份脚本"
echo "开始于: `date +%F' '%T' '%w`"
echo

#新建全备和差异备份的目录
mkdir -p $FULLBACKUP_DIR
mkdir -p $INCRBACKUP_DIR

#查找最新的完全备份
LATEST_FULL_BACKUP=`find $FULLBACKUP_DIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -1`

# 查找最近修改的最新备份时间
LATEST_FULL_BACKUP_CREATED_TIME=`stat -c %Y $FULLBACKUP_DIR/$LATEST_FULL_BACKUP`

#如果全备有效进行增量备份否则执行完全备份
if [ "$LATEST_FULL_BACKUP" -a `expr $LATEST_FULL_BACKUP_CREATED_TIME + $FULLBACKUP_INTERVAL + 5` -ge $STARTED_TIME ] ; then
	# 如果最新的全备未过期则以最新的全备文件名命名在增量备份目录下新建目录
	echo -e "完全备份$LATEST_FULL_BACKUP未过期,将根据$LATEST_FULL_BACKUP名字作为增量备份基础目录名"
	echo "					   "
	NEW_INCRDIR=$INCRBACKUP_DIR/$LATEST_FULL_BACKUP
	mkdir -p $NEW_INCRDIR

	# 查找最新的增量备份是否存在.指定一个备份的路径作为增量备份的基础
	LATEST_INCR_BACKUP=`find $NEW_INCRDIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n"  | sort -nr | head -1`
		if [ ! $LATEST_INCR_BACKUP ] ; then
			INCRBASEDIR=$FULLBACKUP_DIR/$LATEST_FULL_BACKUP
			echo -e "增量备份将以$INCRBASEDIR作为备份基础目录"
			echo "					   "
		else
			INCRBASEDIR=$INCRBACKUP_DIR/${LATEST_FULL_BACKUP}/${LATEST_INCR_BACKUP}
			echo -e "增量备份将以$INCRBASEDIR作为备份基础目录"
			echo "					   "
		fi

	echo "使用$INCRBASEDIR作为基础本次增量备份的基础目录."
	$INNOBACKUPEXFULL --defaults-file=$MY_CNF --use-memory=4G $MYSQL_CMD --incremental $NEW_INCRDIR --incremental-basedir $INCRBASEDIR > $TMPLOG 2>&1	
	
	#保留一份备份的详细日志

	cat $TMPLOG>$BACKUP_DIR/$logfiledate

	if [ -z "`tail -1 $TMPLOG | grep 'innobackupex: completed OK!'`" ] ; then
	 echo "$INNOBACKUPEX命令执行失败:"; echo
	 echo -e "---------- $INNOBACKUPEX_PATH错误 ----------"
	 cat $TMPLOG
	 rm -f $TMPLOG
	 exit 1
	fi

	THISBACKUP=`awk -- "/Backup created in directory/ { split( \\\$0, p, \"'\" ) ; print p[2] }" $TMPLOG`
	rm -f $TMPLOG


	echo -n "数据库成功备份到:$THISBACKUP"
	echo

	# 提示应该保留的备份文件起点
	LATEST_FULL_BACKUP=`find $FULLBACKUP_DIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -1`
	NEW_INCRDIR=$INCRBACKUP_DIR/$LATEST_FULL_BACKUP
	LATEST_INCR_BACKUP=`find $NEW_INCRDIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n"  | sort -nr | head -1`
	RES_FULL_BACKUP=${FULLBACKUP_DIR}/${LATEST_FULL_BACKUP}
	RES_INCRE_BACKUP=`dirname ${INCRBACKUP_DIR}/${LATEST_FULL_BACKUP}/${LATEST_INCR_BACKUP}`

	echo
	echo -e '\e[31m NOTE:---------------------------------------------------------------------------------.\e[m' #红色
	echo -e "必须保留$KEEP_FULLBACKUP份全备即全备${RES_FULL_BACKUP}和${RES_INCRE_BACKUP}目录中所有增量备份."
	echo -e '\e[31m NOTE:---------------------------------------------------------------------------------.\e[m' #红色
	echo
else
	echo  "*********************************"
	echo -e "正在执行全新的完全备份...请稍等..."
	echo  "*********************************"
	$INNOBACKUPEXFULL --defaults-file=$MY_CNF  --use-memory=4G  $MYSQL_CMD $FULLBACKUP_DIR > $TMPLOG 2>&1 
	#保留一份备份的详细日志
	cat $TMPLOG>$BACKUP_DIR/$logfiledate
	if [ -z "`tail -1 $TMPLOG | grep 'innobackupex: completed OK!'`" ] ; then
	 echo "$INNOBACKUPEX命令执行失败:"; echo
	 echo -e "---------- $INNOBACKUPEX_PATH错误 ----------"
	 cat $TMPLOG
	 rm -f $TMPLOG
	 exit 1
	fi

	 
	THISBACKUP=`awk -- "/Backup/mysqlbackup created in directory/ { split( \\\$0, p, \"'\" ) ; print p[2] }" $TMPLOG`
	rm -f $TMPLOG

	echo -n "数据库成功备份到:$THISBACKUP"
	echo

	# 提示应该保留的备份文件起点

	LATEST_FULL_BACKUP=`find $FULLBACKUP_DIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -1`

	RES_FULL_BACKUP=${FULLBACKUP_DIR}/${LATEST_FULL_BACKUP}

	echo
	echo -e '\e[31m NOTE:---------------------------------------------------------------------------------.\e[m' #红色
	echo -e "无增量备份,必须保留$KEEP_FULLBACKUP份全备即全备${RES_FULL_BACKUP}."
	echo -e '\e[31m NOTE:---------------------------------------------------------------------------------.\e[m' #红色
	echo

fi

#删除过期的全备
echo -e "find expire backup file...........waiting........."
echo -e "寻找过期的文件并删除">>$BACKUP_DIR/$logfiledate
for efile in $(/usr/bin/find $BACKUP_DIR/ -mmin +$KEEP_DAY)
#/usr/bin/find /backup/mysqlbackup/ -mmin +1
do
	if [ -d ${efile} ]; then
	rm -rf "${efile}"
	echo -e "删除过期文件夹:${efile}" >>$BACKUP_DIR/$logfiledate
	elif [ -f ${efile} ]; then
	rm -rf "${efile}"
	echo -e "删除过期文件:${efile}" >>$BACKUP_DIR/$logfiledate
	fi;
	
done

if [ $? -eq "0" ];then
   echo
   echo -e "未找到可以删除的过期全备文件" >>$BACKUP_DIR/$logfiledate
fi

echo
echo "完成于: `date +%F' '%T' '%w`" >>$BACKUP_DIR/$logfiledate
exit 0