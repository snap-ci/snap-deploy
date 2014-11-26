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

  option '--version',
    'VERSION',
    'Application Version'

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

    info "Deploying application version `#{version_label}' to application `#{app_name}' on environment `#{env_name}'"
    sleep 5 #s3 eventual consistency
    create_app_version unless application_exists?
    update_environment
  end

  private
  def upload(key, file)
    obj = s3.buckets[bucket].objects[key]
    obj.write(Pathname.new(file))
    obj
  end

  def application_exists?
    application_versions = eb.describe_application_versions({
      :application_name  => app_name,
      :version_labels    => [version_label]
    })[:application_versions]

    if application_versions.any?
      info "Application version already exists, will not create an application version or upload it to S3"
      true
    end
  end

  def create_app_version
    zip_file = create_zip
    s3_object = upload(archive_name, zip_file)
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

  def update_environment
    options = {
      :environment_name  => env_name,
      :version_label     => version_label
    }
    info "Updating environment `#{env_name}' with application version `#{version_label}'"
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
    version ? version : "snap-ci-#{pipeline_counter}-#{short_commit}"
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
    info "Logging in using Access Key ending with : #{access_key_id[-4..-1]}" unless @aws_configured
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
