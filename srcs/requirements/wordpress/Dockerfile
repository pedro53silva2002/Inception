FROM	debian:bookworm

EXPOSE	9000


ARG PHPPATH=/etc/php/8.2/fpm

RUN apt update && apt install --no-install-recommends --no-install-suggests -y \
    ca-certificates \
    php8.2-fpm \
    php8.2-mysql \
    wget \
    tar && \
    rm -rf /var/lib/apt/lists/*

RUN service php8.2-fpm stop

COPY conf/www.conf ${PHPPATH}/pool.d/
RUN  sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' ${PHPPATH}/php.ini && \
     sed -i 's/;daemonize = yes/daemonize = no/g' ${PHPPATH}/pool.d/www.conf
     
RUN wget --no-check-certificate https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp
    
RUN mkdir -p /run/php/ && \
    mkdir -p /var/run/php/ && \
    mkdir -p /var/www/inception/
    
RUN chown -R www-data:www-data /var/www/inception/

COPY	conf/wp-config.php /tmp/
COPY	tools/setup.sh /bin/
RUN	chmod +x /bin/setup.sh

CMD ["setup.sh", "php-fpm8.2", "-F"]
