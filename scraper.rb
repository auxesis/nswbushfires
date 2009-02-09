#!/usr/bin/env ruby 
#

# deps
require 'rubygems'
Gem.path.clear
Gem.path << File.expand_path(File.join(File.dirname(__FILE__), 'gems'))

require 'nokogiri'
require 'open-uri'

# start
def get_page
  open("http://www.rfs.nsw.gov.au/dsp_content.cfm?cat_id=683").read
end

@data = {}
@data[:incidents] = []
@data[:meta] = {}

page = get_page()

doc = Nokogiri::HTML(page)
incidents = doc.search('table').first

incidents.search('tr').each_with_index do |tr, index|
  next if index == 0
  info = tr.search('td')

  incident_data = {}
  incident_data[:council_name]  = info[0].text.strip
  incident_data[:incident_name] = info[1].text.strip
  #incident_data[:location]      = info[2].text.strip.gsub(/(\s)*\r\n\n/, ', ').gsub(/(\w),(\w)/, "#{$1}, #{$2}")
  incident_data[:location]      = info[2].text.strip.gsub(/(\s)*\r\n\n/, ', ')
  incident_data[:class]         = info[3].text.strip
  incident_data[:type]          = info[4].text.strip
  incident_data[:size]          = info[5].text.strip
  incident_data[:status]        = info[6].text.strip
  incident_data[:last_update]   = info[7].text.strip

  @data[:incidents] << incident_data
end

@data[:meta][:modified] = doc.xpath("//meta[@name='DC.Date.modified']").first["content"]

filename = File.join(File.dirname(__FILE__), 'data', Time.now.strftime('%Y-%m-%dT%H:%M:%S%z.yaml'))

File.open(filename, 'w') do |f|
  f << @data.to_yaml
end
