require 'rubygems'
require 'rake'

task 'default' => ['spec']

desc 'install gems and setup environment'
task 'setup' do
  system("gem bundle")
  Dir.mkdir("data") unless File.exists?("data")
end

