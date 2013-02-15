expect         = require('chai').expect
Q              = require 'q'

{ start }      = require '../service.coffee'
{ NodeClient } = require '../node-client.coffee'

# New client.
client         = new NodeClient 'http://127.0.0.1:2120'

# Cleanup the collection in the database.
clean = (collection) ->
    Q.fcall( ->
        def = Q.defer()
        collection.remove {}, (err, removed) ->
            if err then def.reject err
            else def.resolve()
        def.promise
    ).then( ->
        def = Q.defer()
        collection.find({}).toArray (err, results) ->
            if err then def.reject err
            expect(results).to.have.length(0)
            def.resolve()
        def.promise
    )

# Remove `_id`, timestamps coming from MongoDB.
genericise = (obj) ->
    blacklist = [ '_id', 'created' ]
    # Array.
    if obj instanceof Array
        return ( genericise(row) for row in obj )
    # Object.
    if typeof(obj) is 'object'
        # Remove the blacklisted keys.
        for blk in blacklist
            if obj[blk] then delete obj[blk]
        # Go inside.
        nu = {}
        ( nu[k] = genericise(v) for k, v of obj )
        return nu
    # Rest...
    obj

# ----------------------------------------------------------------------------------------------------

describe 'Ledger', ->

    before (done) ->
        start 2120, (app) ->
            app.db (collections) ->
                Q.all([ clean(collections.users), clean(collections.ledger) ]).done(( -> done() ), done)

    describe 'add transaction on an account', ->
        it 'should update the balance', (done) ->
            
            # Create user.
            Q.fcall( ->
                client.addUser 'user:radek'
            
            # Create an account for the user.
            ).then( ->
                client.addAccount 'user:radek',
                    'id':   'hsbc'
                    'type': 102

            # Post a new transaction.
            ).then( ->
                client.addTransaction 'user:radek',
                    'created': (new Date()).getTime()
                    'transfers':
                        'user:radek': [
                            {
                                'amount':      -10.00
                                'account_id':  'hsbc'
                                'description': 'Apple'
                            }
                        ]

            # Get a list of transactions for a user.
            ).then( ->
                client.getTransactions('user:radek').then( (results) ->
                    # Does the response match?
                    expect(genericise results).to.deep.equal
                        'accounts':
                            'hsbc': -10
                        'transactions': [
                            {
                                'transfers':
                                    'user:radek': [
                                        {
                                            'amount':      -10.00
                                            'account_id':  'hsbc'
                                            'description': 'Apple'
                                        }
                                    ]
                            }
                        ]
                )

            ).done(( -> done() ), ( (msg) -> done new Error(msg) ))