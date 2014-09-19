class SnapDeploy::Provider::AWS < Clamp::Command

  require 'snap_deploy/provider/aws/ops_works'
  require 'snap_deploy/provider/aws/s3'

  SnapDeploy::CLI.subcommand           'aws',      'Perform AWS deployments',     self
  SnapDeploy::Provider::AWS.subcommand 'opsworks', 'manage opsworks deployments', SnapDeploy::Provider::AWS::OpsWorks
  SnapDeploy::Provider::AWS.subcommand 's3',       'manage s3 deployments',       SnapDeploy::Provider::AWS::S3


  def execute
    help
  end

end
