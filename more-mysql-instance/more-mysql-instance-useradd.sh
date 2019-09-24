MYSQL_PORY='61920 61921 61922 61923 61924'
mysql_user_cmd1="CREATE USER 'yxkj_star'@'%' IDENTIFIED BY 'liuJH5TTqzE9FSjdf';"
mysql_user_cmd2="GRANT  all privileges ON * . * TO 'yxkj_star'@'%' IDENTIFIED BY 'liuJH5TTqzE9FSjdf';"
mysql_user_cmd3="GRANT ALL PRIVILEGES ON * . * TO 'yxkj_star'@'%' WITH GRANT OPTION MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0 ;flush privileges;"

for  port in  $MYSQL_PORY
do
	mysql -u root -S /data/mysql/${port}/mysql${port}.sock -e "${mysql_user_cmd1}"
	mysql -u root -S /data/mysql/${port}/mysql${port}.sock -e "${mysql_user_cmd2}"
	mysql -u root -S /data/mysql/${port}/mysql${port}.sock -e "${mysql_user_cmd3}"
	
	#mysql -u root -S /data/mysql/61921/mysql61921.sock -e "${mysql_user_cmd1}"
	#mysql -u root -S /data/mysql/61921/mysql61921.sock -e "${mysql_user_cmd2}"
	#mysql -u root -S /data/mysql/61921/mysql61921.sock -e "${mysql_user_cmd3}"	
done
