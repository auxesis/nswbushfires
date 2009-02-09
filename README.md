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

`scraper.rb` gets latest current incidents list from RFS website, extracts some
basic data from it, and writes it out in YAML. 

`poster.rb` compares the last two YAML files, and posts the differences to 
Twitter. 

`nswbushfires.sh` wraps both, making it suitable for running out of cron. 

