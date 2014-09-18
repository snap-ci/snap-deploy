require 'spec_helper'
require 'aws-sdk'

RSpec.describe SnapDeploy::Provider::AWS::OpsWorks do

  before (:each) do
    AWS.stub!
    @client = double(:ops_works_client)
    @cmd = SnapDeploy::Provider::AWS::OpsWorks.new(nil, {}, {})
    expect(@cmd).to receive(:client).at_least(1).and_return(@client)

    expect(ENV).to receive(:[]).with('SNAP_PIPELINE_COUNTER').at_least(1).and_return('123')
    expect(ENV).to receive(:[]).with('SNAP_COMMIT_SHORT').at_least(1).and_return(short_revision)
    expect(ENV).to receive(:[]).with('SNAP_COMMIT').at_least(1).and_return(revision)
    expect(ENV).to receive(:[]).with('SNAP_STAGE_TRIGGERED_BY').at_least(1).and_return('john-doe')
  end

  example 'with migrate option not specified' do
    expect(@client).to receive(:describe_apps).with(app_ids: [app_id]).and_return({apps: [ops_works_app]})
    expect(@client).to receive(:update_app).with(app_id: app_id, app_source: {revision: revision})
    expect(@client).to receive(:create_deployment).with(
      stack_id: stack_id,
      app_id: app_id,
      command: {name: 'deploy'},
      comment: "Deploy build 123(rev #{short_revision}) via Snap CI by john-doe",
      custom_json: {"deploy"=>{"simplephpapp"=>{"migrate"=>false, "scm"=>{"revision"=>revision}}}}.to_json
    ).and_return({deployment_id: deployment_id})

    expect(@client).to receive(:describe_deployments).with({deployment_ids: [deployment_id]}).and_return(
      {deployments: [status: 'running']},
      {deployments: [status: 'successful']}
    )

    expect do
      @cmd.run(['--wait', '--app-id', app_id])
    end.to output(strip_heredoc(<<-EOF
                                Deployment created: #{deployment_id}
                                Deploying .
                                Deployment successful.
                                EOF
                                )).to_stdout
  end

  example 'with migrate option specifed' do
    expect(@client).to receive(:describe_apps).with(app_ids: [app_id]).and_return({apps: [ops_works_app]})
    expect(@client).to receive(:update_app).with(app_id: app_id, app_source: {revision: revision})
    expect(@client).to receive(:create_deployment).with(
      stack_id: stack_id,
      app_id: app_id,
      command: {name: 'deploy'},
      comment: "Deploy build 123(rev #{short_revision}) via Snap CI by john-doe",
      custom_json: {"deploy"=>{"simplephpapp"=>{"migrate"=>true, "scm"=>{"revision"=>revision}}}}.to_json
    ).and_return({deployment_id: deployment_id})

    expect(@client).to receive(:describe_deployments).with({deployment_ids: [deployment_id]}).and_return(
      {deployments: [status: 'running']},
      {deployments: [status: 'successful']}
    )
    expect do
      @cmd.run(['--wait', '--migrate', '--app-id', app_id])
    end.to output(strip_heredoc(<<-EOF
                                Deployment created: #{deployment_id}
                                Deploying .
                                Deployment successful.
                                EOF
                                )).to_stdout

  end

  example 'with migrate option forced off' do
    expect(@client).to receive(:describe_apps).with(app_ids: [app_id]).and_return({apps: [ops_works_app]})
    expect(@client).to receive(:update_app).with(app_id: app_id, app_source: {revision: revision})
    expect(@client).to receive(:create_deployment).with(
      stack_id: stack_id,
      app_id: app_id,
      command: {name: 'deploy'},
      comment: "Deploy build 123(rev #{short_revision}) via Snap CI by john-doe",
      custom_json: {"deploy"=>{"simplephpapp"=>{"migrate"=>false, "scm"=>{"revision"=>revision}}}}.to_json
    ).and_return({deployment_id: deployment_id})

    expect(@client).to receive(:describe_deployments).with({deployment_ids: [deployment_id]}).and_return(
      {deployments: [status: 'running']},
      {deployments: [status: 'successful']}
    )

    expect do
      @cmd.run(['--wait', '--no-migrate', '--app-id', app_id])
    end.to output(strip_heredoc(<<-EOF
                                Deployment created: #{deployment_id}
                                Deploying .
                                Deployment successful.
                                EOF
                                )).to_stdout
  end

  example 'when deployment fails' do
    expect(@client).to receive(:describe_apps).with(app_ids: [app_id]).and_return({apps: [ops_works_app]})
    expect(@client).to receive(:update_app).with(app_id: app_id, app_source: {revision: revision})
    expect(@client).to receive(:create_deployment).with(
      stack_id: stack_id,
      app_id: app_id,
      command: {name: 'deploy'},
      comment: "Deploy build 123(rev #{short_revision}) via Snap CI by john-doe",
      custom_json: {"deploy"=>{"simplephpapp"=>{"migrate"=>false, "scm"=>{"revision"=>revision}}}}.to_json
    ).and_return({deployment_id: deployment_id})

    expect(@client).to receive(:describe_deployments).with({deployment_ids: [deployment_id]}).and_return(
      {deployments: [status: 'running']},
      {deployments: [status: 'failed']}
    )

    expect do
      expect do
        @cmd.run(['--wait', '--no-migrate', '--app-id', app_id])
      end.to raise_error('Deployment failed.')
    end.to output(strip_heredoc(<<-EOF
                                Deployment created: #{deployment_id}
                                Deploying .
                                Deployment failed.
                                EOF
                                )).to_stdout
  end

  def app_id
    @app_id ||= SecureRandom.uuid
  end

  def deployment_id
    @deployment_id ||= SecureRandom.uuid
  end

  def revision
    @revision ||= SecureRandom.hex(32)
  end

  def stack_id
    @stack_id ||= SecureRandom.uuid
  end

  def short_revision
    revision[0..7]
  end

  def strip_heredoc(str)
    indent = str.scan(/^[ \t]*(?=\S)/).min.size || 0
    str.gsub(/^[ \t]{#{indent}}/, '')
  end


  def ops_works_app
    {shortname: 'simplephpapp', stack_id: stack_id}
  end
end
