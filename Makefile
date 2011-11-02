build:
	gem build fcshd.gemspec
clean:
	rm *.gem
push: build
	gem push fcshd-$(shell ruby -r lib/fcshd/version -e 'print FCSHD::VERSION').gem
