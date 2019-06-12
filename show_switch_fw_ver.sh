#!/bin/bash
for switch in `ibnetdiscover -p | grep ^SW | awk '{print $2}'| sort | uniq` 
  do 
   vendstat -N $switch 
  done | grep fw_version
