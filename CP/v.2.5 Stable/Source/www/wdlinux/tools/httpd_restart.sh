#!/bin/bash
# wdcp tools
# ntp time
# author wdlinux
# url http://www.wdlinux.cn
killall -9 httpd
service httpd start
service wdapache start
exit 0
