require File.expand_path('../lib/omniauth-ping-one/version', __FILE__)

Gem::Specification.new do |gem|
    gem.name          = "omniauth-ping-one"
    gem.authors       = ["Rene Schmidt"]
    gem.email         = ["rene+_github@sdo.sh"]
    gem.description   = %q{OmniAuth strategy for PingOne.}
    gem.summary       = %q{OmniAuth strategy for PingOne.}
    gem.homepage      = "https://github.com/Schmidt-DevOps/OmniAuth-PingOne"
    gem.license       = "MIT"
    gem.version       = OmniAuth::PingOne::VERSION

    gem.add_dependency 'omniauth', '~> 2.0.0'
    gem.add_dependency 'omniauth-oauth2', '~> 1.7.0'
    gem.add_development_dependency 'rspec', '~> 3.5'
    gem.add_development_dependency 'rack-test'
    gem.add_development_dependency 'simplecov'
    gem.add_development_dependency 'webmock'
end
