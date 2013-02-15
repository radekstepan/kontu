# Add an expense.
# List all expenses in the last month.
# List all loans we have with a user.
# Get current balance on an account.
# Update a previous transaction.

class User

    accounts: {}

    constructor: (@id) ->

    addAccount: (account) ->
        @accounts[account.id] = account

    # Retrieve account populating its balance.
    getAccount: (account_id) ->
        #

    # Link with user by adding debtor and creditor accounts.
    linkWith: (id) ->
        @accounts["#{id}:creditor"] = 'type': 201
        @accounts["#{id}:debtor"]   = 'type': 103

class Ledger

    # A collection.
    transactions: []

    addTransaction: (obj) ->
        obj.id = transactions.length
        # TODO: Check that the object matches the spec.
        # TODO: Check that the user can share an expense with other users.
        # TODO: Check that users have accounts specified.
        @transactions.push obj

module.exports =
    'User': User
    'Ledger': Ledger