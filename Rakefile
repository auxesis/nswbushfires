require 'rubygems'
require 'rake'

task 'default' => ['spec']

desc 'install gems'
task 'setup' do
  deps = ["twitter", "nokogiri"]
  deps.each do |dep|
    system("gem install #{dep} -i gems")
  end
end

