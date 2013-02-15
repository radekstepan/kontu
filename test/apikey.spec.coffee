expect          = require('chai').expect
Q               = require 'q'

request         = require 'request'

{ start }       = require '../index'
{ genericise }  = require './helper.coffee'

url = 'http://127.0.0.1:2120'

# ----------------------------------------------------------------------------------------------------

describe 'API Key', ->

    before (done) -> start 2120, (app) -> done()

    beforeEach (done) ->
        request
            'method': 'GET'
            'url': url + '/api/clean'
        , -> done()

    describe 'validate', ->
        it 'fail adding account and not providing api key', (done) ->
            # Create user.
            request
                'method': 'POST'
                'url': url + '/api/users'
                'json':
                    'id':      'user:radek'
                    'api_key': 'key:user:radek'
            , (err, res, body) ->
                
                # Create an account for the user.
                request
                    'method': 'POST'
                    'url': url + '/api/accounts'
                    'json':
                        'id':  'hsbc'
                        'type': 102
                , (err, res, body) ->
                    if res.statusCode isnt 200 then done()
                    else done new Error 'Success, is bad...'

        it 'fail adding account and providing invalid api key', (done) ->
            # Create user.
            request
                'method': 'POST'
                'url': url + '/api/users'
                'json':
                    'id':      'user:radek'
                    'api_key': 'key:user:radek'
            , (err, res, body) ->

                # Create an account for the user.
                request
                    'method': 'POST'
                    'url': url + '/api/accounts'
                    'json':
                        'id':  'hsbc'
                        'type': 102
                    'headers':
                        'x-apikey': 'key:user:test'
                , (err, res, body) ->
                    if res.statusCode isnt 200 then done()
                    else done new Error 'Success, is bad...'