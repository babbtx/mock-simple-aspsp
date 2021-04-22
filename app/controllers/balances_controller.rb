class BalancesController < ApplicationController

  # an error if there's a failure with the external authorization service
  class ExternalAuthorizationError < StandardError
  end
  # an error if the external authorization service denies the client's request
  class ExternalAuthorizationDenied < StandardError
  end

  rescue_from ExternalAuthorizationError, with: :render_server_error
  rescue_from ExternalAuthorizationDenied, with: :render_forbidden

  def index
    # this is the ugly way to do this:
    # get all of the accounts for the user,
    # then we'll get the most recent transaction and balance per
    accounts = Account.for_user(current_user!) unless params[:account_id].present?

    # same intentional bug as described in TransactionsController#index
    # accounts = accounts.where(id: params[:account_id]) if params[:account_id].present?
    accounts = Account.where(id: params[:account_id]) if params[:account_id].present?

    authorize_account_access!(accounts)

    transactions = accounts.collect(&:id).collect do |account|
      Transaction.for_account(account).newest_first.first
    end.compact

    self_url = params[:account_id].present? ? account_balances_url(params[:account_id]) : balances_url
    render json: BalanceSerializer.new(transactions, links: {Self: self_url}, meta: { TotalPages: 1 }).serializable_hash
  end

  private

  def authorize_account_access!(accounts)
    # TODO update for multiple accounts
    if accounts.count == 1 then
      account = accounts.first
      authorize_account_access_with_xacml!(account) if ENV['AUTHORIZE_XACML_URL'].present?
      authorize_account_access_with_paz!(account) if ENV['AUTHORIZE_PAZ_URL'].present?
    end
  end

  def authorize_account_access_with_xacml!(account)
    request_body = <<-END_OF_XACML
{
    "Request": {
        "AccessSubject": [
        ],
        "Action": [
            {
                "Id": "action-view",
                "Attribute": [
                    {
                        "AttributeId": "action",
                        "Value": "aspsp-backend-view"
                    }
                ]
            }
        ],
        "Resource": [
            {
                "Id": "service",
                "Attribute": [
                    {
                        "AttributeId": "service",
                        "Value": "ASPSP.AccountBalance"
                    }
                ]
            }
        ],
        "Environment": [
            {
                "Id": "attr-subject",
                "Attribute": [
                    {
                        "AttributeId": "attribute:ASPSP.TokenSubject",
                        "Value": #{@auth_payload[:sub].to_json}
                    }
                ]
            },
            {
                "Id": "attr-ipaddress",
                "Attribute": [
                    {
                        "AttributeId": "attribute:ASPSP.ClientIPAddress",
                        "Value": #{request.ip.to_json}
                    }
                ]
            },
            {
                "Id": "attr-account",
                "Attribute": [
                    {
                        "AttributeId": "attribute:ASPSP.Account",
                        "Value": #{account.to_json.to_json}
                    }
                ]
            }
        ],
        "Category": [
        ],
        "MultiRequests": {
            "RequestReference": [
                {
                    "ReferenceId": [
                        "action-view",
                        "service",
                        "attr-subject",
                        "attr-ipaddress",
                        "attr-account"
                    ]
                }
            ]
        }
    }
}
END_OF_XACML
    connection = Faraday.new(ENV['AUTHORIZE_XACML_URL'], ssl: {verify: false})
    response = connection.post(
        ENV['AUTHORIZE_XACML_URL'],
        request_body,
        'Authorization' => "Bearer " + {active: true, scope: "urn:pingdatagovernance:pdp"}.to_json,
        'Content-Type' => 'application/json',
        'Accept' => 'application/json, application/xacml+json')
    raise ExternalAuthorizationError if response.status != 200
    # Expecting something like this
    # {
    #     "Response": [
    #         {
    #             "Decision": "Permit",
    #             "Obligations": [],
    #             "AssociatedAdvice": []
    #         }
    #     ]
    # }
    response_body = JSON.parse(response.body).with_indifferent_access
    raise ExternalAuthorizationDenied unless response_body[:Response][0][:Decision] == 'Permit'
  end

  def authorize_account_access_with_paz!(account)
    request_body = <<-END_OF_JSON
{
    "service": "ASPSP.AccountBalance",
    "action": "aspsp-backend-view",
    "attributes": {
        "ASPSP.Account": #{account.to_json.to_json},
        "ASPSP.ClientIPAddress": #{request.ip.to_json},
        "ASPSP.TokenSubject": #{@auth_payload[:sub].to_json}
    }
}
END_OF_JSON
    connection = Faraday.new(ENV['AUTHORIZE_PAZ_URL'], ssl: {verify: false})
    response = connection.post(
        ENV['AUTHORIZE_PAZ_URL'],
        request_body,
        'CLIENT-TOKEN' => 'password',
        'Content-Type' => 'application/json',
        'Accept' => 'application/json')
    raise ExternalAuthorizationError if response.status != 200
    # Expecting something like this
    # {
    #     "decision": "PERMIT"
    # }
    response_body = JSON.parse(response.body).with_indifferent_access
    raise ExternalAuthorizationDenied unless response_body[:decision] == 'PERMIT'
  end

  def render_server_error
    head 500
  end

  def render_forbidden
    head 403
  end
end
