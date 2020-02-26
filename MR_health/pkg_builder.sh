#!/bin/bash

#dos2unix /swgwork/eddies/scripts/ib_tools/MR_health/mlnx/mr_health.sh

tar_file="mr_health.tgz"

cd /swgwork/eddies/scripts/ib_tools/MR_health/mlnx/
tar xzf ibdiagnet_monitor_4.8.tgz
cd /swgwork/eddies/scripts/ib_tools/MR_health/
tar czf $tar_file mlnx/

echo ""
echo "File $tar_file is Ready to be used"
echo "md5sum:"
md5sum $tar_file
echo "File count:"
tar -tvf $tar_file | wc -l
