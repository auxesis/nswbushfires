#!/bin/sh 

set -e 

basedir=$(dirname $0)

echo "running fetcher"
ruby $basedir/fetcher.rb

echo "running poster"
ruby $basedir/poster.rb

