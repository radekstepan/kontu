#!/usr/bin/env node
switch (process.env.NODE_ENV) {
    case 'dev':
        p = require('procstreams');
        p('./node_modules/.bin/brunch watch --server').out();
        break;
    case 'test':
        module.exports = (process.env.KONTU_COV) ? require('./lib-cov/service.js') : require('./lib/service.js');
        break;
    default:
        service = require('./lib/service.js');
        service.startServer(process.env.PORT);
}