module Private
  class OffersController < ApiController
    include ExternalAuthz

    def index
      offers = [
        {
          id: '83284733-A719-4A30-B0CD-26CFA4C0C942',
          icon: 'credit-card',
          kind: 'Credit Card',
          name: 'Dining Rewards',
          description: 'Earn higher rewards when you dine out'
        },
        {
          id: '4EF8E67E-EE7C-4E44-B535-A71B0BE27491',
          icon: 'home',
          kind: 'Loan',
          name: 'Home Equity Line of Credit',
          description: 'Get flexible financing terms based on your home equity'
        },
        {
          id: '63BA6728-DD5F-4781-B522-E82FD53A1836',
          icon: 'line-chart',
          kind: 'Brokerage Account',
          name: 'Self-service Stock Trading',
          description: 'Manage your own portfolio of stocks with low trading fees'
        }
      ]

      external_authorize_collection!(offers, typename: 'offer')

      # convert to json-api
      json = {
        data: offers.collect do |offer|
                id = offer.delete :id
                {
                  id: id,
                  type: 'offer',
                  attributes: offer
                }
              end
      }

      render json: json
    end
  end
end
