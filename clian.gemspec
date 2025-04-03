# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
git = File.expand_path('../.git', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'clian/version'

Gem::Specification.new do |spec|
  spec.name          = "clian"
  spec.version       = Clian::VERSION
  spec.authors       = ["Yoshinari Nomura"]
  spec.email         = ["nom@quickhack.net"]

  spec.summary       = %q{Small set of Ruby classes helpful for creation of CLI tools.}
  spec.description   = %q{Small set of Ruby classes helpful for creation of CLI tools.}
  spec.homepage      = "https://github.com/yoshinari-nomura/clian"
  spec.license       = "MIT"

  spec.files         = if Dir.exist?(git)
                         `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
                       else
                         Dir['**/*']
                       end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "thor", '~> 1.3', '>= 1.3.2'
  spec.add_runtime_dependency "googleauth", '~> 1.14'
  spec.add_runtime_dependency "launchy", '~> 3.1', '>= 3.1.1'
  spec.add_runtime_dependency 'webrick', '~> 1.9', '>= 1.9.1'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
