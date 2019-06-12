#!/bin/bash
 for switch in `ibnetdiscover -p | grep ^SW | awk '{print $2}' | sort | uniq `
 do 
  mlxuptime -d lid-$switch  2>/dev/null  
 done | grep "Device up time"
