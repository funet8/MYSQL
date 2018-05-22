# MySQL主从数据库同步延迟问题解决

## 1. MySQL数据库主从同步延迟原理。

答：谈到MySQL数据库主从同步延迟原理，得从mysql的数据库主从复制原理说起，mysql的主从复制都是单线程的操作，主库对所有DDL和DML产生binlog，binlog是顺序写，所以效率很高，slave的Slave_IO_Running线程到主库取日志，效率很比较高，下一步，问题来了，slave的Slave_SQL_Running线程将主库的DDL和DML操作在slave实施。DML和DDL的IO操作是随即的，不是顺序的，成本高很多，还可能可slave上的其他查询产生lock争用，由于Slave_SQL_Running也是单线程的，所以一个DDL卡主了，需要执行10分钟，那么所有之后的DDL会等待这个DDL执行完才会继续执行，这就导致了延时。有朋友会问：“主库上那个相同的DDL也需要执行10分，为什么slave会延时？”，答案是master可以并发，Slave_SQL_Running线程却不可以。

## 2. MySQL数据库主从同步延迟是怎么产生的。

答：当主库的TPS并发较高时，产生的DDL数量超过slave一个sql线程所能承受的范围，那么延时就产生了，当然还有就是可能与slave的大型query语句产生了锁等待。

## 3. MySQL数据库主从同步延迟解决方案

答：最简单的减少slave同步延时的方案就是在架构上做优化，尽量让主库的DDL快速执行。还有就是主库是写，对数据安全性较高，比如sync_binlog=1，innodb_flush_log_at_trx_commit = 1 之类的设置，而slave则不需要这么高的数据安全，完全可以讲sync_binlog设置为0或者关闭binlog，innodb_flushlog也可以设置为0来提高sql的执行效率。另外就是使用比主库更好的硬件设备作为slave。

mysql-5.6.3已经支持了多线程的主从复制。原理和丁奇的类似，丁奇的是以表做多线程，Oracle使用的是以数据库(schema)为单位做多线程，不同的库可以使用不同的复制线程。

sync_binlog=1

This makes MySQL synchronize the binary log’s contents to disk each time it commits a transaction

默认情况下，并不是每次写入时都将binlog与硬盘同步。因此如果操作系统或机器(不仅仅是MySQL服务器)崩溃，有可能binlog中最后的语句丢 失了。要想防止这种情况，你可以使用sync_binlog全局变量(1是最安全的值，但也是最慢的)，使binlog在每N次binlog写入后与硬盘 同步。即使sync_binlog设置为1,出现崩溃时，也有可能表内容和binlog内容之间存在不一致性。如果使用InnoDB表，MySQL服务器 处理COMMIT语句，它将整个事务写入binlog并将事务提交到InnoDB中。如果在两次操作之间出现崩溃，重启时，事务被InnoDB回滚，但仍 然存在binlog中。可以用--innodb-safe-binlog选项来增加InnoDB表内容和binlog之间的一致性。(注释：在MySQL 5.1中不需要--innodb-safe-binlog；由于引入了XA事务支持，该选项作废了），该选项可以提供更大程度的安全，使每个事务的 binlog(sync_binlog =1)和(默认情况为真)InnoDB日志与硬盘同步，该选项的效果是崩溃后重启时，在滚回事务后，MySQL服务器从binlog剪切回滚的 InnoDB事务。这样可以确保binlog反馈InnoDB表的确切数据等，并使从服务器保持与主服务器保持同步(不接收 回滚的语句)。

innodb_flush_log_at_trx_commit （这个很管用）

抱怨Innodb比MyISAM慢 100倍？那么你大概是忘了调整这个值。默认值1的意思是每一次事务提交或事务外的指令都需要把日志写入（flush）硬盘，这是很费时的。特别是使用电 池供电缓存（Battery backed up cache）时。设成2对于很多运用，特别是从MyISAM表转过来的是可以的，它的意思是不写入硬盘而是写入系统缓存。日志仍然会每秒flush到硬 盘，所以你一般不会丢失超过1-2秒的更新。设成0会更快一点，但安全方面比较差，即使MySQL挂了也可能会丢失事务的数据。而值2只会在整个操作系统 挂了时才可能丢数据。


[MySQL主从数据库同步延迟问题解决（转）](http://www.cnblogs.com/sandea/p/5605044.html)

 [一种MySQL主从同步加速方案](http://dinglin.iteye.com/blog/1179574)

