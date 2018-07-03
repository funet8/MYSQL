#!/bin/bash
# -------------------------------------------------------------------------------
# Filename:    auto_execute_dele_mysql.sh
# 自动删除数据库过期数据
# -------------------------------------------------------------------------------

#脚本定时执行的方法###################################################################
# vi /data/conf/shell/auto_execute_dele_mysql.sh
# chmod +x /data/conf/shell/auto_execute_dele_mysql.sh

# 设置crontab任务每月15日5:00执行SQL语句
#echo "0 5 15 * * root /data/conf/shell/auto_execute_dele_mysql.sh >/dev/null 2>&1" >> /etc/crontab

#变量设置#############################################################################
host='192.168.20.178'
user='zabbixuser'
password='123456'
port=61920 # MySQL访问端口
log_file='/data/wwwroot/log_mysql/auto_execute_dele_mysql_zabbix.log'

#登录MySQL并执行SQL语句###############################################################
if [ ! -f $log_file ] ; then
  touch $log_file
fi

echo "---------------------------------" >> $log_file
echo $(date +"%Y-%m-%d %H:%M:%S") >> $log_file
#关闭zabbix监控-避免数据写入
/etc/init.d/zabbix_server stop

#删除history前30天的数据
mysql -h${host} -u${user} -p"${password}" -P${port} -e "use zabbix; delete from history where clock+30*24*3600 < UNIX_TIMESTAMP();" >> $log_file 2>&1

#删除history_uint前30天的数据
mysql -h${host} -u${user} -p"${password}" -P${port} -e "use zabbix; delete from history_uint where clock+30*24*3600 < UNIX_TIMESTAMP();" >> $log_file 2>&1

#优化表
mysql -h${host} -u${user} -p"${password}" -P${port} -e "use zabbix; optimize table history_uint; optimize table history;" >> $log_file 2>&1

if [[ $? == 0 ]]; then
    echo $(date +"%Y-%m-%d %H:%M:%S")"Auto Execute Mysql Success" >> $log_file
else
    echo $(date +"%Y-%m-%d %H:%M:%S") "Auto Execute Mysql Fail" >> $log_file
fi

#开启zabbix监控
/etc/init.d/zabbix_server start

###########################################################################################
#
sleep 30

host2='192.168.20.178'
user2='7477_tongji'
password2='123456'
port2=61920 # MySQL访问端口
log_file2='/data/wwwroot/log_mysql/auto_execute_dele_mysql_7477_com_tongji178.log'

#删除history前30天的数据
mysql -h${host2} -u${user2} -p"${password2}" -P${port2} -e "use 7477_com_tongji178; delete from tongji_click_log where addtime+30*24*3600 < UNIX_TIMESTAMP();" >> $log_file2 2>&1
#优化表
mysql -h${host2} -u${user2} -p"${password2}" -P${port2} -e "use 7477_com_tongji178; optimize table tongji_click_log;" >> $log_file2 2>&1

if [[ $? == 0 ]]; then
    echo $(date +"%Y-%m-%d %H:%M:%S")"Auto Execute 7477_com_tongji178 Mysql Success" >> $log_file2
else
    echo $(date +"%Y-%m-%d %H:%M:%S") "Auto Execute 7477_com_tongji178 Mysql Fail" >> $log_file2
fi


