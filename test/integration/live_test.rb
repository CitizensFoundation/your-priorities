require "json"
require "selenium-webdriver"
require "test/unit"

class LiveTest < Test::Unit::TestCase

  def setup
    @driver = Selenium::WebDriver.for :firefox
    #@base_url = "https://test.betrireykjavik.is/"
    @base_url = "https://test.yrpri.org/"
    @test_user_id = rand(432432432)
    @accept_next_alert = true
    @driver.manage.timeouts.implicit_wait = 30
    @verification_errors = []
  end

  def teardown
    @driver.quit
    assert_equal [], @verification_errors
  end

  def test_basic
    @driver.get(@base_url + "/")
    @driver.find_element(:link, "Sign in with email").click
    @driver.find_element(:link, "Create new email user").click
    @driver.find_element(:id, "user_login").clear
    @driver.find_element(:id, "user_login").send_keys "Test User #{@test_user_id}"
    @driver.find_element(:id, "user_email").clear
    @driver.find_element(:id, "user_email").send_keys "TestUser#{@test_user_id}@ibuar.is"
    @driver.find_element(:id, "user_password").clear
    @driver.find_element(:id, "user_password").send_keys "testpasswordfor#{@test_user_id}"
    @driver.find_element(:id, "user_terms").click
    @driver.find_element(:name, "commit").click
    @driver.find_element(:link, "Ideas").click
    @driver.find_element(:link, "People").click
    #@driver.find_element(:xpath, "(//a[contains(text(),'English')])[2]").click
    #@driver.find_element(:link, "Bulgarian").click
    #@driver.find_element(:link, "English").click
    #@driver.execute_script("$('.has-dropdown').mouseover();")
    @driver.get(@base_url + "/users/additional_information")
    @driver.find_element(:id, "user_login").clear
    @driver.find_element(:id, "user_login").send_keys "Test User 0!"
    @driver.find_element(:name, "commit").click
    @driver.get(@base_url + "/settings/signups")
    @driver.get(@base_url + "/inbox/notifications")
    @driver.find_element(:link, "Ideas").click
    @driver.find_element(:link, "SUBMIT YOUR IDEA").click
    @driver.find_element(:id, "ideaNameContent").clear
    @driver.find_element(:id, "ideaNameContent").send_keys "My first test idea"
    @driver.find_element(:id, "category_id_arrow").click
    @driver.find_element(:css, "#category_id_msa_3 > span.ddTitleText").click
    @driver.find_element(:id, "ideaContent").clear
    @driver.find_element(:id, "ideaContent").send_keys "Lorem Ipsum er rett og slett dummytekst fra og for trykkeindustrien. Lorem Ipsum har vært bransjens standard for dummytekst helt siden 1500-tallet, da en ukjent boktrykker stokket en mengde bokstaver for å lage et prøveeksemplar av en bok. Lorem Ipsum har tålt tidens tann usedvanlig godt, og har i tillegg til å bestå gjennom fem århundrer også tålt spranget over til elektronisk typografi uten vesentlige endringer. Lorem Ipsum ble gjort allment kjent i 1960-årene ved lanseringen av Letraset-ark"
    @driver.find_element(:id, "pointTitle").clear
    @driver.find_element(:id, "pointTitle").send_keys "My Good point"
    @driver.find_element(:id, "pointContent").clear
    @driver.find_element(:id, "pointContent").send_keys "My point my point My point my point My point my point My point my point My point my point My point my point My point my point My point my point My point my point My point my point My point my point My point my point My point my point My point my point My point my point My point my point My point my point My point my point My point my point My point my point My point my point My point my point My point my point My point my point My point my point My point my point My point my point My point my pM"
    @driver.find_element(:name, "commit").click
    @driver.find_element(:link, "UP 1").click
    sleep 5
    @driver.find_element(:link, "DOWN 0").click
    sleep 5
    @driver.find_element(:link, "UP 0").click
    sleep 5
    @driver.find_element(:link, "DOWN 0").click
    sleep 5
    @driver.find_element(:link, "DOWN 1").click
    sleep 5
    @driver.find_element(:link, "UP 0").click
    @driver.find_element(:link, "Add new point").click
    @driver.find_element(:id, "pointTitle").clear
    @driver.find_element(:id, "pointTitle").send_keys "Point against..."
    @driver.find_element(:id, "pointContent").clear
    @driver.find_element(:id, "pointContent").send_keys "Point against...Point against...Point against...Point against...Point against...Point against...Point against...Point against...Point against...Point against...Point against...Point against...Point against...Point against...Point against...Point against...Point against...Point against...Point against...Point against...Point against...Point against...Point against...Point against...Point against...Point against...Point against...Point against... Point against...Point against...Point against...Poi"
    @driver.find_element(:id, "point_value_-1").click
    @driver.find_element(:id, "submit").click
    @driver.find_element(:id, "bulletin_content").clear
    @driver.find_element(:id, "bulletin_content").send_keys "Testing 1...2...3....."
    @driver.find_element(:id, "bulletin-form-submit").click
    #@driver.find_element(:id, "comment_content_20377").clear
    #@driver.find_element(:id, "comment_content_20377").send_keys "Hearing you loudly..."
    #@driver.find_element(:css, "#submit_span_20377 > input[name=\"commit\"]").click
    @driver.find_element(:xpath, "(//a[contains(text(),'My first test idea')])[2]").click
    @driver.get(@base_url + "/users/sign_out")
  end

  def element_present?(how, what)
    @driver.find_element(how, what)
    true
  rescue Selenium::WebDriver::Error::NoSuchElementError
    false
  end

  def alert_present?()
    @driver.switch_to.alert
    true
  rescue Selenium::WebDriver::Error::NoAlertPresentError
    false
  end

  def verify(&blk)
    yield
  rescue Test::Unit::AssertionFailedError => ex
    @verification_errors << ex
  end

  def close_alert_and_get_its_text(how, what)
    alert = @driver.switch_to().alert()
    alert_text = alert.text
    if (@accept_next_alert) then
      alert.accept()
    else
      alert.dismiss()
    end
    alert_text
  ensure
    @accept_next_alert = true
  end
end
