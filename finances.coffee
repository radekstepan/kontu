# Simple assertion class.
class AssertException

    constructor: (@message) ->

    toString: -> "AssertException: #{@message}"

# Shorthand for throwing it.
assert = (exp, message) -> throw new AssertException(message) unless exp


# ---------------------------------------


# Holder of the users and their accounts.
class System

    users: {}

    addUser: (user) ->
        id = user.id
        assert not @users[id], "User #{id} already exists"
        @users[id] = user

    linkAccounts: (ids) ->
        assert ids instanceof Array, 'Need to pass an array in'
        # For all...
        for i in ids
            assert typeof(i) is 'string', 'Access an id of a user by string'
            usr1 = @users[i]
            assert usr1, "User #{i} does not exist"

            # ...with all.
            for j in ids
                usr2 = @users[j]
                assert usr2, "User #{j} does not exist"
                # Don't link us to us.
                if i is j then continue

                # Are we already linked?
                acc = usr1.accounts[j]
                if acc
                    # Make sure the type matches.
                    assert acc.type is 'shared', "User #{i} has a personal account called #{j}"
                    # ...skip then.
                    continue

                # Create a new account for us with the other person's id.
                usr1.accounts[j] = new SharedExpenseAccount 0, usr2

# ---------------------------------------

# A generic account.
class Account

    constructor: (@balance = 0) ->

    addExpense: (amount) ->
        # Have we not rounder?
        assert parseFloat(amount.toFixed(2)) is amount, "#{amount} is not rounded properly"

        # Which type?
        switch @type
            when 'debit' # less money we have
                @balance -= amount
            when 'credit', 'shared' # more money we owe
                @balance += amount

    addSharedExpense: (amount, others) ->
        assert @user, 'Nobody owns this account'
        assert others instanceof Array, 'Need to pass an array in'

        # Deduct the expense.
        @addExpense amount

        # Make sure that the total is all squared away.
        total = 0

        # Update the other's account.
        for [ id, split] in others
            # Get the linked account.
            account = @user.accounts[id]
            # Are we linked?
            assert account and account.type is 'shared', "User #{id} does not have a shared account with us"
            # Update their account with us.
            account.addExpense total += parseFloat((amount * split).toFixed(2))

# Our standard account.
class DebitAccount extends Account

    type: 'debit'

# Credit cards. Not our money.
class CreditAccount extends Account

    type: 'credit'

# Account created internally for dealing with credit between users.
class SharedExpenseAccount extends CreditAccount

    type: 'shared'

    # Make a link to the other user too.
    constructor: (balance, @other) -> super

# ---------------------------------------

# User account having accounts and linked users.
class User

    # Our accounts.
    accounts: {}

    # Users linked to us.
    linked: {}

    constructor: (@id) ->

    addAccount: (id, account) ->
        # Link us.
        @accounts[id] = account
        # Link back to us.
        account.user = @

# ---------------------------------------

module.exports =
    'DebitAccount': DebitAccount
    'CreditAccount': CreditAccount
    'System': System
    'User': User