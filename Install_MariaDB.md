# 安装 MariaDB

### 1.yum安装MariaDB
源码包安装MariaDB-10.2.X ，在centos6下测试成功
使用方法：
```
# wget https://github.com/funet8/MYSQL/raw/master/Yum_Install_MariaDB/CentOS6_Install_MariaDB.sh
修改变量
# sh CentOS6_Install_MariaDB.sh
```
centos7
```
# wget https://github.com/funet8/MYSQL/raw/master/Yum_Install_MariaDB/CentOS7_Install_MariaDB.sh
修改变量
# sh CentOS6_Install_MariaDB.sh
```

### 2.使用RPM包离线安装MariaDB
源码包安装MariaDB-10.0.28 ，在centos6下测试成功
使用方法：
```
# wget https://raw.githubusercontent.com/funet8/MYSQL/master/RPM_Install_MariaDB/RPM_Install_MariaDB.sh
修改以下参数
MYSQL_PORY='61920' #MySQL访问端口
Mariadb_File='/data/software/'  #Mariadb的RPM文件路径
#是否有rpm文件 0没有文件需要下载，其他为有
Mariadb_File_yes=1
#是否需要创建web目录
Filedir_yes=1

############执行 shell脚本
# sh RPM_Install_MariaDB.sh
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
