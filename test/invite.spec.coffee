expect          = require('chai').expect
Q               = require 'q'

request         = require 'request'

{ startServer } = require '../index.js'
{ genericise }  = require './helper.coffee'

url = 'http://127.0.0.1:2120'

# ----------------------------------------------------------------------------------------------------

describe 'Invite', ->

    before (done) -> startServer 2120, null, (app) -> done()

    beforeEach (done) ->
        request
            'method': 'GET'
            'url': url + '/api/clean'
        , -> done()

    describe 'add', ->
        it 'fail providing wrong params', (done) ->
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

            # Allow user 1 to share expenses with user 2.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/invite'
                    'json': {}
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then return def.reject body
                    else def.resolve()
                def.promise

            ).done(( -> done() ), ( (msg) -> done new Error(msg) ))

        it 'fail linking account with self', (done) ->
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
                    if res.statusCode is 200 then def.resolve()
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
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then return def.reject()
                    else def.resolve()
                def.promise

            ).done(( -> done() ), ( (msg) -> done new Error(msg) ))

        it 'fail linking with nonexistent user', (done) ->
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
                    if res.statusCode is 200 then def.resolve()
                    else return def.reject body.message
                def.promise

            # Allow user 1 to share expenses with user 2.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/invite'
                    'json':
                        'user_id': 'user:barbora'
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then return def.reject()
                    else def.resolve()
                def.promise

            ).done(( -> done() ), ( (msg) -> done new Error(msg) ))

        it 'fail linking with already linked user', (done) ->
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
                    if res.statusCode is 200 then def.resolve()
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
                    if res.statusCode is 200 then def.resolve()
                    else return def.reject body.message
                def.promise

            # Allow user 1 to share expenses with user 2.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/invite'
                    'json':
                        'user_id': 'user:barbora'
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then def.resolve()
                    else return def.reject()
                def.promise

            # Allow user 1 to share expenses with user 2.
            ).then( ->
                def = Q.defer()
                request
                    'method': 'POST'
                    'url': url + '/api/invite'
                    'json':
                        'user_id': 'user:barbora'
                    'headers':
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if err then done err
                    if res.statusCode is 200 then return def.reject()
                    else def.resolve()
                def.promise

            ).done(( -> done() ), ( (msg) -> done new Error(msg) ))