#!/usr/bin/perl -w
#
# Copyright (C) Mellanox Ltd. 2001-2014.  ALL RIGHTS RESERVED.
#
# This software product is a proprietary product of Mellanox Ltd.
# (the "Company") and all right, title, and interest and to the software product,
# including all associated intellectual property rights, are and shall
# remain exclusively with the Company.
#
# This software product is governed by the End User License Agreement
#
# The mellanox-disable-sm.pl expect to receive as argument a file contains ip address of Mellanox switches 
# The script will set the sm mode to disable for all switches according the ip addresses given in the file
#
# The script can be used only for Mellanox 4036/2036
#
# Prerequisite: Perl Expect must be installed 
#
# Usage: mellanox-disable-sm.pl <hostfile>
#
# Written by Yair Goldel <yairg@mellanox.com>
#
# July 2009
#

use Net::Ping;
use Expect;
#use POSIX 'strftime';
 

my ($d,$m,$y,$H,$M) = (localtime)[3,4,5,2,1];
my $mdy = sprintf '%02d%02d%04d-%d%d', $m+1, $d, $y+1900,$H,$M;

$LOGFILE="/tmp/mellanox-disable-sm.log.$mdy";

if (@ARGV != 1)
{
	print "mellanox-disable-sm.pl Version 5.5\n\n";
        die "\nUsage: mellanox-disable-sm.pl <hostfile>\n\n";
}

print "mellanox-disable-sm.pl Version 5.5";

$IPFile = $ARGV[0];


sub Activate_Sw_Cli($$;$)
{

 my($spawn_name,$send_expect_str,$log_file)=@_;
 $Expect::Log_Stdout=0;

# for debug
#$Expect::Exp_Internal = 1;

 my (@action_arr,$counter,@tmp_arr);
 $counter=0;
 my $exp = Expect->spawn($spawn_name) 
    or die "Autotest err:Cannot spawn SSH \n";
 if ($log_file)
  { $exp->log_file($log_file);
  }
 @action_arr=split(/,/,$send_expect_str);
 foreach (@action_arr)
 {
   if(index(($counter/2),".")==-1)
     { 
 	$exp->expect(10,
                [qr/to continue connecting/i,#[qr/\?/i,   # if question is -Are you sure you want to continue connecting (yes/no)? yes
                   sub{ my $fun =shift;
                   $exp->send("yes\n");
                   $exp->expect(30,'-re',$_);
                }],
                [qr/$_/i,     
                   sub{ my $fun =shift;
                }],
     		      );
     }
    else
     {$exp->send($_,"\n");
     }
   $counter++;
  }
}

open (T,"$IPFile") or die "Can't open $IPFile, $!\n";

while (<T>)
{
chop;
$SwitchIP=$_;

if (pingecho($SwitchIP))
{
	print("\nDisabling the SM on $SwitchIP  .......   "); 
	Activate_Sw_Cli("ssh admin\@$SwitchIP","password:,123456,#,config,#,sm,#,sm-info mode set disable,#,end>",$LOGFILE);
	print ("Done\n");
}
else
{
	print "\n$SwitchIP is not responding.\n"
}

	sleep(1);
}

close T;

print "\nLogfile is under $LOGFILE\n\n"; 
print "mellanox-disable-sm.pl Version 5.5\n\n";
