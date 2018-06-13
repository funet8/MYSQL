#!/bin/bash 

# mysql_backup_user.sh

#mysql中用户权限导出的脚本
#参考： https://blog.csdn.net/yumushui/article/details/50264123


#配置参数
MYSQL_User=root 
MYSQL_Pwd=123456
MYSQL_Sock=/data/mysql/mysql.sock

expgrants()    
{    
  mysql -B -u${MYSQL_User} -p${MYSQL_Pwd} -N -S ${MYSQL_Sock} $@ -e "SELECT CONCAT(  'SHOW GRANTS FOR ''', user, '''@''', host, ''';' ) AS query FROM mysql.user" | \
  mysql -u${MYSQL_User} -p${MYSQL_Pwd} -S ${MYSQL_Sock} $@ | \
  sed 's/\(GRANT .*\)/\1;/;s/^\(Grants for .*\)/-- \1 /;/--/{x;p;x;}'    
}    
expgrants > ./grants.sql

#这个导出脚本的整体思路是：分成三个步骤，用管道连接起来，前一步操作的结果，作为后一步操作的输入：
#第一步先使用concat函数，查询mysql.user中的用户授权，并连接成一个show grants for 命令，执行命令时，加上 "-B -N"选项，让输出结果没有列名和方框，只是命令；
#第二步将上一步的show grants for 命令，再次执行一次，得出mysql中每个授权对应的具体的GRANT授权命令；
#第三步使用sed和正则表达式，将上一步的运行结果进行处理，在show grant for 行中加上注释前缀和一个空行，在具体授权的GRANT行中结尾加一个分号，形成可以执行的sql授权命令。
#其中正则表达式添加和修改如下，红色为选择行条件，紫色为添加和修改的内容：
#sed 's/GRANT.∗GRANT.∗/\1;/;s/^Grantsfor.∗Grantsfor.∗/-- \1 /;/--/{x;p;x;}'   