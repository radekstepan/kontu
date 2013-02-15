expect          = require('chai').expect
Q               = require 'q'

request         = require 'request'

{ startServer } = require '../index.js'
{ genericise }  = require './helper.coffee'

url = 'http://127.0.0.1:2120'

# ----------------------------------------------------------------------------------------------------

describe 'Transaction', ->

    before (done) -> startServer 2120, null, (app) -> done()

    beforeEach (done) ->
        request
            'method': 'GET'
            'url': url + '/api/clean'
        , -> done()

    describe 'add', ->
        it 'fail not providing creation date', (done) ->
            # Create user.
            Q.fcall( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/users'
                    'json':
                        'id':      'user:radek'
                        'api_key': 'key:user:radek'
                        'currency': 'GBP'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise
            
            # Create an account for the user.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/accounts'
                    'json':
                        'id':       'hsbc'
                        'type':     102
                        'currency': 'GBP'
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise

            # Post a new transaction.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/transactions'
                    'json':
                        'amount': 10.00
                        'currency': 'GBP'
                        'transfers':
                            'user:radek': [
                                {
                                    'amount':      -10.00
                                    'account_id':  'hsbc'
                                    'currency':    'GBP'
                                    'description': 'Apple'
                                }
                            ]
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then return def.reject()
                    else def.resolve()
                def.promise

            ).done(( -> done() ), ( (msg) -> done new Error(msg) ))

        it 'fail providing manky creation date', (done) ->
            # Create user.
            Q.fcall( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/users'
                    'json':
                        'id':      'user:radek'
                        'api_key': 'key:user:radek'
                        'currency': 'GBP'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise
            
            # Create an account for the user.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/accounts'
                    'json':
                        'id':       'hsbc'
                        'type':     102
                        'currency': 'GBP'
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise

            # Post a new transaction.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/transactions'
                    'json':
                        'amount': 10.00
                        'currency': 'GBP'
                        'created': 'today'
                        'transfers':
                            'user:radek': [
                                {
                                    'amount':      -10.00
                                    'account_id':  'hsbc'
                                    'currency':    'GBP'
                                    'description': 'Apple'
                                }
                            ]
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then return def.reject()
                    else def.resolve()
                def.promise
            
            ).done(( -> done() ), ( (msg) -> done new Error(msg) ))

        it 'fail adding transaction for nonexistent user', (done) ->
            # Create user.
            Q.fcall( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/users'
                    'json':
                        'id':      'user:radek'
                        'api_key': 'key:user:radek'
                        'currency': 'GBP'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise
            
            # Create an account for the user.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/accounts'
                    'json':
                        'id':       'hsbc'
                        'type':     102
                        'currency': 'GBP'
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise

            # Post a new transaction.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/transactions'
                    'json':
                        'amount': 10.00
                        'currency': 'GBP'
                        'created': (new Date()).getTime()
                        'transfers':
                            'user:radek': [
                                {
                                    'amount':      -10.00
                                    'account_id':  'hsbc'
                                    'currency':    'GBP'
                                    'description': 'Apple'
                                }
                            ]
                            'user:barbora': [
                                {
                                    'amount':      -10.00
                                    'account_id':  'hsbc'
                                    'currency':    'GBP'
                                    'description': 'Apple'
                                }
                            ]
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then return def.reject()
                    else def.resolve()
                def.promise
            
            ).done(( -> done() ), ( (msg) -> done new Error(msg) ))

        it 'fail adding transaction with incorrect transfer object', (done) ->
            # Create user.
            Q.fcall( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/users'
                    'json':
                        'id':      'user:radek'
                        'api_key': 'key:user:radek'
                        'currency': 'GBP'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise
            
            # Create an account for the user.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/accounts'
                    'json':
                        'id':       'hsbc'
                        'type':     102
                        'currency': 'GBP'
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise

            # Post a new transaction.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/transactions'
                    'json':
                        'amount': 10.00
                        'currency': 'GBP'
                        'created': (new Date()).getTime()
                        'transfers':
                            'user:radek': [
                                {
                                    'amount':      -10.00
                                    'account_id':  'hsbc'
                                    'currency':    'GBP'
                                    'description': 'Apple'
                                }, {
                                    'amount':   -10.00
                                    'currency': 'GBP'
                                    'test':     'azbest'
                                }
                            ]
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then return def.reject()
                    else def.resolve()
                def.promise
            
            ).done(( -> done() ), ( (msg) -> done new Error(msg) ))

        it 'fail adding transaction with incorrectly rounded transfer amount', (done) ->
            # Create user.
            Q.fcall( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/users'
                    'json':
                        'id':      'user:radek'
                        'api_key': 'key:user:radek'
                        'currency': 'GBP'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise
            
            # Create an account for the user.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/accounts'
                    'json':
                        'id':       'hsbc'
                        'type':     102
                        'currency': 'GBP'
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise

            # Post a new transaction.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/transactions'
                    'json':
                        'amount': 10.00
                        'currency': 'GBP'
                        'created': (new Date()).getTime()
                        'transfers':
                            'user:radek': [
                                {
                                    'amount':      -17.567
                                    'account_id':  'hsbc'
                                    'currency':    'GBP'
                                    'description': 'Apple'
                                }
                            ]
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then return def.reject()
                    else def.resolve()
                def.promise
            
            ).done(( -> done() ), ( (msg) -> done new Error(msg) ))

        it 'fail adding transaction with incorrect transfer amount type', (done) ->
            # Create user.
            Q.fcall( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/users'
                    'json':
                        'id':      'user:radek'
                        'api_key': 'key:user:radek'
                        'currency': 'GBP'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise
            
            # Create an account for the user.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/accounts'
                    'json':
                        'id':       'hsbc'
                        'type':     102
                        'currency': 'GBP'
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise

            # Post a new transaction.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/transactions'
                    'json':
                        'amount': 10.00
                        'currency': 'GBP'
                        'created': (new Date()).getTime()
                        'transfers':
                            'user:radek': [
                                {
                                    'amount':      'seven'
                                    'account_id':  'hsbc'
                                    'currency':    'GBP'
                                    'description': 'Apple'
                                }
                            ]
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then return def.reject()
                    else def.resolve()
                def.promise
            
            ).done(( -> done() ), ( (msg) -> done new Error(msg) ))

        it 'success for simple transactions', (done) ->
            # Create user.
            Q.fcall( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/users'
                    'json':
                        'id':      'user:radek'
                        'api_key': 'key:user:radek'
                        'currency': 'GBP'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise
            
            # Create an account for the user.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/accounts'
                    'json':
                        'id':       'hsbc'
                        'type':     102
                        'currency': 'GBP'
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise

            # Post a new transaction.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/transactions'
                    'json':
                        'amount': 10.00
                        'currency': 'GBP'
                        'created': (new Date()).getTime()
                        'transfers':
                            'user:radek': [
                                {
                                    'amount':      -10.00
                                    'account_id':  'hsbc'
                                    'currency':    'GBP'
                                    'description': 'Apple'
                                }
                            ]
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise

            # Get a list of transactions for a user.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'GET'
                    'url': url + '/api/transactions'
                    'json': {}
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise

            ).then( (results) ->
                # Does the response match?
                expect(genericise results).to.deep.equal
                    'results':
                        'accounts':
                            'hsbc':
                                'type': 102
                                'currency': 'GBP'
                                'balance': -10
                        'transactions': [
                            {
                                'amount': 10.00
                                'currency': 'GBP'
                                'transfers':
                                    'user:radek': [
                                        {
                                            'amount':      -10.00
                                            'account_id':  'hsbc'
                                            'currency':    'GBP'
                                            'description': 'Apple'
                                        }
                                    ]
                            }
                        ]

            ).done(( -> done() ), ( (msg) -> done new Error(msg) ))

        it 'success for shared transactions', (done) ->
            # Create user 1.
            Q.fcall( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/users'
                    'json':
                        'id':      'user:radek'
                        'api_key': 'key:user:radek'
                        'currency': 'GBP'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise
            
            # Create user 2.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/users'
                    'json':
                        'id':      'user:barbora'
                        'api_key': 'key:user:barbora'
                        'currency': 'GBP'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise

            # Allow user 1 to share expenses with user 2.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/invite'
                    'json':
                        'user_id': 'user:radek'
                    'headers':
                        'x-apikey': 'key:user:barbora'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise

            # Create an account for user 1.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/accounts'
                    'json':
                        'id':       'hsbc'
                        'type':     102
                        'currency': 'GBP'
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise

            # Post a new transaction.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/transactions'
                    'json':
                        'amount': 10.00
                        'currency': 'GBP'
                        'created': (new Date()).getTime()
                        'transfers':
                            'user:radek': [
                                {
                                    'amount':      -10.00
                                    'account_id':  'hsbc'
                                    'currency':    'GBP'
                                    'description': 'Apple'
                                }, {
                                    'amount':      4.00
                                    'account_id':  'user:barbora:debtor'
                                    'currency':    'GBP'
                                    'description': 'Apple paid by Radek'
                                }
                            ]
                            'user:barbora': [
                                {
                                    'amount':      -4.00
                                    'account_id':  'user:radek:creditor'
                                    'currency':    'GBP'
                                    'description': 'Loan for Apple'
                                }
                            ]
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise

            # Get a list of transactions for user1.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'GET'
                    'url': url + '/api/transactions'
                    'json': {}
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise

            ).then( (results) ->
                # Does the response match?
                expect(genericise results).to.deep.equal
                    'results':
                        'accounts':
                            'hsbc':
                                'type': 102
                                'currency': 'GBP'
                                'balance': -10
                            'user:barbora:debtor':
                                'type': 103
                                'currency': 'GBP'
                                'balance': 4
                        'transactions': [
                            {
                                'amount': 10.00
                                'currency': 'GBP'
                                'transfers':
                                    'user:radek': [
                                        {
                                            'amount':      -10.00
                                            'account_id':  'hsbc'
                                            'currency':    'GBP'
                                            'description': 'Apple'
                                        }, {
                                            'amount':      4.00
                                            'account_id':  'user:barbora:debtor'
                                            'currency':    'GBP'
                                            'description': 'Apple paid by Radek'
                                        }
                                    ]
                                    'user:barbora': [
                                        {
                                            'amount':      -4.00
                                            'account_id':  'user:radek:creditor'
                                            'currency':    'GBP'
                                            'description': 'Loan for Apple'
                                        }
                                    ]
                            }
                        ]

            # Get a list of transactions for user2.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'GET'
                    'url': url + '/api/transactions'
                    'json': {}
                    'headers':
                        'x-apikey': 'key:user:barbora'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise

            ).then( (results) ->
                # Does the response match?
                expect(genericise results).to.deep.equal
                    'results':
                        'accounts':
                            'user:radek:creditor':
                                'type': 201
                                'currency': 'GBP'
                                'balance': -4
                        'transactions': [
                            {
                                'amount': 10.00
                                'currency': 'GBP'
                                'transfers':
                                    'user:radek': [
                                        {
                                            'amount':      -10.00
                                            'account_id':  'hsbc'
                                            'currency':    'GBP'
                                            'description': 'Apple'
                                        }, {
                                            'amount':      4.00
                                            'account_id':  'user:barbora:debtor'
                                            'currency':    'GBP'
                                            'description': 'Apple paid by Radek'
                                        }
                                    ]
                                    'user:barbora': [
                                        {
                                            'amount':      -4.00
                                            'account_id':  'user:radek:creditor'
                                            'currency':    'GBP'
                                            'description': 'Loan for Apple'
                                        }
                                    ]
                            }
                        ]

            ).done(( -> done() ), ( (msg) -> done new Error(msg) ))

        it 'success deleting a transaction', (done) ->
            # Create user.
            Q.fcall( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/users'
                    'json':
                        'id':      'user:radek'
                        'api_key': 'key:user:radek'
                        'currency': 'GBP'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise
            
            # Create an account for the user.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/accounts'
                    'json':
                        'id':       'hsbc'
                        'type':     102
                        'currency': 'GBP'
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise

            # Post a new transaction.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/transactions'
                    'json':
                        'amount': 10.00
                        'currency': 'GBP'
                        'created': (new Date()).getTime()
                        'transfers':
                            'user:radek': [
                                {
                                    'amount':      -10.00
                                    'account_id':  'hsbc'
                                    'currency':    'GBP'
                                    'description': 'Apple'
                                }
                            ]
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body.results.id
                    else return def.reject body.message
                def.promise

            # Remove the transaction.
            ).then( (id) ->
                def = Q.defer()
                request
                    'method': 'DELETE'
                    'url': url + "/api/transactions/#{id}"
                    'json': {}
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise

            # Get a list of transactions for a user.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'GET'
                    'url': url + '/api/transactions'
                    'json': {}
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise

            ).then( (results) ->
                # Does the response match?
                expect(genericise results).to.deep.equal
                    'results':
                        'accounts':
                            'hsbc':
                                'type': 102
                                'currency': 'GBP'
                                'balance': 0
                        'transactions': []

            ).done(( -> done() ), ( (msg) -> done new Error(msg) ))

        it 'success updating a transaction', (done) ->
            # Create user.
            Q.fcall( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/users'
                    'json':
                        'id':      'user:radek'
                        'api_key': 'key:user:radek'
                        'currency': 'GBP'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise
            
            # Create an account for the user.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/accounts'
                    'json':
                        'id':       'hsbc'
                        'type':     102
                        'currency': 'GBP'
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise

            # Post a new transaction.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/transactions'
                    'json':
                        'amount': 10.00
                        'currency': 'GBP'
                        'created': (new Date()).getTime()
                        'transfers':
                            'user:radek': [
                                {
                                    'amount':      -10.00
                                    'account_id':  'hsbc'
                                    'currency':    'GBP'
                                    'description': 'Apple'
                                }
                            ]
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body.results.id
                    else return def.reject body.message
                def.promise

            # Update the transaction.
            ).then( (id) ->
                def = Q.defer()
                request
                    'method': 'PUT'
                    'url': url + "/api/transactions/#{id}"
                    'json':
                        'amount':   13.20
                        'currency': 'EUR'
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise

            # Get a list of transactions for a user.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'GET'
                    'url': url + '/api/transactions'
                    'json': {}
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise

            ).then( (results) ->
                # Does the response match?
                expect(genericise results).to.deep.equal
                    'results':
                        'accounts':
                            'hsbc':
                                'type': 102
                                'currency': 'GBP'
                                'balance': -10
                        'transactions': [
                            {
                                'amount': 13.20
                                'currency': 'EUR'
                                'transfers':
                                    'user:radek': [
                                        {
                                            'amount':      -10.00
                                            'account_id':  'hsbc'
                                            'currency':    'GBP'
                                            'description': 'Apple'
                                        }
                                    ]
                            }
                        ]

            ).done(( -> done() ), ( (msg) -> done new Error(msg) ))