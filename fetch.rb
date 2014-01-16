#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'
require 'backports'

class SwitchDataFetch
  def initialize(config)
    @config   = config
    @switches = config[:switches]
    @fetchers = {}
  end

  def configure
    @fetchers[:mcollective]         = MCollective.new(@config)       if @config[:fetchers][:mcollective][:enable]
    @fetchers[:snmp]                = SNMP.new(@config)              if @config[:fetchers][:snmp][:enable]
    @fetchers[:switch_config]       = SwitchConfig.new(@config)      if @config[:fetchers][:switch_config][:enable]
    @fetchers[:switch_bridge_table] = SwitchBridgeTable.new(@config) if @config[:fetchers][:switch_bridge_table][:enable]
  end

  def run
    Thread.abort_on_exception = true

    @fetchers.each_value do |fetcher|
      Thread.new do
        loop do
          fetcher.fetch
          fetcher.write
          sleep 60
        end
      end
    end
  end

  class FetcherBase < SwitchDataFetch
    def initialize(config)
      super(config)
    end

    def fetch
      @data = @switches.each_with_object({}) { |switch, switches| switches[switch] = %x[#{@command.gsub(/\$SWITCH/, switch)}] }
    end

    def write
      @data.each { |switch, data| File.open(File.join(@output_dir, switch), "w") { |file| file.write data } }
    end
  end

  class MCollective < FetcherBase
    def initialize(config)
      super(config)

      @output_dir = @config[:fetchers][:mcollective][:output_dir]
      @command    = "sudo mco rpc network_interfaces get_hash -j --WF network=bunker_nat_network"
    end

    def fetch
      @data = %x[#{@command}]
    end

    def write
      File.open(File.join(@output_dir, 'config'), "w") { |file| file.write @data }
    end
  end

  class SNMP < FetcherBase
    def initialize
      @output_dir = @config[:fetchers][:snmp][:output_dir]
      @command    = "snmpwalk $SWITCH -c snmpantico -v2c"
    end
  end

  class SwitchConfig < FetcherBase
    def initialize(config)
      super(config)
      user        = @config[:fetchers][:switch_config][:auth][:user]
      password    = @config[:fetchers][:switch_config][:auth][:password]
      enable      = @config[:fetchers][:switch_config][:auth][:enable]
      @output_dir = @config[:fetchers][:switch_config][:output_dir]
      @command    = "./switch_exec/bin/switch_exec.expect $SWITCH #{user} #{password} '#{enable}' 'show running-config'"
    end
  end

  class SwitchBridgeTable < FetcherBase
    def initialize
      user        = @config[:fetchers][:switch_bridge_table][:auth][:user]
      password    = @config[:fetchers][:switch_bridge_table][:auth][:password]
      enable      = @config[:fetchers][:switch_bridge_table][:auth][:enable]
      @output_dir = @config[:fetchers][:switch_bridge_table][:output_dir]
      @command    = "./switch_exec/bin/switch_exec.expect $SWITCH #{user} #{password} '#{enable}' 'show bridge address-table'"
    end
  end
end
