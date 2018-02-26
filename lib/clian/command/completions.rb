module Clian
  module Command
    class Completions

      def initialize(help, global_options, arguments, &custom_completion_proc)
        @help, @global_options, @arguments = help, global_options, arguments
        @custom_completion_proc = custom_completion_proc
        command_name = arguments.find {|arg| arg !~ /^-/}

        print completion_header
        print possible_subcommands(help)

        if command_name and help[command_name]
          print arguments_spec(help[command_name])
          print options_spec(help[command_name].options)
        end
        print options_spec(global_options)
      end

      private

      def completion_header
        "_arguments\n"
      end

      def possible_subcommands(help, position = 1)
        str = "#{position}:Possible commands\\::(("
        help.each_value do |cmd|
          next if cmd.name == "completions"
          str << " #{cmd.name}\\:"
          str << cmd.description.gsub(/([()\s"';&|#\\])/, '\\\\\1')
        end
        str << "))\n"
      end

      def arguments_spec(command, position = 2)
        str = ""
        command.usage.split(/\s+/)[1..-1].each do |arg|
          pos = position
          optional = ""

          if /^\[(.*)\]/ =~ arg
            arg = $1
            optional = ":"
          end

          multi = ""
          if /(.*)\.\.\.$/ =~ arg
            arg = $1
            pos = "*"
            multi = ":"
          end

          str << "#{pos}:#{optional}#{arg}\\::#{possible_values(arg)}#{multi}\n"
          position += 1
        end
        return str
      end

      def options_spec(options)
        str = ""

        options.each do |name, opt|
          name = name.to_s.gsub("_", "-")

          if opt.type == :boolean
            str << "(--#{name})--#{name}[#{opt.description}]\n"
          else
            str << "(--#{name})--#{name}=-[#{opt.description}]:#{opt.banner}:#{possible_values_for_opt(opt)}\n"
          end
        end
        return str
      end

      def possible_values(banner)
        if @custom_completion_proc
          @custom_completion_proc.call(banner)
        end || default_possible_values(banner)
      end

      def possible_values_for_opt(option)
        return "(" + option.enum.join(" ") + ")" if option.enum
        return possible_values(option.banner)
      end

      def default_possible_values(banner)
        case banner
        when /^(FILE|CONF)/
          "_files"
        when /^DIR/
          "_files -/"
        when "COMMAND"
          possible_commands
        when /^NUM/
          "_guard '[0-9]#' 'Number'"
        else
          "{_message '#{banner} is required'}"
        end
      end

    end # class Completions
  end # module Command
end # module Clian
