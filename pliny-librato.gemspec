# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pliny/librato/version'

Gem::Specification.new do |spec|
  spec.name          = "pliny-librato"
  spec.version       = Pliny::Librato::VERSION
  spec.authors       = ["Andrew Appleton", "Josh W Lewis"]
  spec.email         = "andysapple@gmail.com"

  spec.summary       = %q{A Librato metrics reporter backend for pliny}
  spec.homepage      = "https://github.com/appleton/pliny-librato"

  spec.licenses      = ["MIT"]
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "librato-metrics", "~> 2.0"
  spec.add_dependency "pliny",           ">= 0.20.0"

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "pry", "~> 0.10"
  spec.add_development_dependency "pry-byebug", "~> 3.4"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.3"
  spec.add_development_dependency "timecop", "~> 0.8.1"
end
