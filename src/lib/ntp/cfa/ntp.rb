require "cfa/base_model"
require "cfa/augeas_parser"
require "cfa/matcher"

module Yast
  module Ntp
    module CFA
      # Represents a Ntp configuration file.
      class NtpConf < ::CFA::BaseModel
        # Configuration parser
        PARSER = ::CFA::AugeasParser.new("ntp.lns")
        # Path to configuration file
        PATH = "/etc/ntp.conf".freeze

        # Constructor
        #
        # @param file_handler [.read, .write, nil] an object able to read/write a string.
        def initialize(file_handler: nil)
          super(PARSER, PATH, file_handler: file_handler)
        end

        def sections
          data
        end
      end
    end
  end
end
