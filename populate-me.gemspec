Gem::Specification.new do |s| 
  s.name = 'populate-me'
  s.version = '0.0.31'
  s.platform = Gem::Platform::RUBY
  s.summary = "ALPHA !!! Populate Me is relatively complete but simple CMS"
  s.description = "ALPHA !!! Populate Me is relatively complete but simple CMS. It includes a Rack middleware for putting in your Rack stack, and a bespoke MongoDB ODM. But Populate Me is not really finished yet."
  s.files = `git ls-files`.split("\n").sort
  s.require_path = './lib'
  s.author = "Mickael Riga"
  s.email = "mig@mypeplum.com"
  s.homepage = "https://github.com/mig-hub/populate-me"
  s.licenses = ['MIT']

  s.add_dependency 'rack-golem', '~> 0'
  s.add_dependency 'json', '~> 2.1'
  s.add_dependency 'mongo', '~> 2.0'

  s.add_development_dependency 'bundler', '~> 1.13'
  s.add_development_dependency 'bacon', '~> 1.2'
  s.add_development_dependency 'rack-test', '~> 0.6'
  s.add_development_dependency 'racksh', '~> 1.0'

end

