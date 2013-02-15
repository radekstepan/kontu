Q = require 'q'

class Kontu

    # We understand these currencies.
    currencies: [ 'USD', 'CZK', 'GBP', 'EUR' ]

    constructor: (@db) ->

    user: (service) =>
        User = require './user'
        user = new User @
        service.post -> user.post @req, @res

    invite: (service) =>
        Invite = require './invite'
        invite = new Invite @
        service.post -> invite.post @req, @res

    account: (service) =>
        Account = require './account'
        account = new Account @
        service.post -> account.post @req, @res
        service.get ->  account.get  @req, @res
        service.put ->  account.put  @req, @res

    transaction: (service) =>
        Transaction = require './transaction'
        transaction = new Transaction @
        service.post -> transaction.post @req, @res
        service.get ->  transaction.get  @req, @res

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
                if err then def.reject err
                if !doc then def.reject { 'code': 403, 'message': "API key `#{api_key}` is not allowed" }
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