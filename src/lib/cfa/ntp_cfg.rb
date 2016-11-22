require "cfa/base_model"
require "cfa/augeas_parser"
require "cfa/matcher"

module CFA
  # Represents a Ntp configuration file.
  class NtpCfg < ::CFA::BaseModel
    # Configuration parser
    PARSER = ::CFA::AugeasParser.new("ntp.lns")
    # Path to configuration file
    PATH = "/etc/ntp.conf".freeze

    TYPES = ["server", "peer", "broadcast", "multicastclient", "manycastclient", "manycastserver"].freeze
    SERVER_VALUE_KEYS = ["minpoll", "maxpoll", "ttl", "version", "key"].freeze

    attributes(
      driftfile:   "driftfile",
      controlkey: "controlkey",
      requestkey: "requestkey",
      trustedkey: "trustedkey",
      keys:       "keys",
      logfile:    "logfile"
    )

    # Constructor
    #
    # @param file_handler [.read, .write, nil] an object able to read/write a string.
    def initialize(file_handler: nil)
      super(PARSER, PATH, file_handler: file_handler)
    end

    def parser
      PARSER
    end

    def server_entries(type = :all)
      if type == :all
        matcher = Matcher.new { |k, v| TYPES.any? { |s| k.include? s } }
      else
        matcher = Matcher.new { |k, v| k.include? type }
      end

      data.select(matcher).each_with_object([]) do |server, result|
        entry = server[:value]
        type = server[:key].gsub("[]","")

        s = { "type" => type }

        if entry.is_a? AugeasTreeValue
          s["address"] = entry.value
          s["options"] = ServerTree.parse(entry.tree)
        else
          s["address"] = entry
        end

        fudge = fudge_options(s["address"])

        s["fudge_options"] = fudge if fudge

        result << s
      end
    end

    def servers
      server_entries("server")
    end

    def server(type = "server", address)
      data.select(match_address(type, address))
    end

    def delete_server(type = "server", address)
    end

    def peers
      server_entries("peers")
    end

    def broadcasts
      matcher = Matcher.new { |k, v| k.include? "broadcast" }
      data.select(matcher) { |d| d[:value] }
    end

    def manycastclients
      matcher = Matcher.new { |k, v| k.include? "manycastclient" }
      data.select(matcher) { |d| d[:value] }
    end

    def fudge_entries
      matcher = Matcher.new { |k, v| k.include? "fudge" }
      data.select(matcher) { |d| d[:value] }
    end

    def fudge_options(address)
      fudge_entries.each do |e|
        if e[:value].value == address
          options = []
          e[:value].tree.data.each do |d|
            options << d[:key] if d[:key]
            options << d[:value] if d[:value]
          end

          return options.join(" ")
        end
      end

      nil
    end

    def restrictions
      server_entries("restrict")
    end

  private

    def match_address(type, address)
      Matcher.new { |k, v| k.include?(type) && v.value == address }
    end

  end


  class ServerTree
    def self.parse(tree)
      tree.data.each_with_object([]) do |option, result|
        next if option[:key].include? "comment"
        if option[:value] != nil
          result << "#{option[:key]}=#{option[:value]}"
        else
          result << option[:key]
        end
      end.join(" ")
    end

    def self.serialize(line)
      value = false
      last_key = nil
      line.split(" ").each_with_object(AugeasTree.new) do |option, tree|
        if value
          tree.add(last_key, option)
          value = false
        else
          if NtpCfg::SERVER_VALUE_KEYS.include? option
            value = true
            last_key = option
          else
            tree.add(option, nil)
          end
        end
      end
    end
  end
end
