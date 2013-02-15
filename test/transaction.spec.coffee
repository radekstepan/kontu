expect          = require('chai').expect
Q               = require 'q'

request         = require 'request'

{ start }       = require '../index'
{ genericise }  = require './helper.coffee'

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
        it 'for simple transactions', (done) ->
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
                    else def.reject res.message
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
                    else def.reject res.message
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
                    else def.reject res.message
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
                    else def.reject res.message
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