#!/usr/bin/perl -w
#
# Copyright (C) Mellanox Ltd. 2001-2010.  ALL RIGHTS RESERVED.
#
# This software product is a proprietary product of Mellanox Ltd.
# (the "Company") and all right, title, and interest and to the software product,
# including all associated intellectual property rights, are and shall
# remain exclusively with the Company.
#
# This software product is governed by the End User License Agreement
#
# The script c
#
# Prerequisite: Perl Expect must be installed 
#
# Usage: show-running-config.pl <> <> <>
#
# Written by Yair Goldel <yairg@mellanox.com>
#
# Aug 2009
#

use Net::Ping;
use Expect;
#use POSIX 'strftime';
 

my ($d,$m,$y,$H,$M) = (localtime)[3,4,5,2,1];
my $mdy = sprintf '%02d%02d%d%d', $m+1, $d, $H,$M;


if (@ARGV != 3)
{
        die "\nUsage: show-running-config.pl <SYSTEM_TYPE> <IP ADDRESS> <ADMIN PASSWORD>\n\n";
}

$SystemType=$ARGV[0];
$SwitchIP=$ARGV[1];
$AdminPass=$ARGV[2];

print "\nSysType is $SystemType\n";

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

if (pingecho($SwitchIP))
{
	$LOGFILE="/tmp/Show-running-config-$SystemType-$SwitchIP.log.$mdy";
	print("\nSaving Running Configuration Of $SwitchIP  .......   "); 
	
	if ( $SystemType eq "4036") 
	{
		Activate_Sw_Cli("ssh admin\@$SwitchIP","password:,$AdminPass,#,firmware-version show,#,front show,#,info-led show,#,sm-info show,#,remote show,#,version show,#,config,#,interface,#,ip-address show,#,exit,#,ntp,#,clock show,#,ntp show,#,exit,#,security,#,telnetd show,#,ufmagent show,#,exit,#,snmp,#,snmp show,#,exit,#,exit,#,cable-config show,36,temperature show,#,end>",$LOGFILE);
	}
	elsif (( $SystemType eq "2012") or ( $SystemType eq "2004"))
	{
	Activate_Sw_Cli("ssh admin\@$SwitchIP","password:,$AdminPass,built-in,,#,version show,#,,#,smb-state show ,#,,#,sm-info show,#,end",$LOGFILE);
	}
	print ("Done\n");
}
else
{
	print "\n$SwitchIP is not responding.\n"
}

sleep(1);

print "\nLogfile is under $LOGFILE\n\n"; 


