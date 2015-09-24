require 'spec_helper'
require 'aws-sdk'

RSpec.describe SnapDeploy::Provider::AWS::S3 do
  subject(:cmd) { SnapDeploy::Provider::AWS::S3.new(nil, {}, {}) }

  before do
    AWS.stub!

    allow(ENV).to receive(:[]).with(anything).and_call_original
    allow(ENV).to receive(:[]).with('AWS_ACCESS_KEY_ID').and_return(SecureRandom.hex)
    allow(ENV).to receive(:[]).with('AWS_SECRET_ACCESS_KEY').and_return(SecureRandom.hex)
    allow(ENV).to receive(:[]).with('SNAP_PIPELINE_COUNTER').and_return('123')
    allow(ENV).to receive(:[]).with('SNAP_COMMIT_SHORT').and_return(short_revision)
    allow(ENV).to receive(:[]).with('SNAP_COMMIT').and_return(revision)
    allow(ENV).to receive(:[]).with('SNAP_STAGE_TRIGGERED_BY').and_return('john-doe')
  end

  example 'with local dir not specified' do
    expect(Dir).to receive(:chdir).with(Dir.pwd)
    cmd.run(['--bucket', 'example.com'])
  end

  example 'with local dir specified' do
    expect(Dir).to receive(:chdir).with('_build')
    cmd.run(['--bucket', 'example.com', '--local-dir', '_build'])
  end

  example "Sends MIME type" do
    expect(Dir).to receive(:glob).and_yield(__FILE__)
    expect_any_instance_of(AWS::S3::ObjectCollection).to receive(:create).with(anything(), anything(), hash_including(:content_type => 'application/x-ruby'))
    cmd.run(['--bucket', 'example.com'])
  end

  example "Sets Cache and Expiration" do
    expect(Dir).to receive(:glob).and_yield(__FILE__)
    expect_any_instance_of(AWS::S3::ObjectCollection).to receive(:create).with(anything(), anything(), hash_including(:cache_control => 'max-age=99999999', :expires => '2012-12-21 00:00:00 -0000'))
    cmd.run(['--bucket', 'example.com', '--cache-control', 'max-age=99999999', '--expires', '2012-12-21 00:00:00 -0000'])
  end

  example "Sets ACL" do
    expect(Dir).to receive(:glob).and_yield(__FILE__)
    expect_any_instance_of(AWS::S3::ObjectCollection).to receive(:create).with(anything(), anything(), hash_including(:acl => "public_read"))
    cmd.run(['--bucket', 'example.com', '--acl', 'public_read'])
  end

  example "when detect_encoding is set" do
    path = 'foo.js'
    expect(Dir).to receive(:glob).and_yield(path)
    expect(cmd).to receive(:'`').at_least(1).times.with("file #{path}").and_return('gzip compressed')
    allow(File).to receive(:read).with(path).and_return("")
    expect_any_instance_of(AWS::S3::ObjectCollection).to receive(:create).with(anything(), anything(), hash_including(:content_encoding => 'gzip'))
    cmd.run(['--bucket', 'example.com', '--detect-encoding'])
  end

  example "when dot_match is set" do
    expect(Dir).to receive(:glob).with("**/*", File::FNM_DOTMATCH)
    cmd.run(['--bucket', 'example.com', '--detect-encoding', '--include-dot-files'])
  end
end
