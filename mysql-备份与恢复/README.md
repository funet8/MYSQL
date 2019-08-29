
# mysql-备份与恢复

## [xtrabackup](mysql-备份与恢复/使用xtrabackup备份恢复mysql数据库)


## mysqldump 备份数据库

操作方法：
```
# cd /data/conf/shell/
# wget https://github.com/funet8/MYSQL/blob/master/mysql-%E5%A4%87%E4%BB%BD%E4%B8%8E%E6%81%A2%E5%A4%8D/mysql_all_backup_mysqldump_remote.sh

# chmod +x mysql_all_backup_mysqldump_remote.sh

添加到crontab定时任务中。
```


[mysql导出用户权限脚本](https://github.com/funet8/MYSQL/blob/master/Mysql_Shell/mysql_backup_user.sh)