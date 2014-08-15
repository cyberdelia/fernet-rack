# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["Timothée Peignier"]
  gem.email         = ["timothee.peignier@tryphon.org"]
  gem.description   = %q{Fernet rack authentication middleware}
  gem.summary       = %q{Easily authenticate }
  gem.homepage      = "http://rubygems.org/gems/fernet-rack"
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "fernet-rack"
  gem.require_paths = ["lib"]
  gem.version       = '0.7'

  gem.add_runtime_dependency "fernet", '~> 2.1'
  gem.add_development_dependency "minitest", '~> 5.4'
end
