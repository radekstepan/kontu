require('chai').should()

Q              = require 'q'

{ start }      = require '../service.coffee'
{ NodeClient } = require '../node-client.coffee'

# New client.
client         = new NodeClient 'http://127.0.0.1:2121'

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
            results.should.have.property('length').equal(0)
            def.resolve()
        def.promise
    )

# ----------------------------------------------------------------------------------------------------

describe 'Ledger', ->

    before (done) ->
        start 2121, (app) ->
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
                    'user:radek': [
                        {
                            'amount':      -10.00
                            'account_id':  'hsbc'
                            'description': 'Apple'
                        }
                    ]
            ).done(( -> done() ), ( (msg) -> done new Error(msg) ))