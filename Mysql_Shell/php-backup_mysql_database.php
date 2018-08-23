#!/usr/bin/env php
<?php 

ini_set('memory_limit','1024M'); //解决PHP内存限制

// 备份数据库

$dbport = "3306";

$host = "192.168.1.251:$dbport";

$user = "root"; //数据库账号

$password = "123456"; //数据库密码

$dbname = "phpcms_9.6"; //数据库名称

$backup_pwd = "/backup/"; //备份路径

// 这里的账号、密码、名称都是从页面传过来的
if (!mysql_connect("$host", "$user", "$password")) // 连接mysql数据库
    {
        echo '数据库连接失败，请核对后再试';
    exit;
} 
if (!mysql_select_db($dbname)) // 是否存在该数据库
    {
        echo '不存在数据库:' . $dbname . ',请核对后再试';
    exit;
} 
mysql_query("set names 'utf8'");
$mysql = "set charset utf8;\r\n";
$q1 = mysql_query("show tables");
while ($t = mysql_fetch_array($q1))
{
    $table = $t[0];
    $q2 = mysql_query("show create table `$table`");
    $sql = mysql_fetch_array($q2);
    $mysql .= $sql['Create Table'] . ";\r\n";
    $q3 = mysql_query("select * from `$table`");
    while ($data = mysql_fetch_assoc($q3))
    {
        $keys = array_keys($data);
        $keys = array_map('addslashes', $keys);
        $keys = join('`,`', $keys);
        $keys = "`" . $keys . "`";
        $vals = array_values($data);
        $vals = array_map('addslashes', $vals);
        $vals = join("','", $vals);
        $vals = "'" . $vals . "'";
        $mysql .= "insert into `$table`($keys) values($vals);\r\n";
    } 
}
 
$filename = "$backup_pwd" . $dbname . date('Ymjgi') . ".sql"; //存放路径

$fp = fopen($filename, 'w');
fputs($fp, $mysql);
fclose($fp);
echo "数据备份成功";

?>

