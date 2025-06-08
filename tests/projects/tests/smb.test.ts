import _ from 'lodash';
import { test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createTcpTests } from '../../utils/tests';

test.describe(apps.samba.title, () => {
    for (const instance of apps.samba.instances) {
        test.describe(instance.title, () => {
            createTcpTests(instance.url, [139, 445]);
        });
    }
});
