import fsx from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import axios from 'axios';
import { assert } from 'simple-assert';
import sleep from 'sleep-promise';

type AppBase = {
    defaultPriority: number,
    description: string,
    name: string,
};

type AppPost = AppBase;

type AppGet = AppPost & {
    id: number,
};

async function loadApps(file: string): Promise<AppPost[]> {
    const fileContent = await fsx.readFile(file, 'utf8');
    const fileObj = JSON.parse(fileContent) as { apps: AppPost[] };
    return fileObj.apps;
}

// Compare local-app with server-app
// @return - true on equality, false if they differ
function compareApp(localApp: AppPost, serverApp: AppGet): boolean {
    const properties = ['defaultPriority', 'description', 'name'] satisfies (keyof typeof localApp)[];
    const equals = properties.every((property) => localApp[property] === serverApp[property]);
    return equals;
}

async function syncApps() {
    // Load new apps
    const localApps = await loadApps('apps.json');

    // Load existing apps in database
    const serverApps = await (async () => {
        console.log('Loading list of existing apps');
        const response = await axios.get('/application');
        assert(response.status === 200, `Failed to fetch list of apps\nStatus: ${response.status}\nBody: ${response.data}`);
        const body = response.data as AppGet[];
        return body;
    })();

    console.log('Existing apps:', serverApps);

    // Delete apps in database which are no longer used
    const appsToDelete = serverApps.filter((el1) => !localApps.find((el2) => el2.name === el1.name));
    for (const serverApp of appsToDelete) {
        console.log(`Deleting app ${serverApp.name}`);
        await (async () => {
            const response = await axios.delete(`/application/${serverApp.id}`);
            assert(response.status === 200, `Failed to delete app\nStatus: ${response.status}\nBody: ${response.data}`);
        })();
    }

    // Edit existing apps in database
    const appsToEdit = serverApps.filter((el1) => localApps.find((el2) => el2.name === el1.name));
    for (const serverApp of appsToEdit) {
        const localApp = localApps.find((el) => el.name === serverApp.name)!;
        if (!compareApp(localApp, serverApp)) {
            serverApp.description = localApp.description;
            serverApp.defaultPriority = localApp.defaultPriority;
            await (async () => {
                console.log(`Updating app ${serverApp.name}`);
                const response = await axios.put(`/application/${serverApp.id}`, serverApp);
                assert(response.status === 200, `Failed to update app ${serverApp.name}\nStatus: ${response.status}\nBody: ${response.data}`);
            })();
        } else {
            console.log(`App ${serverApp.name} already up-to-date.`);
        }
    }

    // Add new apps to database
    const appsToAdd = localApps.filter((el1) => !serverApps.find((el2) => el2.name === el1.name));
    for (const localApp of appsToAdd) {
        await (async () => {
            console.log(`Creating app ${localApp.name}`);
            const response = await axios.post('/application', localApp, {
                headers: {
                    'Content-Type': 'application/json',
                },
            });
            assert(response.status === 200, `Failed to create app\nStatus: ${response.status}\nBody: ${response.data}`);
        })();
    }
}

type UserBase = {
    admin: boolean,
    name: string,
};

type UserPost = UserBase & {
    pass: string,
}

type UserGet = UserBase & {
    id: number,
};

async function loadUsers(file: string): Promise<UserPost[]> {
    const fileContent = await fsx.readFile(file, 'utf8');
    const fileObj = (JSON.parse(fileContent) as { users: UserPost[] });
    return fileObj.users.map((user) => {
        user.pass = (process.env[`USER_${user.name.toUpperCase().replaceAll(/[ -]+/g, '_')}_PASSWORD`] || (() => { throw new Error(`User ${user.name} password missing in environment`) })());
        return user;
    });
}

async function syncUsers() {
    // Load new users
    const localUsers = await loadUsers('users.json');

    // Load existing apps in database
    const serverUsers = await (async () => {
        console.log('Loading list of existing users');
        const response = await axios.get('/user');
        assert(response.status === 200, `Failed to fetch list of users\nStatus: ${response.status}\nBody: ${response.data}`);
        const body = response.data as UserGet[];
        return body;
    })();

    console.log('Existing users:', serverUsers);

    // Delete users in database which are no longer used
    const usersToDelete = serverUsers.filter((el1) => !localUsers.find((el2) => el2.name === el1.name));
    for (const serveruser of usersToDelete) {
        console.log(`Deleting user ${serveruser.name}`);
        await (async () => {
            const response = await axios.delete(`/user/${serveruser.id}`);
            assert(response.status === 200, `Failed to delete user\nStatus: ${response.status}\nBody: ${response.data}`);
        })();
    }

    // Edit existing users in database
    const usersToEdit = serverUsers.filter((el1) => localUsers.find((el2) => el2.name === el1.name));
    for (const serverUser of usersToEdit) {
        const localUser = localUsers.find((el) => el.name === serverUser.name)!;
        serverUser.admin = localUser.admin;
        const editUser = {
            ...serverUser,
            pass: localUser.pass,
        }
        console.log('User:', editUser);
        await (async () => {
            console.log(`Updating user ${serverUser.name}`);
            const response = await axios.post(`/user/${serverUser.id}`, editUser);
            assert(response.status === 200, `Failed to update user ${serverUser.name}\nStatus: ${response.status}\nBody: ${response.data}`);
        })();
    }

    // Add new users to database
    const usersToAdd = localUsers.filter((el1) => !serverUsers.find((el2) => el2.name === el1.name));
    for (const localUser of usersToAdd) {
        await (async () => {
            console.log(`Creating user ${localUser.name}`);
            const response = await axios.post('/user', localUser, {
                headers: {
                    'Content-Type': 'application/json',
                },
            });
            assert(response.status === 200, `Failed to create user\nStatus: ${response.status}\nBody: ${response.data}`);
        })();
    }
}
(async () => {
    const statusFile = path.join('tmpfs', 'status.txt');
    await fsx.mkdir(path.dirname(statusFile), { recursive: true });
    await fsx.writeFile(statusFile, 'starting', 'utf8');

    axios.defaults.headers.common['Authorization'] = `Basic ${Buffer.from(`${process.env['GOTIFY_DEFAULTUSER_NAME']}:${process.env['GOTIFY_DEFAULTUSER_PASS']}`, 'utf8').toString('base64')}`;

    axios.defaults.baseURL = `http://app:80`;
    axios.defaults.validateStatus = () => true;

    console.log('Waiting for gotify to start');
    const startDate = new Date();
    while (true) {
        const currentDate = new Date();
        const elapsedSeconds = (currentDate.getTime() - startDate.getTime()) / 1000;
        if (elapsedSeconds > 60) {
            throw new Error("Couldn't connect to gotify app in reasonable time.");
        }

        try {
            const response = await axios.get('/');
            assert(response.status === 200, `Failed to connect to gotify app\nStatus: ${response.status}\n`);
            break;
        } catch {
            await sleep(1000);
        }
    }
    console.log('Gotify status OK');

    await syncApps();
    await syncUsers();

    console.log('Setup successful');
    await fsx.writeFile(statusFile, 'started', 'utf8');

    // Sleep forever
    while (true) {
        await sleep(Math.pow(2, 31) - 1);
    }
})();
