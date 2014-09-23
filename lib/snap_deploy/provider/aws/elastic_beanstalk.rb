require 'timeout'
require 'json'
require 'rake'
require 'rake/file_utils_ext'

class SnapDeploy::Provider::AWS::ElasticBeanstalk < Clamp::Command

  option '--app-name',
    'APP_NAME',
    "Elastic Beanstalk application name",
    :required => true

  option '--env-name',
    'ENV_NAME' ,
    'Elastic Beanstalk environment name which will be updated',
    :required => true

  option '--bucket',
    'BUCKET_NAME',
    'S3 Bucket.',
    :required => true

  option '--region',
    "REGION",
    'EC2 Region.',
    :default => 'us-east-1'

  include SnapDeploy::CLI::DefaultOptions
  include SnapDeploy::Helpers
  include Rake::FileUtilsExt

  def execute
    require 'aws-sdk'
    setup_aws_auth
    create_bucket unless bucket_exists?
    zip_file = create_zip
    s3_object = upload(archive_name, zip_file)
    sleep 5 #s3 eventual consistency
    version = create_app_version(s3_object)
    update_app(version)
  end

  private
  def upload(key, file)
    obj = s3.buckets[bucket].objects[key]
    obj.write(Pathname.new(file))
    obj
  end

  def create_app_version(s3_object)
    options = {
      :application_name  => app_name,
      :version_label     => version_label,
      :description       => deploy_comment,
      :source_bundle     => {
        :s3_bucket => bucket,
        :s3_key    => s3_object.key
      },
      :auto_create_application => false
    }
    eb.create_application_version(options)
  end

  def update_app(version)
    options = {
      :environment_name  => env_name,
      :version_label     => version[:application_version][:version_label]
    }
    eb.update_environment(options)
  end

  def create_zip
    sh("git ls-files | zip -q -@ #{archive_name}", :verbose => !!verbose?)
    archive_name
  end

  def files_to_pack
    `git ls-files -z`.split("\x0")
  end

  def archive_name
    "#{version_label}.zip"
  end

  def version_label
    "snap-ci-#{pipeline_counter}-#{short_commit}"
  end

  def create_bucket
    s3.buckets.create(bucket)
  end

  def bucket_exists?
    s3.buckets.map(&:name).include?(bucket)
  end

  def eb
    @eb ||= AWS::ElasticBeanstalk.new.client
  end

  def s3
    @s3 ||= AWS::S3.new
  end

  def setup_aws_auth
    info "Logging in with Access Key: #{access_key_id[-4..-1].rjust(20, '*')}" unless @aws_configured
    AWS.config(
      access_key_id: access_key_id,
      region: region,
      secret_access_key: secret_access_key,
      logger: logger,
      log_formatter: AWS::Core::LogFormatter.colored
    )
    @aws_configured = true
  end

end
