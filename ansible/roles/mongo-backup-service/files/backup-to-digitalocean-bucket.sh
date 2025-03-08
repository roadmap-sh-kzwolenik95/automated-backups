#!/usr/bin/env bash
set -euo pipefail

filename="dump-$(date '+%Y%m%d%H%M%S').gz"

mongodump --gzip --archive="${filename}"

export AWS_ACCESS_KEY_ID=$(jq -r '.id' < "${CREDENTIALS_DIRECTORY}/do_access_secret")
export AWS_SECRET_ACCESS_KEY=$(jq -r '.key' < "${CREDENTIALS_DIRECTORY}/do_access_secret")

s3cmd --host="fra1.digitaloceanspaces.com" \
      --host-bucket="%(bucket)s.fra1.digitaloceanspaces.com" \
      put "${filename}" s3://backups-roadmapsh-kzwolenik95/

rm "${filename}"
