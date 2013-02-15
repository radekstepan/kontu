expect         = require('chai').expect
Q              = require 'q'

request        = require 'request'

{ start }      = require '../index'
{ genericise } = require './helper.coffee'

url = 'http://127.0.0.1:2120'

# ----------------------------------------------------------------------------------------------------

describe 'Account', ->

    before (done) -> start 2120, (app) -> done()

    beforeEach (done) ->
        request
            'method': 'GET'
            'url': url + '/api/clean'
        , -> done()

    describe 'add', ->
        it 'fail adding account to nonexistent user', (done) ->
            # Create an account for nonexistent user.
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
                if res.statusCode isnt 200 then done()
                else done new Error 'Success, is bad...'

        it 'fail adding account using wrong params', (done) ->
            # Create user.
            request
                'method': 'POST'
                'url': url + '/api/users'
                'json':
                    'id':      'user:radek'
                    'api_key': 'key:user:radek'
                    'currency': 'GBP'
            , (err, res, body) ->
                if err then done err
               
                # Create an account for the user.
                request
                    'method': 'POST'
                    'url': url + '/api/accounts'
                    'json':
                        'test': 'azbest'
                        'type': 102
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode isnt 200 then done()
                    else done new Error 'Success, is bad...'

        it 'fail adding account using different number of params', (done) ->
            # Create user.
            request
                'method': 'POST'
                'url': url + '/api/users'
                'json':
                    'id':      'user:radek'
                    'api_key': 'key:user:radek'
                    'currency': 'GBP'
            , (err, res, body) ->
                if err then done err
               
                # Create an account for the user.
                request
                    'method': 'POST'
                    'url': url + '/api/accounts'
                    'json':
                        'id':       'hsbc'
                        'type':     102
                        'currency': 'GBP'
                        'category': 666
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode isnt 200 then done()
                    else done new Error 'Success, is bad...'

        it 'fail adding account using wrong account type', (done) ->
            # Create user.
            request
                'method': 'POST'
                'url': url + '/api/users'
                'json':
                    'id':      'user:radek'
                    'api_key': 'key:user:radek'
                    'currency': 'GBP'
            , (err, res, body) ->
                if err then done err
               
                # Create an account for the user.
                request
                    'method': 'POST'
                    'url': url + '/api/accounts'
                    'json':
                        'id':   'hsbc'
                        'type': 'mine'
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode isnt 200 then done()
                    else done new Error 'Success, is bad...'

        it 'fail adding account that already exists', (done) ->
            # Create user.
            request
                'method': 'POST'
                'url': url + '/api/users'
                'json':
                    'id':      'user:radek'
                    'api_key': 'key:user:radek'
                    'currency': 'GBP'
            , (err, res, body) ->
                if err then done err
               
                # Create an account for the user.
                request
                    'method': 'POST'
                    'url': url + '/api/accounts'
                    'json':
                        'id':       'hsbc'
                        'type':     109
                        'currency': 'GBP'
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode isnt 200 then new Error body.message

                    # Create an account for the user.
                    request
                        'method': 'POST'
                        'url': url + '/api/accounts'
                        'json':
                            'id':       'hsbc'
                            'type':     210
                            'currency': 'GBP'
                        'headers':
                            'x-apikey': 'key:user:radek'
                    , (err, res, body) ->
                        if err then done err
                        if res.statusCode isnt 200 then done()
                        else done new Error 'Success, is bad...'

        it 'success adding account with a pre-existing amount', (done) ->
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
                        'difference': 15.67
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
                                'balance': 5.67
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

        it 'success updating an account', (done) ->
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
                        'difference': 15.67
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise

            # Update the account.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'PUT'
                    'url': url + '/api/accounts/hsbc'
                    'json':
                        'id':       'hsbc'
                        'type':     102
                        'currency': 'GBP'
                        'difference': 25.67
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve body
                    else return def.reject body.message
                def.promise

            # Get the account listing.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'GET'
                    'url': url + '/api/accounts'
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
                                'type':       102
                                'currency':   'GBP'
                                'difference': 25.67

            ).done(( -> done() ), ( (msg) -> done new Error(msg) ))