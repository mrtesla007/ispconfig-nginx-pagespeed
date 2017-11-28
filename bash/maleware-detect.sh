#!/bin/bash

# debian-specific installation script by M. Cramer <m.cramer@pixcept.de>
# howto taken from howtoforge written by "felan":
# http://www.howtoforge.com/forums/showthread.php?p=284504
#

CURDIR=`pwd`
PROG=`readlink -f $0`
echo "Installing prerequisites..."
apt-get -y -q install inotify-tools sed
echo "Fetching latest version of maldetect..."
cd /tmp
wget http://www.rfxn.com/downloads/maldetect-current.tar.gz
tar -xzf maldetect-current.tar.gz
cd maldetect-*
echo "Modifying install script..."
sed -r -i 's/^(.*cp.*/libinotifytools.so.0[ ]+/usr/lib/.*)$/#1/g' install.sh;
echo "Modifying cron job..."
sed -r -i '/maldet.*/var/www/vhosts/?/subdomains/?/httpdocs.*$/ a
elif [ -d "/usr/local/ispconfig" || -d "/root/ispconfig" ]; then
# ispconfig
/usr/local/maldetect/maldet -b -r /var/www 2 >> /dev/null 2>&1' cron.daily;
echo "Modifying maldet script..."
sed -r -i 's/^$nice .*$/$nice -n $inotify_nice $inotify -r --fromfile $inotify_fpaths $exclude --timefmt "%d %b %H:%M:%S" --format "%w%f %e %T" -m -e create,move,modify >> $inotify_log 2>&1 &/g' files/maldet;
sed -r -i '/lmdup() {.*$/ a
ofile=$tmpdir/.lmdup_vercheck.$$
tmp_inspath=/usr/local/lmd_update
rm -rf $tmp_inspath
rm -f $ofile
mkdir -p $tmp_inspath
chmod 750 $tmp_inspath
eout "{update} checking for available updates..." 1
$wget --referer="http://www.rfxn.com/LMD-$ver" -q -t5 -T5 "$lmdurl_ver" -O $ofile >> /dev/null 2>&1
if [ -s "$ofile" ]; then
installed_ver=`echo $ver | tr -d "."`
current_ver=`cat $ofile | tr -d "."`
current_hver=`cat $ofile`
if [ "$current_ver" -gt "$installed_ver" ]; then
eout "{update} new version $current_hver found, updating..." 1
'"$PROG"'
fi
else
echo "no update file found. try again later"
exit
fi
rm -rf $tmp_inspath $ofile $ofile_has
exit;
# skip all the rest
' files/maldet;
echo "Modifying config..."
sed -r -i 's/^inotify=.*$/inotify=/usr/bin/inotifywait/g' files/internals.conf
echo "Deleting unneccessary files..."
rm -f files/inotify/inotifywait
rm -f files/inotify/libinotifytools.so.0
./install.sh
rm -r /tmp/maldetect-*
cd $CURDIR
echo "Soll ein Echtzeit-Monitoring laufen bitte folgende Änderungen vornehmen:"
echo ""
echo "vi /usr/local/maldetect/maldetfilelist"
echo ""
echo "Einfügen (Verzeichnis/Verzeichnisse, die untersucht werden sollen)"
echo "/var/www"
echo "(bzw. das Basisverzeichnis für die Webseiten, kann auch /home/www oder ähnlich sein)"
echo ""
echo "vi /etc/rc.local"
echo ""
echo "Einfügen (Befehl startet den Monitor beim Boot des Servers)"
echo "/usr/local/maldetect/maldet -m /usr/local/maldetect/maldetfilelist"
echo ""
echo "Zum starten des Monitors einmalig den Befehl ausführen"
echo "/usr/local/maldetect/maldet -m /usr/local/maldetect/maldetfilelist"