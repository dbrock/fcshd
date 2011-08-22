require "./lib/fcshd/version"
 
Gem::Specification.new do |gem|
  gem.name = "fcshd"
  gem.summary = "Usable CLI for the Adobe Flex compiler shell (fcsh)"
  gem.description = <<'^D'
By using a client-server architecture, we are able to make the Adobe Flex
compiler run fast while still being usable in command-line environments.
In practice, you start the `fcshd' server, and are then able to use the
client program `fcshc' as a faster and more usable replacement for `mxmlc'.
^D
  gem.version = FCSHD::VERSION
  gem.author = "Daniel Brockman"
  gem.email = "daniel@gointeractive.se"
  gem.date = Time.now.utc.strftime("%Y-%m-%d")
  gem.homepage = "http://github.com/dbrock/fcshd"
  gem.files = `git ls-files`.lines.map(&:chomp)
  gem.executables = %w"fcshd fcshc"
end
