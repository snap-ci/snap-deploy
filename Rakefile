require 'bundler/setup'
require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'tmpdir'

desc "Run units"
RSpec::Core::RakeTask.new("spec:unit") do |t|
  t.pattern = "spec/unit/**/*_spec.rb"
  t.rspec_opts = "--format documentation"
end

desc "Run integrations"
RSpec::Core::RakeTask.new("spec:integration") do |t|
  t.pattern = "spec/integration/**/*_spec.rb"
  t.rspec_opts = "--format documentation"
end

task :spec => ['spec:unit', 'spec:integration']
task :default => :spec
