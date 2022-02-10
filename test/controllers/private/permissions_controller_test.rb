require 'test_helper'

class Private::PermissionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    sign_in FactoryBot.create :user
  end

  test "user gets all permissions by default" do
    get private_permissions_url, as: :json, headers: authz_headers
    assert_response :success
    json = JSON.parse(@response.body)

    %w[ accounts transactions transfers offers ].each do |permission|
      assert json.has_key?(permission), "Expected a permission for #{permission}"
      assert_equal true, json[permission], "Expected #{permission} to be truthy"
    end
  end

  test "external authz returns default of accounts if no statements are returned" do
    Private::PermissionsController.any_instance.
      expects(:external_authz_configured?).
      returns(true)
    Private::PermissionsController.any_instance.
      expects(:external_authorize!).
      returns({})

    get private_permissions_url, as: :json, headers: authz_headers
    assert_response :success
    json = JSON.parse(@response.body)

    assert json.has_key?('accounts'), "Expected a permission for accounts"
    assert_equal true, json['accounts'], "Expected accounts to be truthy"

    %w[ transactions transfers offers ].each do |permission|
      assert !json.has_key?(permission) || !json[permission], "Unexpected truthy for #{permission}"
    end
  end

  test "collects the results of all statements from external authz" do
    authz_result = {'statements' => [
      {'code' => 'set-permission', 'payload' => 'transfers'},
      {'code' => 'set-permission', 'payload' => 'offers'},
      {'code' => 'set-permission', 'payload' => 'custom'},
    ]}
    Private::PermissionsController.any_instance.
      expects(:external_authz_configured?).
      returns(true)
    Private::PermissionsController.any_instance.
      expects(:external_authorize!).
      returns(authz_result)

    get private_permissions_url, as: :json, headers: authz_headers
    assert_response :success
    json = JSON.parse(@response.body)

    %w[ accounts transfers offers custom ].each do |permission|
      assert json.has_key?(permission), "Expected a permission for #{permission}"
      assert_equal true, json[permission], "Expected #{permission} to be truthy"
    end
  end
end
