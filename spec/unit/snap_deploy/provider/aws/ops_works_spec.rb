require 'spec_helper'
require 'aws-sdk'

RSpec.describe SnapDeploy::Provider::AWS::OpsWorks do
  subject(:cmd) { SnapDeploy::Provider::AWS::OpsWorks.new(nil, {}, {}) }

  let(:client) { double(:ops_works_client) }
  let(:app_id) { SecureRandom.uuid }
  let(:deployment_id) { SecureRandom.uuid }
  let(:stack_id) { SecureRandom.uuid }

  let(:ops_works_app) do
    {shortname: 'simplephpapp', stack_id: stack_id}
  end

  before do
    AWS.stub!

    allow(cmd).to receive(:client).and_return(client)

    allow(ENV).to receive(:[]).with('SNAP_PIPELINE_COUNTER').and_return('123')
    allow(ENV).to receive(:[]).with('SNAP_COMMIT_SHORT').and_return(short_revision)
    allow(ENV).to receive(:[]).with('SNAP_COMMIT').and_return(revision)
    allow(ENV).to receive(:[]).with('SNAP_STAGE_TRIGGERED_BY').and_return('john-doe')
  end

  example 'with migrate option not specified' do
    expect(client).to receive(:describe_apps).with(app_ids: [app_id]).and_return({apps: [ops_works_app]})
    expect(client).to receive(:create_deployment).with(
      stack_id: stack_id,
      app_id: app_id,
      command: {name: 'deploy'},
      comment: "Deploy build 123(rev #{short_revision}) via Snap CI by john-doe",
      custom_json: {"deploy"=>{"simplephpapp"=>{"migrate"=>true, "scm"=>{"revision"=>revision}}}}.to_json
    ).and_return({deployment_id: deployment_id})

    expect(client).to receive(:describe_deployments).with({deployment_ids: [deployment_id]}).and_return(
      {deployments: [status: 'running']},
      {deployments: [status: 'successful']}
    )

    expect do
      cmd.run(['--wait', '--app-id', app_id])
    end.to output(strip_heredoc(<<-EOF
                                Deployment created: #{deployment_id}
                                Deploying .
                                Deployment successful.
                                EOF
                                )).to_stdout
  end

  example 'with migrate option specified' do
    expect(client).to receive(:describe_apps).with(app_ids: [app_id]).and_return({apps: [ops_works_app]})
    expect(client).to receive(:create_deployment).with(
      stack_id: stack_id,
      app_id: app_id,
      command: {name: 'deploy'},
      comment: "Deploy build 123(rev #{short_revision}) via Snap CI by john-doe",
      custom_json: {"deploy"=>{"simplephpapp"=>{"migrate"=>true, "scm"=>{"revision"=>revision}}}}.to_json
    ).and_return({deployment_id: deployment_id})

    expect(client).to receive(:describe_deployments).with({deployment_ids: [deployment_id]}).and_return(
      {deployments: [status: 'running']},
      {deployments: [status: 'successful']}
    )
    expect do
      cmd.run(['--wait', '--migrate', '--app-id', app_id])
    end.to output(strip_heredoc(<<-EOF
                                Deployment created: #{deployment_id}
                                Deploying .
                                Deployment successful.
                                EOF
                                )).to_stdout

  end

  example 'with migrate option forced off' do
    expect(client).to receive(:describe_apps).with(app_ids: [app_id]).and_return({apps: [ops_works_app]})
    expect(client).to receive(:create_deployment).with(
      stack_id: stack_id,
      app_id: app_id,
      command: {name: 'deploy'},
      comment: "Deploy build 123(rev #{short_revision}) via Snap CI by john-doe",
      custom_json: {"deploy"=>{"simplephpapp"=>{"migrate"=>false, "scm"=>{"revision"=>revision}}}}.to_json
    ).and_return({deployment_id: deployment_id})

    expect(client).to receive(:describe_deployments).with({deployment_ids: [deployment_id]}).and_return(
      {deployments: [status: 'running']},
      {deployments: [status: 'successful']}
    )

    expect do
      cmd.run(['--wait', '--no-migrate', '--app-id', app_id])
    end.to output(strip_heredoc(<<-EOF
                                Deployment created: #{deployment_id}
                                Deploying .
                                Deployment successful.
                                EOF
                                )).to_stdout
  end

  example 'when deployment fails' do
    expect(client).to receive(:describe_apps).with(app_ids: [app_id]).and_return({apps: [ops_works_app]})
    expect(client).to receive(:create_deployment).with(
      stack_id: stack_id,
      app_id: app_id,
      command: {name: 'deploy'},
      comment: "Deploy build 123(rev #{short_revision}) via Snap CI by john-doe",
      custom_json: {"deploy"=>{"simplephpapp"=>{"migrate"=>false, "scm"=>{"revision"=>revision}}}}.to_json
    ).and_return({deployment_id: deployment_id})

    expect(client).to receive(:describe_deployments).with({deployment_ids: [deployment_id]}).and_return(
      {deployments: [status: 'running']},
      {deployments: [status: 'failed']}
    )

    expect do
      expect do
        cmd.run(['--wait', '--no-migrate', '--app-id', app_id])
      end.to raise_error('Deployment failed.')
    end.to output(strip_heredoc(<<-EOF
                                Deployment created: #{deployment_id}
                                Deploying .
                                Deployment failed.
                                EOF
                                )).to_stdout
  end
end
