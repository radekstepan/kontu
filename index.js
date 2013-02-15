module.exports = process.env.KONTU_COV
    ? require('./lib-cov/service.js')
    : require('./lib/service.js');