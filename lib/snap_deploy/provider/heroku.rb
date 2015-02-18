require 'rake'
require 'rake/file_utils_ext'

class SnapDeploy::Provider::Heroku < Clamp::Command

  SnapDeploy::CLI.subcommand 'heroku', 'deploy to heroku', self

  include SnapDeploy::CLI::DefaultOptions
  include SnapDeploy::Helpers
  include Rake::FileUtilsExt

  option '--app-name',
         'APP_NAME',
         'The name of the heroku app to deploy',
         :required => true

  option '--region',
         'REGION',
         'The name of the region',
         :default => 'us'

  option '--config-var',
         'KEY=VALUE',
         'The name of the config variables',
         :multivalued => true

  option '--buildpack-url',
         'BUILDPACK_URL',
         'The url of the heroku buildpack' do |url|
    require 'uri'
    if url =~ URI::regexp(%w(http https git))
      url
    else
      raise 'The buildpack url does not appear to be a url.'
    end
  end

  option '--stack-name',
         'STACK_NAME',
         'The name of the heroku stack',
         :default => 'cedar'

  option '--[no-]db-migrate',
         :flag,
         'If the db should be automatically migrated',
         :default => false

  def initialize(*args)
    super
    require 'snap_deploy/provider/heroku/api'
    require 'netrc'
    require 'ansi'
    require 'rendezvous'
    require 'tempfile'
  end

  def execute
    check_auth
    maybe_create_app
    setup_configuration
    git_push
    maybe_db_migrate
  end

  private
  SLEEP_INTERVAL = 0.1

  def maybe_db_migrate
    return unless db_migrate?

    log ANSI::Code.ansi("Attempting to run `#{migrate_command}`", :cyan)
    dyno = client.dyno.create(app_name, :command => %Q{#{migrate_command}; echo "Command exited with $?"}, :attach => true)

    reader, writer = IO.pipe

    thread = Thread.new do
      Rendezvous.start(:input => StringIO.new, :output => writer, :url => dyno['attach_url'])
    end

    begin
      exit_code = Timeout.timeout(300) do
        copy_to_stdout(thread, reader, writer)
      end

      unless exit_code
        error ANSI::Code.ansi('The remote command execution may have failed to return an exit code.', :red)
        exit(-1)
      end

      if exit_code != 0
        error ANSI::Code.ansi("The remote command exited with status #{exit_code}", :red)
        exit(exit_code)
      end
    rescue Timeout::Error
      raise Timeout::Error('There was no output generated in 300 seconds.')
    end

    thread.join(SLEEP_INTERVAL)
  end

  def copy_to_stdout(thread, reader, writer)
    writer.sync = true
    exit_code = nil
    tempfile = Tempfile.new('heroku-console-log')

    loop do
      nothing_to_read = if IO.select([reader], nil, nil, SLEEP_INTERVAL)
        contents = (reader.readpartial(4096) rescue nil) unless writer.closed?
        copy_output(contents, tempfile)
        !!contents
      else
        true
      end

      thread_dead = if thread.join(SLEEP_INTERVAL)
        writer.close unless writer.closed?
        true
      end

      break if thread_dead && nothing_to_read
    end

    # read everything one last time
    copy_output(reader.read, tempfile)

    # go back a bit in the console output to check on the exit status, aka poor man's tail(1)
    tempfile.seek([-tempfile.size, -32].max, IO::SEEK_END)

    if last_line = tempfile.readlines.last
      if match_data = last_line.match(/Command exited with (\d+)/)
        exit_code = match_data[1].to_i
      end
    end

    exit_code
  end

  def copy_output(contents, tempfile)
    return unless contents
    tempfile.print contents
    print contents
  end

  def migrate_command
    'rake db:migrate --trace'
  end

  def maybe_create_app
    print ANSI::Code.ansi('Checking to see if app already exists... ', :cyan)
    if app_exists?
      print ANSI::Code.ansi("OK\n", :green)
    else
      print ANSI::Code.ansi("No\n", :yellow)
      create_app
    end
  end

  def setup_configuration
    print ANSI::Code.ansi('Setting up config vars... ', :cyan)

    # config_var_list returns a dup
    configs = config_var_list

    configs << "BUILDPACK_URL=#{buildpack_url}" if buildpack_url

    if configs.empty?
      print ANSI::Code.ansi("No config vars specified\n", :green)
      return
    end

    existing_vars = client.config_var.info(app_name)

    vars = configs.inject({}) do |memo, var|
      key, value = var.split('=')
      if existing_vars[key] != value
        memo[key] = value
      end
      memo
    end

    if vars.empty?
      print ANSI::Code.ansi("No change required\n", :green)
    else
      print ANSI::Code.ansi("\nUpdating config vars #{vars.keys.join(', ')}... ", :cyan)
      client.config_var.update(app_name, vars)
      print ANSI::Code.ansi("OK\n", :green)
    end
  end

  def git_push
    print ANSI::Code.ansi("Pushing branch #{snap_branch} to heroku.\n", :cyan)
    cmd = "git push https://git.heroku.com/#{app_name}.git HEAD:refs/heads/master -f"
    puts "$ #{ANSI::Code.ansi(cmd, :green)}"
    sh(cmd) do |ok, res|
      raise "Could not push to heroku remote. The exit code was #{res.exitstatus}." unless ok
    end
  end

  def create_app
    print ANSI::Code.ansi('Creating app on heroku since it does not exist... ', :cyan)
    client.app.create({ name: app_name, region: region, stack: stack_name })
    print ANSI::Code.ansi("Done\n", :green)
  end

  def app_exists?
    !!client.app.info(app_name)
  rescue Excon::Errors::Unauthorized, Excon::Errors::Forbidden => e
    raise "You are not authorized to check if the app exists, perhaps you don't own that app?. The server returned status code #{e.response[:status]}."
  rescue Excon::Errors::NotFound => ignore
    false
  end

  def check_auth
    print ANSI::Code.ansi('Checking heroku credentials... ', :cyan)
    client.account.info
    print ANSI::Code.ansi("OK\n", :green)
  rescue Excon::Errors::HTTPStatusError => e
    raise "Could not connect to heroku to check your credentials. The server returned status code #{e.response[:status]}."
  end

  def client
    SnapDeploy::Provider::Heroku::API.connect_oauth(token)
  end

  def netrc
    @netrc ||= Netrc.read
  end

  def token
    @token ||= netrc['api.heroku.com'].password
  end

  def default_options
    {
    }
  end

end
