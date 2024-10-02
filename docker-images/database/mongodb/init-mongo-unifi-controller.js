let dbName = '';
let dbName2 = '';
let user = '';
let password = '';

// The following try/catch is to ensure this script works in both `mongo` and `mongosh`
try {
    process = require('node:process');
    dbName = process.env['DBNAME'];
    dbName2 = `${process.env['DBNAME']}_stat`;
    user = process.env['USER'];
    password = process.env['PASSWORD'];
} catch {
    dbName = _getEnv('DBNAME');
    dbName2 = `${_getEnv('DBNAME')}_stat`;
    user = _getEnv('USER');
    password = _getEnv('PASSWORD');
}

// This differs a little from the official README, because of authorization problems with the "_stat" database when using mongo's --auth
// See discussion at https://github.com/linuxserver/docker-unifi-network-application/issues/29
db.getSiblingDB(dbName).createUser({
    user: user,
    pwd: password,
    roles: [
        { role: 'dbOwner', db: dbName },
        { role: 'dbOwner', db: dbName2 }
    ],
});
