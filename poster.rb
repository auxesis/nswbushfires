#!/usr/bin/env ruby
#

require File.join(File.dirname(__FILE__), "vendor", "gems", "environment")
require 'yaml'
require 'twitter'
require 'ostruct'
require 'optparse'
require 'json/pure'
require 'open-uri'

class PosterOptions
  def self.parse(args)
    options = OpenStruct.new
    opts = OptionParser.new do |opts|
      opts.banner = "Usage: fetcher <options>"
      opts.on('-o', '--diff-only', "compare, but don't post") do
        options.diff_only = true
      end
      opts.on('-d', '--directory DIR', 'directory for YAML') do |dir|
        options.directory = dir
      end
      opts.on('-c', '--config FILE', 'config filename') do |file|
        options.config_filename = file
      end
    end

    begin
      opts.parse!(args)
    rescue => e
      puts e.message.capitalize + "\n\n"
      puts opts
      exit 1
    end

    # set a default config filename, and verify its existance
    options.config_filename ||= File.join(File.dirname(__FILE__), 'config.yaml')
    unless File.exists?(options.config_filename)
      puts "You need to setup a config file."
      puts "Please read the README."
      exit 1
    end

    # set a default data directory location
    options.directory ||= File.join(File.dirname(__FILE__), 'data')

    options
  end
end

class Poster
  def initialize(opts={})
    @diff_only = opts[:diff_only]
    @data_directory = opts[:data_directory]
    @config_filename = opts[:config_filename]
  end

  def load_data
    @config = YAML::load(File.read(@config_filename))
    @yamls = Dir.glob(File.expand_path(File.join(@data_directory, '*.yaml'))).sort

    unless @yamls[-1] && @yamls[-2]
      puts "Please run the fetcher again - need another dataset to compare against."
      exit 1
    end

    @second_last = YAML::load(File.read(@yamls[-2]))
    @last        = YAML::load(File.read(@yamls[-1]))
  end

  def unprocessed?
    @last[:meta][:processed?] != true
  end

  def changed?
    @diff = @last[:incidents] - @second_last[:incidents]
    updated = @diff.size == 0
    modified = @last[:meta][:modified] != @second_last[:meta][:modified]

    updated || modified
  end

  def post_updates
    @diff.each do |i|
      if i[:status] =~ /patrol/i
        puts "Updated #{i[:incident_name]}, but status is patrol."
        next
      end
      i[:gmaps] = shorten_gmaps_url(:lat => i[:lat], :long => i[:long])
      puts "Update to #{i[:incident_name]}"
      msg = build_message(i)
      if @diff_only
        puts " - not posting to twitter, but here's the message:"
        puts " - \"#{msg}\""
      else
        puts " - posting to Twitter"
        auth = Twitter::HTTPAuth.new(@config[:email], @config[:password])
        client = Twitter::Base.new(auth)
        begin
          client.update(msg, :lat => i[:lat], :long => i[:long])
        rescue Twitter::Unavailable, Twitter::InformTwitter => e
          puts "Problem with Twitter: #{e.message}"
        rescue Twitter::General => e
          puts "Problem with tweet: #{e.message}"
        end
      end
    end
  end

  def shorten_gmaps_url(opts={})
    if opts[:lat] && opts[:long]
      api_key   = "R_3215bce34570d671032a02d1075a0d94"
      api_login = "nswbushfires"
      gmaps_url = "http://maps.google.com.au/maps?q=#{opts[:lat]},#{opts[:long]}&z=9"
      escaped_gmaps_url = URI.escape(gmaps_url, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
      bitly_api_url = "http://api.bit.ly/shorten?apiKey=#{api_key}&login=#{api_login}&version=2.0.1&longUrl=#{escaped_gmaps_url}"

      response = open(bitly_api_url).read
      json = JSON.parse(response)

      if json["errorCode"] == 0 && json["statusCode"] == "OK"
        url = json["results"].keys.first
        json["results"][url]["shortUrl"]
      else
        nil
      end
    end
  end

  def build_message(i)
    msg = []
    if i[:incident_name] =~ /unmapped/i
      msg << "Council: #{i[:council_name]}"
    else
      msg << "Location: #{i[:location]}"
    end
    msg << "Type: #{i[:type]}"
    msg << "Status: #{i[:status]}"
    msg << "Size: #{i[:size]}"
    msg << "Map: #{i[:gmaps]}" if i[:gmaps]
    message = msg.join(', ')

    if message.size > 140
      (msg - [msg[3]]).join(', ')
    else
      message
    end
    #message = (msg - msg[3]).join(', ') if message.size > 140
  end

  def mark_as_processed
    return if @diff_only
    @last[:meta][:processed?] = true
    File.open(@yamls[-1], 'w') do |f|
      f << @last.to_yaml
    end
  end

  # entry point - you should only ever have to call this
  def post
    load_data
    if unprocessed? && changed?
      post_updates
      mark_as_processed
    end
  end


end

options = PosterOptions.parse(ARGV)
poster = Poster.new(:data_directory => options.directory,
                    :config_filename => options.config_filename,
                    :diff_only => options.diff_only)
poster.post


exit


