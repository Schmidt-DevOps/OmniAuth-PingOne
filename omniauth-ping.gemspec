require File.expand_path('../lib/omniauth-ping/version', __FILE__)

Gem::Specification.new do |gem|
    gem.name          = "omniauth-ping"
    gem.authors       = ["Rene Schmidt"]
    gem.email         = ["rene+_github@sdo.sh"]
    gem.description   = %q{OmniAuth strategy for PingOne.}
    gem.summary       = %q{OmniAuth strategy for PingOne.}
    gem.homepage      = "https://github.com/Schmidt-DevOps/OmniAuth-PingOne"
    gem.license       = "MIT"
    gem.version       = OmniAuth::Ping::VERSION

    gem.add_dependency 'omniauth', '~> 1.5'
    gem.add_dependency 'omniauth-oauth2', '>= 1.4.0', '< 2.0'
    gem.add_development_dependency 'rspec', '~> 3.5'
    gem.add_development_dependency 'rack-test'
    gem.add_development_dependency 'simplecov'
    gem.add_development_dependency 'webmock'
end
