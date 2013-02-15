Q = require 'q'

class Invite

    constructor: (@kontu) ->

    ###
    Allow a user to share expenses with us.
    ###
    post: (req, res) =>
        # Check API Key.
        Q.fcall( =>
            @kontu.checkApi req.headers['x-apikey']

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
                user1.accounts[user2.id + ':creditor'] =
                    'type':       201
                    'difference': 0
            
            # Check we do not have the debtor account already.
            if user2.accounts[user1.id + ':debtor']
                throw "User #{user2.id} already has a debtor account with `#{user1.id}`"
            else
                user2.accounts[user1.id + ':debtor'] =
                    'type':       103
                    'difference': 0

            # Insert the updated user.
            update = (user) ->
                def = Q.defer()
                collections.users.update { 'id': user.id }, user, { 'safe': true }, (err) ->
                    if err then def.reject err
                    def.resolve()
                def.promise

            Q.all [ update(user1), update(user2) ]

        ).done( =>
            @kontu.success res
        , (err) =>
            @kontu.error res, err
        )

module.exports = Invite