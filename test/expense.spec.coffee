require('chai').should()

f = require '../finances.coffee'

describe 'Expense', ->

    describe 'simple expense on debit account', ->
        acc = new f.DebitAccount(0)
        it 'should update the balance to negative amount', ->
            acc.should.have.property('balance').equal(0)
            acc.addExpense(5.67)
            acc.addExpense(4.13)
            acc.should.have.property('balance').equal(-9.80)

    describe 'simple expense on credit account', ->
        acc = new f.CreditAccount(0)
        it 'should update the balance to positive amount', ->
            acc.should.have.property('balance').equal(0)
            acc.addExpense(5.67)
            acc.addExpense(4.13)
            acc.should.have.property('balance').equal(9.80)