Dependencies
============

 * ruby
 * rake

Setup
=====

setup data dir + install gem dependencies with: 

    $ rake setup

create a `config.yaml`:

    --- 
    :email: your-twitter-email@foo.com
    :password: moocow

set up a cron job: 

    $ crontab -e 

    */15 * * * * /path/to/project/nswbushfires.sh

How it works
============

`fetcher.rb` gets latest current incidents list from RFS GeoRSS feed, extracts
data from it, and writes it out in YAML. 

`poster.rb` compares the last two YAML files, and posts the differences to 
Twitter. Also builds a shortened GMaps url for viewing incident location, and
embeds lat/lng data in Twitter update. 

`nswbushfires.sh` wraps both, making it suitable for running out of cron. 

