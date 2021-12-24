Capybara.server_host = Socket.ip_address_list.detect {|addr| addr.ipv4_private?}&.ip_address || 'localhost'
Capybara.server_port = 3001
Capybara.default_max_wait_time = 4

RSpec.configure do |config|
  config.before(:each, type: :system) do
    options = {}
    if ENV["SELENIUM_REMOTE_URL"].present?
      options[:url] = ENV['SELENIUM_REMOTE_URL']
      options[:browser] = :remote
    end

    driven_by :selenium, using: :headless_chrome, screen_size: [1920, 1080], options: options do |opts|
      opts.add_argument('no-sandbox')
      opts.add_argument('disable-dev-shm-usage')
      opts.add_argument('disable-popup-blocking')
      opts.add_argument('disable-gpu')
      opts.add_argument('--enable-features=NetworkService,NetworkServiceInProcess')
      opts.add_argument('--disable-features=VizDisplayCompositor')
    end
  end
  Capybara.app_host = "http://#{Capybara.server_host}:#{Capybara.server_port}"
  config.include CapybaraSelect2
  config.include CapybaraSelect2::Helpers
end
