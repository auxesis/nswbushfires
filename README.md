Dependencies
============

 * ruby
 * rake
 * bundler

Setup
=====

Setup data dir + run bundler with:

    $ rake setup

Once you've created an account, register the application with Twitter:

    http://dev.twitter.com/apps/new

Note the consumer key & consumer secret on the application page, follow the
"My Access Token" link, and note the access token and access secret.

Create a `config.yaml` with the previously noted details:

    ---
    :consumer_token: "consumer_token_of_doom"
    :consumer_secret: "consumer_secret_of_doom"
    :access_token: "accces_token_of_doom"
    :access_secret: "access_secret_of_doom"

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

