class SnapDeploy::Provider::AWS < Clamp::Command

  require 'snap_deploy/provider/aws/ops_works'

  SnapDeploy::CLI.subcommand           'aws',      'Perform AWS deployments',     self
  SnapDeploy::Provider::AWS.subcommand 'opsworks', 'manage opsworks deployments', SnapDeploy::Provider::AWS::OpsWorks


  def execute
    help
  end

end
