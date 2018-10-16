# CentOS 7编译安装MySQL 8.0

## 查看linux的版

```
[root@node2 ~]# cat /etc/redhat-release 
CentOS Linux release 7.3.1611 (Core) 
```
**备注：**
安装过程中会缺少基础包，本实例环境缺少上述包，先提前安装相应的包
```
yum install ncurses-devel bison
```
## 安装步骤

**1.cmake的源编译安装**
```
# wget https://cmake.org/files/v3.11/cmake-3.11.1.tar.gz
# tar zxvf cmake-3.11.1.tar.gz
# cd cmake-3.11.1
# ./configure
# gmake && make install

./bootstrap && gmake && gmake install

####yum安装
yum install -y cmake
```
报错：
```
[root@node2 cmake-3.11.1]# ./configure
---------------------------------------------
CMake 3.11.1, Copyright 2000-2018 Kitware, Inc. and Contributors
C compiler on this system is: cc       
---------------------------------------------
Error when bootstrapping CMake:
Cannot find a C++ compiler supporting C++11 on this system.
Please specify one using environment variable CXX.
See cmake_bootstrap.log for compilers attempted.
---------------------------------------------
Log of errors: /root/software/cmake-3.11.1/Bootstrap.cmk/cmake_bootstrap.log
---------------------------------------------

[root@node2 cmake-3.11.1]# gcc -v
Using built-in specs.
COLLECT_GCC=gcc
COLLECT_LTO_WRAPPER=/usr/libexec/gcc/x86_64-redhat-linux/4.8.5/lto-wrapper
Target: x86_64-redhat-linux
Configured with: ../configure --prefix=/usr --mandir=/usr/share/man --infodir=/usr/share/info --with-bugurl=http://bugzilla.redhat.com/bugzilla --enable-bootstrap --enable-shared --enable-threads=posix --enable-checking=release --with-system-zlib --enable-__cxa_atexit --disable-libunwind-exceptions --enable-gnu-unique-object --enable-linker-build-id --with-linker-hash-style=gnu --enable-languages=c,c++,objc,obj-c++,java,fortran,ada,go,lto --enable-plugin --enable-initfini-array --disable-libgcj --with-isl=/builddir/build/BUILD/gcc-4.8.5-20150702/obj-x86_64-redhat-linux/isl-install --with-cloog=/builddir/build/BUILD/gcc-4.8.5-20150702/obj-x86_64-redhat-linux/cloog-install --enable-gnu-indirect-function --with-tune=generic --with-arch_32=x86-64 --build=x86_64-redhat-linux
Thread model: posix
gcc version 4.8.5 20150623 (Red Hat 4.8.5-28) (GCC) 

```
## [在CentOS 7.2下升级gcc编译器的版本](https://www.cnblogs.com/freeweb/p/5990860.html)
下载安装包：
```
# wget http://ftp.tsukuba.wide.ad.jp/software/gcc/releases/gcc-4.9.3/gcc-4.9.3.tar.bz2
# wget http://ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz
# wget http://ftp.gnu.org/gnu/mpfr/mpfr-3.1.5.tar.gz
# wget http://ftp.gnu.org/gnu/gmp/gmp-5.0.1.tar.gz
```
### 安装gmp
```
tar -xvzf gmp-5.0.1.tar.gz
cd gmp-5.0.1/
mkdir temp
cd temp/
../configure --prefix=/usr/local/gmp-5.0.1
make && make install
```
这样就安装好了，注意：编译时建议指定安装位置，以便后面加载依赖，这里是/usr/local下

### 安装mpfr
```
tar -xvzf mpfr-3.1.5.tar.gz
cd mpfr-3.1.5/
mkdir temp
cd temp/
../configure --prefix=/usr/local/mpfr-3.1.5 --with-gmp=/usr/local/gmp-5.0.1
make && make install
```
到这里mpfr安装完毕，并且必须添加--with-gmp导入gmp依赖，如果不加这个参数也会安装成功，但是后面安装GCC会报一个内部依赖的错误，如果这里不加会很麻烦

### 安装mpc
```
tar -xvzf mpc-1.0.3.tar.gz
cd mpc-1.0.3/
mkdir temp
cd temp/
../configure --prefix=/usr/local/mpc-1.0.3 --with-gmp=/usr/local/gmp-5.0.1 --with-mpfr=/usr/local/mpfr-3.1.5
make && make install
```
同样一定要加上依赖的参数，现在mpc也安装完毕，然后执行 vim /etc/profile 编辑环境变量配置文件，直接在文件最后添加一行下面的变量：
```
# vi /etc/profile 
添加：
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/mpc-1.0.3/lib:/usr/local/gmp-5.0.1/lib:/usr/local/mpfr-3.1.5/lib
# source /etc/profile
```

## 安装（升级）GCC
解压文件：
```
yum install -y bzip2
bunzip2 gcc-4.9.3.tar.bz2 
tar -xvf gcc-4.9.3.tar 

### 安装编译源码所需要工具及库
yum groupinstall "Development Tools"
yum install -y ncurses-devel openssl-devel openssl gcc gcc-c++ ncurses-devel perl
```
安装gcc
```
cd gcc-4.9.3/
mkdir output
cd output/ 
../configure --disable-multilib --enable-languages=c,c++ --with-gmp=/usr/local/gmp-5.0.1 --with-mpfr=/usr/local/mpfr-3.1.5 --with-mpc=/usr/local/mpc-1.0.3

然后开始编译并且安装：
make -j4
make install
```
**gcc安装失败**

## mysql的编译安装

```
#tar zxvf mysql-8.0.11.tar.gz
# cd mysql-8.0.11/
# mkdir Zdebug
# cd Zdebug

# cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DENABLED_LOCAL_INFILE=ON \
-DWITH_INNODB_MEMCACHED=ON \
-DWITH_SSL=system \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_FEDERATED_STORAGE_ENGINE=1 \
-DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
-DWITH_ARCHIVE_STORAGE_ENGINE=1 \
-DWITHOUT_EXAMPLE_STORAGE_ENGINE=1 \
-DWITH_PERFSCHEMA_STORAGE_ENGINE=1 \
-DCOMPILATION_COMMENT="zsd edition" \
-DDOWNLOAD_BOOST=1 \
-DWITH_BOOST=/tmp \
-DMYSQL_UNIX_ADDR=/data/mysqldata/3306/mysql.sock \
-DSYSCONFDIR=/data/mysqldata/3306 > /root/software/mysql-8.0.11/Zdebug/mysql_cmake80.log 2>&1
```
出现下列日志:

```
............-- Configuring done-- Generating done-- Build files have been written to: /data/software/mysql-8.0.11/Zdebug............
```
说明编译成功，其中-DWITH_SSL=system用的是linux操作系统的openssl，需要安装openssl和openssl-devel包，才可以被编译


如果需要编译安装快速，可以运用多线程加快编译安装，命令如下:
```
make -j 12
make install
```
MySQL 8.0的软件目录结构
```
 cd /usr/local/mysql/
ls -l
```