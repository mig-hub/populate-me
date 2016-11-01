require_relative 'lib/populate_me/version'

Gem::Specification.new do |s| 

  s.authors = ["Mickael Riga"]
  s.email = ["mig@mypeplum.com"]
  s.homepage = "https://github.com/mig-hub/populate-me"
  s.licenses = ['MIT']

  s.name = 'populate-me'
  s.version = PopulateMe::VERSION
  s.summary = "ALPHA !!! PopulateMe is an admin system for web applications."
  s.description = "ALPHA !!! PopulateMe is an admin system for web applications. It is built on top of the Sinatra framework, but can be used with any framework using Rack."

  s.platform = Gem::Platform::RUBY
  s.files = `git ls-files`.split("\n").sort
  s.test_files = s.files.grep(/^test\//)
  s.require_paths = ['lib']
  s.add_dependency('web-utils')
  s.add_dependency('sinatra')
  s.add_dependency('json')

end

