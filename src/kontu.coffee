Q = require 'q'

User        = require './user'
Invite      = require './invite'
Account     = require './account'
Transaction = require './transaction'

class Kontu

    # We understand these currencies.
    currencies: [ 'USD', 'CZK', 'GBP', 'EUR' ]

    constructor: (@db) ->
        user = new User @
        @user =
            # Save new user.
            post: -> user.post @req, @res

        invite = new Invite @
        @invite =
            # Make an invite.
            post: -> invite.post @req, @res

        account = new Account @
        @account =
            # Save new account.
            post: -> account.post @req, @res
            # Get all accounts.
            get: ->  account.get  @req, @res
            
            '/:id':
                # Update a specific account.
                put: (id) -> account.put @req, @res, id
                # Delete a specific account.
                delete: (id) -> account.delete @req, @res, id
        
        transaction = new Transaction @
        @transaction =
            # Save new transaction.
            post: ->   transaction.post @req, @res
            # Get all transactions.
            get: ->    transaction.get  @req, @res

            '/:id':
                # Update a specific transaction.
                put: (id) -> transaction.put @req, @res, id
                # Delete a specific transaction.
                delete: (id) -> transaction.delete @req, @res, id

    # Check that API Key is valid.
    checkApi: (api_key) =>
        # Which user is this for?
        Q.fcall( ->
            # Provided key?
            unless api_key then throw { 'message': 'API key not provided' }
            else api_key
        
        # Gives us db access.
        ).then( (api_key) =>
            def = Q.defer()
            @db (collections) -> def.resolve [ api_key, collections ]
            def.promise
        
        # Check we know this user.
        ).then( ([ api_key, collections ]) ->
            def = Q.defer()
            collections.users.findOne { 'api_key': api_key }, (err, doc) ->
                if err then return def.reject err
                if !doc then return def.reject { 'code': 403, 'message': "API key `#{api_key}` is not allowed" }
                def.resolve [ doc, collections ]
            def.promise
        )

    # Promise fulfilled.
    success: (res, results='ok') ->
        res.writeHead 200, 'content-type': 'application/json'
        res.write JSON.stringify 'results': results
        res.end()

    # Promise not fulfilled.
    error: (res, err) ->
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

module.exports = Kontu