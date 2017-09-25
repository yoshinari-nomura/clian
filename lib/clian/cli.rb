require "thor"

module Clian
  class Cli < Thor
    ################################################################
    # config files

    DEFAULT_CONFIG_HOME = File.join((ENV["XDG_CONFIG_HOME"] ||
                                     "~/.config"), basename)
    DEFAULT_CONFIG_FILE = "config.yml"
    DEFAULT_CONFIG_PATH = File.join(DEFAULT_CONFIG_HOME, DEFAULT_CONFIG_FILE)
    NAMED_OPTIONS = {}

    def self.default_config_home ; DEFAULT_CONFIG_HOME; end
    def self.default_config_path ; DEFAULT_CONFIG_PATH; end

    ################################################################
    # rbenv support:
    # If this file is a symlink, and bound to a specific ruby
    # version via rbenv (indicated by RBENV_VERSION),
    # I want to resolve the symlink and re-exec
    # the original executable respecting the .ruby_version
    # which should indicate the right version.
    #
    def self.bundler_rbenv_setup(command_path)
      if File.symlink?(command_path) and ENV["RBENV_VERSION"]
        ENV["RBENV_VERSION"] = nil
        shims_path = File.expand_path("shims", ENV["RBENV_ROOT"])
        ENV["PATH"] = shims_path + ":" + ENV["PATH"]
        exec(File.readlink(command_path), *ARGV)
      end

      gemfile = File.expand_path("../../Gemfile", command_path)

      if File.exists?(gemfile + ".lock")
        ENV["BUNDLE_GEMFILE"] = gemfile
        require "bundler/setup"
      end
    end

    ################################################################
    # register preset options

    def self.named_option(name, options)
      ::Clian::Cli::NAMED_OPTIONS[name] = options
    end

    def self.expand_option(*names)
      expand_named_option(:method, *names)
    end

    def self.expand_class_option(*names)
      expand_named_option(:class, *names)
    end

    def self.expand_named_option(type, *names)
      names.each do |name|
        options = ::Clian::Cli::NAMED_OPTIONS[name]
        if type == :class
          class_option name, options
        else
          method_option name, options
        end
      end
    end
    private_class_method :expand_named_option

    # default options
    named_option :debug,   :desc => "Set debug flag", :type => :boolean
    named_option :profile, :desc => "Set profiler flag", :type => :boolean
    named_option :config,  :desc => "Set config path (default: #{DEFAULT_CONFIG_PATH})", :banner => "FILE"
    named_option :dry_run, :desc => "Perform a trial run with no changes made", :type => :boolean

    ################################################################
    # command name mappings

    map ["--version", "-v"] => :version

    map ["--help", "-h"] => :help

    default_command :help

    ################################################################
    # Command: help
    ################################################################

    desc "help [COMMAND]", "Describe available commands or one specific command"

    def help(command = nil)
      super(command)
    end

    ################################################################
    # Command: version
    ################################################################
    desc "version", "Show version"

    def version
      puts Clian::VERSION
    end

    ################################################################
    # Command: completions
    ################################################################
    check_unknown_options! :except => :completions

    desc "completions [COMMAND]", "List available commands or options for COMMAND", :hide => true

    long_desc <<-LONGDESC
      List available commands or options for COMMAND
      This is supposed to be a zsh compsys helper"
    LONGDESC

    def completions(*command)
      help = self.class.commands
      global_options = self.class.class_options
      Clian::Command::Completions.new(help, global_options, command, config)
    end

    ################################################################
    # Command: config
    ################################################################
    desc "configuration", "Show current configuration in various formats."

    def configuration(name = nil)
      puts Clian::Converter::Emacs.new.to_emacs(config.get_value(name))
    end

    ################################################################
    # add some hooks to Thor

    no_commands do
      def invoke_command(command, *args)
        setup_global_options(command, *args)
        result = super
        teardown
        result
      end
    end

    ################################################################
    # private

    private

    def exit_on_error(&block)
      begin
        yield if block_given?
      rescue Clian::ConfigurationError => e
        STDERR.print "ERROR: #{e.message}.\n"
        exit 1
      end
    end

    attr_reader :builder, :config, :calendar

    def setup_global_options(command, *args)
      exit_on_error do
        # @config = Clian::Config.create_from_file(options[:config] || DEFAULT_CONFIG_PATH)
        # @builder ||= Clian::Builder.new(@config)
        # if @config.general.tzid
        #  Clian.default_tzid = @config.general.tzid
        #end

        # calname  = options[:calendar] || @config.calendars.first.name
        # @config.general.repository = options[:repository] if options[:repository]

        # self.class.calendar ||= builder.calendar(calname)
        # @calendar = self.class.calendar
      end

      # load_plugins

      # if options[:profile]
      #   require 'profiler'
      #   Profiler__.start_profile
      # end
      # if options[:debug]
      #   require "pp"
      #   $MHC_DEBUG = true
      #   $MHC_DEBUG_FOR_DEVELOPER = true if ENV["MHC_DEBUG_FOR_DEVELOPER"]
      # end
    end

    def load_plugins
      config_path = options[:config] || DEFAULT_CONFIG_PATH
      plugin_dir  = File.dirname(config_path)

      Dir.glob(File.expand_path("plugins/*.rb", plugin_dir)) do |rb|
        require rb
      end
    end

    def teardown
      if options[:profile]
        Profiler__.print_profile($stdout)
      end
    end

  end # class Cli
end # module Clian
