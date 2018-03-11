#!/bin/bash

# Exit immediately if a command exits with a non-zero status:
set -e

rclone_name="backup"
data_dir="/backup"

verbose=0
remote_folder="WT"
cluster_id="dev"
mongo_host="wt_mongo1:27017,wt_mongo2:27017,wt_mongo3:27017"
restore_date=""

usage() {
      echo "Usage: `basename $0` -f remote_folder -c cluster_id -m mongo_hosts -r retain_days -d date"
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
    d) restore_date=$OPTARG
      ;;
    esac
done


if [ "${restore_date}" == "" ];
then
    printf "You must specify a restore date\n"
    exit 1;
fi

mongo_restore_path="${remote_folder}/${cluster_id}/${restore_date}/mongodump-${restore_date}.tgz"
home_restore_path="${remote_folder}/${cluster_id}/${restore_date}/home-${restore_date}.tgz"

printf "\nRestore started for ${cluster_id} ${restore_date}\n"

printf "Copying ${mongo_restore_path} to /tmp\n"
rclone --config /conf/rclone.conf copy backup:${mongo_restore_path} /tmp
printf "Copying ${home_restore_path} to /tmp\n"
rclone --config /conf/rclone.conf copy backup:${home_restore_path} /tmp

# Restoring mongodb
printf "\nRestoring mongodb\n"
mongorestore --drop --host=$mongo_host --gzip --archive=/tmp/mongodump-${restore_date}.tgz

# Restoring home directories
printf "\nRestoring home directories\n"
tar xvfz /tmp/home-${restore_date}.tgz -C /backup
