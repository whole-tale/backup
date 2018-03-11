#!/bin/bash

# Exit immediately if a command exits with a non-zero status:
set -e

rclone_name="backup"
data_dir="/backup"

verbose=0
remote_folder="WT"
cluster_id="dev"
mongo_host="wt_mongo1:27017,wt_mongo2:27017,wt_mongo3:27017"
retain=7

usage() {
      echo "Usage: `basename $0` -f remote_folder -c cluster_id -m mongo_hosts -r retain_days"
}

while getopts "h?vf:n:c:m:d:" opt; do
    case "$opt" in
    h|\?)
      usage
      exit 0
      ;;
    v) verbose=1
      ;;
    f) remote_folder=$OPTARG
      ;;
    c) cluster_id=$OPTARG
      ;;
    m) mongo_host=$OPTARG
      ;;
    r) retain=$OPTARG
      ;;
    esac
done


if [ "${cluster_id}" == "" ];
then
	printf "You must specify a cluster_id\n"
	exit 1;
fi

# Get the ISO-8601 date
DATE=$(date +%Y%m%d)
TARGET_PATH="${remote_folder}/${cluster_id}/${DATE}"

printf "\nBackup started for ${cluster_id}: ${DATE} -> ${TARGET_PATH}\n"

# Do the mongo dump
printf "\nExporting mongodb\n"
mongodump --host=$mongo_host --gzip --archive=/tmp/mongodump-${DATE}.tgz

# Tar up the home filesystem
printf "\nArchiving home directories\n"
cd ${data_dir}
tar -cvzf /tmp/home-${DATE}.tgz *

# Do rclone
printf "\nrclone ${RCLONE_NAME}:${TARGET_PATH}\n"
rclone --config /conf/rclone.conf mkdir ${RCLONE_NAME}:${TARGET_PATH}
rclone --config /conf/rclone.conf copy /tmp/home-${DATE}.tgz ${RCLONE_NAME}:${TARGET_PATH}
rclone --config /conf/rclone.conf copy /tmp/mongodump-${DATE}.tgz ${RCLONE_NAME}:${TARGET_PATH}
rclone --config /conf/rclone.conf ls ${RCLONE_NAME}:${TARGET_PATH}

rm /tmp/home-${DATE}.tgz
rm /tmp/mongodump-${DATE}.tgz
printf "\nBackup complete for ${cluster_id}: ${DATE}\n"

# Delete 
DELETE_DATE=$(date -d "-${retain} days" +%Y%m%d)
DELETE_PATH="${remote_folder}/${cluster_id}/${DELETE_DATE}"

# Ignore errors from rclone on delete
set +e

rclone --log-file /tmp/rclone.log --config /conf/rclone.conf lsd ${RCLONE_NAME}:${DELETE_PATH}
if [ $? == 0 ]
then
   printf "\nDeleting old backup ${DELETE_DATE}\n"
   rclone --config /conf/rclone.conf delete ${RCLONE_NAME}:${DELETE_PATH}
   rclone --config /conf/rclone.conf rmdir ${RCLONE_NAME}:${DELETE_PATH}
else
   printf "Nothing to delete"
fi
