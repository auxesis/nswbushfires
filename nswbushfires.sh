#!/bin/sh -e 

basedir=$(dirname $0)

echo "running scraper"
ruby $basedir/scraper.rb

echo "running poster"
ruby $basedir/poster.rb

