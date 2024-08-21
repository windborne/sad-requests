require "test_helper"

class PublicControllerTest < ActionDispatch::IntegrationTest
  test "should get up" do
    get public_up_url
    assert_response :success
  end

  test "should get sleep" do
    get public_sleep_url
    assert_response :success
  end

  test "should get wait" do
    get public_wait_url
    assert_response :success
  end
end
