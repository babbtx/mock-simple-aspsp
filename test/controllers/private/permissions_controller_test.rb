require 'test_helper'

class Private::PermissionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    ExternalAuthz.stubs(:configured?).returns(false)
  end
  
  test "user gets all permissions by default" do
    sign_in FactoryBot.create :user
    get private_permissions_url, as: :json, headers: authz_headers
    assert_response :success

    json = JSON.parse(@response.body)
    %w[ accounts transactions transfers offers ].each do |permission|
      assert json.has_key?(permission), "Expected a permission for #{permission}"
      assert_equal true, json[permission], "Expected #{permission} to be truthy"
    end
  end
end
