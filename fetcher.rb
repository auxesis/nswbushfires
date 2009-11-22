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
      incident_data[:council_name]  = find_part(description_parts, /^COUNCIL AREA/i)
      incident_data[:location]      = find_part(description_parts, /^LOCATION/i)
      incident_data[:type]          = find_part(description_parts, /^TYPE/i)
      incident_data[:size]          = find_part(description_parts, /^SIZE/i)
      incident_data[:status]        = find_part(description_parts, /^STATUS/i)
      incident_data[:last_update]   = find_part(description_parts, /^UPDATED/i)
      incident_data[:agency]        = find_part(description_parts, /^RESPONSIBLE AGENCY/i)
      incident_data[:alert_level]   = find_part(description_parts, /^ALERT LEVEL/i)
      incident_data[:lat]           = geo.split.first
      incident_data[:long]          = geo.split.last
    
      @data[:incidents] << incident_data
    end

    @data[:meta][:modified] = doc.xpath("//pubDate").first.text
  end

  private
  def find_part(parts, regex)
    part = parts.find {|d| d =~ regex}
    part ? part.split(/:\s*/).last.strip : nil
  end

end

# engage!

options = FetcherOptions.parse(ARGV)

f = RFSCurrentIncidentsFetcher.new(:output_directory => options.output_directory)
f.shebang!
