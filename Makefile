version=$(shell ruby -r lib/fcshd/version -e 'print FCSHD::VERSION')

default: install

build:
	gem build fcshd.gemspec
install: build
	sudo gem install fcshd-${version}.gem
push: build
	gem push fcshd-${version}.gem
clean:
	rm *.gem
