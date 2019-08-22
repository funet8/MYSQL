#  MySQL慢查询分析工具pt-query-digest详解



## 安装pt-query-digest

1.下载页面：[https://www.percona.com/doc/percona-toolkit/2.2/installation.html](https://www.percona.com/doc/percona-toolkit/2.2/installation.html)

2.perl的模块
```
yum install -y perl-CPAN perl-Time-HiRes perl-Digest-MD5 perl-DBD-MySQL
```

方法一：rpm安装
```
cd /usr/local/src
wget percona.com/get/percona-toolkit.rpm
yum install -y percona-toolkit.rpm

报错：
Loaded plugins: fastestmirror
Cannot open: percona-toolkit.rpm. Skipping.
Error: Nothing to do
```

方法二：源码安装
```
cd /usr/local/src
wget percona.com/get/percona-toolkit.tar.gz
tar zxf percona-toolkit.tar.gz
cd percona-toolkit-2.2.19 
perl Makefile.PL PREFIX=/usr/local/percona-toolkit
make && make install

-------------
报错：
Checking if your kit is complete...
Looks good
Warning: prerequisite DBD::mysql 3 not found.
Writing Makefile for percona-toolkit
------------
解决：
yum install perl-DBD-MySQL
再重新安装

```
工具安装目录在：/usr/local/percona-toolkit/bin

(1)慢查询日志分析统计
```
/usr/local/percona-toolkit/bin/pt-query-digest /data/tmp/slowQuery/slowQuery20190704-haiwai.log
```

(2)服务器摘要
```
/usr/local/percona-toolkit/bin/pt-summary
```
(3)服务器磁盘监测

```
/usr/local/percona-toolkit/bin/pt-diskstats
```

3.分析指定时间范围内的查询：
```
/usr/local/percona-toolkit/bin/pt-query-digest slow.log --since '2017-01-07 09:30:00' --until '2017-01-07 10:00:00'> > slow_report3.log
```








