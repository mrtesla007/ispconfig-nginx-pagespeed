#!/bin/bash
red='\033[0;31m'
green='\033[0;32m'
NC='\033[0m'
HOSTNAME_FQDN=`hostname -f`;

# Variabeln Konfigurieren

	JKV="2.19"  # Jailkit Version für Installation ->  Aktuelle Version: http://olivier.sessink.nl/jailkit/jailkit

	MYSQL_ROOT_USR="root"
	MYSQL_ROOT_PWD="Dan!el1992"
	MYSQL_ROOT_DB="dbispconfig"
	MYSQL_HOST="localhost"

	SSL_COUNTRY_CODE="CH"
	SSL_COUNTRY="Switzerland"
	SSL_CITY="Solothurn"
	SSL_ORG="SpeedWP"
	SSL_ORG_UNIT="Hosting"

# Function: PreInstall Check

	if [ $(id -u) != "0" ]; then
	echo -n "Error: You must be root to run this script, please use the root user to install the software."
	exit 1  

	if [ -f /usr/local/ispconfig/interface/lib/config.inc.php ]; then
	echo "ISPConfig is already installed, can't go on."
	exit 1

# Update & Installation der Basis Tools

	echo -n "Updating apt and upgrading currently installed packages... "
	echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list
	apt-get -qq update > /dev/null 2>&1
	apt-get -qqy upgrade > /dev/null 2>&1
	echo -e "[${green}DONE${NC}]\n"

	echo "Installation der Basis Tools... "
	apt-get -y install ssh openssh-server php5-cli ufw ntp ntpdate debconf-utils sudo git lsb-release haveged e2fsprogs jessie-backports libssl1.0.0 > /dev/null 2>&1
	echo "dash dash/sh boolean false" | debconf-set-selections
	dpkg-reconfigure -f noninteractive dash > /dev/null 2>&1
	echo -n "Konfiguriere Dash... "
	echo -e "[${green}DONE${NC}]\n"

# Installation MariaDB
	
	echo -n "Installing MariaDB... "
	apt-get install software-properties-common
	apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db
	add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://mirror.klaus-uwe.me/mariadb/repo/10.2/debian jessie main'
	echo "deb-src http://mirror.klaus-uwe.me/mariadb/repo/10.2/debian jessie main" >> /etc/apt/sources.list
	apt-get -y update
    apt-get -y install mariadb-client mariadb-server > /dev/null 2>&1
	mysql_secure_installation
    sed -i 's/bind-address		= 127.0.0.1/#bind-address		= 127.0.0.1/' /etc/mysql/my.cnf
    service mysql restart > /dev/null 2>&1
    echo -e "[${green}DONE${NC}]\n"
	
# Installation NGINX Extras mit PageSpeed & HTTP/2
	
	service apache2 stop
	update-rc.d -f apache2 remove
	wget https://www.dotdeb.org/dotdeb.gpg
    apt-key add dotdeb.gpg
	echo "deb http://packages.dotdeb.org jessie-nginx-http2 all" >> /etc/apt/sources.list
    echo "deb-src http://packages.dotdeb.org jessie-nginx-http2 all" >> /etc/apt/sources.list
    apt-get -y update
	echo -n "Installation NGINX Extras mit PageSpeed & HTTP/2... "	
	apt-get -yqq install nginx-extras > /dev/null 2>&1
	service nginx start
    echo -e "[${green}DONE${NC}]\n"

# Function:	Installation PHP 5.6 - 7.2
	
	echo -n "Installation PHP 5.6... "
	apt-get -yqq install php5-fpm php5-mysqlnd php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-memcached php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl memcached php-apc > /dev/null 2>&1
	sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini
	sed -i "s/;date.timezone =/date.timezone=\"Europe\/Zurich\"/" /etc/php5/fpm/php.ini	
	apt-get -yqq install mcrypt imagemagick memcached curl tidy snmp > /dev/null 2>&1
	#apt-get install -y php5-mysql php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-memcached  php5-pspell php5-recode php5-sqlite php5-tidy php5-xmlrpc php5-xsl memcached
	service php5-fpm reload
	apt-get -yqq install fcgiwrap
	echo -e "[${green}DONE${NC}]\n"
	
	echo -n "Installation von PHP 5.6 - 7.2 "
	apt-get install apt-transport-https lsb-release ca-certificates
	wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
	echo "deb https://packages.sury.org/php/ jessie main" > /etc/apt/sources.list
	apt-get update
	apt-get install -y php5.6 php5.6-cli php5.6-cgi php5.6-fpm php7.0 php7.0-cli php7.0-cgi php7.0-fpm php7.1 php7.1-cli php7.1-cgi php7.1-fpm php7.2 php7.2-cli php7.2-cgi php7.2-fpm php-apcu php-apcu-bc php-memcache php-memcached php-xdebug
	service php5.6-fpm restart && service php7.0-fpm restart && service php7.1-fpm restart && service php7.2-fpm restart
	echo -e "[${green}DONE${NC}]\n"
	
# Function:	Installing phpMyAdmin
	
	echo -n "Installing phpMyAdmin... "
	apt-get -y install phpmyadmin
	echo -e "[${green}DONE${NC}]\n"
	
# Function:	Installing Lets Encrypt
	
  	echo -n "Installing Lets Encrypt... "	
	apt-get -yqq install certbot -t jessie-backports
	certbot &
	echo -e "[${green}DONE${NC}]\n"
	
# Function: Install HHVM	
	
    echo -e "Installing HHVM"
    apt-get install -y apt-transport-https software-properties-common
    apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xB4112585D386EB94
    add-apt-repository https://dl.hhvm.com/debian
    apt-get update
    apt-get install -y hhvm	
	
# Function: Install Quota

	echo -n "Installing and initializing Quota (this might take while)... "
	apt-get -qqy install quota quotatool > /dev/null 2>&1
	if ! [ -f /proc/user_beancounters ]; then
	  if [ `cat /etc/fstab | grep ',usrjquota=aquota.user,grpjquota=aquota.group,jqfmt=vfsv0' | wc -l` -eq 0 ]; then
		sed -i '/tmpfs/!s/errors=remount-ro/errors=remount-ro,usrjquota=aquota.user,grpjquota=aquota.group,jqfmt=vfsv0/' /etc/fstab
	if [ `cat /etc/fstab | grep 'defaults' | wc -l` -ne 0 ]; then
		sed -i '/tmpfs/!s/defaults/defaults,usrjquota=aquota.user,grpjquota=aquota.group,jqfmt=vfsv0/' /etc/fstab
	mount -o remount /
	quotacheck -avugm > /dev/null 2>&1
	quotaon -avug > /dev/null 2>&1
	echo -e "[${green}DONE${NC}]\n"	
  
# Function: Install WebStats 

	echo -n "Installing stats... ";
	apt-get -y install vlogger webalizer awstats geoip-database libclass-dbi-mysql-perl > /dev/null 2>&1
	sed -i 's/^/#/' /etc/cron.d/awstats
	echo -e "[${green}DONE${NC}]\n"
	
# Function: Install Jailkit

	echo -n "Installing Jailkit... "
	apt-get -y install build-essential autoconf automake libtool flex bison debhelper binutils > /dev/null 2>&1
	cd /tmp
	wget -q http://olivier.sessink.nl/jailkit/jailkit-$JKV.tar.gz
	tar xfz jailkit-$JKV.tar.gz
	cd jailkit-$JKV
	./debian/rules binary > /dev/null 2>&1
	cd ..
	dpkg -i jailkit_$JKV-1_*.deb > /dev/null 2>&1
	rm -rf jailkit-$JKV
	echo -e "[${green}DONE${NC}]\n"	

# Function: Install Fail2ban

	echo -n "Installing fail2ban... "
	apt-get -y install fail2ban > /dev/null 2>&1

	service fail2ban restart > /dev/null 2>&1
	echo -e "[${green}DONE${NC}]\n"

# Function: Install ISPConfig

	echo "Installing ISPConfig3... "
	cd /tmp
	wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
	tar xfz ISPConfig-3-stable.tar.gz
	cd ispconfig3_install/install/
	echo "Create INI file"
	touch autoinstall.ini
	echo "[install]" > autoinstall.ini
	echo "language=de" >> autoinstall.ini
	echo "install_mode=expert" >> autoinstall.ini
	echo "hostname=$HOSTNAME_FQDN" >> autoinstall.ini
	echo "mysql_hostname=localhost" >> autoinstall.ini
	echo "mysql_root_user=root" >> autoinstall.ini
	echo "mysql_root_password=$MYSQL_ROOT_PWD" >> autoinstall.ini
	echo "mysql_database=dbispconfig" >> autoinstall.ini
	echo "mysql_port=3306" >> autoinstall.ini
	echo "mysql_charset=utf8" >> autoinstall.ini
	echo "http_server=nginx" >> autoinstall.ini
	echo "ispconfig_port=8080" >> autoinstall.ini
	echo "ispconfig_use_ssl=yes" >> autoinstall.ini
	echo
	echo "[ssl_cert]" >> autoinstall.ini
	echo "ssl_cert_country=CH" >> autoinstall.ini
	echo "ssl_cert_state=Switzerland" >> autoinstall.ini
	echo "ssl_cert_locality=Solothurn" >> autoinstall.ini
	echo "ssl_cert_organisation=SpeedWP" >> autoinstall.ini
	echo "ssl_cert_organisation_unit=Hosting" >> autoinstall.ini
	echo "ssl_cert_common_name=$HOSTNAME_FQDN" >> autoinstall.ini
	echo
	echo "[expert]" >> autoinstall.ini
	echo "mysql_ispconfig_user=ispconfig" >> autoinstall.ini
	echo "mysql_ispconfig_password=afStEratXBsgatRtsa42CadwhQ" >> autoinstall.ini
	echo "join_multiserver_setup=no" >> autoinstall.ini
	echo "mysql_master_hostname=localhost" >> autoinstall.ini
	echo "mysql_master_root_user=root" >> autoinstall.ini
	echo "mysql_master_root_password=$MYSQL_ROOT_PWD" >> autoinstall.ini
	echo "mysql_master_database=dbispconfig-master" >> autoinstall.ini
	echo "configure_mail=no" >> autoinstall.ini
	echo "configure_jailkit=yes" >> autoinstall.ini
	echo "configure_nginx=yes" >> autoinstall.ini
	echo "configure_firewall=yes" >> autoinstall.ini
	echo "install_ispconfig_web_interface=yes" >> autoinstall.ini
	echo
	echo "[update]" >> autoinstall.ini
	echo "do_backup=yes" >> autoinstall.ini
	echo "mysql_root_password=$MYSQL_ROOT_PWD" >> autoinstall.ini
	echo "mysql_master_hostname=localhost" >> autoinstall.ini
	echo "mysql_master_root_user=root" >> autoinstall.ini
	echo "mysql_master_root_password=$MYSQL_ROOT_PWD" >> autoinstall.ini
	echo "mysql_master_database=dbispconfig-master" >> autoinstall.ini
	echo "reconfigure_permissions_in_master_database=yes" >> autoinstall.ini
	echo "reconfigure_services=yes" >> autoinstall.ini
	echo "ispconfig_port=8080" >> autoinstall.ini
	echo "create_new_ispconfig_ssl_cert=no" >> autoinstall.ini
	echo "reconfigure_crontab=yes" >> autoinstall.ini
	echo | php -q install.php --autoinstall=autoinstall.ini
	php -q install.php
	/etc/init.d/nginx restart

	echo -e "[${green}DONE${NC}]\n"


	echo -e "${green}Well done ISPConfig installed and configured correctly :D ${NC}"
	echo "Now you can connect to your ISPConfig installation at https://$HOSTNAME_FQDN:8080 or https://IP_ADDRESS:8080"
	echo "phpMyAdmin is accessibile at  http://$HOSTNAME_FQDN:8081/phpmyadmin or http://IP_ADDRESS:8081/phpmyadmin";

	nano /etc/php5/fpm/php.ini
	cgi.fix_pathinfo=0
	date.timezone="Europe/Zurich