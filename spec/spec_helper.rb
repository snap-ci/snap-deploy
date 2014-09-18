ENV['TEST'] = 'true'
require 'simplecov'
SimpleCov.start do
  add_filter '/bundle/ruby/'
  add_filter '/vendor/cache/'
end

require 'snap_deploy'

RSpec.configure do |config|
  config.tty                 = true
  config.expose_dsl_globally = false
  config.disable_monkey_patching!
end
