RSpec.configure do |config|
  config.before(:each, type: :controller) do
    @request.env['devise.mapping'] = Devise.mappings[:spree_user]
  end

  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :system

  config.include Warden::Test::Helpers
  config.before :suite do
    Warden.test_mode!
  end
end
