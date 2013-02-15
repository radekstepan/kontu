Mediator = require 'chaplin/core/Mediator'

View = require 'chaplin/core/View'

module.exports = class LedgerView extends View

    container:       'body'
    containerMethod: 'html'
    autoRender:      true

    getTemplateFunction: -> require 'chaplin/templates/ledger'

    afterRender: ->
        super

        $(@el).foundationCustomForms()