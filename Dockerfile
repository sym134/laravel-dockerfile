# Adapted from https://github.com/joseluisq/alpine-php-fpm/blob/master/8.2-fpm/Dockerfile

FROM php:8.2-alpine


# Accepted values: production | development
ARG APP_ENV=production

# 显示系统版本
RUN cat /etc/issue

# [php8] Add basics first
RUN apt-get update && apt-get upgrade && apt-get install bash curl ca-certificates openssl openssh git nano libxml2-dev tzdata icu-dev openntpd libedit-dev libzip-dev libjpeg62-turbo-dev libpng12-dev libfreetype6-dev autoconf dpkg-dev dpkg file g++ gcc libc-dev make pkgconf re2c pcre-dev openssl-dev libffi-dev libressl-dev libevent-dev zlib-dev libtool automake supervisor

# 安装自定义 PHP 扩展
COPY ./extension /tmp/extension
WORKDIR /tmp/extension
RUN chmod +x install.sh \
    && sh install.sh \
    && rm -rf /tmp/extension

# 安装swoole
RUN pecl install swoole && docker-php-ext-enable swoole

# 单独安装 FFmpeg（仅主程序）
RUN apk add --no-cache ffmpeg

# 列出当前 PHP 已加载的模块，确保扩展安装成功。
RUN php -m

# Add Composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# Configure PHP
#COPY config/php.ini /usr/local/etc/php/conf.d/zzz_custom.ini

# Configure supervisord
#COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 将 /run 目录的所有权更改为 nobody 用户，确保非 root 用户可以访问。
RUN chown -R nobody.nobody /run

# 创建应用目录
RUN mkdir -p /app

# Make the document root a volume
VOLUME /app

#echo " > /usr/local/etc/php/conf.d/phalcon.ini
# Switch to use a non-root user from here on
USER root

# Add application
WORKDIR /app

VOLUME /supervisord

# 复制主机上的 supervisord 配置文件及其子目录
COPY /supervisord/supervisord.conf /etc/supervisor/supervisord.conf

# 暴露端口 workman端口
EXPOSE 9000 8000 6001

# 容器启动时运行 Supervisord，并加载指定的配置文件
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

ENTRYPOINT ["docker-php-entrypoint"]

STOPSIGNAL SIGQUIT