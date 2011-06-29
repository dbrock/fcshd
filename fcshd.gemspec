require "./lib/fcshd/version"
 
Gem::Specification.new do |gem|
  gem.name = "fcshd"
  gem.version = FCSHD::VERSION
  gem.author = "Daniel Brockman"
  gem.email = "daniel@gointeractive.se"
  gem.date = Time.now.utc.strftime("%Y-%m-%d")
  gem.homepage = "http://github.com/dbrock/fcshd"
  gem.summary = "Invoke the Flex Compiler Shell more... better."
  gem.files = `git ls-files`.lines.map(&:chomp)
  gem.executables = %w"fcshd fcshc"
end
