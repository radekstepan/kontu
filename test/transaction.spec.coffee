require('chai').should()

Q         = require 'q'
request   = require 'request'

{ start } = require '../service.coffee'

url = 'http://127.0.0.1:2121'

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

describe 'Ledger', ->

    before (done) ->
        start 2121, (app) ->
            app.db (collections) ->
                Q.all([ clean(collections.users), clean(collections.ledger) ]).done(( -> done() ), done)

    describe 'add transaction on an account', ->
        it 'should update the balance', (done) ->
            
            # Create user.
            Q.fcall( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/users'
                    'json':
                        'id':      'user:radek'
                        'api_key': '@dummy!'
                , (err, res, body) ->
                    if err then def.reject err
                    if res.statusCode isnt 200 then def.reject body.message
                    def.resolve()
                def.promise
            
            # Create an account for the user.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/accounts'
                    'json':
                        'id':   'hsbc'
                        'type': 102
                    'headers':
                        'x-apikey': '@dummy!'
                , (err, res, body) ->
                    if err then def.reject err
                    if res.statusCode isnt 200 then def.reject body.message
                    def.resolve()
                def.promise

            # Post a new transaction.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/transactions'
                    'json':
                        'transactions':
                            'user:radek': [
                                {
                                    'amount':      -10.00
                                    'account_id':  'hsbc'
                                    'description': 'Apple'
                                }
                            ]
                    'headers':
                        'x-apikey': '@dummy!'
                , (err, res, body) ->
                    if err then def.reject err
                    if res.statusCode isnt 200 then def.reject body.message
                    def.resolve()
                def.promise
            ).done(( -> done() ), ( (msg) -> done new Error(msg) ))