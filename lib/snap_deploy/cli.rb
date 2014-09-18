require 'clamp'

module SnapDeploy

  class CLI < Clamp::Command

    module DefaultOptions
      def self.included(receiver)
        receiver.send :option, '--verbose', :flag, 'increase verbosity'
      end
    end

    include DefaultOptions

    def execute

    end
  end

end
