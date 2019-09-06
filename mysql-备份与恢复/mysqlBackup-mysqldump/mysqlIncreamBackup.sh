#!/bin/bash
#在使用之前，请提前创建以下各个目录
backupDir=/usr/local/work/backup/daily
#增量备份时复制mysql-bin.00000*的目标目录，提前手动创建这个目录
mysqlDir=/var/lib/mysql
#mysql的数据目录
logFile=/usr/local/work/backup/bak.log
BinFile=/var/lib/mysql/mysql-bin.index
#mysql的index文件路径，放在数据目录下的

mysqladmin -uroot -p123456 flush-logs
#这个是用于产生新的mysql-bin.00000*文件
# wc -l 统计行数
# awk 简单来说awk就是把文件逐行的读入，以空格为默认分隔符将每行切片，切开的部分再进行各种分析处理。
Counter=`wc -l $BinFile |awk '{print $1}'`
NextNum=0
#这个for循环用于比对$Counter,$NextNum这两个值来确定文件是不是存在或最新的
for file in `cat $BinFile`
do
    base=`basename $file`
    echo $base
    #basename用于截取mysql-bin.00000*文件名，去掉./mysql-bin.000005前面的./
    NextNum=`expr $NextNum + 1`
    if [ $NextNum -eq $Counter ]
    then
        echo $base skip! >> $logFile
    else
        dest=$backupDir/$base
        if(test -e $dest)
        #test -e用于检测目标文件是否存在，存在就写exist!到$logFile去
        then
            echo $base exist! >> $logFile
        else
            cp $mysqlDir/$base $backupDir
            echo $base copying >> $logFile
         fi
     fi
done
echo `date +"%Y年%m月%d日 %H:%M:%S"` $Next Bakup succ! >> $logFile

# 使用 nodejs 上传备份文件到 私有云
#NODE_ENV=$backUpFolder@$backUpFileName /root/node/v8.11.3/bin/node /usr/local/upload.js

# 使用 python 上传备份文件到 私有云
#python /use/local/upload.py $backUpFolder $backUpFileName
