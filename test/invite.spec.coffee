expect         = require('chai').expect
Q              = require 'q'

request        = require 'request'

{ start }      = require '../index'
{ genericise } = require './helper.coffee'

url = 'http://127.0.0.1:2120'

# ----------------------------------------------------------------------------------------------------

describe 'Invite', ->

    before (done) -> start 2120, (app) -> done()

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
                , (err, res, body) ->
                    if res.statusCode is 200 then def.resolve body
                    else def.reject body.message

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
                    if res.statusCode is 200 then def.reject body
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
                , (err, res, body) ->
                    if res.statusCode is 200 then def.resolve()
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
                        'x-apikey': 'key:user:radek'
                , (err, res, body) ->
                    if res.statusCode is 200 then def.reject()
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
                , (err, res, body) ->
                    if res.statusCode is 200 then def.resolve()
                    else def.reject body.message
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
                    if res.statusCode is 200 then def.reject()
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
                , (err, res, body) ->
                    if res.statusCode is 200 then def.resolve()
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
                    if res.statusCode is 200 then def.resolve()
                    else def.reject body.message
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
                    if res.statusCode is 200 then def.resolve()
                    else def.reject()
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
                    if res.statusCode is 200 then def.reject()
                    else def.resolve()
                def.promise

            ).done(( -> done() ), ( (msg) -> done new Error(msg) ))