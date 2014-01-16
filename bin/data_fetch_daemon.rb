#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '../lib'))

require 'rubygems'
require 'backports'
require 'yaml'
require 'awesome_print'
require 'active_support/core_ext/hash/indifferent_access'
require 'data_fetch_daemon'

config = HashWithIndifferentAccess.new(YAML.load_file(File.join(File.dirname(__FILE__), '../config.yaml')))
fetch  = DataFetchDaemon.new(config)

fetch.configure
fetch.run

loop do; end
