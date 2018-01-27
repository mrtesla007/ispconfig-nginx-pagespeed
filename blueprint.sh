#!/bin/bash
echo -n "Paketliste wird ergänzt"
export DEBIAN_FRONTEND="noninteractive"
wget https://www.dotdeb.org/dotdeb.gpg
apt-key add dotdeb.gpg
echo "deb http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list
echo "deb-src http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list
echo -n "Vollständiges Updaten... "
apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y
echo -n "Must have Software... "
apt-get -y install ssh openssh-server sudo php5-cli python-software-properties ufw ntp ntpdate debconf-utils git lsb-release haveged e2fsprogs jessie-backports libssl1.0.0
echo -n "Konfiguriere Dash... "
dpkg-reconfigure -f noninteractive dash

# echo -n "Erstelle Unix Benutzer mit Sudo Rechten... "
# adduser isp && usermod -a -G sudo isp


