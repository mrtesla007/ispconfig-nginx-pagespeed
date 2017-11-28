#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;
use Getopt::Long;

# get table size,engine from db
# get table size on disk from datadir
# compare
# MyISAM should be exact, InnoDB can be up to 10% off

my %opt = (
                "host" => 0,
                "socket" => 0,
                "port" => 0,
                "user" => 0,
                "pass" => 0,
                "debug" => 0,
                "recommend" => 0,
                "output" => 0,
                "help" => 0,
                "skipsize" => 0
);

GetOptions(\%opt,
                'host=s',
                'socket=s',
                'port=i',
                'user=s',
                'pass=s',
                'debug',
                'recommend',
                'output=s',
                'help',
                'skipsize'
);

######### subroutines
sub usage();
sub mysql_setup();
sub get_table_info_from_db();
sub get_datadir();
sub get_filesize();
############ variable init
my ($mysqllogin,$doremote,$remotestring);
my $recommendations='';
my (%tbls, @dblist);
my ($name,$datadir,$loginstatus);

if (!$opt{'output'}) {
$opt{'output'} = "pretty";
}

# if they want help, give them help
if (defined $opt{'help'} && $opt{'help'} == 1) { usage(); }

#login to mysql
mysql_setup;

get_table_info_from_db;
get_datadir;

my ($tbl,$tname,$engine,$filename);

foreach $tname (keys %tbls) {
  # first figure out what file types to look at
  # given the storage engine of the table
$engine=$tbls{$tname}{Engine};
if ($engine eq 'MyISAM') {
#  foo is myisam
#  $datadir/$db/foo.MYD and .MYD
  $filename=$datadir.$tbls{$tname}{Db}."/".$tname.".MYD";
  $tbls{$tname}{fs_Data_length}=&get_filesize($filename);
  $filename=$datadir.$tbls{$tname}{Db}."/".$tname.".MYI";
  $tbls{$tname}{fs_Index_length}=&get_filesize($filename);
  }
if ($engine eq 'InnoDB') {
  # this client doesn't have any InnoDB tables so we can stop right here.
}

}

############## subroutine definitions
sub get_filesize() {
my $_filename=shift;
my ($_dev,$_ino,$_mode,$_nlink,$_uid,$_gid,$_rdev,$_size,$_atime,$_mtime,$_ctime,$_blksize,$_blocks) = stat($_filename);
  if ($opt{debug}) { print "$_filename is $_size bytes\n"; }
return $_size;
}

sub get_datadir() {
my $foo;
my @rows=split(/:/,`mysql $mysqllogin -EBse "SHOW GLOBAL VARIABLES LIKE 'datadir';"`);
($datadir,$foo)=split(/:/,$rows[-1]);
chomp($datadir);
$datadir =~ s/^\s+//;
}

sub get_table_info_from_db() {
if ($opt{debug}) { print "Getting table size info from SHOW TABLE STATUS\n"; }
#get the db names and go through each one, parsing SHOW TABLE STATUS
push (@dblist,`mysql $mysqllogin -Bse "SHOW DATABASES;"`);
foreach my $db (@dblist) {
chomp($db);
  if ($opt{debug}) { print $db."\n"; }
  foreach my $info (`mysql $mysqllogin $db -EBse 'SHOW TABLE STATUS;'`) {
    # Get the Name: Engine: Data_length: Index_length:
    if ($info =~ /Name|Engine|Data_length|Index_length/) { 
      # if ($opt{debug}) { print $info."\n"; }
      my ($key,$value)=split(/:/, $info);
      chomp($value);
      $value =~ s/^\s+//;
      # the Name is the first key
      if ($key =~ /Name/) {
        #if ($opt{debug}) { print "setting name=$value\n"; }
        $name=$value;
        $tbls{$name}{Db}=$db;
      }
      else {
        # if ($opt{debug}) { print "setting $name $key = $value\n"; }
        $key =~ s/^\s+//;
        $tbls{$name}{$key}=$value;
        }
    } # end if info is name/engine/data or index length
  } # end foreach line in SHOW TABLE STATUS
} # end foreach database


}

sub mysql_setup() {
        if ($opt{skipsize} ne 0 ) {return;}
        $doremote = 0;
        $remotestring = '';
        my $command = `which mysqladmin`;
        chomp($command);
        if (! -e $command) {
                print ("\nUnable to find mysqladmin in your \$PATH.  Is MySQL installed?\nFor offline operation, use --filelist.  See $0 --help\n\n");
                exit 10;
        }
        # Are we being asked to connect via a socket?
        if ($opt{socket} ne 0) {
                $remotestring = " -S $opt{socket}";
        }
        # Are we being asked to connect to a remote server?
        if ($opt{host} ne 0) {
                chomp($opt{host});
                $opt{port} = ($opt{port} eq 0)? 3306 : $opt{port} ;
                # If we're doing a remote connection, but forcemem wasn't specified, we need to exit
                if ($opt{'forcemem'} eq 0) {
                        print ("!! - The --forcemem option is required for remote connections\n");
                        print_all();
                        exit 20;
                }
                print ("-- Performing tests on $opt{host}:$opt{port}\n");
                $remotestring = " -h $opt{host} -P $opt{port}";
                $doremote = 1;
        }
        # Did we already get a username and password passed on the command line?
        if ($opt{user} ne 0 and $opt{pass} ne 0) {
                $mysqllogin = "-u $opt{user} -p'$opt{pass}'".$remotestring;
                $loginstatus = `mysqladmin ping $mysqllogin 2>&1`;
                if ($loginstatus =~ /mysqld is alive/) {
                        print ("OK Logged in using credentials passed on the command line\n");
                        return 1;
                } else {
                        print ("$mysqllogin\n\nAttempted to use login credentials, but they were invalid\n");
                        exit 30;
                }
        }
        if ( -r "/etc/psa/.psa.shadow" and $doremote == 0 ) {
                # It's a Plesk box, use the available credentials
                $mysqllogin = "-u admin -p`cat /etc/psa/.psa.shadow`";
                $loginstatus = `mysqladmin ping $mysqllogin 2>&1`;
                unless ($loginstatus =~ /mysqld is alive/) {
                        print ("!! Attempted to use login credentials from Plesk, but they failed.\n");                        exit 40;
                }
        } else {
                # It's not Plesk, we should try a login
                $loginstatus = `mysqladmin $remotestring ping 2>&1`;
                if ($loginstatus =~ /mysqld is alive/) {
                        # Login went just fine
                        $mysqllogin = " $remotestring ";
                        # Did this go well because of a .my.cnf file or is there no password set?
                        my $userpath = `ls -d ~ 2>/dev/null`;
                        if (length($userpath) > 0) {
                                chomp($userpath);
                        }
                        unless ( -e "${userpath}/.my.cnf" ) {
                                print ("!! Successfully authenticated with no password - SECURITY RISK!\n");
                        }
                        return 1;
                } else {
                        print STDERR "Please enter your MySQL administrative login: ";
                        my $name = <>;
                        print STDERR "Please enter your MySQL administrative password: ";
                        system("stty -echo");
                        my $password = <>;
                        system("stty echo");
                        chomp($password);
                        chomp($name);
                        $mysqllogin = "-u $name";
                        if (length($password) > 0) {
                                $mysqllogin .= " -p'$password'";
                        }
                        $mysqllogin .= $remotestring;
                        $loginstatus = `mysqladmin ping $mysqllogin 2>&1`;
                        if ($loginstatus =~ /mysqld is alive/) {
                                print STDERR "\n";
                                if (! length($password)) {
                                        # Did this go well because of a .my.cnf file or is there no passwordset?
                                        my $userpath = `ls -d ~`;
                                        chomp($userpath);
                                        unless ( -e "$userpath/.my.cnf" ) {
                                                print ("!! Successfully authenticated with no password - SECURITY RISK!\n");
                                        }
                                }
                                return 1;
                        } else {
                                print "\n$loginstatus\nAttempted to use login credentials, but they were invalid.\n";
                                exit 50;
                        }
                        print "exited because loginstatus is not 'mysqld is alive'.\n loginstatus=$loginstatus\n";
                        exit 60;
        }
        }
}

