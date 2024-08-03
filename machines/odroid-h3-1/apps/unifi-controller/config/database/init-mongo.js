const fs = require('fs');
const process = require('process');

const dbName = process.env['DBNAME'];
const dbName2 = `${process.env['DBNAME']}_stat`;
const user = process.env['USER'];
const password = fs.readFileSync('/.homelab/database-password.txt', 'utf8').trim();

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
