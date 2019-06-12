#!/bin/bash

 for switch in `ibnetdiscover -p | grep ^SW | awk '{print $2}'| sort | uniq` 
   do for port in {1..40} 
    do 
       mlxlink -d lid$switch -p -m | grep "FW Version|Part Number "  
    done 
 done



