let dbName = '';
let user = '';
let password = '';

// The following try/catch is to ensure this script works in both `mongo` and `mongosh`
try {
    process = require('node:process');
    dbName = process.env['DBNAME'];
    user = process.env['USER'];
    password = process.env['PASSWORD'];
} catch {
    dbName = _getEnv('DBNAME');
    user = _getEnv('USER');
    password = _getEnv('PASSWORD');
}

db.getSiblingDB(dbName).createUser({
    user: user,
    pwd: password,
    roles: [{ role: 'dbOwner', db: dbName }],
});
