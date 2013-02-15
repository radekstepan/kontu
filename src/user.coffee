Q = require 'q'

class User

    constructor: (@kontu) ->

    ###
    Save a new user.
    ###
    post: (req, res) =>
        # Get the data posted.
        Q.fcall( ->
            user = req.body
            for key in  [ 'id', 'api_key', 'currency' ]
                unless user[key] then throw "Need to provide user `#{key}`"
            unless Object.keys(user).length is 3 then throw "Provided incorrect number of keys"
            user

        # Gives us db access.
        ).then( (user) =>
            def = Q.defer()
            @kontu.db (collections) -> def.resolve [ user, collections ]
            def.promise
        
        # Does the user already exist?
        ).then( ([ user, collections ]) ->
            def = Q.defer()
            collections.users.findOne { 'id': user.id }, (err, doc) ->
                if err then return def.reject err
                if doc then return def.reject { 'code': 400, 'message': "User `#{user.id}` already exists" }
                def.resolve [ user, collections ]
            def.promise

        # Save the new information.
        ).then( ([ user, collections ]) ->
            def = Q.defer()

            # Reject any accounts trying to be saved with the user. A blank slate.
            user.accounts = {}

            collections.users.insert user, { 'safe': true }, (err) ->
                if err then return def.reject err
                def.resolve user
            def.promise

        ).done( =>
            @kontu.success res
        , (err) =>
            @kontu.error res, err
        )

module.exports = User