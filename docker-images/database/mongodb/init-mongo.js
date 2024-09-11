const fs = require('node:fs');
const process = require('node:process');

const dbName = process.env['DBNAME'];
const user = process.env['USER'];
const password = fs.readFileSync('/homelab/database-password.txt', 'utf8').trim();

db.getSiblingDB(dbName).createUser({
    user: user,
    pwd: password,
    roles: [{ role: 'dbOwner', db: dbName }],
});
