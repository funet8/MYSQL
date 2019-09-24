# 安装Percona XtraBackup 2.3

## 系统介绍
IP：192.168.0.2
centos7

# centos7 安装 percona-xtrabackup 2.4.8-1

https://blog.csdn.net/mr_tia/article/details/81979689
```
下载XtraBackup rpm包

wget https://www.percona.com/downloads/XtraBackup/Percona-XtraBackup-2.4.8/binary/redhat/7/x86_64/percona-xtrabackup-24-2.4.8-1.el7.x86_64.rpm

安装依赖包：

rpm -Uvh http://rpmfind.net/linux/epel/6/x86_64/Packages/l/libev-4.03-3.el6.x86_64.rpm
yum -y install perl perl-devel libaio libaio-devel perl-Time-HiRes perl-DBD-MySQL perl-Digest-MD5

安装XtraBackup

rpm -ivh percona-xtrabackup-24-2.4.8-1.el7.x86_64.rpm
# innobackupex -v

```

## 卸载
```
rpm -qa | grep -i percona*
percona-xtrabackup-24-2.4.8-1.el7.x86_64
percona-release-0.1-3.noarch
yum remove percona*
```




# centos7 安装 percona-xtrabackup 2.3

https://www.percona.com/doc/percona-xtrabackup/2.3/installation.html

```
1，安装依赖库

yum install -y http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm

yum -y install perl-Time-HiRes perl-DBD-MySQL perl-IO-Socket-SSL perl-Digest-MD5

2，安装软件

yum install -y percona-xtrabackup-23


3进入mysql,赋予最低权限
#mysql -u root -p

> create user 'bkpuser'@'%' identified by '123456';

> grant reload,lock tables,replication client on *.* to 'bkpuser'@'%';

```

mariadn10版本之后的要用xtabackup2.4版本之后的。用2.4版本后就ok了。


















## 参考
https://www.percona.com/doc/percona-xtrabackup/2.3/installation/compiling_xtrabackup.html#compiling-xtrabackup

## 克隆项目
源代码可以从Percona XtraBackup Github项目。最简单的方法得到的代码是git克隆和切换到所需的发布分支,如以下:
```
$ git clone https://github.com/percona/percona-xtrabackup.git
目录有3G多，下载比较慢，我的方法，使用香港vpn再打包上传到服务器。
$ cd percona-xtrabackup
$ git checkout 2.3
```

安装依耐
```
yum install -y cmake gcc gcc-c++ libaio libaio-devel automake autoconf bison libtool ncurses-devel libgcrypt-devel libev-devel libcurl-devel vim-common
```

编译与CMake和安装
```
$ cmake -DBUILD_CONFIG=xtrabackup_release -DWITH_MAN_PAGES=OFF && make -j4
$ make install   #默认是：`/usr/local/xtrabackup`目录
$ make DESTDIR=/data/xtrabackup/2.3 install
```


或通过改变安装布局(or by changing the installation layout with):
```
$ cmake -DINSTALL_LAYOUT=...
```


```
[root@node2 bin]# /data/xtrabackup/2.3/usr/local/xtrabackup/bin/xtrabackup -v
xtrabackup: recognized server arguments: --datadir=/var/lib/mysql 
/data/xtrabackup/2.3/usr/local/xtrabackup/bin/xtrabackup version 2.3.10 based on MySQL server 5.6.24 Linux (x86_64) (revision id: 9c6e4ef)
```


# 安装Percona XtraBackup 2.4

## 参考
https://www.percona.com/doc/percona-xtrabackup/2.4/installation/compiling_xtrabackup.html#compiling-xtrabackup
```
$ git clone https://github.com/percona/percona-xtrabackup.git
$ cd percona-xtrabackup
$ git checkout 2.4
```

安装依耐
```
$ yum install cmake gcc gcc-c++ libaio libaio-devel automake autoconf  bison libtool ncurses-devel libgcrypt-devel libev-devel libcurl-devel vim-common
```


编译与CMake和安装
```
$ cmake -DBUILD_CONFIG=xtrabackup_release -DWITH_MAN_PAGES=OFF && make -j4
$ make install   #默认是：`/usr/local/xtrabackup`目录
$ make DESTDIR=/data/xtrabackup/2.4 install
```







