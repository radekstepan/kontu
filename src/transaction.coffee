Q       = require 'q'
mongodb = require 'mongodb'

class Transaction

    constructor: (@kontu) ->

    ###
    Save a new transaction.
    ###
    post: (req, res) =>        
        # Check API Key.
        Q.fcall( =>
            @kontu.checkApi req.headers['x-apikey']
        
        # Do we know all the accounts and users?.
        ).then( ([ user, collections ]) =>
            # Do we have a timestamp saved?
            transaction = req.body
            unless transaction.created
                throw 'Need to provide timestamp in `created`'
            unless transaction.created % 1 is 0
                throw 'Timestamp `created` not properly formatted'

            # Have we provided amount and currency?
            for key in [ 'amount', 'currency' ]
                unless transaction[key] then throw "Did not provide `#{key}` key"

            # Is the amount an actual number?
            unless not isNaN(parseFloat(transaction.amount)) and isFinite(transaction.amount)
                throw "`#{transaction.amount}` is not a number"
            # OK, is the amount a 'correct' number?
            if parseFloat((parseFloat(transaction.amount)).toFixed(2)) isnt transaction.amount
                throw "`#{transaction.amount}` is not correctly formatted"

            # Do we know this currency?
            transaction.currency = transaction.currency.toUpperCase() # match on case
            unless transaction.currency in @kontu.currencies
                throw "Unknown currency `#{transaction.currency}`"

            # Traverse all the transfers.
            for user_id, list of transaction.transfers
                # Is this us?
                unless user_id is user.id
                    # Do we share an account with this user?
                    unless user.accounts[user_id + ':debtor'] or user.accounts[user_id + ':creditor']
                        throw "Cannot add transaction for user `#{user_id}`"

            [ user, collections ]

        # Now check that all the accounts mentioned in the transaction exist and transfers are correctly formatted.
        ).then( ([ user, collections ]) =>
            def = Q.defer()
            
            users = Object.keys req.body.transfers
            
            # Do we actually have users?
            if users.length is 0 then return def.reject { 'message': 'No users in transactions' }

            # Get all of the users in question.
            collections.users.find(
                '$or': ( { 'id': u } for u in users )
            ).toArray (err, docs) =>
                if err then return def.reject err
                # Correct count? Just double checking...
                if docs.length isnt users.length
                    return def.reject { 'code': 500, 'message': 'Incorrect number of users in a transaction' }

                # Convert docs into an accounts object.
                accounts = {}
                ( accounts[doc.id] = doc.accounts or {} for doc in docs )

                # Check that all the accounts in the request exist in the appropriate users.
                for user_id, list of req.body.transfers
                    for transfer in list
                        # Check that we have an account, amount and currency saved.
                        for key in [ 'account_id', 'amount', 'currency' ]
                            unless transfer[key]
                                return def.reject { 'message': "Need to provide `#{key}` in a transfer" }
                        
                        # Is the amount an actual number?
                        unless not isNaN(parseFloat(transfer.amount)) and isFinite(transfer.amount)
                            return def.reject { 'message': "`#{transfer.amount}` is not a number" }
                        # OK, is the amount a 'correct' number?
                        if parseFloat((parseFloat(transfer.amount)).toFixed(2)) isnt transfer.amount
                            return def.reject { 'message': "`#{transfer.amount}` is not correctly formatted" }

                        # Do we know this currency?
                        transfer.currency = transfer.currency.toUpperCase() # match on case
                        unless transfer.currency in @kontu.currencies
                            return def.reject { 'message': "Unknown currency `#{transfer.currency}`" }

                        # Does the account exist?
                        unless acc = accounts[user_id][transfer.account_id]
                            return def.reject { 'message': "User `#{user_id}` does not have account `#{transfer.account_id}`" }

                        # For some reason currency not supplied on account?
                        unless acc.currency
                            return def.reject { 'message': "Account `#{transfer.account_id}` does not have a `currency` field" }

                        # Do we match on currency?
                        if transfer.currency isnt acc.currency
                            # We better have the exchange rate then.
                            unless transfer.rate and not isNaN(parseFloat(transfer.rate)) and isFinite(transfer.rate)
                                return def.reject { 'message': "Exchange `rate` not provided, transfer and account currencies do not match" }

                def.resolve collections

            def.promise

        # All went fine, save the request into the ledger.
        ).then( (collections) ->
            def = Q.defer()
            collections.ledger.insert req.body, { 'safe': true }, (err, docs) ->
                if err then return def.reject err
                def.resolve docs.pop()
            def.promise

        ).done( (doc) =>
            @kontu.success res, 'id': doc._id
        , (err) =>
            @kontu.error res, err
        )

    ###
    Update a transaction.
    ###
    put: (req, res, id) =>        
        # Check API Key.
        Q.fcall( =>
            @kontu.checkApi req.headers['x-apikey']
        
        # Do we know all the accounts and users?.
        ).then( ([ user, collections ]) =>
            transaction = req.body

            # If timestamp provided, is it well formatted?
            if transaction.created
                if transaction.created % 1 is 0
                    throw 'Timestamp `created` not properly formatted'

            # Is the amount an actual number?
            if transaction.amount
                unless not isNaN(parseFloat(transaction.amount)) and isFinite(transaction.amount)
                    throw "`#{transaction.amount}` is not a number"
                # OK, is the amount a 'correct' number?
                if parseFloat((parseFloat(transaction.amount)).toFixed(2)) isnt transaction.amount
                    throw "`#{transaction.amount}` is not correctly formatted"

            # Do we know this currency?
            if transaction.currency
                transaction.currency = transaction.currency.toUpperCase() # match on case
                unless transaction.currency in @kontu.currencies
                    throw "Unknown currency `#{transaction.currency}`"

            # Traverse all the transfers.
            for user_id, list of transaction.transfers
                # Is this us?
                unless user_id is user.id
                    # Do we share an account with this user?
                    unless user.accounts[user_id + ':debtor'] or user.accounts[user_id + ':creditor']
                        throw "Cannot add transaction for user `#{user_id}`"

            [ user, collections ]

        # Now check that all the accounts mentioned in the transaction exist and transfers are correctly formatted.
        ).then( ([ user, collections ]) =>
            def = Q.defer()
            
            # Early exit?
            unless req.body.transfers then return collections

            users = Object.keys req.body.transfers
            
            # Do we actually have users?
            if users.length is 0 then return def.reject { 'message': 'No users in transactions' }

            # Get all of the users in question.
            collections.users.find(
                '$or': ( { 'id': u } for u in users )
            ).toArray (err, docs) =>
                if err then return def.reject err
                # Correct count? Just double checking...
                if docs.length isnt users.length
                    return def.reject { 'code': 500, 'message': 'Incorrect number of users in a transaction' }

                # Convert docs into an accounts object.
                accounts = {}
                ( accounts[doc.id] = doc.accounts or {} for doc in docs )

                # Check that all the accounts in the request exist in the appropriate users.
                for user_id, list of req.body.transfers
                    for transfer in list
                        # Check that we have an account, amount and currency saved.
                        for key in [ 'account_id', 'amount', 'currency' ]
                            unless transfer[key]
                                return def.reject { 'message': "Need to provide `#{key}` in a transfer" }
                        
                        # Is the amount an actual number?
                        unless not isNaN(parseFloat(transfer.amount)) and isFinite(transfer.amount)
                            return def.reject { 'message': "`#{transfer.amount}` is not a number" }
                        # OK, is the amount a 'correct' number?
                        if parseFloat((parseFloat(transfer.amount)).toFixed(2)) isnt transfer.amount
                            return def.reject { 'message': "`#{transfer.amount}` is not correctly formatted" }

                        # Do we know this currency?
                        transfer.currency = transfer.currency.toUpperCase() # match on case
                        unless transfer.currency in @kontu.currencies
                            return def.reject { 'message': "Unknown currency `#{transfer.currency}`" }

                        # Does the account exist?
                        unless acc = accounts[user_id][transfer.account_id]
                            return def.reject { 'message': "User `#{user_id}` does not have account `#{transfer.account_id}`" }

                        # For some reason currency not supplied on account?
                        unless acc.currency
                            return def.reject { 'message': "Account `#{transfer.account_id}` does not have a `currency` field" }

                        # Do we match on currency?
                        if transfer.currency isnt acc.currency
                            # We better have the exchange rate then.
                            unless transfer.rate and not isNaN(parseFloat(transfer.rate)) and isFinite(transfer.rate)
                                return def.reject { 'message': "Exchange `rate` not provided, transfer and account currencies do not match" }

                def.resolve collections

            def.promise

        # All went fine, update the ledger.
        ).then( (collections) ->
            id = mongodb.ObjectID.createFromHexString id

            def = Q.defer()
            collections.ledger.findAndModify { '_id': id }, [], { '$set': req.body }, { 'safe': true }, (err, doc) ->
                if err then return def.reject err
                unless doc then return def.reject { 'message': "Transaction `#{id}` does not exist" }
                def.resolve doc
            def.promise

        ).done( (doc) =>
            @kontu.success res, 'id': doc._id
        , (err) =>
            @kontu.error res, err
        )

    ###
    Get transactions.
    ###
    get: (req, res) =>
        # Check API Key.
        Q.fcall( =>
            @kontu.checkApi req.headers['x-apikey']

        # Get the data.
        ).then( ([ user, collections ]) ->
            q = {}
            q["transfers.#{user.id}"] = '$exists': true

            def = Q.defer()
            collections.ledger.find(q).toArray (err, docs) ->
                if err then return def.reject err
                def.resolve [ user, docs ]
            def.promise

        # Calculate the totals for each account.
        ).then( ([ user, docs ]) ->
            # Make a difference into a total balance.
            accounts = {}
            for key, val of user.accounts
                val.balance = val.difference
                delete val.difference
                accounts[key] = val

            # Go through transactions and update the balance.
            for doc in docs
                for t in doc.transfers[user.id]
                    accounts[t.account_id].balance += t.amount # throws if acc not present :)

            'accounts':     accounts
            'transactions': docs

        ).done( (results) =>
            @kontu.success res, results
        , (err) =>
            @kontu.error res, err
        )

    ###
    Delete a transaction.
    ###
    delete: (req, res, id) =>
        # Check API Key.
        Q.fcall( =>
            @kontu.checkApi req.headers['x-apikey']

        # Get the data? We need a transaction id AND be involved.
        ).then( ([ user, collections ]) ->
            q = '_id': mongodb.ObjectID.createFromHexString id
            q["transfers.#{user.id}"] = '$exists': true

            def = Q.defer()
            collections.ledger.remove q, { 'safe': true }, (err, removed) ->
                if err then return def.reject err
                if removed isnt 1 then return def.reject { 'message': "We have removed `#{removed}` transactions" }
                def.resolve()
            def.promise

        ).done( =>
            @kontu.success res
        , (err) =>
            @kontu.error res, err
        )

module.exports = Transaction