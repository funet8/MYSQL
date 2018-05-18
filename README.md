# 说明

基于centos6 or 7 服务器中的 Mysql/Mariadb 数据库相关内容

本文中 所提到的Mysql与Mariadb相同

github地址： https://github.com/funet8/MYSQL
说明
| 1 | 1|
|---|---|
| 系统 | Centos6 |
| 端口 | 61920 |


## 一、数据库的安装


### 1.yum安装MariaDB
使用方法：

### 2.使用RPM包离线安装MariaDB
源码包安装MariaDB-10.0.28 ，在centos6下测试成功
使用方法：
```
wget https://raw.githubusercontent.com/funet8/MYSQL/master/RPM_Install_MariaDB/RPM_Install_MariaDB.sh
修改参数
MYSQL_PORY='61920' #MySQL访问端口
Mariadb_File='/data/software/'  #Mariadb的RPM文件路径
#是否有rpm文件 0没有文件需要下载，其他为有
Mariadb_File_yes=1
#是否需要创建web目录
Filedir_yes=1
############执行 shell脚本
sh RPM_Install_MariaDB.sh
```
### 3.源码包安装MariaDB
源码包安装mariadb-10.0.35 ，在centos6下测试成功

使用方法：
```
wget https://raw.githubusercontent.com/funet8/MYSQL/master/Source_Package_Install_MariaDB/Source_Package_Install_MariaDB.sh
修改脚本参数
运行脚本
sh Source_Package_Install_MariaDB.sh
```


## 二、mysql优化技术


## 三、数据库主从配置


## 四、SQL常用语句


## 五、数据库高可用方案


## 六、相关知识点
[数据库脑裂](https://github.com/funet8/MYSQL/wiki/%25E6%2595%25B0%25E6%258D%25AE%25E5%25BA%2593%25E8%2584%2591%25E8%25A3%2582)

[DDL，DML和DCL的区别与理解](https://github.com/funet8/MYSQL/wiki/DDL%EF%BC%8CDML%E5%92%8CDCL%E7%9A%84%E5%8C%BA%E5%88%AB%E4%B8%8E%E7%90%86%E8%A7%A3)

[半同步复制](https://github.com/funet8/MYSQL/wiki/%E5%8D%8A%E5%90%8C%E6%AD%A5%E5%A4%8D%E5%88%B6)





