Q = require 'q'

class Account

    constructor: (@kontu) ->

    ###
    Save a new account.
    ###
    post: (req, res) =>
        kontu = @kontu
        
        # Check API Key.
        Q.fcall( =>
            @kontu.checkApi req.headers['x-apikey']

        # Check if doc matches the spec.
        ).then( ([ user, collections ]) =>
            # Does it have all the keys?
            account = req.body
            
            for key in [ 'id', 'type', 'currency' ]
                unless account[key] then throw "Need to provide account `#{key}`"
            
            # Do we have a difference?
            account.difference ?= 0
            # Is the amount an actual number?
            unless not isNaN(parseFloat(account.difference)) and isFinite(account.difference)
                throw "`#{account.difference}` is not a number"
            # OK, is the amount a 'correct' number?
            if parseFloat((parseFloat(account.difference)).toFixed(2)) isnt account.difference
                throw "`#{account.difference}` is not correctly formatted"
            
            # Do we know the account currency?
            account.currency = account.currency.toUpperCase() # match on case
            unless account.currency in @kontu.currencies
                throw "Unknown currency `#{account.currency}`"

            # Key count?
            unless Object.keys(account).length is 4 then throw "Provided incorrect number of keys"

            # Does the account exist already?
            if user.accounts[account.id] then throw "Account `#{account.id}` exists already"
            # Does the type match the types we know about?
            if account.type not in [ 101...112 ].concat [ 201, 206, 210, 220, 250, 270, 300, 350, 360, 370 ]
                throw "Account type `#{account.type}` not known"

            # Add it to the user object.
            user.accounts[account.id] =
                'type':       account.type
                'currency':   account.currency
                'difference': account.difference

            [ user, collections ]

        # Update the user with the new account.
        ).then( ([ user, collections ]) ->
            def = Q.defer()

            collections.users.update { 'id': user.id }, user, { 'safe': true }, (err) ->
                if err then return def.reject err
                def.resolve()
            def.promise

        ).done( =>
            @kontu.success res
        , (err) =>
            @kontu.error res, err
        )

    ###
    Update an account.
    ###
    put: (req, res, id) =>
        kontu = @kontu

        # Check API Key.
        Q.fcall( =>
            @kontu.checkApi req.headers['x-apikey']

        # Check if doc matches the spec.
        ).then( ([ user, collections ]) =>
            # Does it have all the keys?
            account = req.body
            
            for key in [ 'id', 'type', 'currency' ]
                unless account[key] then throw "Need to provide account `#{key}`"
            
            # Do we have a difference?
            account.difference ?= 0
            # Is the amount an actual number?
            unless not isNaN(parseFloat(account.difference)) and isFinite(account.difference)
                throw "`#{account.difference}` is not a number"
            # OK, is the amount a 'correct' number?
            if parseFloat((parseFloat(account.difference)).toFixed(2)) isnt account.difference
                throw "`#{account.difference}` is not correctly formatted"
            
            # Do we know the account currency?
            account.currency = account.currency.toUpperCase() # match on case
            unless account.currency in @kontu.currencies
                throw "Unknown currency `#{account.currency}`"

            # Key count?
            unless Object.keys(account).length is 4 then throw "Provided incorrect number of keys"

            # Does the account not exist already?
            unless user.accounts[id] then throw "Account `#{id}` does not exist"
            # Does the type match the types we know about?
            if account.type not in [ 101...112 ].concat [ 201, 206, 210, 220, 250, 270, 300, 350, 360, 370 ]
                throw "Account type `#{account.type}` not known"

            # Delete the previous account.
            delete user.accounts[id]

            # Create a new account in the user object.
            user.accounts[account.id] =
                'type':       account.type
                'currency':   account.currency
                'difference': account.difference

            [ user, collections ]

        # Update the user with the new account.
        ).then( ([ user, collections ]) ->
            def = Q.defer()

            collections.users.update { 'id': user.id }, user, { 'safe': true }, (err) ->
                if err then return def.reject err
                def.resolve()
            def.promise

        ).done( =>
            @kontu.success res
        , (err) =>
            @kontu.error res, err
        )

    ###
    Get all accounts for a user.
    ###
    get: (req, res) =>
        kontu = @kontu
        
        # Check API Key.
        Q.fcall( =>
            @kontu.checkApi req.headers['x-apikey']

        # Format only the accounts
        ).then( ([ user, collections ]) ->            
            'accounts': user.accounts

        ).done( (results) =>
            @kontu.success res, results
        , (err) =>
            @kontu.error res, err
        )

    ###
    Delete an account.
    ###
    delete: (req, res, id) =>
        # Check API Key.
        Q.fcall( =>
            @kontu.checkApi req.headers['x-apikey']

        # Get the data.
        ).then( ([ user, collections ]) ->
            # Do we recognize the account on us?
            unless user.accounts[id] then throw "Account `#{id}` not recognized"

            # Remove it from the user.
            delete user.accounts[id]

            [ user, collections ]

        # Is the account involved in any transactions?
        ).then( ([ user, collections ]) ->
            q = {}
            q["transfers.#{user.id}.account_id"] = id

            def = Q.defer()
            collections.ledger.find(q).toArray (err, docs) ->
                if err then return def.reject err
                if docs.length isnt 0 then return def.reject { 'message': "Account `#{id}` involved in transactions" }
                def.resolve [ user, collections ]
            def.promise

        # Update the user without the account.
        ).then( ([ user, collections ]) ->
            def = Q.defer()

            collections.users.update { 'id': user.id }, user, { 'safe': true }, (err) ->
                if err then return def.reject err
                def.resolve()
            def.promise

        ).done( =>
            @kontu.success res
        , (err) =>
            @kontu.error res, err
        )

module.exports = Account