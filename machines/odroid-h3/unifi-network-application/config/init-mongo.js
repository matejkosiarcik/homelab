const fs = require('fs');

const dbName = 'unifi';
const dbName2 = 'unifi_stat';
const user = 'unifi';
const password = fs.readFileSync('/.homelab/mongodb-password.txt', 'utf8').trim();

// This differs a little from the official README, because of authorization problems with the _stat database when using mongo's --auth
// See discussion at https://github.com/linuxserver/docker-unifi-network-application/issues/29
db.getSiblingDB(dbName).createUser({
    user: user,
    pwd: password,
    roles: [
        { role: "dbOwner", db: dbName },
        { role: "dbOwner", db: dbName2 }
    ],
});
