ENV['TEST'] = 'true'
require 'simplecov'
SimpleCov.start do
  add_filter '/bundle/ruby/'
  add_filter '/vendor/cache/'
end

require 'snap_deploy'
require 'webmock/rspec'

module SpecHelper
  def revision
    @revision ||= SecureRandom.hex(32)
  end

  def short_revision
    revision[0..7]
  end

  def strip_heredoc(str)
    indent = str.scan(/^[ \t]*(?=\S)/).min.size || 0
    str.gsub(/^[ \t]{#{indent}}/, '')
  end
end

RSpec.configure do |config|
  config.include SpecHelper
  config.tty                 = true
  config.expose_dsl_globally = false
  config.disable_monkey_patching!

  config.before(:each) do
    @original_env = ENV.to_h.dup
    ENV.clear
  end

  config.after(:each) do
    ENV.replace(@original_env)
  end

end
