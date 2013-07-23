require "test/unit"
require "watir-webdriver"
require "test_helper"
require "#{Rails.root}/db/seeds.rb"
require "net/http"
require "uri"

class Navigation < ActionController::IntegrationTest
  def setup
    if !!(RbConfig::CONFIG['host_os'] =~ /mingw|mswin32|cygwin/)
      @browser_types = [:firefox,:chrome,:ie]
    elsif ENV['HEADLESS']
      @browser_types = [:firefox]
    else
      @browser_types = [:firefox,:chrome]
    end

    if ENV['HEADLESS']
      require "headless"
      @headless = Headless.new
      @headless.start
    end

    @browser = Watir::Browser.new(@browser_types[rand(@browser_types.length)])
  end

  def teardown
    @browser.close
    @headless.destroy if ENV['HEADLESS']
  end

  test "navigate the site" do
    host, port = "localhost", 3000
    @browser.goto "http://#{host}:#{port}"
    @browser.ul(id: 'sib_side_nav').links.map { |l| l.href }.each do |link|
      @browser.goto link
    end
  end
end
