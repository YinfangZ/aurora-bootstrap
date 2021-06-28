require "logger"
require "rollbar"
require "multi_json"

module AuroraBootstrapper
  class Logger
    Rollbar.configure do |config|
      if ENV.key?('ROLLBAR_TOKEN')
        rollbar_token = ENV.fetch( 'ROLLBAR_TOKEN')
      else  
        rollbar_token = File.open(ENV.fetch( 'AURORA_BOOTSTRAP_ROLLBAR_TOKEN_FILE' ), &:readline)
      end
      config.access_token = rollbar_token
    end

    ROLLBAR_SEVERITY = { error: :error,
                         fatal: :critical }

    
    def initialize( output )
      @logger = ::Logger.new output
    end

    [ :fatal, :error, :warn, :info, :debug ].each do |severity|
      define_method severity do | args, &block |
        message = args[ :message ]
        error   = args[ :error ]

        @logger.send severity, "#{message}: #{error}"
        rollbar severity, message: message, error: error
      end
    end

    def rollbar( severity, error:, message: )
      rollbar_severity = ROLLBAR_SEVERITY[ severity ]

      unless rollbar_severity.nil?
        Rollbar.send rollbar_severity, error, message
      end
    end
  end
end