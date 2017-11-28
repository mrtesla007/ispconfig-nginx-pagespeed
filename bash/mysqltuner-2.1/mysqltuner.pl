#!/usr/bin/perl -w
# mysqltuner.pl - Version 2.0.1 
# High Performance MySQL Tuning Script
# Copyright (C) 2006-2009 Major Hayden - major@mhtx.net and Pythian, Inc.
#
# For the latest updates, please visit http://mysqltuner.com/
### IMPORT TO LAUNCHPAD / BAZAAR!!
# Subversion repository available at http://tools.assembla.com/svn/mysqltuner/
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# This project would not be possible without help from:
#   Matthew Montgomery     Paul Kehrer
#   Dave Burgess           Jonathan Hinds
#   Mike Jackson           Nils Breunese
#   Shawn Ashlee           Luuk Vosslamber
#   Ville Skytta           Trent Hornibrook
#   Jason Gill             Mark Imbriaco
#   Greg Eden              Aubin Galinotti
#   Giovanni Bechis        Bill Bradford
#   Ryan Novosielski       Michael Scheidell
#   Blair Christensen      Hans du Plooy
#   Victor Trac            Everett Barnes
#   Tom Krouper            Gary Barrueto
#   Simon Greenaway        Adam Stein
#   Gerry Narvaja          Sheeri Cabral
#
# Inspired by Matthew Montgomery's tuning-primer.sh script:
# http://forge.mysql.com/projects/view.php?id=44
#
use strict;
use warnings;
use diagnostics;
use Getopt::Long;
use Switch;

# Set up a few variables for use in the script
my $tunerversion = "2.0.1";
### MAKE THIS part of the header....

my %opt = (
                "config" => 0,
                "filelist" => 0,
                "forcearch" => 0,
                "forcemem" => 0,
                "forceswap" => 0,
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
                'config=s',
                'filelist=s',
                'forcearch=i',
                'forcemem=i',
                'forceswap=i',
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


my ($mysqllogin,$doremote,$remotestring);

sub mysql_setup();
sub pretty_uptime();
sub hr_num();
sub round2();
sub hr_bytime();
sub hr_bytes();
sub usage();
sub get_vars_from_server(); 
sub populate_var_hash(); 
sub get_vars_from_files();
my (@myconfig,$compval,$comp,$expr,$output,$parsedexpr);
my $label='';
sub read_config_file();
sub parse_config_file();
sub pretty_output();
sub csv_output();
sub spreadsheet_output();
sub get_vars_from_query();

if (!$opt{'output'}) {
$opt{'output'} = "pretty";
}

#### BEGIN MAIN

# if they want help, give them help
if (defined $opt{'help'} && $opt{'help'} == 1) { usage(); }

# if they don't specify a config file, give them help
if ($opt{'config'} eq 0) { usage(); }

my $recommendations='';

if ($opt{filelist} ne 0) {
	$doremote=1;
	$opt{skipsize}=1; 
	}
if ($opt{debug}) { print "mysql_setup starting\n"; }
mysql_setup;				 # Gotta login first

# Populates all of the variable hashes

my (%mylist,@mysqlvarlist);
if ($opt{'filelist'} ne 0) {
  get_vars_from_files;
  }
  else {
  get_vars_from_server;
  }               

populate_var_hash;
read_config_file;
parse_config_file;
if ($opt{'recommend'}) {
print "\n\nRECOMMENDATIONS:\n". $recommendations."\n";
}

####### BEGIN SUBROUTINES

sub get_vars_from_server() {
if ($opt{debug}) { print "using SHOW commands on the live database\n"; }
        push (@mysqlvarlist,`mysql $mysqllogin -Bse "SHOW /*!40003 GLOBAL */ VARIABLES;"`);
        push (@mysqlvarlist,`mysql $mysqllogin -Bse "SHOW /*!50002 GLOBAL */ STATUS;"`);
}

sub get_vars_from_files() {
if ($opt{debug}) { print "using filenames from list $opt{'filelist'}\n"; }
foreach my $filename (split(",",$opt{'filelist'})) {
	if (open(FILE,"<$filename")) {
        push (@mysqlvarlist,<FILE>);
        close(FILE);
	}
	else {
		print "cannot open $filename\n"; 
		exit 1;
		}
	}
}

sub populate_var_hash() {
foreach my $vline (@mysqlvarlist) {
#if ($opt{debug}) { print "$vline"; }
           $vline =~ /([a-zA-Z_]*)\s*(.*)/;
           $mylist{$1} = $2;
        }        
}

sub read_config_file() {
# read the config file
if ($opt{debug}) {print "Reading from $opt{'config'}\n";}
        open(CONF,"<$opt{'config'}");
        @myconfig=<CONF>;
        close(CONF);
}

sub parse_config_file() {
foreach my $line (@myconfig) {
($label, $comp, $expr, $output)=split (/\|\|\|/,$line);

# replace variable names with their values
# ie, max_connections is replaced with $mylist{max_connections}
if ($line =~ /^\#/) {next;}
if ($opt{debug}) {print "expr starts as $expr\n";}
$parsedexpr='';
foreach my $word (split(/\b/,$expr)) {
  if (exists($mylist{$word})) {
    $parsedexpr.=$mylist{$word};
    }
  else {
    $parsedexpr.=$word;
    }
}
if ($opt{'debug'}) {print "expr after parsing is $parsedexpr\n";}
$compval=eval($parsedexpr);
if ($opt{'debug'}) {print "expr evals to '$compval'\n";}

$compval=&round2($compval);
#if ($opt{'debug'}) {print "after rounding, expr evals to $compval\n";}

switch ($opt{'output'}) {
  case "csv" { csv_output; }
  else { pretty_output; }
}

#MAKE AN OPTION FOR HOW TO PRINT OUTPUT
} # end foreach my $line (@myconfig)

} #end parse_config_file

sub round2() {
my $num=shift;
# if the result is a number with a decimal point, round to the nearest 0.01
if ($num=~/^-?\d+\.?\d*(e.\d+)?$/ && $expr !~ /version/i) {
  $num=sprintf("%.2f",$num);
}
else { return $num;}
}

sub pretty_output() {
print "$label: ".$compval; 
if (eval($parsedexpr.$comp) eq 1) {
if ($opt{debug}) { print "\t".$label." matches $comp"; }
  $recommendations.=$output;}
print "\n";
}

sub csv_output() {
print "$label,".eval($parsedexpr)."\n";
if (eval($parsedexpr.$comp) eq 1) {
  $recommendations.=$output."\n";}
}

sub get_vars_from_query() {
}


sub usage() {
	# Shown with --help option passed
	print "\n".
		"   How to use $0:\n".
		"    The script requires a config file, to use the config that comes with \n".
		"    $0, run '$0 --config tuner-default.cnf'\n".
		"\n".
		"    --config <filename>  File to use with thresholds, calculations, and output\n".
		"\n".
		"   OPTIONAL COMMANDS\n".
		"   Output and Recommendations\n".
		"    --recommend          output recommendations\n".
		"    --output <type>      output format, choices are 'pretty' (default) and 'csv'\n".
		"\n".
		"   Connection and Authentication\n".
		"    --host <hostname>    Host to connect to for data retrieval (default: localhost)\n".
		"    --port <port>        Port to use for connection (default: 3306)\n".
		"    --socket <socket>    Socket to connect to for data retrieval\n".
		"    --user <username>    Username to use for authentication\n".
		"    --pass <password>    Password to use for authentication\n".
		"\n".
		"   Remote/Offline Options\n".
		"    --filelist <f1,f2..> Comma-separated list of file(s) to populate the key/value hash\n".
		"                         Use --filelist when you do not want to connect to a database to get\n".
                "                         variable values.  You must use --forcemem, --forceswap and --forcearch\n".
		"    --forcemem <size>    Use this amount of RAM in Mb instead of getting local memory size\n".
		"    --forceswap <size>   Amount of swap memory configured in megabytes\n".
		"    --forcearch 32|64    Architecture of operating system (32-bit or 64-bit)\n".
		"\n".
		"   Misc\n".
		"    --help               Shows this help message\n".
		"    --debug              debugging output will be shown\n".
		"\n";
	exit;
}
sub hr_bytime() {
        my $num = shift;
	my $per="";
        if ($num >= 1) { # per second
		$per="per second";
        } elsif ($num*60 >= 1) { # per minute
                $num=$num*60;
		$per="per minute";
        } elsif ($num*60*60 >=1 ) { # per hour
                $num=$num*60*60;
		$per="per hour";
        } else {
                $num=$num*60*60*24;
		$per="per day";
        }
$num=&round2($num);
return "$num $per";
}

sub hr_bytes() {
	my $num = shift;
	if ($num >= (1024**3)) { #GB
		return sprintf("%.1f",($num/(1024**3)))." Gb";
	} elsif ($num >= (1024**2)) { #MB
		return sprintf("%.1f",($num/(1024**2)))." Mb";
	} elsif ($num >= 1024) { #KB
		return sprintf("%.1f",($num/1024))." Kb";
	} else {
		return $num." bytes";
	}
}

sub hr_num() {
	my $num = shift;
	if ($num >= (1000**3)) { # Billions
		return int(($num/(1000**3)))." Billion";
	} elsif ($num >= (1000**2)) { # Millions
		return int(($num/(1000**2)))." Million";
	} elsif ($num >= 1000) { # Thousands
		return int(($num/1000))." Thousand";
	} else {
		return $num;
	}
}

# Calculates uptime to display in a more attractive form
sub pretty_uptime() {
	my $uptime = shift;
	my $seconds = $uptime % 60;
	my $minutes = int(($uptime % 3600) / 60);
	my $hours = int(($uptime % 86400) / (3600));
	my $days = int($uptime / (86400));
	my $uptimestring;
	if ($days > 0) {
		$uptimestring = "${days}d ${hours}h ${minutes}m ${seconds}s";
	} elsif ($hours > 0) {
		$uptimestring = "${hours}h ${minutes}m ${seconds}s";
	} elsif ($minutes > 0) {
		$uptimestring = "${minutes}m ${seconds}s";
	} else {
		$uptimestring = "${seconds}s";
	}
	return $uptimestring;
}

sub mysql_setup() {
	if ($opt{filelist} ne 0 ) {return;}
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
                if ($opt{'forcemem'} eq 0 && $opt{host} ne '127.0.0.1') {
			print ("!! - The --forcemem option is required for remote connections\n");
			exit 20;
		}
		print ("-- Performing tests on $opt{host}:$opt{port}\n");
		$remotestring = " -h $opt{host} -P $opt{port}";
		$doremote = 1;
	}
	# Did we already get a username and password passed on the command line?
	if ($opt{user} ne 0 and $opt{pass} ne 0) {
		$mysqllogin = "-u $opt{user} -p'$opt{pass}'".$remotestring;
		my $loginstatus = `mysqladmin ping $mysqllogin 2>&1`;
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
		my $loginstatus = `mysqladmin ping $mysqllogin 2>&1`;
		unless ($loginstatus =~ /mysqld is alive/) {
			print ("!! Attempted to use login credentials from Plesk, but they failed.\n");
			exit 40;
		}
	} else {
		# It's not Plesk, we should try a login
		my $loginstatus = `mysqladmin $remotestring ping 2>&1`;
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
			my $loginstatus = `mysqladmin ping $mysqllogin 2>&1`;
			if ($loginstatus =~ /mysqld is alive/) {
				print STDERR "\n";
				if (! length($password)) {
					# Did this go well because of a .my.cnf file or is there no password set?
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


