require 'test_helper'

class Private::PermissionsControllerTest < ActionDispatch::IntegrationTest

  test "user gets all permissions" do
    sign_in FactoryBot.create :user
    get private_permissions_url, as: :json, headers: authz_headers
    assert_response :success

    json = JSON.parse(@response.body)
    %w[ accounts transactions transfers offers ].each do |permission|
      assert json.has_key?(permission)
      assert_equal true, json[permission]
    end
  end
end