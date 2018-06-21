#!/bin/sh

###################################################
# 定时备份的文件                                  #
###################################################
#添加定时任务：
#切割mysql慢查询日志
#0 0 * * * root /data/conf/shell/tar_clear_slowQuery_log.sh

File_Pwd="/data/wwwroot/log/mysql/"
File_Name="slowQuery.log"
#目标路径
File_Pwd_Target="/data/wwwroot/log/mysql/"

File_Pwd2="/data/wwwroot/mysql_log/"
File_Name2="slowQuery.log"
File_Pwd_Target2="/data/wwwroot/mysql_log/"

#tar -zcPf ${File_Pwd_Target}${File_Name}-`date "+%Y-%m-%d-%H-%M-%S"`.tar.gz ${File_Pwd}${File_Name}
#echo '' > ${File_Pwd}${File_Name}

tar -zcPf ${File_Pwd_Target2}${File_Name2}-`date "+%Y-%m-%d-%H-%M-%S"`.tar.gz ${File_Pwd2}${File_Name2}
echo '' > ${File_Pwd2}${File_Name2}
