require 'rubygems'
require 'yaml'
require 'pp'

config = '../config/config.yml'
result = YAML.load_file(config)
pp result
