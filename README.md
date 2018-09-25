# Simple Mock ASPSP

This is a simple OpenBanking ASPSP API server designed for testing. It is written
in Ruby On Rails and backed by a PostgreSQL database.

## Background

OpenBanking sets a new standard for user-managed data privacy in which
users give fine-grained authorizations to third parties to access their data.
 
While OpenBanking uses industry-standard OAuth2 to put users in control
of which third parties can access the APIs, the fine-grained authorizations allow users to
limit access to very specific resources with varying resource detail per API.
For example, users may authorize one third party to access to basic account details for all of his
or her accounts, while authorizing another third party to access the past year's
worth of detailed transaction history for only his or her bank card account. 

This places new burden on API developers to ensure the user authorizations
are enforced so that the wrong data doesn't get shared to a third party.

[PingDataGovernance](https://www.pingidentity.com/en/platform/data-governance.html)
is an API proxy that gives enterprises a second layer
of data security to protect user-related data. With a flexible policy
language and multiple data connectors, it is especially useful for
use cases like user-managed data privacy where user preferences or consents
dictate the authorization or restriction of exposing user-related data via APIs.

This mock ASPSP includes several security omissions and mistakes that
PingDataGovernance can filter or block in order to enforce data privacy
and ensure protocol and regulation conformance.

## What's Included

Right now only these account and transaction APIs are available:

API URL | Description
------- | -----------
`/OpenBanking/v2/accounts` | Access the list of authorized accounts
`/OpenBanking/v2/accounts/{account_id}` | Access information of a specific account
`/OpenBanking/v2/accounts/{account_id}/balances` | Balance of a specific account
`/OpenBanking/v2/accounts/{account_id}/transactions` | Individual transactions of a specific account
`/OpenBanking/v2/accounts/{account_id}/statements` | Statement summaries for a specific account
`/OpenBanking/v2/accounts/{account_id}/statements/{statement_id}` | Statement summary for a specific account
`/OpenBanking/v2/accounts/{account_id}/statements/{statement_id}/transactions` | Individual transactions of an account statement
`/OpenBanking/v2/accounts/{account_id}/statements/{statement_id}/file` | Download the individual transactions of an account statement
`/OpenBanking/v2/transactions` | Bulk API for all transactions of all accounts for the authenticated user
`/OpenBanking/v2/balances` | Bulk API for all current balances of all accounts for the authenticated user
`/OpenBanking/v2/statements` | Bulk API for all statement summaries of all accounts for the authenticated user

All of the mock data is generated when a third party makes its first request to `/OpenBanking/v2/accounts`.

The Statement download API provides data only in CSV format.

## What's Missing

This is a demo after all.

1. No payment initiation APIs (yet...)

1. The `account-requests` resource is altogether missing. This API is provided by
the PingDataGovernance and PingDirectory servers: PingDataGovernance takes the staged consent
from the AISP in the OpenBanking `account-request` format, then translates it and stores it
in PingDirectory via
[PingDirectory's consent API](https://apidocs.pingidentity.com/pingdirectory/consent/v1/api/guide/index.html).

1. No Access Token validation. The APIs only decode the Bearer JWT to extract the `sub` claim
to map it to a hypothetical account owner. No signature verification or anything else is provided.
This was done for simplicity sake rather than as a mock vulnerability, though you could consider it
a mock vulnerability too.

1. No filtering nor paging on the transactions API or the statements API. Resources are returned in
a single page.

## What's Intentionally Broken

A number of things are intentionally broken in order to highlight simple, common mistakes that
developers could make which would unintentionally lead to data breach, and for which PingDataGovernance 
can inspect the request and response to guard against those breaches.

1. No checking of authorized consents. Normally an API server would check the terms of the user's
authorization either to validate the request and/or to tailor the response.
The most egregious mistake herein is that no attempt is made to tailor the API responses 
based on the user's authorized consent. Obviously there are several implications of this:
   * Access is allowed even when the user revokes his or her authorization.
   * Access is allowed to resource types that the user did not authorize.
   * The caller will get `Detailed` resource data for every resource which OpenBanking mandates `Basic` versus `Detailed` variations on resources.
   * The caller can access transaction data outside the timeframes that the user has authorized (e.g. `TransactionFromDateTime`, `TransactionToDateTime`, ...)
   * The caller can access resources related to accounts that the user has not authorized. 
  
1. A simple two character mistake documented in [transactions_controller.rb](app/controllers/transactions_controller.rb)
will allow an OAuth-authorized third party to "change the parameters of the URL" and gain
access to transaction data for a different account, including accounts owned by other users.
For example, a request to `/OpenBanking/v2/accounts/11111/transactions` where account `11111`
is owned by the user identified in the bearer token can be altered to request 
`/OpenBanking/v2/accounts/22222/transactions` instead. The transaction data will be returned
despite the token subject not being the owner of account `22222`.
This is not too dissimilar from [a recent real-world data breach](https://krebsonsecurity.com/2018/08/fiserv-flaw-exposed-customer-data-at-hundreds-of-banks/). 

1. The previous mistake is repeated in the account balances API and the account statements API.

1. Disclosing too much data via HTTP response codes. API developers like to be descriptive with their
HTTP error codes, but sometimes doing so can disclose too much information to an attacker.
The logic documented in the account statement API at [statements_controller.rb](app/controllers/statements_controller.rb), 
allows an authenticated third party to poke around and test for the existence of other
statements for which the third party is not authorized. This is because the API currently returns
403 Forbidden when the statement exists versus 404 Not Found when the statement doesn't exist,
which is [not recommended by OWASP](https://www.owasp.org/index.php/Exception_Handling#HTTP_Status_Codes).
 
## What's Unintentionally Broken

Probably several things! Open an issue, or even better, open a pull request with your fix!

# Running the Server

### The easy way - On Heroku

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

### The harder way - On your Mac

Here's a crash course on running a Rails API on your Mac.

1. Install Homebrew because you're going to need PostgreSQL.
1. Install RVM to help you install Ruby.
1. Install PostgreSQL 9.6.
1. Install Ruby 2.4.1
1. Create a gemset to isolate this app's gems.
1. Install the gems required by this app into that gemset.
1. Create the database.
1. Start your server.

Here's the script:

```bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
\curl -sSL https://get.rvm.io | bash -s stable --ruby
brew install postgresql@9.6
rvm install ruby-2.4.1
cd /path/to/cloned/repo
rvm use ruby-2.4.1@mock-simple-aspsp
bundle
rake db:setup
rails s
```

### The DIY way -- On your non-Mac

All of this stuff works on other operating systems. Good luck with that. 

# Testing the APIs

Coming soon, a Postman collection to play with the various APIs!
