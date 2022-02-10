require 'test_helper'

class PingOneClientTest < ActiveSupport::TestCase

  test "gets access token" do
    access_token = stub(token: 'token')
    PingOneClient.any_instance.expects(:access_token).once.returns(access_token)

    url = 'https://example.com/pdp'
    stub_request(:any, url)
      .with(headers: {authorization: 'Bearer token'})
      .to_return(status: 200)

    p1 = PingOneClient.new(url: url)
    p1.post
  end

  test "checks access token each time" do
    access_token = stub(token: 'token')
    PingOneClient.any_instance.expects(:access_token).twice.returns(access_token)

    url = 'https://example.com/pdp'
    stub_request(:any, url)
      .with(headers: {authorization: 'Bearer token'})
      .to_return(status: 200)

    p1 = PingOneClient.new(url: url)
    p1.post
    p1.post
  end
end
