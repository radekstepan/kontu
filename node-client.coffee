Q       = require 'q'
request = require 'request'

# Node.js client used for testing the API.
class NodeClient

    constructor: (@url) ->

    # Create a user.
    addUser: (user_id) ->
        def = Q.defer()
        request
            'method': 'POST'
            'url': @url + '/api/users'
            'json':
                'id':      user_id
                'api_key': 'key:'  + user_id
        , (err, res, body) ->
            if err then def.reject err
            if res.statusCode isnt 200 then def.reject body.message
            def.resolve()
        def.promise

    # Add an account for a user.
    addAccount: (user_id, account) ->
        def = Q.defer()
        request
            'method': 'POST'
            'url': @url + '/api/accounts'
            'json': account
            'headers':
                'x-apikey': 'key:' + user_id
        , (err, res, body) ->
            if err then def.reject err
            if res.statusCode isnt 200 then def.reject body.message
            def.resolve()
        def.promise

    # Add a transaction as a user.
    addTransaction: (user_id, transactions) ->
        def = Q.defer()
        request
            'method': 'POST'
            'url': @url + '/api/transactions'
            'json':
                'transactions': transactions
            'headers':
                'x-apikey': 'key:' + user_id
        , (err, res, body) ->
            if err then def.reject err
            if res.statusCode isnt 200 then def.reject body.message
            def.resolve()
        def.promise

exports.NodeClient = NodeClient