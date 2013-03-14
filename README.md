# Kontu API

A web service for a ledger based budgetting app using MongoDB as a data store.

[ ![Codeship Status for radekstepan/kontu](https://www.codeship.io/projects/98ac3c10-6f12-0130-b089-22000a9d02dd/status?branch=master)](https://www.codeship.io/projects/1945)

## Quickstart

To run the app in `ukraine` cloud:

```bash
$ node index.js
```

To start the app in Chaplin app dev mode using Brunch:

```bash
$ NODE_ENV=dev node index.js
```

To compile the API code from CoffeeScript to JavaScript:

```bash
$ make cs-compile
```

To run tests against the API using Mocha:

```bash
$ make test
```

To see API coverage using JSCoverage and Mocha reporter:

```bash
$ make test-cov
```