require_relative './lib/populate_me/version'

Gem::Specification.new do |s| 

  s.name = 'populate-me'
  s.version = PopulateMe::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = "ALPHA !!! Populate Me is a relatively complete but simple CMS"
  s.description = "ALPHA !!! Populate Me is a relatively complete but simple CMS. It includes a Rack middleware for putting in your Rack stack, and a bespoke MongoDB ODM. But Populate Me is not really finished yet."
  s.author = "Mickael Riga"
  s.email = "mig@mypeplum.com"
  s.homepage = "https://github.com/mig-hub/populate-me"
  s.licenses = ['MIT']

  s.files = `git ls-files`.split("\n").sort
  s.test_files = s.files.select { |p| p =~ /^spec\/.*_spec.rb/ }
  s.require_path = './lib'
  s.add_dependency('sinatra')
  s.add_dependency('json')

end

