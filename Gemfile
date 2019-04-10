# -*- ruby -*-
# encoding: utf-8

source 'https://rubygems.org/'

gemspec

if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.3')
  # WORKAROUND: google-protobuf 3.7.0 and newer dropped ruby 2.2 and older,
  # but the gem isn't specifying a minimum ruby for the pre-compiled versions.
  # Downgrade the gem when running on 2.2.
  gem 'google-protobuf', '~> 3.6.0'
end
