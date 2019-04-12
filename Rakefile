require 'bundler/gem_tasks'

Bundler.setup :default, :development

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
  t.warning = false
end

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :coverage do
  require 'simplecov'
  SimpleCov.start

  if ENV['CI'] == 'true' || ENV['CODECOV_TOKEN']
    require 'codecov'
    SimpleCov.formatter = SimpleCov::Formatter::Codecov
  end

  Rake::Task[:test].invoke
  Rake::Task[:spec].invoke
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)

task default: %i[coverage rubocop]
