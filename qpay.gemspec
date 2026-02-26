# frozen_string_literal: true

require_relative "lib/qpay/version"

Gem::Specification.new do |spec|
  spec.name = "qpay"
  spec.version = QPay::VERSION
  spec.authors = ["QPay Ruby SDK Authors"]
  spec.license = "MIT"

  spec.summary = "QPay V2 API Ruby SDK"
  spec.description = "Ruby SDK for QPay V2 payment gateway API with auto token management."
  spec.homepage = "https://github.com/qpay/qpay-ruby"

  spec.required_ruby_version = ">= 3.0.0"

  spec.files = Dir["lib/**/*.rb", "LICENSE", "qpay.gemspec"]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.0"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
end
