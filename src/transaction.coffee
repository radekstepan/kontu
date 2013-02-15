Q = require 'q'

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
                        if parseFloat((parseFloat(transfer.amount)).toFixed(2)) isnt transfer.amount
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

        ).done( =>
            @kontu.success res
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
                if err then def.reject err
                def.resolve [ user, docs ]
            def.promise

        # Calculate the totals for each account.
        ).then( ([ user, docs ]) ->
            accounts = {}
            for doc in docs
                for t in doc.transfers[user.id]
                    accounts[t.account_id] ?= user.accounts[t.account_id].difference
                    accounts[t.account_id] += t.amount
            
            'accounts':     accounts
            'transactions': docs

        ).done( (results) =>
            @kontu.success res, results
        , (err) =>
            @kontu.error res, err
        )

module.exports = Transaction