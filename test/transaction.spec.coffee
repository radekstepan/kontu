expect         = require('chai').expect
Q              = require 'q'

request        = require 'request'

{ start }      = require '../index'
{ genericise } = require './helper.coffee'

url = 'http://127.0.0.1:2120'

# ----------------------------------------------------------------------------------------------------

describe 'Transaction', ->

    before (done) -> start 2120, (app) -> done()

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
                , (err, res, body) ->
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message
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
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message
                def.promise

            # Post a new transaction.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/transactions'
                    'json':
                        'transfers':
                            'user:radek': [
                                {
                                    'amount':      -10.00
                                    'account_id':  'hsbc'
                                    'description': 'Apple'
                                }
                            ]
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if res.statusCode is 200 then def.reject()
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
                , (err, res, body) ->
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message
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
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message
                def.promise

            # Post a new transaction.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/transactions'
                    'json':
                        'created': 'today'
                        'transfers':
                            'user:radek': [
                                {
                                    'amount':      -10.00
                                    'account_id':  'hsbc'
                                    'description': 'Apple'
                                }
                            ]
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if res.statusCode is 200 then def.reject()
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
                , (err, res, body) ->
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message
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
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message
                def.promise

            # Post a new transaction.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/transactions'
                    'json':
                        'created': (new Date()).getTime()
                        'transfers':
                            'user:radek': [
                                {
                                    'amount':      -10.00
                                    'account_id':  'hsbc'
                                    'description': 'Apple'
                                }
                            ]
                            'user:barbora': [
                                {
                                    'amount':      -10.00
                                    'account_id':  'hsbc'
                                    'description': 'Apple'
                                }
                            ]
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if res.statusCode is 200 then def.reject()
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
                , (err, res, body) ->
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message
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
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message
                def.promise

            # Post a new transaction.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/transactions'
                    'json':
                        'created': (new Date()).getTime()
                        'transfers':
                            'user:radek': [
                                {
                                    'amount':      -10.00
                                    'account_id':  'hsbc'
                                    'description': 'Apple'
                                }, {
                                    'amount':  -10.00
                                    'test':   'azbest'
                                }
                            ]
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if res.statusCode is 200 then def.reject()
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
                , (err, res, body) ->
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message
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
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message
                def.promise

            # Post a new transaction.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/transactions'
                    'json':
                        'created': (new Date()).getTime()
                        'transfers':
                            'user:radek': [
                                {
                                    'amount':      -17.567
                                    'account_id':  'hsbc'
                                    'description': 'Apple'
                                }
                            ]
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if res.statusCode is 200 then def.reject()
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
                , (err, res, body) ->
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message
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
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message
                def.promise

            # Post a new transaction.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/transactions'
                    'json':
                        'created': (new Date()).getTime()
                        'transfers':
                            'user:radek': [
                                {
                                    'amount':      'seven'
                                    'account_id':  'hsbc'
                                    'description': 'Apple'
                                }
                            ]
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if res.statusCode is 200 then def.reject()
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
                , (err, res, body) ->
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message
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
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message
                def.promise

            # Post a new transaction.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/transactions'
                    'json':
                        'created': (new Date()).getTime()
                        'transfers':
                            'user:radek': [
                                {
                                    'amount':      -10.00
                                    'account_id':  'hsbc'
                                    'description': 'Apple'
                                }
                            ]
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message
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
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message
                def.promise

            ).then( (results) ->
                # Does the response match?
                expect(genericise results).to.deep.equal
                    'results':
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
                , (err, res, body) ->
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message
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
                , (err, res, body) ->
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message
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
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message
                def.promise

            # Create an account for user 1.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/accounts'
                    'json':
                        'id':   'hsbc'
                        'type': 102
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message
                def.promise

            # Post a new transaction.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/transactions'
                    'json':
                        'created': (new Date()).getTime()
                        'transfers':
                            'user:radek': [
                                {
                                    'amount':      -10.00
                                    'account_id':  'hsbc'
                                    'description': 'Apple'
                                }, {
                                    'amount':      4.00
                                    'account_id':  'user:barbora:debtor'
                                    'description': 'Apple paid by Radek'
                                }
                            ]
                            'user:barbora': [
                                {
                                    'amount':      -4.00
                                    'account_id':  'user:radek:creditor'
                                    'description': 'Loan for Apple'
                                }
                            ]
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message
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
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message
                def.promise

            ).then( (results) ->
                # Does the response match?
                expect(genericise results).to.deep.equal
                    'results':
                        'accounts':
                            'hsbc':                -10
                            'user:barbora:debtor': 4
                        'transactions': [
                            {
                                'transfers':
                                    'user:radek': [
                                        {
                                            'amount':      -10.00
                                            'account_id':  'hsbc'
                                            'description': 'Apple'
                                        }, {
                                            'amount':      4.00
                                            'account_id':  'user:barbora:debtor'
                                            'description': 'Apple paid by Radek'
                                        }
                                    ]
                                    'user:barbora': [
                                        {
                                            'amount':      -4.00
                                            'account_id':  'user:radek:creditor'
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
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message
                def.promise

            ).then( (results) ->
                # Does the response match?
                expect(genericise results).to.deep.equal
                    'results':
                        'accounts':
                            'user:radek:creditor': -4
                        'transactions': [
                            {
                                'transfers':
                                    'user:radek': [
                                        {
                                            'amount':      -10.00
                                            'account_id':  'hsbc'
                                            'description': 'Apple'
                                        }, {
                                            'amount':      4.00
                                            'account_id':  'user:barbora:debtor'
                                            'description': 'Apple paid by Radek'
                                        }
                                    ]
                                    'user:barbora': [
                                        {
                                            'amount':      -4.00
                                            'account_id':  'user:radek:creditor'
                                            'description': 'Loan for Apple'
                                        }
                                    ]
                            }
                        ]

            ).done(( -> done() ), ( (msg) -> done new Error(msg) ))