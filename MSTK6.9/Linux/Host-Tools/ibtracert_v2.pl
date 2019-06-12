#!/usr/bin/perl -w

#
# Copyright (C) Mellanox Technologies Ltd. 2001-2014.  ALL RIGHTS RESERVED.
#
# This software product is a proprietary product of Mellanox Technologies Ltd.
# (the "Company") and all right, title, and interest and to the software product,
# including all associated intellectual property rights, are and shall
# remain exclusively with the Company.
#
# This software product is governed by the End User License Agreement
# provided with the software product.
#
#

use strict;


my $src = '';
my $dst = '';
my $useGuid = 0;
my @hops;
my $hop= '';
my $tmpHop = '';
my $first;
my $second;
my $sourceName = '';
my $portNum ;
my $portNumLocation;

my $exitPortNum ;
my $exitPortNumLocation;

my $shortNames = 0;

# Version 
my $ver = '1.0';





if ( @ARGV == 0 )
{
   #help();
   #exit;
}

##
# Getting all arguments
##

while (@ARGV){
    $_          = shift (@ARGV);  
	# $user       = shift (@ARGV) if $_ eq '-u';
    $src	= shift (@ARGV) if $_ eq '--src';
    $dst	= shift (@ARGV) if $_ eq '--dst';
	$useGuid 	= 1 if $_ eq '-G';
	$shortNames 	= 1 if $_ eq '--short_names';
	
   # help() if $_ eq '-h';
   # help(1) if $_ eq '-H';
}

my $result;

if ( $useGuid ){
	$result = `ibtracert -G $src $dst`;
}
else {
   $result = `ibtracert $src $dst`;
}

#delete empty lines
$result =~ s/\n\s*/\n/g;
@hops =  split("\n", $result);
my $hopName = '';
my @hopToWords;
my $lastHopCA = 0;
my $FirstHopSwitch = 0;
my $FirstHopSwitchName = '';

foreach $hop(@hops){

	#find start/source
	#saving the original hop in case I would have to do some manipulation on it, will work on the tmpHop 
	$tmpHop = $hop;
	
	# splitting the hop to words as we need to query some known positions in the hop
	my @hopToWords = split(' ', $hop);
	
	if ( $hop =~ m/^From|^To/ ){
		
		
		#$tmpHop =~ s/\"(.*)\"/$1/m;
		$portNumLocation = index($tmpHop,"portnum");
		$portNum = substr ($tmpHop,$portNumLocation,9);
		$portNum =~ tr/0-9//cd; 
		$first = index($tmpHop,"\"",0);
		$second = index ($tmpHop,"\"",$first+1);
		$sourceName = substr($tmpHop,$first+1,$second-$first-1);
		
		if ( $hop =~ m/^To/){
			
			if ( $hopToWords[1] eq 'ca'){
				$lastHopCA=1;
			}
			else
			{
				print "[$portNum] "
			}
			
		}
		
		if ($shortNames){
			if ( $hopToWords[1] eq 'switch' ) {
				$FirstHopSwitch = 1;
				$FirstHopSwitchName = $sourceName;
			}
		
		}
		if ($sourceName =~ m/^MF0;/){
		
			$sourceName =~ s/^MF0;//
		}
		
		if ( $hop =~ m/^From/){ 
			print "[$portNum] $sourceName "; #if !$lastHopCA;
		}
	
		
		
	}
	else {
	
		$portNumLocation = index($tmpHop,'[',3);
		$exitPortNumLocation = index($tmpHop,'[',0);
		$portNum = substr ($tmpHop,$portNumLocation,3);
		
		$portNum =~ tr/0-9//cd; 
		
		$exitPortNum = substr ($tmpHop,$exitPortNumLocation,3);
		$exitPortNum =~ tr/0-9//cd; 
		
		$first = index($tmpHop,"\"",0);
		$second = index ($tmpHop,"\"",$first+1);
		$hopName = substr($tmpHop,$first+1,$second-$first-1);
		
		if ($shortNames){
			if ($FirstHopSwitchName =~ m/^MF0;/){
		
				$FirstHopSwitchName =~ s/^MF0;//
			}
		}
		print "$FirstHopSwitchName $hopToWords[0] ->" if ( $FirstHopSwitch);
		
		if ($shortNames){		
			if ($hopName =~ m/^MF0;/){
		
				$hopName =~ s/^MF0;//
			}
		}
		
		#print " $hopName [$portNum] ";
		print "[$exitPortNum] -> [$portNum]  $hopName ";
	}
	
}
print"\n";




