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

        ).done( =>
            @kontu.success res
        , (err) =>
            @kontu.error res, err
        )

module.exports = Account