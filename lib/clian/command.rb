module Clian
  module Command

    dir = File.dirname(__FILE__) + "/command"

    autoload :Completions, "#{dir}/completions.rb"

  end # module Command
end # module Clian
