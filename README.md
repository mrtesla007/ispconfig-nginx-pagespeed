# ISP-Config-NGiNX-PageSpeed-HHVM-php-fpm-MariaDB

## Bash

* https://launchpad.net/mysqltuner
* https://www.howtoforge.de/anleitung/malware-finden-auf-linux-servern/
* https://launchpadlibrarian.net/78745738/tuning-primer.sh



Abspeichern und schließen
Ausführbar machen mit folgendem Befehl
chmod malweredetect.sh

Nun starten wir dass Script
sh ./malewaredetect.sh

Nun ist Malewaredetect Installiert und ein Täglicher Cronjob Prüft automatisiert dass Systeme jeden Tag, wir sollten noch folgende eisntellungen erledigen in der maledetect config
nano /usr/local/maldetect/conf.maldet

Hier solltet ihr zunächst die Alamierung ein schalten und eine E-mail Adresse für Warnmeldungen eingeben
email_alert=1

email_addr="dein@email.local"

Nun abspeichern und wir können einen ersten Check machen von Hand im ISPConfig Standard Verzeichniss www

root@howtoforge:~# /usr/local/maldetect/maldet -b -a /var/www/
Ausgabe:
Linux Malware Detect v1.4.2 
(C) 2002-2013, R-fx Networks <proj@r-fx.org> 
(C) 2013, Ryan MacDonald <ryan@r-fx.org>

inotifywait (C) 2007, Rohan McGovern <rohan@mcgovern.id.au>

This program may be freely redistributed under the terms of the GNU GPL v2
maldet(18641): {scan} launching scan of /var/www/ to background, see /usr/local/maldetect/event_log for progress


Logfile findet sich hier
cat /usr/local/maldetect/event_log


Ausgabe des Logfiles
Jun 24 22:04:32 46038 maldet(18641): {scan} launching scan of /var/www/ to background, see /usr/local/maldetect/event_log for progress

Jun 24 22:04:32 46038 maldet(18641): {scan} signatures loaded: 11760 (9871 MD5 / 1889 HEX)

Jun 24 22:04:32 46038 maldet(18641): {scan} building file list for /var/www/, this might take awhile...

Jun 24 22:04:32 46038 maldet(18641): {scan} file list completed, found 43517 files...

Jun 24 22:04:32 46038 maldet(18641): {scan} found ClamAV clamscan binary, using as scanner engine...

Jun 24 22:04:32 46038 maldet(18641): {scan} scan of /var/www/ (43517 files) in progress...

Der Cronjob befindet sich hier
cat /etc/cron.d/maldet_pub


Ausgabe:
*/10 * * * * root /usr/local/maldetect/maldet --mkpubpaths >> /dev/null 2>&1



