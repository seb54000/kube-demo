FROM php:5-apache-jessie

ADD index.php /var/www/html/
RUN mkdir -p /var/www/html/data/ && chmod 777 /var/www/html/data/
RUN mkdir -p /var/www/html/data/prom && chmod 777 /var/www/html/data/prom
RUN mkdir -p /var/www/html/filebeat && chmod 777 /var/www/html/filebeat
COPY default-apache.conf /etc/apache2/sites-available/000-default.conf
