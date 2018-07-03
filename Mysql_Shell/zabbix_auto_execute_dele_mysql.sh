#!/bin/bash

# -------------------------------------------------------------------------------
# Filename:    zabbix_auto_execute_dele_mysql.sh
# 自动删除zabbix数据库N天之前的数据
# -------------------------------------------------------------------------------


#脚本定时执行的方法###################################################################
# vi /data/conf/shell/zabbix_auto_execute_dele_mysql.sh
# chmod +x /data/conf/shell/zabbix_auto_execute_dele_mysql.sh

# 设置crontab任务每月15日4:00执行SQL语句
# echo "0 4 15 * * root /data/conf/shell/zabbix_auto_execute_dele_mysql.sh" >> /etc/crontab

####################################
#20180703执行该脚本，清除了所有历史数据！
####################################

#变量设置#############################################################################
User="zabbixuser"
Passwd="123456"
host='192.168.20.178'
Date=`date -d $(date -d "-30 day" +%Y%m%d) +%s` #取15天之前的时间戳

log_file='/data/wwwroot/log_mysql/zabbix_auto_execute_dele_mysql.log'

#关闭zabbix监控-避免数据写入和误报
/etc/init.d/zabbix_server stop

$(which mysql) -u${User} -h${host} -p${Passwd} -e "
use zabbix;
DELETE FROM history WHERE 'clock' < $Date;
optimize table history;
DELETE FROM history_str WHERE 'clock' < $Date;
optimize table history_str;
DELETE FROM history_uint WHERE 'clock' < $Date;
optimize table history_uint;
DELETE FROM history_text WHERE 'clock' < $Date;
optimize table history_text;
DELETE FROM  trends WHERE 'clock' < $Date;
optimize table  trends;
DELETE FROM trends_uint WHERE 'clock' < $Date;
optimize table trends_uint;
DELETE FROM events WHERE 'clock' < $Date;
optimize table events;
"
if [[ $? == 0 ]]; then
    echo $(date +"%Y-%m-%d %H:%M:%S")"Auto Execute Mysql Success" >> $log_file
else
    echo $(date +"%Y-%m-%d %H:%M:%S") "Auto Execute Mysql Fail" >> $log_file
fi

#启动zabbix服务
/etc/init.d/zabbix_server start



