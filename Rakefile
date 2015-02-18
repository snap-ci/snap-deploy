require 'bundler/setup'
require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'tmpdir'

desc 'build heroku api'
task "build-heroku-api" do
  sh('curl --silent --fail https://api.heroku.com/schema -H "Accept: application/vnd.heroku+json; version=3" > /tmp/heroku-schema.json')
  sh('bundle exec heroics-generate -H "Accept: application/vnd.heroku+json; version=3" SnapDeploy::Provider::Heroku::API /tmp/heroku-schema.json https://api.heroku.com > lib/snap_deploy/provider/heroku/api.rb')
end

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
