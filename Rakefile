require "./lib/fcshd/version"

version = FCSHD::VERSION

gem = "fcshd-#{version}.gem"
gemspec = "fcshd.gemspec"

task :default => :install

task :install => gem do
  sh "sudo gem install #{gem}"
end

file gem do
  sh "gem build #{gemspec}"
end

task :push => gem do
  sh "gem push #{gem}"
end

require "rake/clean"

CLEAN << "*.gem"
