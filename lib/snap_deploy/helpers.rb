module SnapDeploy
  module Helpers
    def log(message)
      puts message
    end

    def info(message)
      puts message
    end

    def error(message)
      puts message
    end

    def snap_commit
      ENV['SNAP_COMMIT'] or raise
    end

    def access_key_id
      ENV['AWS_ACCESS_KEY_ID'] or raise "AWS_ACCESS_KEY_ID is not defined"
    end

    def pipeline_counter
      ENV['SNAP_PIPELINE_COUNTER'] or raise
    end

    def short_commit
      ENV['SNAP_COMMIT_SHORT'] or raise
    end

    def manually_triggered_by
      ENV['SNAP_STAGE_TRIGGERED_BY']
    end

    def secret_access_key
      ENV['AWS_SECRET_ACCESS_KEY'] or raise "AWS_SECRET_ACCESS_KEY is not defined"
    end

    def logger
      @logger ||= Logger.new($stdout).tap do |logger|
        $stdout.sync = true
        logger.level = verbose? ? Logger::DEBUG : Logger::WARN
      end
    end

    def deploy_comment
      comment = "Deploy build #{pipeline_counter}(rev #{short_commit}) via Snap CI"
      comment << " by #{manually_triggered_by}" if manually_triggered_by
      comment
    end

    def encoding_for(path)
      file_cmd_output = `file #{path}`
      case file_cmd_output
      when /gzip compressed/
        'gzip'
      when /compress'd/
        'compress'
      end
    end
  end
end
