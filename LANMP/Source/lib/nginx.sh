# nginx install function
function nginx_ins {
    local IN_LOG=$LOGPATH/${logpre}_nginx_install.log
    [ -f $nginx_inf ] && return
    pcre_ins
    echo
    echo "installing nginx..."
    cd $IN_SRC
    rm -fr nginx-$NGI_VER
    tar xvf nginx-$NGI_VER.tar.gz >$IN_LOG 2>&1
    cd nginx-$NGI_VER
    make_clean
    ./configure --user=www --group=www \
        --prefix=$IN_DIR/nginx-$NGI_VER \
        --with-http_stub_status_module \
        --with-http_ssl_module >>$IN_LOG 2>&1
    [ $? != 0 ] && err_exit "nginx configure err"
    make >>$IN_LOG 2>&1
    [ $? != 0 ] && err_exit "nginx make err"
    make install >>$IN_LOG 2>&1
    [ $? != 0 ] && err_exit "nginx make install err"
    ln -sf $IN_DIR/nginx-$NGI_VER $IN_DIR/nginx
    mkdir -p $IN_DIR/nginx/conf/{vhost,rewrite}
    mkdir -p /www/{web/default,web_logs}
    file_cp phpinfo.php /www/web/default/phpinfo.php
    file_cp iProber2.php /www/web/default/iProber2.php
    file_cp wdlinux_n.php /www/web/default/index.php
    chown -R www.www /www/web
    file_cp fcgi.conf $IN_DIR/nginx/conf/fcgi.conf
    file_cp nginx.conf $IN_DIR/nginx/conf/nginx.conf
    #file_cp wdcp_n.conf $IN_DIR/nginx/conf/wdcp.conf
    file_cp defaultn.conf $IN_DIR/wdcp_bk/conf/defaultn.conf
    file_cpv defaultn.conf $IN_DIR/nginx/conf/vhost/00000.default.conf
    file_cp dz7_nginx.conf $IN_DIR/nginx/conf/rewrite/dz7_nginx.conf
    file_cp dzx15_nginx.conf $IN_DIR/nginx/conf/rewrite/dzx15_nginx.conf
    mkdir -p $IN_DIR/nginx/conf/vhost
    if [ $OS_RL == 2 ]; then
        file_cp init.nginxd-ubuntu $IN_DIR/init.d/nginxd
    else
        file_cp init.nginxd $IN_DIR/init.d/nginxd
    fi
    chmod 755 $IN_DIR/init.d/nginxd
    #ln -sf $IN_DIR/php/sbin/php-fpm $IN_DIR/init.d/php-fpm
    #chmod 755 $IN_DIR/init.d/php-fpm
    #ln -sf $IN_DIR/php/sbin/php-fpm /etc/rc.d/init.d/php-fpm
    file_rm /etc/init.d/nginxd
    ln -sf $IN_DIR/init.d/nginxd /etc/init.d/nginxd
    if [ $OS_RL == 2 ]; then
        update-rc.d -f nginxd defaults >>$IN_LOG 2>&1
    else
        chkconfig --add nginxd >>$IN_LOG 2>&1
        chkconfig --level 35 nginxd on >>$IN_LOG 2>&1
    fi
    if [ $IN_DIR_ME == 1 ]; then
        sed -i "s#/www/wdlinux#$IN_DIR#g" /etc/init.d/nginxd
        sed -i "s#/www/wdlinux#$IN_DIR#g" /etc/init.d/php-fpm
        sed -i "s#/www/wdlinux#$IN_DIR#g" $IN_DIR/nginx/conf/nginx.conf
    fi
    touch $nginx_inf
}

