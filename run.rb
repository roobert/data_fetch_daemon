#!/usr/bin/env ruby

require 'awesome_print'
require 'active_support/core_ext/hash/indifferent_access'
require './fetch.rb'

config = HashWithIndifferentAccess.new(YAML.load_file('config.yaml'))

fetch = SwitchDataFetch.new(config)

fetch.configure
fetch.run

loop do; end
