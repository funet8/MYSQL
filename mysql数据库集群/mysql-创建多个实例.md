# mysql-创建多个实例

IP：192.168.1.6
端口： 61920,61921,61922,61923,61924

## 安装Mysql
略

## mysql-创建多个实例

1.创建文件夹
```
mkdir -p /home/data/mysql/{61920,61921,61922,61923,61924} 	# mysql文件目录
mkdir -p /home/data/mysql/etc/my.cnf.d	 					# mysql配置目录
```

2. 初始化实例
```
mysql_install_db --basedir=/usr --datadir=/home/data/mysql/61920 --user=mysql
mysql_install_db --basedir=/usr --datadir=/home/data/mysql/61921 --user=mysql
mysql_install_db --basedir=/usr --datadir=/home/data/mysql/61922 --user=mysql
```

3. 增加配置文件
```
vi /home/data/mysql/etc/61920.cnf
填写一下：
[client]
port=61920
socket=/home/data/mysql/61920/mysql61920.sock

[mysqld]
datadir=/home/data/mysql/61920
port=61920
server_id=1
socket=/home/data/mysql/61920/mysql61920.sock
slow-query-log-file=/data/wwwroot/mysql_log/slowQuery_61920.log

!includedir /home/data/mysql/etc/my.cnf.d/

```

新增通用配置
```
vim /home/data/mysql/etc/my.cnf.d/my.cnf

[mysqld]
skip-name-resolve
lower_case_table_names=1
innodb_file_per_table=1
back_log=50
max_connections=10000
max_connect_errors=1000
table_open_cache=2048
max_allowed_packet=16M
binlog_cache_size=2M
max_heap_table_size=64M
sort_buffer_size=2M
join_buffer_size=2M
thread_cache_size=64
thread_concurrency=8
query_cache_size=64M
query_cache_limit=2M
ft_min_word_len=4
default-storage-engine=innodb
thread_stack=192K
transaction_isolation=REPEATABLE-READ
tmp_table_size=64M
log-bin=mysql-bin
binlog_format=row
slow_query_log
long_query_time=1
server-id=1
key_buffer_size=8M
read_buffer_size=2M
read_rnd_buffer_size=2M
bulk_insert_buffer_size=64M
myisam_sort_buffer_size=128M
myisam_max_sort_file_size=10G
myisam_repair_threads=1
myisam_recover
innodb_additional_mem_pool_size=16M
innodb_buffer_pool_size=200M
innodb_data_file_path=ibdata1:10M:autoextend
innodb_file_io_threads=8
innodb_thread_concurrency=16
innodb_flush_log_at_trx_commit=1
innodb_log_buffer_size=16M
innodb_log_file_size=512M
innodb_log_files_in_group=3
innodb_max_dirty_pages_pct=60
innodb_lock_wait_timeout=120
[mysqldump]
quick
max_allowed_packet=256M
[mysql]
no-auto-rehash
[myisamchk]
key_buffer_size=512M
sort_buffer_size=512M
read_buffer=8M
write_buffer=8M
[mysqlhotcopy]
interactive-timeout
[mysqld_safe]
open-files-limit=8192
```

配置文件更改权限
```
chown mysql.mysql -R /home/data/mysql/etc/
```
启动实例
```
/usr/bin/mysqld_safe --defaults-file=/home/data/mysql/etc/61920.cnf &
/usr/bin/mysqld_safe --defaults-file=/home/data/mysql/etc/61921.cnf &
/usr/bin/mysqld_safe --defaults-file=/home/data/mysql/etc/61922.cnf &
```
进入实例
```
mysql -u root -S /home/data/mysql/61920/mysql61920.sock
mysql -u root -S /home/data/mysql/61921/mysql61921.sock
mysql -u root -S /home/data/mysql/61922/mysql61922.sock
```
关闭数据库
```
mysqladmin -uroot  -p 123456 -S /home/data/mysql/61920/mysql61920.sock shutdown
mysqladmin -uroot  -p 123456 -S /home/data/mysql/61921/mysql61921.sock shutdown
mysqladmin -uroot  -p 123456 -S /home/data/mysql/61922/mysql61922.sock shutdown
```

新建用户并且设置密码
```
新建用户 star
密码 123456

# mysql -u root -S /home/data/mysql/61921/mysql61921.sock
mysql>CREATE USER 'star'@'%' IDENTIFIED BY '123456';
mysql>GRANT  all privileges ON * . * TO 'star'@'%' IDENTIFIED BY '123456';   #此命令GRANT权限没有赋予用户
mysql>GRANT ALL PRIVILEGES ON * . * TO 'star'@'%' WITH GRANT OPTION MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0 ;
mysql>flush privileges;

使用新用户登录
mysql -u star -h127.0.0.1  -P 61921 -p123456
```
开机启动
```
echo '/usr/bin/mysqld_safe --defaults-file=/home/data/mysql/etc/61920.cnf &
/usr/bin/mysqld_safe --defaults-file=/home/data/mysql/etc/61921.cnf &
/usr/bin/mysqld_safe --defaults-file=/home/data/mysql/etc/61922.cnf &' >> /etc/rc.local
```
是否开机启动
```
systemctl enable mariadb
systemctl disable mariadb
```


