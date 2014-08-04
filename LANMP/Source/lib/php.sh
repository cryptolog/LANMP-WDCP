# php install function
function php_ins {
    local IN_LOG=$LOGPATH/${logpre}_php_install.log
    echo
    [ -f $php_inf ] && return
    libiconv_ins
    echo
    echo "installing php..."
    cd $IN_SRC
    rm -fr php-$PHP_VER/
    tar xf php-$PHP_VER.tar.gz >$IN_LOG 2>&1
    if [ $OS_RL == 2 ]; then
        if [ $X86 == 1 ]; then
            ln -sf /usr/lib/x86_64-linux-gnu/libssl.* /usr/lib/
        else
            ln -sf /usr/lib/i386-linux-gnu/libssl.* /usr/lib/
        fi
        if [ $PHP_VER = "5.2.17" ]; then
            patch -d php-$PHP_VER -p1 < debian_patches_disable_SSLv2_for_openssl_1_0_0.patch >>$IN_LOG 2>&1
        fi
    fi
    NV=""
    if [ $SERVER == "nginx" ]; then
        if [ $PHP_VER == "5.2.17" ]; then
            NV="--enable-fastcgi --enable-fpm --with-fpm-conf=$IN_DIR/etc/php-fpm.conf"
            gzip -cd php-$PHP_VER-fpm-0.5.14.diff.gz | patch -fd php-$PHP_VER -p1 >>$IN_LOG 2>&1
        else
            NV="--enable-fpm --with-fpm-user=www --with-fpm-group=www"
        fi
    fi
    [ $SERVER == "apache" -o $SERVER == "na" ] && NV="--with-apxs2=$IN_DIR/apache/bin/apxs"
    cd php-$PHP_VER/
    make clean >/dev/null 2>&1
    if [ $SERVER == "apache" -o $SERVER == "na" ]; then
        PHP_DIR="apache_php-$PHP_VER"
        PHP_DIRS="apache_php"
    elif [ $SERVER == "nginx" ];then
        PHP_DIR="nginx_php-$PHP_VER"
        PHP_DIRS="nginx_php"
    else
        PHP_DIR="def_php-$PHP_VER"
        PHP_DIRS="def_php"
    fi
    ./configure --prefix=$IN_DIR/$PHP_DIR \
        --with-config-file-path=$IN_DIR/$PHP_DIR/etc \
        --with-mysql=$IN_DIR/mysql --with-iconv=/usr \
        --with-mysqli=$IN_DIR/mysql/bin/mysql_config \
        --with-pdo-mysql=$IN_DIR/mysql \
        --with-freetype-dir --with-jpeg-dir \
        --with-png-dir --with-zlib \
        --with-libxml-dir=/usr --enable-xml \
        --disable-rpath --enable-discard-path \
        --enable-inline-optimization --with-curl \
        --enable-mbregex --enable-mbstring \
        --with-mcrypt=/usr --with-gd \
        --enable-gd-native-ttf --with-openssl \
        --with-mhash --enable-ftp \
        --enable-bcmath --enable-exif \
        --enable-sockets --enable-zip $NV >>$IN_LOG 2>&1
    [ $? != 0 ] && err_exit "php configure err"
    make >>$IN_LOG 2>&1
    [ $? != 0 ] && err_exit "php make err"
    make install >>$IN_LOG 2>&1
    [ $? != 0 ] && err_exit "php make install err"
    ln -sf $IN_DIR/$PHP_DIR $IN_DIR/$PHP_DIRS
    rm -rf $IN_DIR/php
    ln -sf $IN_DIR/$PHP_DIRS $IN_DIR/php
    if [ $PHP_VER == "5.2.17" ]; then
        cp php.ini-dist $IN_DIR/$PHP_DIR/etc/php.ini
    else
        cp php.ini-production $IN_DIR/$PHP_DIR/etc/php.ini
    fi
    chown wdcpu.wdcpg $IN_DIR/$PHP_DIR/etc/php.ini
    ln -sf $IN_DIR/$PHP_DIRS/etc/php.ini $IN_DIR/etc/php.ini
    mkdir -p $IN_DIR/$PHP_DIR/lib/php/extensions/no-debug-zts-20060613
    ln -s $IN_DIR/$PHP_DIR/lib/php/extensions/no-debug-zts-20060613 \
        $IN_DIR/$PHP_DIR/lib/php/extensions/no-debug-non-zts-20060613
    
    if [ $SERVER == "nginx" ]; then
        if [ $PHP_VER == "5.2.17" ]; then
            ln -sf $IN_DIR/$PHP_DIR/sbin/php-fpm $IN_DIR/init.d/php-fpm
            sed -i '/nobody/s#<!--##g' $IN_DIR/etc/php-fpm.conf
            sed -i '/nobody/s#-->##g' $IN_DIR/etc/php-fpm.conf
            sed -i 's/>nobody</>www</' $IN_DIR/etc/php-fpm.conf
        else
            /bin/cp -f sapi/fpm/init.d.php-fpm $IN_DIR/init.d/php-fpm
            /bin/cp -f sapi/fpm/php-fpm.conf $IN_DIR/$PHP_DIR/etc/php-fpm.conf
            ln -s $IN_DIR/$PHP_DIR/etc/php-fpm.conf $IN_DIR/etc/php-fpm.conf
        fi
        
        chmod 755 $IN_DIR/init.d/php-fpm
        ln -sf $IN_DIR/init.d/php-fpm /etc/init.d/php-fpm
        if [ $PHP_VER == "5.2.17" ]; then
            sed -i '1 a \\n### BEGIN INIT INFO \
# Provides:          php-fpm \
# Required-Start:    $remote_fs $network \
# Required-Stop:     $remote_fs $network \
# Default-Start:     2 3 4 5 \
# Default-Stop:      0 1 6 \
# Short-Description: starts php-fpm \
# Description:       starts the PHP FastCGI Process Manager daemon \
### END INIT INFO

' $IN_DIR/init.d/php-fpm
        fi
        if [ $OS_RL == 2 ]; then
            file_cp nginxd.fpm-ubuntu /www/wdlinux/init.d/nginxd
        else
            file_cp nginxd.fpm /www/wdlinux/init.d/nginxd
        fi
        chmod 755 /www/wdlinux/init.d/nginxd
    fi

    if [ $SERVER_ID == 4 ]; then
        sed -i 's/service/#service/g' /www/wdlinux/init.d/nginxd
    fi
    touch $php_inf
}

