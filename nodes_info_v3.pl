#!/usr/bin/perl -w

#
# Copyright (C) Mellanox Technologies Ltd. 2001-2013.  ALL RIGHTS RESERVED.
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
use warnings;
use Switch;
#use List::MoreUtils qw(uniq);




#$Term::ANSIColor::AUTORESET = 1;

# Version 
my $ver = '3.0';



##################################################################################################
	
my $file = "";
my $dbCsvFile = "";
my $FILE;
my @defaultNodeSections = qw (NodeDesc NodeGUID HWInfo_DeviceID FWInfo_Extended_Major FWInfo_Extended_Minor 
							FWInfo_Extended_SubMinor FWInfo_PSID
							);
my @sections = "@defaultNodeSections";

my @Keys;
my @nodeInfo;


my @NODES=();
my @NODES_INFO=();
my @links=();
my @PM_INFO=();
my @sm = ();

my $llr_only = 0;

#my @tmp ; 
#my @NodesInfo;

my $formatRaw = "raw";
my $defaultFormat="csv";

my $format=$defaultFormat;
my $snPrefix="SN: ";
if ( @ARGV == 0 )
{
   help();
   exit;
}


##
# Arguments
##

   if (@ARGV == 0) {
		help();
	}  

while (@ARGV){
   $_  	= shift (@ARGV);  
   #$cablesFile  = shift (@ARGV) if $_ eq '--cables';
   $dbCsvFile 	= shift (@ARGV) if $_ eq '--db';
   @sections	= split (",",shift (@ARGV)) if $_ eq '-s';
   $llr_only	= 1 if $_  eq '--llr';
   
   $format 	= shift (@ARGV) if $_ eq '-f';
 #  help() if $_ eq '-h';
 
 }

if ( -e $dbCsvFile){
   #OpenFile($dbCsvFile);
   
   # Getting names for easier work
   
   parseSectionDbCsv(\@NODES,"NODES");
   
   for my $section ( @sections) {
   switch ( $section ) {
		case 	("PM_INFO") {
				parseSectionDbCsv(\@PM_INFO,"PM_INFO");
				printPM_INFO();
			}
		case 	("NODES") {
				parseSectionDbCsv(\@NODES,"NODES");
				printNodes();
			}	
		case 	("NODES_INFO") {
				parseSectionDbCsv(\@NODES_INFO,"NODES_INFO");
				printNodesInfo();
			}	
		# case 	("LINKS") {
				# parseSectionDbCsv(\@NODES_INFO,"LINKS");
				# printLinksInfo();
			# }	
	 }
   }
   
   #print " Reading Nodes Info from file: $dbCsvFile\n";
  # parseSectionDbCsv(\@nodesInfo,"NODES_INFO");
   
   #parseSectionDbCsv(\@Errors,"ERRORS_PORTS_COUNTERS_DIFFERENCE_CHECK_(DURING_RUN)");
   # parseSectionDbCsv(\@links,"LINKS");
   #printLinks();
   #parseSectionDbCsv(\@sm,"SM_INFO");
   closeFile();
   #printNodesInfoShort();
   #printErrors();
   #printNodes();
   
   #FW();
   
}
else {
  print "No file\n";
}

sub help {
########
# Help #
########

	print  "\n\t$0 Version: $ver\n";
	print  "\tAuthor: Mellanox\xAE Technologies Technical Support\n\n";
	
	print "\tUsage: $0 --db \"ibdiagnet2.db_csv\"  \"  -s \<section>\n";
  
    print "avialable sections: \n ";
	print "\t NODES\n";
	print "\t NODES_INFO\n";
	print "\t PM_INFO\n";	
}
sub OpenFile{
   my $file = shift;
   open FILE, "<", $file or die "$! \n";
   #@fullData= <FILE>;
   
}

sub closeFile{
   close(FILE);
}


sub getNodeName{
my $guid = shift;
my $node ;

	for $node (@NODES){
	  if ( $node->{NodeGUID} eq $guid ){
		return $node->{NodeDesc};
	  }
	}
	
	return "NA";

}

sub parseSectionDbCsv{
   
#NodeGUID,HWInfo_DeviceID,HWInfo_DeviceHWRevision,HWInfo_UpTime,FWInfo_SubMinor,FWInfo_Minor,FWInfo_Major,FWInfo_BuildID,FWInfo_Year,FWInfo_Day,FWInfo_Month,FWInfo_Hour,FWInfo_PSID,FWInfo_INI_File_Version,FWInfo_Extended_Major,FWInfo_Extended_Minor,FWInfo_Extended_SubMinor,SWInfo_SubMinor,SWInfo_Minor,SWInfo_Major
   
   my $data = shift;
   my $section = shift;
   my $start= "START_${section}";
   my $end  = "END_${section}";
   my $startNode = 0;
   my $endNode   = 0;
   my $counter = 0;
  # my $i = 0 ;
   
   #print "$start $end\n";
   open FILE, "<", $dbCsvFile or die "$! \n";
   while ( my $line = <FILE>) {
      chomp ($line);
	  if ($line eq $end){
	       $startNode = 2;
		   #$endNode = 1;
	  }
	  if ( $line eq $start ){
		$startNode = 1;
      }
	  else {
			if ( ( $startNode == 1 ) && ( $line !~ $end ) ){
				@nodeInfo = split(",",$line);
				if ($counter == 0){
					@Keys=@nodeInfo;
				}
				else{
				#@nodeInfo = split(",",$line);
					for ( my $i = 0 ; $i < @Keys ; $i++ ) {
						${$data}[$counter-1]{$Keys[$i]} = $nodeInfo[$i];
					}
				}
			$counter++;
			} 
		}  
	}
}
#sub NodeInfoParsing


sub printNodes{

			  # LocalPortNum                   PortGUID                       ClassVersion     
              # SystemImageGUID                NodeType                       NodeGUID
			  # revision                       DeviceID                       NodeDesc 
			  # BaseVersion                    NumPorts                       VendorID 
			  # PartitionCap


 my $href;
 my @nodeKeys;
 
 
 my $Attribute;
 my $length;

 @nodeKeys = keys %{$NODES[0]}  ;
 
 # for ( my $i = 0 ; $i <50 ; $i++) { print "*"; }
 # print "\n******************** Nodes *********************\n\n";
 # for ( my $i = 0 ; $i <50 ; $i++) { print "*"; }
# print "\n"; 

  for $Attribute ( @nodeKeys ) {
	printf("%s,",$Attribute);
  }
 
 print "\n";
 for $href ( @NODES  ) {
    #print "{ ";
    for $Attribute ( @nodeKeys ) {
			
			printf "%s,",$href->{$Attribute}; 
	}
	print "\n";		
}
	
}

sub printPM_INFO{

 my $href;
 my @nodeKeys;
 
 my $NodeDesc;
 my $Attribute;
 my $length;

 
 
 @nodeKeys = ( sort keys %{$PM_INFO[0]} ) ;
 
# counter1 - port_rcv_cells
# counter2 - port_rcv_cells_dropped
# counter3 - port_rcv_crc_error
# counter4 - port_xmit_cells
# counter5 - port_xmit_retry_cells
# counter6 - port_xmit_retry
# counter7 - port_symbol_error
 
 # for ( my $i = 0 ; $i <50 ; $i++) { print "*"; }
 # print "\n******************** PM_INFO *********************\n\n";
 # for ( my $i = 0 ; $i <50 ; $i++) { print "*"; }
 
 # print "\n";
 
 print "NodeDesc,";
 if ( $llr_only ){ 
				print "Counter1,Counter2,Counter3,Counter4,Counter5,Counter6,Counter7,retransmission_rate";
	}	
 else {
	for $Attribute ( @nodeKeys ) {
		print"$Attribute,";
	}
 }
 
 print "\n";
 for $href ( @PM_INFO  ) {
    $NodeDesc = getNodeName($href->{NodeGUID});
	print "$NodeDesc,";
	if ($llr_only){ 
					# print "$href->{Counter1},$href->{Counter2},$href->{Counter3},$href->{Counter4},$href->{Counter5},$href->{Counter6},$href->{Counter7},$href->{retransmission_rate}";
				}
	else{
			
			for $Attribute ( @nodeKeys ) {
				if ( index($Attribute , "PortXmitPktsExtended") != -1 ){
					print hex $href->{$Attribute};
					print $href->{$Attribute};
					print ","
					
				}
				
				else {
					printf "%s,",$href->{$Attribute}; 
				}
			}
		}
	print "\n";	
	}
		
}

sub printLinks{

 my $href;
 my @nodeKeys;
 
 
 my $Attribute;
 my $length;

 my ($node1,$node2);
 
 @nodeKeys = keys %{$links[0]}  ;
 
  for $Attribute ( @nodeKeys ) {
	print "$Attribute,";
  }
 
 print "\n";
 for $href ( @links  ) {
    #print "{ ";
   
   $node1= getNodeName($href->{NodeGuid1});
   $node2= getNodeName($href->{NodeGuid2});
   print " $node1,$href->{PortNum1},$node2,$href->{PortNum2}";
   #   for $Attribute ( @nodeKeys ) {
			#print "%s","
			#printf "%s,",$href->{$Attribute}; 
	#}
	print "\n";		
	}
}

#}


	
sub printNodesInfoShort{
 my $href; 
 my $Attribute;
 
 my $defaultPadd=30;
 
  for $Attribute ( @defaultNodeSections ) {
	
	 if (index($Attribute,"FWInfo_Extended_SubMinor") != -1 ){ 
		printf (",FW_version " );
	 }
	 else {
			if ( index($Attribute , "FWInfo_Extended_Minor") == -1    || index($Attribute,"FWInfo_Extended_Major") == -1 ) {
				printf("%s ",$Attribute);
		}
	}
  }
 
 print "\n";
 
 for $href ( @NODES_INFO   ) {
	
    my $nodeDesc;
 #printf "%s ",$nodeDesc;
	
	for $Attribute ( @defaultNodeSections ) {
	
		#printf "%s ",$href->{$Attribute}; 
		
		#printf "%s",$Attribute;
		 if ( index($Attribute,"NodeDesc") !=-1 ){
			  $nodeDesc = getNodeName($href->{NodeGUID});
			  printf "%s ",$nodeDesc;
			 next
		 }
		 if ( index($Attribute,"FWInfo_Extended") !=-1 ){
			 printf "%d ",hex($href->{$Attribute});
			 next
		 }
		if ( index($Attribute,"FWInfo_Major") !=-1  || index($Attribute,"FWInfo_Minor") !=-1  || index($Attribute,"FWInfo_SubMinor") !=-1  ){
			 printf "%d",hex($href->{$Attribute});
			 next
		 }
		
		if  ( index($Attribute,"FWInfo_Year") !=-1  ||  index($Attribute,"FWInfo_Month") != -1  ||  index($Attribute,"FWInfo_Day") !=-1 
				  ||  index($Attribute,"FWInfo_Hour") !=-1 ) {
				 printf "%x ",hex($href->{$Attribute});
				 next
		}
		if  ( index($Attribute,"FWInfo_buildID") !=-1 ){
			printf "%s",hex($href->{$Attribute});
			next
		}
		if  ( index($Attribute,"HWInfo_UpTime") !=-1 ){
			printf "%d ",hex($href->{$Attribute});
			next
		}

		else{
			printf "%s ",$href->{$Attribute}; 
		}
		
		}
	print "\n";	
	}
	
}

 


sub printNodesInfo{

my $NodeDesc = "NA";
my $length1;


				
	
	# for my $title(@Keys){
	# $length1 = length ($NODES_INFO[0]->{$title} );
    # $length1 = length($title) if ( length($title) >= length($NODES_INFO[0]->{$title} ) ) ; 
	
	# if (index($title,"FWInfo_Extended_SubMinor") != -1 ){ 
		# print "FW_version,"
	# }
	# else {
		# if ( index($title, "FWInfo_Extended_Minor") == -1    |  index($title,"FWInfo_Extended_Major") == -1 ) {
			# printf("%s,",$title);
			# }
		# }
	# }

	print "NodeDesc,NodeGuid,DeviceID,FWInfo_Uptime,FWInfo_PSID,FW_Version,FWInfo_BuildID,FWInfo_Year,FWInfo_Month,FWInfo_Day,FWInfo_Hour";
 print"\n";
  for my $node ( @NODES_INFO){
	
	#NodeGUID HWInfo_DeviceID HWInfo_DeviceHWRevision HWInfo_UpTime FWInfo_SubMinor FWInfo_Minor 
	#FWInfo_Major FWInfo_BuildID FWInfo_Year FWInfo_Day FWInfo_Month FWInfo_Hour FWInfo_PSID 
	#FWInfo_INI_File_Version FWInfo_Extended_Major FWInfo_Extended_Minor FWInfo_Extended_SubMinor 
	#SWInfo_SubMinor SWInfo_Minor SWInfo_Major
	
	$NodeDesc = getNodeName($node->{NodeGUID});
	print "$NodeDesc,";
	printf "%s,%s,%s,%s,%d.%d.%d,%s,%x,%x,%x,%x\n",
				$node->{NodeGUID}, 
				$node->{HWInfo_DeviceID},
				
				hex($node->{HWInfo_UpTime}),
				$node->{FWInfo_PSID},
				hex($node->{FWInfo_Extended_Major}),
				hex($node->{FWInfo_Extended_Minor}),
				hex($node->{FWInfo_Extended_SubMinor}),
				hex($node->{FWInfo_BuildID}),
				hex($node->{FWInfo_Year}),
				hex($node->{FWInfo_Month}),
				hex($node->{FWInfo_Day}),
				hex($node->{FWInfo_Hour})
				;
	}
 }
