require File.join(File.dirname(__FILE__), 'lib/populate_me/version')

Gem::Specification.new do |s| 

  s.authors = ["Mickael Riga"]
  s.email = ["mig@mypeplum.com"]
  s.homepage = "https://github.com/mig-hub/populate-me"
  s.licenses = ['MIT']

  s.name = 'populate-me'
  s.version = PopulateMe::VERSION
  s.summary = "PopulateMe is an admin system for web applications."
  s.description = "PopulateMe is an admin system for managing structured content of web applications. It is built on top of the Sinatra framework, but can be used along any framework using Rack."

  s.platform = Gem::Platform::RUBY
  s.files = `git ls-files`.split("\n").sort
  s.test_files = s.files.grep(/^test\//)
  s.require_paths = ['lib']

  s.add_dependency 'web-utils', '~> 0'
  s.add_dependency 'sinatra', '~> 3'
  s.add_dependency 'json', '~> 2.1'

  s.add_development_dependency 'bundler', '>= 2.2.10'
  s.add_development_dependency 'minitest', '~> 5.8'
  s.add_development_dependency 'rack-test', '~> 2'
  s.add_development_dependency 'rack-cerberus', '~> 1.0'
  s.add_development_dependency 'mongo', '~> 2.18'
  s.add_development_dependency 'rack-grid-serve', '~> 0.0.8'
  s.add_development_dependency 'aws-sdk-s3', '~> 1'
  s.add_development_dependency 'racksh', '~> 1.0'
  s.add_development_dependency 'rake', '>= 12.3.3'
end

