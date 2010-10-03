require 'rubygems'
require 'rake'

task 'default' => ['spec']

desc 'install gems and setup environment'
task 'setup' do
  system("bundle install")
  Dir.mkdir("data") unless File.exists?("data")
end

