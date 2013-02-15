Controller = require 'chaplin/core/Controller'

LedgerView = require 'chaplin/views/Ledger'

module.exports = class LedgerController extends Controller

    historyURL: (params) -> ''

    index: (params) ->
        @views.push new LedgerView()
        @adjustTitle 'Ledger'