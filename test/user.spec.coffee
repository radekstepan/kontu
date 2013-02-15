expect         = require('chai').expect

request        = require 'request'

{ start }      = require '../index'
{ genericise } = require './helper.coffee'

url = 'http://127.0.0.1:2120'

# ----------------------------------------------------------------------------------------------------

describe 'User', ->

    before (done) -> start 2120, (app) -> done()

    beforeEach (done) ->
        request
            'method': 'GET'
            'url': url + '/api/clean'
        , -> done()

    describe 'add', ->
        it 'fail adding user using wrong params', (done) ->
            # Create user.
            request
                'method': 'POST'
                'url': url + '/api/users'
                'json':
                    'id':   'user:radek'
                    'test': 'key:user:radek'
                    'currency': 'GBP'
            , (err, res, body) ->
                if err then done err
                if res.statusCode isnt 200 then done()
                else done new Error 'Success, is bad...'

        it 'fail adding user using different number of params', (done) ->
            # Create user.
            request
                'method': 'POST'
                'url': url + '/api/users'
                'json':
                    'id':          'user:radek'
                    'api_key':     'key:user:radek'
                    'permissions': 'root'
                    'currency':    'GBP'
            , (err, res, body) ->
                if err then done err
                if res.statusCode isnt 200 then done()
                else done new Error 'Success, is bad...'

        it 'fail adding user that already exists', (done) ->
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
                if res.statusCode isnt 200 then new Error body.message

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
                    if res.statusCode isnt 200 then done()
                    else done new Error 'Success, is bad...'