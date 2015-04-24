ENV['RACK_ENV'] = 'test'

RSpec.configure do |config|

  config.include Rack::Test::Methods
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!
  config.warnings = true
  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end
  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed

end

RSpec::Matchers.define :be_json do
  match do |res|
    result = res.content_type=='application/json'
    result &&=res.status==@code unless @code.nil?
    result &&=res.status==@code unless @code.nil?
    result
  end
  chain :with_code do |code|
    @code = code
  end
  chain :and_ok do
    @code = 200
  end
end

RSpec::Matchers.define :be_for_view do |template|
  match do |json|
    result = json['template']==template
    result &&=json['page_title']==@title unless @title.nil?
    result
  end
  chain :with_title do |title|
    @title = title
  end
end

