REPORTER = spec

test:
	@NODE_ENV=test ./node_modules/.bin/mocha --compilers coffee:coffee-script --reporter $(REPORTER)

test-cov: prep-coverage
	@KONTU_COV=1 $(MAKE) test REPORTER=html-cov > coverage.html

prep-coverage: cs-compile node-coverage

cs-compile:
	@coffee -c -o lib/ src/

node-coverage:
	rm -fr lib-cov/
	@jscoverage lib lib-cov

.PHONY: test