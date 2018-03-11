# Whole Tale Backup 

Docker image definition for the Whole Tale backup container. This container is used to backup user data to remote cloud storage via [rclone](https://rclone.org). See the [terraform_deployment](https://github.com/whole-tale/terraform_deployment) repository for information about how this is deployed in the system.

## To run manually

To run the backup or restore process manually required first configuring rclone:

```
rclone --config rclone.conf config
...
n) New remote 
name> backup
Storage> 4 (box)
client_id> <empty>
client_secret> <empty>
Use auto config? Y
```

This will produce rclone.conf with a section ``backup`` and an initial token (valid for 60 days).  The rclone.conf is used by the backup/restore processes.

Now, run the backup:
```
docker run --rm --network wt_mongo -v /mnt/home:/backup -v /home/core/rclone/:/conf  wholetale/backup backup.sh
```

This will create a directory ``WT/dev/YYYYMMDD/`` containing an archive of home directory data and a dump of the mongodb.

