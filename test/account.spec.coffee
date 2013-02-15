expect          = require('chai').expect
Q               = require 'q'

request         = require 'request'

{ start }       = require '../index'
{ genericise }  = require './helper.coffee'

url = 'http://127.0.0.1:2120'

# ----------------------------------------------------------------------------------------------------

describe 'Account', ->

    before (done) -> start 2120, (app) -> done()

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
                    'id':   'hsbc'
                    'type': 102
                'headers':
                    'x-apikey': 'key:user:radek'
            , (err, res, body) ->
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
            , (err, res, body) ->
               
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
            , (err, res, body) ->
               
                # Create an account for the user.
                request
                    'method': 'POST'
                    'url': url + '/api/accounts'
                    'json':
                        'id':       'hsbc'
                        'type':     102
                        'category': 666
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
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
            , (err, res, body) ->
               
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
            , (err, res, body) ->
               
                # Create an account for the user.
                request
                    'method': 'POST'
                    'url': url + '/api/accounts'
                    'json':
                        'id':   'hsbc'
                        'type': 109
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if res.statusCode isnt 200 then new Error body.message

                    # Create an account for the user.
                    request
                        'method': 'POST'
                        'url': url + '/api/accounts'
                        'json':
                            'id':   'hsbc'
                            'type': 210
                        'headers':
                            'x-apikey': 'key:user:radek'
                    , (err, res, body) ->
                        if res.statusCode isnt 200 then done()
                        else done new Error 'Success, is bad...'