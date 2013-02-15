Q  = require 'q'

# Database access.
db = null

# Set db access.
exports.app = (app) -> db = app.db

# Check that API Key is valid.
checkAPIKey = (api_key) ->
    # Which user is this for?
    Q.fcall( ->
        # Provided key?
        unless api_key then throw { 'message': 'API key not provided' }
        else api_key
    
    # Gives us db access.
    ).then( (api_key) ->
        def = Q.defer()
        db (collections) -> def.resolve [ api_key, collections ]
        def.promise
    
    # Check we know this user.
    ).then( ([ api_key, collections ]) ->
        def = Q.defer()
        collections.users.findOne { 'api_key': api_key }, (err, doc) ->
            if err then def.reject err
            if !doc then def.reject { 'code': 403, 'message': "API key `#{api_key}` is not allowed" }
            def.resolve [ doc, collections ]
        def.promise
    )

# Promise fulfilled.
successHandler = (res, results='ok') ->
    res.writeHead 200, 'content-type': 'application/json'
    res.write JSON.stringify 'results': results
    res.end()

# Promise not fulfilled.
errorHandler = (res, err) ->
    code = err.code or 400
    # Is the error a string or an object.
    if typeof(err) is 'object'
        # Error type?
        if err.name and err.message
            message = err.name + ': ' + err.message
        else
            message = err.message or 'Error'
    else
        message = err

    # Respond.
    res.writeHead code, 'content-type': 'application/json'
    res.write JSON.stringify 'message': message
    res.end()

# ----------------------------------------------------------------------------------------------------

exports.users = ->
    ###
    Save a new user.
    ###
    @post ->
        req = @req ; res = @res

        # Get the data posted.
        Q.fcall( ->
            user = req.body
            for key in  [ 'id', 'api_key' ]
                unless user[key] then throw "Need to provide user `#{key}`"
            unless Object.keys(user).length is 2 then throw "Provided incorrect number of keys"
            user

        # Gives us db access.
        ).then( (user) ->
            def = Q.defer()
            db (collections) -> def.resolve [ user, collections ]
            def.promise
        
        # Does the user already exist?
        ).then( ([ user, collections ]) ->
            def = Q.defer()
            collections.users.findOne { 'id': user.id }, (err, doc) ->
                if err then def.reject err
                if doc then def.reject { 'code': 400, 'message': "User `#{user.id}` already exists" }
                def.resolve [ user, collections ]
            def.promise

        # Save the new information.
        ).then( ([ user, collections ]) ->
            def = Q.defer()

            # Reject any accounts trying to be saved with the user. A blank slate.
            user.accounts = {}

            collections.users.insert user, { 'safe': true }, (err) ->
                if err then def.reject err
                def.resolve user
            def.promise

        ).done( ->
            successHandler res
        , (err) ->
            errorHandler res, err
        )

exports.accounts = ->
    ###
    Save a new account.
    ###
    @post ->
        req = @req ; res = @res
        
        # Check API Key.
        Q.fcall( ->
            checkAPIKey req.headers['x-apikey']

        # Check if doc matches the spec.
        ).then( ([ user, collections ]) ->
            # Does it have all the keys?
            account = req.body
            for key in  [ 'id', 'type' ]
                unless account[key] then throw "Need to provide account `#{key}`"
            unless Object.keys(account).length is 2 then throw "Provided incorrect number of keys"
            # Does the account exist already?
            if user.accounts[account.id] then throw "Account `#{id}` exists already"
            # Does the type match the types we know about?
            if account.type not in [ 101...112 ].concat [ 201, 206, 210, 220, 250, 270, 300, 350, 360, 370 ]
                throw "Account type `#{account.type}` not known"

            # Add it to the user object.
            user.accounts[account.id] = { 'type': account.type }

            [ user, collections ]

        # Update the user with the new account.
        ).then( ([ user, collections ]) ->
            def = Q.defer()

            collections.users.update { 'id': user.id }, user, { 'safe': true }, (err) ->
                if err then def.reject err
                def.resolve()
            def.promise

        ).done( ->
            successHandler res
        , (err) ->
            errorHandler res, err
        )

exports.transactions = ->
    ###
    Save a new transaction.
    ###
    @post ->
        req = @req ; res = @res
        
        # Check API Key.
        Q.fcall( ->
            checkAPIKey req.headers['x-apikey']
        
        # Do we know all the accounts and users?.
        ).then( ([ user, collections ]) ->
            # Do we have a timestamp saved?
            time = req.body.created
            unless time
                throw 'Need to provide timestamp in `created`'
            unless time % 1 is 0
                throw 'Timestamp `created` not properly formatted'

            for user_id, list of req.body.transfers
                # Is this us?
                unless user_id is user.id
                    # Do we share an account with this user?
                    unless user.accounts[user_id + ':debtor'] or user.accounts[user_id + ':creditor']
                        throw "Cannot add transaction for user `#{user_id}`"

            [ user, collections ]

        # Now check that all the accounts mentioned in the transaction exist and transfers are correctly formatted.
        ).then( ([ user, collections ]) ->
            def = Q.defer()
            
            users = Object.keys(req.body.transfers)
            
            # Get all of the users in question.
            collections.users.find(
                '$or': ( { 'id': u } for u in users )
            ).toArray (err, docs) ->
                if err then def.reject err
                # Correct count? Just double checking...
                if docs.length isnt users.length
                    def.reject { 'code': 500, 'message': 'Incorrect number of users in a transaction' }

                # Convert docs into an accounts object.
                accounts = {}
                ( accounts[doc.id] = doc.accounts or {} for doc in docs )

                # Check that all the accounts in the request exist in the appropriate users.
                for user_id, list of req.body.transfers
                    for transfer in list
                        # Check that we have an account and amount saved.
                        for key in  [ 'account_id', 'amount' ]
                            unless transfer[key]
                                def.reject { 'message': "Need to provide `#{key}` in a tranfer" }
                        # Is the amount an actual number?
                        unless not isNaN(parseFloat(transfer.amount)) and isFinite(transfer.amount)
                            def.reject { 'message': "`#{transfer.amount}` is not a number" }
                        # OK, is the amount a 'correct' number?
                        if parseFloat(transfer.amount.toFixed(2)) isnt transfer.amount
                            def.reject { 'message': "`#{transfer.amount}` is not correctly formatted" }
                        # Does the account exist?
                        unless accounts[user_id][transfer.account_id]
                            def.reject { 'message': "User `#{user_id}` does not have account `#{transfer.account_id}`" }

                def.resolve collections

            def.promise

        # All went fine, save the request into the ledger.
        ).then( (collections) ->
            def = Q.defer()
            collections.ledger.insert req.body, { 'safe': true }, (err, doc) ->
                if err then def.reject err
                def.resolve doc
            def.promise

        ).done( ->
            successHandler res
        , (err) ->
            errorHandler res, err
        )

    ###
    Get transactions.
    ###
    @get ->
        req = @req ; res = @res

        # Check API Key.
        Q.fcall( ->
            checkAPIKey req.headers['x-apikey']

        # Get the data.
        ).then( ([ user, collections ]) ->
            q = {}
            q["transfers.#{user.id}"] = '$exists': true

            def = Q.defer()
            collections.ledger.find(q).toArray (err, docs) ->
                if err then def.reject err
                def.resolve [ user, docs ]
            def.promise

        # Calculate the totals for each account.
        ).then( ([ user, docs ]) ->
            accounts = {}
            for doc in docs
                for t in doc.transfers[user.id]
                    accounts[t.account_id] ?= 0
                    accounts[t.account_id] += t.amount

            'accounts':     accounts
            'transactions': docs

        ).done( (results) ->
            successHandler res, results
        , (err) ->
            errorHandler res, err
        )

exports.invite = ->
    ###
    Allow a user to share expenses with us.
    ###
    @post ->
        req = @req ; res = @res

        # Check API Key.
        Q.fcall( ->
            checkAPIKey req.headers['x-apikey']

        # Check the format of req and if the other user exists.
        ).then( ([ user1, collections ]) ->
            # Do we have the user id?
            unless user_id = req.body.user_id
                throw 'Need to provide `user_id` parameter'

            # Sharing with ourselves?
            if user_id is user1.id
                throw 'You cannot share an account with yourself'

            # Get the second user.
            def = Q.defer()
            collections.users.findOne { 'id': user_id }, (err, doc) ->
                if err then def.reject err
                if !doc then def.reject { 'code': 403, 'message': "User `#{user_id}` not found" }
                def.resolve [ user1, doc, collections ]
            def.promise

        # Save the debtor, creditor accounts.
        ).then( ([ user1, user2, collections ]) ->
            # Check we do not have the creditor account already.
            if user1.accounts[user2.id + ':creditor']
                throw "User #{user1.id} already has a creditor account with `#{user2.id}`"
            else
                user1.accounts[user2.id + ':creditor'] = { 'type': 201 }
            
            # Check we do not have the debtor account already.
            if user2.accounts[user1.id + ':debtor']
                throw "User #{user2.id} already has a debtor account with `#{user1.id}`"
            else
                user2.accounts[user1.id + ':debtor'] = { 'type': 103 }

            # Insert the updated user.
            update = (user) ->
                def = Q.defer()
                collections.users.update { 'id': user.id }, user, { 'safe': true }, (err) ->
                    if err then def.reject err
                    def.resolve()
                def.promise

            Q.all [ update(user1), update(user2) ]

        ).done( ->
            successHandler res
        , (err) ->
            errorHandler res, err
        )