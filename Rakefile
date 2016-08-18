require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |t|
  t.libs << "test"
  t.pattern = 'test/test_*.rb'
  unless ENV['TESTONLY'].nil?
    t.pattern = t.pattern.sub(/\*/, ENV['TESTONLY'])
  end
  t.options = '--pride'
  # t.warning = true
end

