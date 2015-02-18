require 'spec_helper'

RSpec.describe SnapDeploy::Provider::Heroku do
  before(:each) do
    @cmd = SnapDeploy::Provider::Heroku.new(nil, {}, {})
    allow(@cmd).to receive(:token).and_return(token)
    ENV['SNAP_BRANCH'] = branch
  end

  describe 'execution behavior' do
    it 'should invoke methods in order' do
      expect(@cmd).to receive(:check_auth)
      expect(@cmd).to receive(:maybe_create_app)
      expect(@cmd).to receive(:setup_configuration)
      expect(@cmd).to receive(:git_push)
      expect(@cmd).to receive(:maybe_db_migrate)

      @cmd.run(['--app-name', 'foo'])
    end
  end

  describe 'check authentication' do
    it 'should raise error on auth failure' do
      stub_request(:get, 'https://api.heroku.com/account').
        with(:headers => { 'Authorization' => "Bearer #{token}" }).
        to_return(:status => 401, :body => {}.to_json, :headers => {})

      expect do
        @cmd.parse(['--app-name', 'foo'])
        @cmd.send :check_auth
      end.to raise_error(RuntimeError, 'Could not connect to heroku to check your credentials. The server returned status code 401.')
    end

    it 'should raise error when could not connect' do
      stub_request(:get, 'https://api.heroku.com/account').
        with(:headers => { 'Authorization' => "Bearer #{token}" }).
        to_raise(EOFError)

      expect do
        @cmd.parse(['--app-name', 'foo'])
        @cmd.send :check_auth
      end.to raise_error(EOFError)
    end
  end

  describe 'create app' do
    it 'should create app if one does not exist' do
      stub_request(:get, 'https://api.heroku.com/apps/foo').
        with(:headers => { 'Authorization' => "Bearer #{token}" }).
        to_return(:status => 404)

      stub_request(:post, 'https://api.heroku.com/apps').
        with(:headers => { 'Authorization' => "Bearer #{token}" })

      @cmd.parse(['--app-name', 'foo'])
      @cmd.send(:maybe_create_app)
    end

    [401, 403].each do |code|
      it "should raise error if we cannot verify if app exists (#{code})" do
        stub_request(:get, 'https://api.heroku.com/apps/foo').
          with(:headers => { 'Authorization' => "Bearer #{token}" }).
          to_return(:status => code)

        allow(@cmd).to receive(:setup_configuration)
        allow(@cmd).to receive(:git_push)

        expect do
          @cmd.parse(['--app-name', 'foo'])
          @cmd.send(:maybe_create_app)
        end.to raise_error(RuntimeError, "You are not authorized to check if the app exists, perhaps you don't own that app?. The server returned status code #{code}.")
      end
    end

    it 'should create app if one does not exist' do
      stub_request(:get, 'https://api.heroku.com/apps/foo').
        with(:headers => { 'Authorization' => "Bearer #{token}" }).
        to_return(:status => 404)

      stub_request(:post, 'https://api.heroku.com/apps').
        with(:headers => { 'Authorization' => "Bearer #{token}" })

      allow(@cmd).to receive(:setup_configuration)
      allow(@cmd).to receive(:git_push)

      @cmd.parse(['--app-name', 'foo', '--region', 'jhumri-taliya', '--stack-name', 'some-stack'])
      @cmd.send(:maybe_create_app)
      expect(a_request(:post, 'https://api.heroku.com/apps').
               with(:body => { name: 'foo', region: 'jhumri-taliya', stack: 'some-stack' }, :headers => { 'Authorization' => "Bearer #{token}" })).to have_been_made
    end
  end

  describe 'setup_configuration' do
    it 'should not send config vars if one is not specified' do
      @cmd.parse(['--app-name', 'foo'])
      @cmd.send(:setup_configuration)
    end

    it 'should not set any config vars if there is no delta' do
      stub_request(:get, 'https://api.heroku.com/apps/foo/config-vars').
        with(:headers => { 'Authorization' => "Bearer #{token}" }).
        to_return(:body => { 'FOO' => 'bar', 'BOO' => 'baz' }.to_json, :headers => { 'Content-Type' => 'application/json' })

      @cmd.parse(['--app-name', 'foo', '--config-var', 'FOO=bar', '--config-var', 'BOO=baz'])
      @cmd.send(:setup_configuration)

      expect(a_request(:any, "api.heroku.com")).not_to have_been_made
    end

    it 'should set any config vars if there is a delta' do
      stub_request(:get, 'https://api.heroku.com/apps/foo/config-vars').
        with(:headers => { 'Authorization' => "Bearer #{token}" }).
        to_return(:body => { 'FOO' => 'oldfoo', 'BOO' => 'oldboo' }.to_json, :headers => { 'Content-Type' => 'application/json' })

      stub_request(:patch, 'https://api.heroku.com/apps/foo/config-vars')

      @cmd.parse(['--app-name', 'foo', '--config-var', 'FOO=newfoo', '--config-var', 'BOO=oldboo', '--config-var', 'NEW_VAR=new_value'])
      @cmd.send(:setup_configuration)

      expect(a_request(:patch, "https://api.heroku.com/apps/foo/config-vars").
               with(:body => {'FOO' => 'newfoo', 'NEW_VAR' => 'new_value'}, :headers => { 'Authorization' => "Bearer #{token}"})).to have_been_made
    end

    it 'should set buildpack url if one is specified' do
      stub_request(:get, 'https://api.heroku.com/apps/foo/config-vars').
        with(:headers => { 'Authorization' => "Bearer #{token}" }).
        to_return(:body => { 'FOO' => 'oldfoo', 'BOO' => 'oldboo' }.to_json, :headers => { 'Content-Type' => 'application/json' })

      stub_request(:patch, 'https://api.heroku.com/apps/foo/config-vars')

      @cmd.parse(['--app-name', 'foo', '--config-var', 'FOO=newfoo', '--config-var', 'BOO=oldboo', '--config-var', 'NEW_VAR=new_value', '--buildpack-url', 'https://github.com/heroku/heroku-buildpack-ruby'])
      @cmd.send(:setup_configuration)

      expect(a_request(:patch, "https://api.heroku.com/apps/foo/config-vars").
               with(:body => {'FOO' => 'newfoo', 'NEW_VAR' => 'new_value', 'BUILDPACK_URL' => 'https://github.com/heroku/heroku-buildpack-ruby'}, :headers => { 'Authorization' => "Bearer #{token}"})).to have_been_made

    end
  end

  describe 'git push' do
    it 'should push to heroku via https' do
      @cmd.parse(['--app-name', 'foo'])
      expect(@cmd).to receive(:system).with('git push https://git.heroku.com/foo.git HEAD:refs/heads/master -f').and_return(true)
      @cmd.send(:git_push)
    end

    it 'should raise error when push fails' do
      @cmd.parse(['--app-name', 'foo'])
      expect(@cmd).to receive(:system).with('git push https://git.heroku.com/foo.git HEAD:refs/heads/master -f').and_return(system('exit -1'))
      expect do
        @cmd.send(:git_push)
      end.to raise_error(RuntimeError, 'Could not push to heroku remote. The exit code was 255.')
    end
  end

  def token
    @token ||= SecureRandom.hex
  end

  def branch
    @branch ||= SecureRandom.hex
  end

end
