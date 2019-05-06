require "bundler/gem_tasks"

Bundler.setup :default, :development

require "rake/testtask"
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = false
end

require "rubocop/rake_task"
RuboCop::RakeTask.new :rubocop

task default: [:test, :rubocop]
