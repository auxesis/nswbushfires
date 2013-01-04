#!/bin/sh

set -e

basedir=$(dirname $0)

echo "running fetcher"
ruby -W0 $basedir/fetcher.rb

echo "running poster"
ruby -W0 $basedir/poster.rb

