# encoding: UTF-8
lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'spree_stock_locking/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_stock_locking'
  s.version     = SpreeStockLocking.version
  s.summary     = 'A Spree extension that implements stock movement locking with Redis::Lock'
  s.description = ''
  s.required_ruby_version = '>= 2.5'

  s.author    = 'ROUTE06'
  s.email     = 'development+rubygems@route06.co.jp'
  s.homepage  = 'https://github.com/route06/spree_stock_locking'
  s.license   = 'BSD-3-Clause'

  s.files       = `git ls-files`.split("\n").reject { |f| f.match(/^spec/) && !f.match(/^spec\/fixtures/) }
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree', '>= 4.3.0'
  s.add_dependency 'spree_auth_devise'
  s.add_dependency 'spree_backend'
  s.add_dependency 'spree_extension'

  s.add_dependency 'redis-objects'

  s.add_development_dependency 'actionmailer' # needed for running rspec
  s.add_development_dependency 'spree_dev_tools'
end
