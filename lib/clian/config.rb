require 'yaml'
require 'pp'

module Clian
  module Config
    ################################################################
    # Syntax table manipulation
    class Syntax
      def initialize(syntax_config)
        @syntax_config = syntax_config
      end

      def keyword_symbols
        @syntax_config.keys
      end

      def keywords
        keyword_symbols.map {|sym| sym.to_s.upcase }
      end

      def keyword?(word)
        if word.is_a?(Symbol)
          keyword_symbols.member?(word)
        else
          # String
          keywords.member?(word)
        end
      end

      def instance_variable_name(word)
        return nil unless keyword?(word)
        return '@' + as_symbol(word).to_s
      end

      def item_class(word)
        return nil unless keyword?(word)
        @syntax_config[as_symbol(word)]
      end

      private
      def as_symbol(word)
        word.to_s.downcase.sub(/^@+/, "").to_sym
      end
    end # class Syntax

    ################################################################
    # Parse Key-Value object in YAML
    class Element

      def self.create_from_yaml_file(yaml_file)
        yaml_string = File.open(File.expand_path(yaml_file)).read
        return create_from_yaml_string(yaml_string, yaml_file)
      end

      def self.create_from_yaml_string(yaml_string, filename = nil)
        hash = YAML.load(yaml_string, filename) || {}
        return new(hash)
      end

      # class General < Clian::Config::Element
      #   define_syntax :client_id => String,
      #                 :client_secret => String,
      #                 :token_store => String,
      #                 :context_store => String,
      #                 :default_user => String
      # end # class General
      #
      def self.define_syntax(config)
        @syntax = Syntax.new(config)
        @syntax.keyword_symbols.each do |sym|
          attr_reader sym
        end
      end

      def self.syntax
        return @syntax
      end

      def initialize(hash = {})
        @original_hash = hash
        (hash || {}).each do |key, val|
          raise Clian::ConfigurationError, "config syntax error (#{key})" unless syntax.keyword?(key)
          var = syntax.instance_variable_name(key)
          obj = create_subnode(key, val)
          instance_variable_set(var, obj)
        end
      end

      attr_reader :original_hash

      def get_value(dot_separated_string = nil)
        if dot_separated_string.to_s == ""
          return original_hash
        end

        key, subkey = dot_separated_string.to_s.upcase.split(".", 2)
        subnode = get_subnode(key)

        if subnode.respond_to?(:get_value)
          return subnode.get_value(subkey)
        else
          return subnode.to_s
        end
      end

      def to_yaml
        return self.to_hash.to_yaml
      end

      def to_hash
        hash = {}
        syntax.keywords.each do |key|
          var = syntax.instance_variable_name(key)
          obj = instance_variable_get(var)
          obj = obj.respond_to?(:to_hash) ? obj.to_hash : obj.to_s
          hash[key] = obj
        end
        return hash
      end

      private
      def syntax
        self.class.syntax
      end

      def get_subnode(key)
        raise Clian::ConfigurationError, "Invalid key: #{key}" unless syntax.keyword?(key)
        return instance_variable_get(syntax.instance_variable_name(key))
      end

      def create_subnode(keyword, value)
        item_class = syntax.item_class(keyword)
        if item_class.is_a?(Array)
          return List.new(item_class.first, value)
        elsif item_class == String
          return value.to_s
        else
          return item_class.new(value)
        end
      end

    end # class Base

    ################################################################
    # Parse Array object in YAML
    class List < Element
      include Enumerable

      def initialize(item_class, array = [])
        @original_hash = array
        @configs = []
        (array || []).each do |value|
          item = item_class.new(value)
          @configs << item
        end
      end

      def [](key)
        @configs.find {|c| c.name == key}
      end

      alias_method :get_subnode, :[]

      def <<(conf)
        @configs << conf
      end

      def to_hash # XXX: actually, it returns a Array
        return @configs.map {|c| c.respond_to?(:to_hash) ? c.to_hash : c.to_s}
      end

      def each
        @configs.each do |conf|
          yield conf
        end
      end
    end # class List

    ################################################################
    # Syntax table manipulation
    class Toplevel < Element
      DEFAULT_DIR  = ENV["XDG_CONFIG_HOME"] || "~/.config"
      DEFAULT_FILE = "config.yml"

      def self.default_home(package_name)
        File.join(DEFAULT_DIR, package_name)
      end

      def self.default_path(package_name)
        File.join(default_home(package_name), DEFAULT_FILE)
      end

      def self.create_from_file(file_name = self.default_path)
        unless File.exists?(File.expand_path(file_name))
          raise ConfigurationError, "config file '#{file_name}' not found"
        end
        begin
          return create_from_yaml_file(file_name)
        rescue Psych::SyntaxError, Clian::ConfigurationError => e
          raise ConfigurationError, e.message
        end
      end
    end # class Toplevel
  end # class Config
end # module Clian
