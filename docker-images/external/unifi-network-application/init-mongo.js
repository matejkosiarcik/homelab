let dbName = '';
let user = '';
let password = '';

// The following try/catch is to ensure this script works in both `mongo` and `mongosh`
try {
    process = require('node:process');
    dbName = process.env['MONGO_DBNAME'];
    user = process.env['MONGO_USER'];
    password = process.env['MONGO_PASSWORD'];
} catch {
    dbName = _getEnv('MONGO_DBNAME');
    user = _getEnv('MONGO_USER');
    password = _getEnv('MONGO_PASSWORD');
}

db.getSiblingDB(dbName).createUser({
    user: user,
    pwd: password,
    roles: [
        { role: 'dbOwner', db: dbName },
        { role: 'dbOwner', db: `${dbName}_stat` },
        { role: 'dbOwner', db: `${dbName}_audit` }
    ],
});
