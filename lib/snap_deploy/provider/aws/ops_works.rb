require 'timeout'
require 'json'

class SnapDeploy::Provider::AWS::OpsWorks < Clamp::Command

  option '--app-id', "APP_ID", "The application ID", :required => true
  option '--[no-]wait',    :flag, 'Wait until (or not) deployed and return the deployment status.', :default => true
  option '--[no-]migrate', :flag, 'If the db should be automatically migrated.', :default => true

  include SnapDeploy::CLI::DefaultOptions
  include SnapDeploy::Helpers

  def execute
    require 'aws-sdk'
    Timeout::timeout(600) do
      update_deployment
      create_deployment
    end
  rescue ::Timeout::Error
    error 'Timeout: Could not finish deployment in 10 minutes.'
  end

  private
  def update_deployment
    client.update_app(
      app_id: app_id,
      app_source: {revision: snap_commit}
    )
  end

  def create_deployment
    data = client.create_deployment(
      stack_id: ops_works_app[:stack_id],
      app_id:   app_id,
      command:  {name: 'deploy'},
      comment:  deploy_comment,
      custom_json: custom_json.to_json
    )
    info "Deployment created: #{data[:deployment_id]}"
    return unless wait?
    print "Deploying "
    deployment = wait_until_deployed(data[:deployment_id])
    print "\n"
    if deployment[:status] == 'successful'
      info "Deployment successful."
    else
      error "Deployment failed."
      raise "Deployment failed."
    end
  end

  def custom_json
    {
      deploy: {
        ops_works_app[:shortname] => {
          migrate: !!migrate?,
          scm: {
            revision: snap_commit
          }
        }
      }
    }
  end

  def wait_until_deployed(deployment_id)
    deployment = nil
    loop do
      result = client.describe_deployments(deployment_ids: [deployment_id])
      deployment = result[:deployments].first
      break unless deployment[:status] == "running"
      print "."
      sleep 5
    end
    deployment
  end

  def ops_works_app
    @ops_works_app ||= fetch_ops_works_app
  end

  def fetch_ops_works_app
    data = client.describe_apps(app_ids: [app_id])
    unless data[:apps] && data[:apps].count == 1
      raise "App #{app_id} not found."
    end
    data[:apps].first
  end

  def deploy_comment
    comment = "Deploy build #{pipeline_counter}(rev #{short_commit}) via Snap CI"
    comment << " by #{manually_triggered_by}" if manually_triggered_by
    comment
  end

  def client
    @client ||= begin
      AWS.config(access_key_id: access_key_id, secret_access_key: secret_access_key, logger: logger, log_formatter: AWS::Core::LogFormatter.colored)
      info "Logging in with Access Key: #{access_key_id[-4..-1].rjust(20, '*')}"
      AWS::OpsWorks.new.client
    end
  end

end
