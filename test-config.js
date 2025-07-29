// test-config.js
const database = require('./config/database');
const server = require('./config/server');

console.log('Database config:', database({ env: (key, defaultValue) => process.env[key] || defaultValue }));
console.log('Server config:', server({ env: (key, defaultValue) => process.env[key] || defaultValue }));