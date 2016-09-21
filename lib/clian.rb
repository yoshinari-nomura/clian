require "clian/version"

module Clian
  class ConfigurationError < StandardError ; end

  dir = File.dirname(__FILE__) + "/clian"

  autoload :Authorizer,           "#{dir}/authorizer.rb"
  autoload :Cli,                  "#{dir}/cli.rb"
  autoload :Config,               "#{dir}/config.rb"
  autoload :VERSION,              "#{dir}/version.rb"
end
