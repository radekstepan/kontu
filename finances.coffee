# A generic account.
class Account

    constructor: (@balance) ->

    addExpense: (amount) ->
        switch @type
            when 'debit' # less money we have
                @balance -= amount
            when 'credit' # more money we owe
                @balance += amount

# Our standard account.
class DebitAccount extends Account

    type: 'debit'

# Credit cards, loans from other users. Not our money.
class CreditAccount extends Account

    type: 'credit'

# User account having accounts and linked users.
class User

    accounts: {}

    constructor: (@name) ->

    addAccount: (id, account) -> accounts[id] = account

module.exports =
    'DebitAccount': DebitAccount
    'CreditAccount': CreditAccount
    'User': User