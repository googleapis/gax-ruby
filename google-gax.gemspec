# -*- ruby -*-
# encoding: utf-8
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'google/gax/version'

Gem::Specification.new do |s|
  s.name = 'google-gax'
  s.version = Google::Gax::VERSION
  s.authors = ['Google API Authors']
  s.email = 'googleapis-packages@google.com'
  s.homepage = 'https://github.com/googleapis/gax-ruby'
  s.summary = 'Aids the development of APIs for clients and servers based'
  s.summary += ' on GRPC and Google APIs conventions'
  s.description = 'Google API Extensions'
  s.files = %w( Rakefile )
  s.files += Dir.glob('lib/**/*')
  s.files += Dir.glob('bin/**/*')
  s.files += Dir.glob('spec/**/*')
  s.require_paths = %w(lib)
  s.platform = Gem::Platform::RUBY

  s.add_dependency 'googleauth', '~> 0.5.1'
  s.add_dependency 'grpc', '~> 0.13.1'

  s.add_development_dependency 'bundler', '~> 1.9'
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rubocop', '~> 0.32'
  s.add_development_dependency 'simplecov', '~> 0.9'
end
