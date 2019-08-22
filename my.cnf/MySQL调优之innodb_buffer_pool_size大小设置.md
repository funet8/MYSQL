# MySQL调优之innodb_buffer_pool_size大小设置


相关查看命令:
```
sql> show global variables like 'innodb_buffer_pool_size';

sql> show global status like 'Innodb_buffer_pool_pages_data';

sql> show global status like 'Innodb_page_size';

或

sql> use mysql;
sql> select @@innodb_buffer_pool_size;
```

```
MariaDB [(none)]> show global variables like 'innodb_buffer_pool_size';

+-------------------------+-----------+
| Variable_name           | Value     |
+-------------------------+-----------+
| innodb_buffer_pool_size | 268435456 |
+-------------------------+-----------+
1 row in set (0.00 sec)


MariaDB [(none)]> show global status like 'Innodb_buffer_pool_pages_data';
+-------------------------------+-------+
| Variable_name                 | Value |
+-------------------------------+-------+
| Innodb_buffer_pool_pages_data | 6082  |
+-------------------------------+-------+
1 row in set (0.00 sec)


MariaDB [(none)]> show global status like 'Innodb_buffer_pool_pages_total';
+--------------------------------+-------+
| Variable_name                  | Value |
+--------------------------------+-------+
| Innodb_buffer_pool_pages_total | 16383 |
+--------------------------------+-------+
1 row in set (0.00 sec)


MariaDB [(none)]> show global status like 'Innodb_page_size';
+------------------+-------+
| Variable_name    | Value |
+------------------+-------+
| Innodb_page_size | 16384 |
+------------------+-------+
1 row in set (0.00 sec)
```


## Innodb_buffer_pool_pages_data-官方解释
```
Innodb_buffer_pool_pages_data
The number of pages in the InnoDB buffer pool containing data. The number includes both dirty and clean pages.

InnoDB的页面数量的缓冲池包含的数据。包括脏的和干净的页面数量。
```


## Innodb_buffer_pool_pages_total-官方解释
```
The total size of the InnoDB buffer pool, in pages.
InnoDB缓冲池的总大小,页面。
```

## Innodb_page_size-官方解释
```
InnoDB page size (default 16KB). Many values are counted in pages; the page size enables them to be easily converted to bytes

InnoDB页面大小(默认16 kb)。许多值计算页;页面大小支持他们 很容易转换为字节

```



## 调优参考计算方法：
```
val = Innodb_buffer_pool_pages_data / Innodb_buffer_pool_pages_total * 100%
val > 95% 则考虑增大 innodb_buffer_pool_size， 建议使用物理内存的75%
val < 95% 则考虑减小 innodb_buffer_pool_size， 建议设置为：Innodb_buffer_pool_pages_data * Innodb_page_size * 1.05 / (1024*1024*1024)
```




设置命令：
```
set global innodb_buffer_pool_size = 2097152; //缓冲池字节大小，单位kb，如果不设置，默认为128M
```


**设置要根据自己的实际情况来设置，如果设置的值不在合理的范围内，并不是设置越大越好，可能设置的数值太大体现不出优化效果，反而造成系统的swap空间被占用，导致操作系统变慢，降低sql查询性能。**



修改配置文件的调整方法，修改my.cnf配置：
```
innodb_buffer_pool_size = 2147483648  #设置2G

innodb_buffer_pool_size = 2G  #设置2G

innodb_buffer_pool_size = 500M  #设置500M
```



MySQL5.7及以后版本，改参数时动态的，修改后，无需重启MySQL，但是低版本，静态的，修改后，需要重启MySQL。


原文：https://blog.csdn.net/sunny05296/article/details/78916775 
