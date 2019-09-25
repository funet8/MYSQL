
# mysql-备份与恢复

## [xtrabackup](使用xtrabackup备份恢复mysql数据库)


## mysqldump 备份数据库

备份会锁表
### mysqldump 锁表备份
```
mysqldump -h'127.0.0.1' -u'用户' -p'密码' --default-character-set=utf8 --all-databases --lock-all-tables --master-data=1 > /root/master.sql
```

### 恢复数据库
```
mysql -h'127.0.0.1' -u'用户' -P'端口' -p'密码' < /root/master.sql

```



操作方法：

```
# cd /data/conf/shell/
# wget https://github.com/funet8/MYSQL/blob/master/mysql-%E5%A4%87%E4%BB%BD%E4%B8%8E%E6%81%A2%E5%A4%8D/mysql_all_backup_mysqldump_remote.sh

# chmod +x mysql_all_backup_mysqldump_remote.sh

添加到crontab定时任务中。
```


[mysql导出用户权限脚本](https://github.com/funet8/MYSQL/blob/master/Mysql_Shell/mysql_backup_user.sh)


https://www.cnblogs.com/halberd-lee/p/11402041.html
