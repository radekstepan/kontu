require('chai').should()

f = require '../finances.coffee'

describe 'Expense', ->

    describe 'simple expense on debit account', ->
        it 'should update the balance to negative amount', ->
            usr = new f.User 'A'
            usr.addAccount 'debit', new f.DebitAccount(0)

            usr.should.have.property('accounts')
            usr.accounts.should.have.property('debit')
            acc = usr.accounts.debit
            acc.should.have.property('balance').equal(0)
            acc.addExpense(5.67)
            acc.addExpense(4.13)
            acc.should.have.property('balance').equal(-9.80)

    describe 'simple expense on credit account', ->
        it 'should update the balance to positive amount', ->
            usr = new f.User 'A'
            usr.addAccount 'credit', new f.CreditAccount(0)

            usr.should.have.property('accounts')
            usr.accounts.should.have.property('credit')
            acc = usr.accounts.credit
            acc.should.have.property('balance').equal(0)
            acc.addExpense(5.67)
            acc.addExpense(4.13)
            acc.should.have.property('balance').equal(9.80)

    describe 'an expense shared with a user', ->
        it 'should update the balance in both accounts', ->
            # New system.
            sys = new f.System()
            # Init users.
            usr1 = new f.User 'A'
            usr2 = new f.User 'B'
            # Add them to the system.
            sys.addUser usr1
            sys.addUser usr2

            # Add a debit account to the first user.
            usr1.addAccount 'debit', acc1 = new f.DebitAccount(20)
            
            # Link accounts.
            sys.linkAccounts [ 'A', 'B' ]

            # Check our balance.
            acc1.addSharedExpense 4.99, [ [ 'B', .33 ] ]
            acc1.should.have.property('balance').equal(15.01)

            # Check their balance.
            usr2.accounts.should.have.property('B')
            acc2 = usr2.accounts['B']
            acc2.should.have.property('balance').equal(1.65)