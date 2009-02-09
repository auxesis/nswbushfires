#!/usr/bin/env ruby
#

require 'rubygems'

Gem.path.clear
Gem.path << File.expand_path(File.join(File.dirname(__FILE__), 'gems'))

require 'yaml'
require 'twitter'

# config
config_filename = File.join(File.dirname(__FILE__), 'config.yaml')
unless File.exists?(config_filename)
  puts "You need to populate config.yaml!"
  puts "Please read the README."
  exit 1
end

@config = YAML::load(File.read('config.yaml'))

diff_only = ARGV.grep(/--diff-only/).size > 0 ? true : false

# engage!
@yaml = Dir.glob(File.expand_path(File.join(File.dirname(__FILE__), 'data', '*.yaml'))).sort

second = YAML::load(File.read(@yaml[-2]))
first  = YAML::load(File.read(@yaml[-1]))

if (first[:meta][:modified] != second[:meta][:modified]) && first[:meta][:processed?] != true
  diff = first[:incidents] - second[:incidents]
  diff.each do |i|
    next if i[:status] =~ /patrol/i
    puts "Update to #{i[:incident_name]}"
    msg = "Location: #{i[:location]}, Type: #{i[:type]}, Status: #{i[:status]}, Class: #{i[:class]}, Size: #{i[:size]} Ha, Updated: #{i[:last_update].split.last}"
    if diff_only
      puts " - not posting to twitter, but here's the message:"
      puts " - \"#{msg}\""
    else
      puts " - posting to Twitter"
      Twitter::Base.new(@config[:email], @config[:password]).update(msg)
    end
  end

else
  puts "No changes!"
end


unless diff_only 
  first[:meta][:processed?] = true
  File.open(@yaml[-1], 'w') do |f|
    f << first.to_yaml 
  end
end
