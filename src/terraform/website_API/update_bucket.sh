#! /usr/bin/bash

rm -fr ../../hugo_site/public

hugo -D -s ../../hugo_site

echo "public updated"

aws s3 sync ../../hugo_site/public s3://carsten-singleton.com --delete \
> sync_output.txt

echo "bucket updated"

perl -nle 'print $1 if /(?<=s3:\/\/carsten-singleton\.com)(.{0,})/' \
sync_output.txt > invalidations.txt && truncate -s -1 invalidations.txt

rm -f sync_output.txt

echo "invalidations.txt created"