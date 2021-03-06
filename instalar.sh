#!/bin/sh
sudo groupadd www-group
sudo useradd -m -s /bin/bash -g www-data www-prova
echo "Instalação e configurações"
sudo apt update && sudo apt install -y openssh-server apache2 php libapache2-mod-php && sudo apt clean
sudo echo "PermitRootLogin no" | sudo tee -a /etc/ssh/sshd_config
sudo systemctl restart sshd
sudo a2dismod mpm_event && a2enmod mpm_prefork &&  a2enmod php7.2
sudo ufw allow "Apache Full"
sudo systemctl restart apache2
echo "Clonando repositório da aplicação"
sudo -H -u www-prova bash -c 'git clone https://github.com/herculan0/prova-devops /home/www-prova/prova-devops'
echo "Configurando Servidor Web"
echo 'DefaultRuntimeDir ${APACHE_RUN_DIR}
PidFile ${APACHE_PID_FILE}
Timeout 300
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 5
User ${APACHE_RUN_USER}
Group ${APACHE_RUN_GROUP}
HostnameLookups Off
ErrorLog ${APACHE_LOG_DIR}/error.log
LogLevel warn
IncludeOptional mods-enabled/*.load
IncludeOptional mods-enabled/*.conf
Include ports.conf
LogFormat "%v:%p %h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" vhost_combined
LogFormat "%h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%h %l %u %t \"%r\" %>s %O" common
LogFormat "%{Referer}i -> %U" referer
LogFormat "%{User-agent}i" agent
Alias /perguntas "/home/www-prova/prova-devops"
<Directory /home/www-prova/prova-devops>
        Options Indexes FollowSymLinks ExecCGI
        AllowOverride None
        Require all granted
</Directory>
<FilesMatch \.php$>
SetHandler application/x-httpd-php
</FilesMatch>' | sudo tee /etc/apache2/apache2.conf
echo '<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot /home/www-prova/prova-devops
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>' | sudo tee /etc/apache2/sites-available/000-default.conf
sudo mv /etc/apache2/sites-enabled/000-default.conf /etc/apache2/sites-enabled/bkp-default.conf
sudo ln -s /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-enabled/000-default.conf
sudo systemctl restart apache2
echo "Instalado com sucesso, basta acessar http://$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1 -d'/')/perguntas"
