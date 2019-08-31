# 说明

基于centos6 or 7 服务器中的 Mysql/Mariadb 数据库相关内容

本文中 所提到的Mysql与Mariadb相同，[本github地址](https://github.com/funet8/MYSQL)

系统：最小化安装 Centos6 or 7 (64位)

mysql端口 ：61920

ssh端口：60920


## 一、数据库的安装

[Centos系统安装 MariaDB](https://github.com/funet8/MYSQL/blob/master/Install_MariaDB.md)

## 二、mysql优化技术


## 三、数据库主从配置
[数据库主从配置](https://github.com/funet8/MYSQL/wiki/Mysql%25E6%2595%25B0%25E6%258D%25AE%25E5%25BA%2593%25E4%25B8%25BB%25E4%25BB%258E%25E9%2585%258D%25E7%25BD%25AE)


## 四、SQL常用语句


## 五、数据库备份

[数据库备份](https://github.com/funet8/MYSQL/tree/master/mysql-%E5%A4%87%E4%BB%BD%E4%B8%8E%E6%81%A2%E5%A4%8D)



## 六、数据库高可用方案

### [1.Mycat 数据库中间件](https://github.com/funet8/MYSQL/tree/master/High_Availability/MyCat)

### [2.MHA Keepalived](https://github.com/funet8/MYSQL/tree/master/High_Availability/MHA_Keepalived)

### [3.Mysql-MMM](https://github.com/funet8/MYSQL/tree/master/High_Availability/Mysql-MMM)

### [4.Haproxy Keepalived MySQL](https://github.com/funet8/MYSQL/tree/master/High_Availability/Haproxy_Keepalived_MySQL)

### [5.MariaDB Galera Cluster](https://github.com/funet8/MYSQL/tree/master/High_Availability/MariaDB_Galera_Cluster)


## 七、MYSQL监控
### zabbix 添加mysql监控
### 慢查询日志

## 八、压力测试
### [mysql 压力测试 自带工具mysqlslap](https://github.com/funet8/MYSQL/wiki/mysql-%E5%8E%8B%E5%8A%9B%E6%B5%8B%E8%AF%95-%E8%87%AA%E5%B8%A6%E5%B7%A5%E5%85%B7mysqlslap)
### sysbench

### tpcc-mysql

## 九、相关知识点
[数据库脑裂](https://github.com/funet8/MYSQL/wiki/%E6%95%B0%E6%8D%AE%E5%BA%93%E8%84%91%E8%A3%82)

[DDL，DML和DCL的区别与理解](https://github.com/funet8/MYSQL/wiki/DDL%EF%BC%8CDML%E5%92%8CDCL%E7%9A%84%E5%8C%BA%E5%88%AB%E4%B8%8E%E7%90%86%E8%A7%A3)

[半同步复制](https://github.com/funet8/MYSQL/wiki/%E5%8D%8A%E5%90%8C%E6%AD%A5%E5%A4%8D%E5%88%B6)

[mysql 压力测试 自带工具mysqlslap](https://github.com/funet8/MYSQL/wiki/mysql-%E5%8E%8B%E5%8A%9B%E6%B5%8B%E8%AF%95-%E8%87%AA%E5%B8%A6%E5%B7%A5%E5%85%B7mysqlslap)

[慢查询日志分析-mysqldumpslow](https://github.com/funet8/MYSQL/blob/master/mysql_optimize/mysqldumpslow-help.md)

## 十、Mysql排错记录
[Mysql排错记录](https://github.com/funet8/MYSQL/blob/master/Bug_Record.md)












