Q  = require 'q'

# Database access.
db = null

# Set db access.
exports.app = (app) -> db = app.db

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
            collections.users.insert user, { 'safe': true }, (err) ->
                if err then def.reject err
                def.resolve [ user, collections ]
            def.promise

        # Query for us to make sure.
        ).then( ([ user, collections ]) ->
            def = Q.defer()
            collections.users.findOne 'id': user.id, (err, doc) ->
                if err then def.reject err
                if !doc then def.reject { 'code': 500, 'message': "We should be saving `#{user.id}` but we ain't" }
                def.resolve doc
            def.promise

        ).done( (user) ->
            # Respond.
            res.writeHead 200, 'content-type': 'application/json'
            res.write JSON.stringify 'message': "User `#{user.id}` created"
            res.end()
        , (err) ->
            code = err.code or 400
            message = err.message or 'Error'
            # Respond.
            res.writeHead code, 'content-type': 'application/json'
            res.write JSON.stringify 'message': message
            res.end()
        )

exports.transactions = ->
    ###
    Save a new transaction.
    ###
    @post ->
        req = @req ; res = @res
        
        # Which user is this for?
        Q.fcall( ->
            api_key = req.headers['x-apikey']
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
                def.resolve doc
            def.promise
        
        # Do we know all the accounts and users?.
        ).then( (user) ->
            for user_id, list of req.body.transactions
                # This is us.
                if user_id is user.id
                    1
                # Do we share an account with this user?
                else
                    if user_id + ':debtor' in user.accounts or user_id + ':creditor' in user.accounts
                        1
                    else
                        throw "Cannot add transaction for user `#{user_id}`"

        ).done( ->
            # Respond.
            res.writeHead 200, 'content-type': 'application/json'
            res.end()
        , (err) ->
            code = err.code or 400
            message = err.message or 'Error'
            # Respond.
            res.writeHead code, 'content-type': 'application/json'
            res.write JSON.stringify 'message': message
            res.end()
        )

    ###
    Get all transactions for a user.
    ###
    @get ->
        @res.end()