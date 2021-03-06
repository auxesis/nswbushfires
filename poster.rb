#!/usr/bin/env ruby
#

require 'rubygems'
require 'bundler/setup'
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
      opts.banner = "Usage: poster <options>"
      opts.on('-o', '--diff-only', "compare, but don't post") do
        options.diff_only = true
      end
      opts.on('-d', '--directory DIR', 'directory for YAML') do |dir|
        options.directory = dir
      end
      opts.on('-c', '--config FILE', 'config filename') do |file|
        options.config_filename = file
      end
      opts.on('-v', '--verbose', 'increase verbosity') do
        options.verbose  = true
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
    @diff_only       = opts[:diff_only]
    @data_directory  = opts[:data_directory]
    @config_filename = opts[:config_filename]
    @verbose         = opts[:verbose]
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
    if @verbose
      puts "Second Latest: #{@yamls[-2]}"
      puts "Latest:        #{@yamls[-1]}"
    end

    # Filter out attrs that change frequently.
    attr_whitelist = [:type, :status, :size, :council_name, :location, :incident_name, :lat, :long]
    last        = @last[:incidents].map        {|i| i.reject {|k,v| !attr_whitelist.include?(k) } }
    second_last = @second_last[:incidents].map {|i| i.reject {|k,v| !attr_whitelist.include?(k) } }

    # Get the list of new incidents. Remove MVAs.
    @diff = (last - second_last).reject {|i| i[:type] =~ /vehicle/i }

    if @verbose
      puts "\nAttributes that are different:" if @diff.size > 0
      @diff.each do |incident|
        old_incident = second_last.find {|i| i[:incident_name] == incident[:incident_name] }
        if old_incident
          puts incident[:incident_name]
          print "Before:    "
          p incident.reject {|k, v| v == old_incident[k]}
          print "After:     "
          p old_incident.reject {|k, v| v == incident[k]}
        else
          puts incident[:incident_name]
          puts "**New incident**"
        end
        puts
      end
      puts
    end

    updated = @diff.size == 0
    modified = @last[:meta][:modified] != @second_last[:meta][:modified]

    updated || modified
  end

  def authenticate
    credentials = {
      :consumer_key       => @config[:consumer_token],
      :consumer_secret    => @config[:consumer_secret],
      :oauth_token        => @config[:access_token],
      :oauth_token_secret => @config[:access_secret],
    }

    @twitter = Twitter::Client.new(credentials)
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
        puts " - This would be posted to Twitter:"
        puts " - \"#{msg}\""
      else
        puts " - posting to Twitter"

        begin
          @twitter.update(msg, :lat => i[:lat], :long => i[:long])
        rescue SocketError
          puts "Problem with networking: #{e.message}"
        rescue Twitter::Error => e
          puts "Problem with Twitter: #{e.class}: #{e.message}"
        end
      end
      puts
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

  def validate_config
    %w(consumer_token consumer_secret access_token access_secret).each do |attr|
      attr = attr.to_sym

      @missing ||= []
      @missing << attr unless @config[attr]
    end

    if @missing.size > 0
      pretty_missing = @missing.map {|m| ":#{m}" }.join(', ')
      puts "You need to specify #{pretty_missing} in #{@config_filename}"
      exit 2
    end
  end

  # entry point - you should only ever have to call this
  def post
    load_data
    validate_config
    if unprocessed? && changed?
      authenticate
      post_updates
      mark_as_processed
    end
  end

end

options = PosterOptions.parse(ARGV)
poster = Poster.new(:data_directory  => options.directory,
                    :config_filename => options.config_filename,
                    :verbose         => options.verbose,
                    :diff_only       => options.diff_only)
poster.post


exit


