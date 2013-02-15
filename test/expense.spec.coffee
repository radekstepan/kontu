should = require('chai').should()

describe 'Expense', ->

    foo = "bar"
    beverages = tea: [ 'chai', 'matcha', 'oolong' ]

    it 'it should work', ->
        foo.should.be.a "string"
        foo.should.equal "bar"
        foo.should.have.length 3
        beverages.should.have.property("tea").with.length 3