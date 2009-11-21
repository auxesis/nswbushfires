#!/usr/bin/env ruby 
#

# deps
require File.join(File.dirname(__FILE__), 'vendor', 'gems', 'environment')


require 'open-uri'
require 'nokogiri'
require 'json'
require 'ostruct'
require 'optparse'
require 'uri'

class FetcherOptions
  def self.parse(args)
    options = OpenStruct.new
    opts = OptionParser.new do |opts|
      opts.banner = "Usage: fetcher <options>"
      opts.on('-d', '--directory DIR', 'output directory for JSON') do |dir|
        options.output_directory = dir
      end
    end

    begin 
      opts.parse!(args)
    rescue => e
      puts e.message.capitalize + "\n\n"
      puts opts
      exit 1
    end

    # output in current directory
    options.output_directory ||= File.join(File.dirname(__FILE__), 'data')

    options
  end
end

class Fetcher
  def initialize(opts={})
    @data = []
    @filename = File.expand_path(File.join(opts[:output_directory], 'data.json'))
  end
 
  def fetch
    @raw = open(@uri).read
  end

  def build 
    raise "you need to subclass this to use it!"
  end

  def write(opts={})
    opts[:output_type] ||= (@output_type || "json")
    File.open(@filename, 'w') do |f|
      f << @data.method("to_#{opts[:output_type]}").call
    end
  end

  def shebang!
    fetch
    build
    write
  end
end

class RFSCurrentIncidentsFetcher < Fetcher
  def initialize(opts={})
    super
    @filename = File.expand_path(File.join(opts[:output_directory], Time.now.strftime('%Y-%m-%dT%H:%M:%S%z.yaml')))
    @uri = "http://www.rfs.nsw.gov.au/feeds/majorIncidents.xml"
    
    # data structure for storing incidents
    @data = {}
    @data[:incidents] = []
    @data[:meta] = {}
    
    @output_type = "yaml"
  end

  def build
    doc = Nokogiri::XML(@raw)
    incidents = doc.search("//item")

    incidents.each do |incident|

      raw_description = incident.children.css("description").first
      description_parts = raw_description.text.split('<br />')
      geo = incident.children.find {|child| child.name == "point"}.text

      incident_data = {}
      incident_data[:incident_name] = incident.children.css('title').first.text
      incident_data[:council_name]  = description_parts.find {|d| d =~ /^COUNCIL AREA/i}.split(/:\s*/).last
      incident_data[:location]      = description_parts.find {|d| d =~ /^LOCATION/i}.split(/:\s*/).last
      incident_data[:type]          = description_parts.find {|d| d =~ /^TYPE/i}.split(/:\s*/).last
      incident_data[:size]          = description_parts.find {|d| d =~ /^SIZE/i}.split(/:\s*/).last
      incident_data[:status]        = description_parts.find {|d| d =~ /^STATUS/i}.split(/:\s*/).last
      incident_data[:last_update]   = description_parts.find {|d| d =~ /^UPDATED/i}.split(/:\s*/).last
      incident_data[:agency]        = description_parts.find {|d| d =~ /^RESPONSIBLE AGENCY/i}.split(/:\s*/).last
      incident_data[:alert_level]   = description_parts.find {|d| d =~ /^ALERT LEVEL/i}.split(/:\s*/).last
      incident_data[:lat]           = geo.split.first
      incident_data[:long]          = geo.split.last
    
      @data[:incidents] << incident_data
    end

    @data[:meta][:modified] = doc.xpath("//pubDate").first.text
  end

end

# engage!

options = FetcherOptions.parse(ARGV)

f = RFSCurrentIncidentsFetcher.new(:output_directory => options.output_directory)
f.shebang!
