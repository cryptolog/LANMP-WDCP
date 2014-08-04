#!/bin/bash
# wdcp tools
# web logs on/off
# author wdlinux
# url http://www.wdlinux.cn
[ ! $1 ] && exit
if [ $1 == "on" ];then
	if [ -f /www/wdlinux/nginx/conf/nginx.conf ];then
		sed -i '/access_log off/d' /www/wdlinux/nginx/conf/nginx.conf
		service nginxd restart
	fi
	if [ -f /www/wdlinux/apache/conf/httpd.conf ];then
		sed -i 's#CustomLog /dev/null common#CustomLog "logs/access_log" common#' /www/wdlinux/apache/conf/httpd.conf
		service httpd restart
	fi
	echo
	echo "web logs is on success"
elif [ $1 == "off" ];then
	if [ -f /www/wdlinux/nginx/conf/nginx.conf ];then
		sed -i '/log_format/a\
    access_log off;' /www/wdlinux/nginx/conf/nginx.conf
		service nginxd restart
	fi
	if [ -f /www/wdlinux/apache/conf/httpd.conf ];then
		sed -i 's#CustomLog "logs/access_log" common#CustomLog /dev/null common#' /www/wdlinux/apache/conf/httpd.conf
		service httpd restart
	fi
	echo
	echo "web logs is off success"

else
	echo "err"
fi
echo
