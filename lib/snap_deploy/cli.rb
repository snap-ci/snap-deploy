require 'clamp'

module SnapDeploy

  class CLI < Clamp::Command

    module DefaultOptions
      def self.included(receiver)
        receiver.send :option, '--verbose', :flag, 'increase verbosity'
        receiver.send :option, '--version', :flag, 'display the version' do
          puts "Snap Deploy v#{SnapDeploy::VERSION}"
          exit(0)
        end
      end
    end

    include DefaultOptions

    def execute

    end
  end

end
