# -*- ruby -*-
# encoding: utf-8

source 'https://rubygems.org/'

gemspec

if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.3')
  # WORKAROUND: googleauth 0.8.0 and newer are using ruby 2.3 syntax
  # but the gem isn't specifying a minimum ruby.
  # Downgrade the gem when running on 2.2.
  gem 'googleauth', '~> 0.7.0'
  # WORKAROUND: google-protobuf 3.7.0 and newer dropped ruby 2.2 and older,
  # but the gem isn't specifying a minimum ruby for the pre-compiled versions.
  # Downgrade the gem when running on 2.2.
  gem 'google-protobuf', '~> 3.6.0'
end
