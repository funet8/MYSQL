# mysqldumpslow 慢查询日志分析

```
查找执行时间最慢的10条：
# mysqldumpslow -s t -t 10 {慢查询日志路径}

按锁表时间最长的前10条：
# mysqldumpslow -s l -t 10 {慢查询日志路径}
平均锁定时间:
# mysqldumpslow -s al -t 10 {慢查询日志路径}

慢查询次数最多的前10条:
# mysqldumpslow -s c -t 10 {慢查询日志路径}
```


```
mysqldumpslow --help
Usage: mysqldumpslow [ OPTS... ] [ LOGS... ]

Parse and summarize the MySQL slow query log. Options are

  --verbose    verbose
  --debug      debug
  --help       write this text to standard output

  -v           verbose
  -d           debug
  -s ORDER     what to sort by (al, at, ar, ae, c, l, r, e, t), 'at' is default
                al: average lock time
                ar: average rows sent
                at: average query time
                 c: count
                 l: lock time
                 r: rows sent
                 t: query time  
				　　什么排序(al,ar,ae,c、l r e t),“在”是默认
				
					al   平均锁定时间
					ar   平均返回记录时间
					at   平均查询时间（默认）
					c    计数
					l    锁定时间
					r    返回记录
					t    查询时间


				
  -r           reverse the sort order (largest last instead of first)
				最大反向排序顺序(最后而不是第一次)

  -t NUM       just show the top n queries
				只显示前n查询

  -a           don't abstract all numbers to N and strings to 'S'
				不抽象的所有数字N和字符串“年代”

  -n NUM       abstract numbers with at least n digits within names
				抽象的数字至少n位内的名字

				
  -g PATTERN   grep: only consider stmts that include this string
				grep:只考虑支撑,包括这个字符串

				
  -h HOSTNAME  hostname of db server for *-slow.log filename (can be wildcard),
               default is '*', i.e. match all		
			   数据库服务器的主机名*运行效率低下。日志文件名(可以通配符),
　　			默认是‘*’,即匹配所有

  -i NAME      name of server instance (if using mysql.server startup script)	的名字(如果使用mysql服务器实例。服务器启动脚本)
  
  -l           don't subtract lock time from total time  不要总时间减去锁定时间
```

  
 
 
 
 



  