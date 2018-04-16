#!/bin/bash

# Updates the domain and globus configuration
mongo_host="rs1/wt_mongo1:27017,wt_mongo2:27107,wt_mongo3:27017"

domain=$1
globus_client_id=$2
globus_client_secret=$3

echo "Adding $domain to Girder CORS origin"
mongo --host=${mongo_host} girder --eval 'db.setting.updateOne( { key: "core.cors.allow_origin" }, { $set : { value: "http://localhost:4200, https://dashboard.wholetale.org, http://localhost:8000, https://dashboard-dev.wholetale.org, https://dashboard.'$domain'"}})'

echo "Updating Globus client ID and secret"
mongo --host=${mongo_host} girder --eval 'db.setting.updateOne( { key : "oauth.globus_client_id" }, { $set: { value: "'$globus_client_id'"} } )'
mongo --host=${mongo_host} girder --eval 'db.setting.updateOne( { key : "oauth.globus_client_secret" }, { $set: { value: "'$globus_client_secret'"} } )'
mongo --host=${mongo_host} girder --eval 'db.setting.find()'
