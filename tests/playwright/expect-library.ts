import { expect as baseExpect } from '@playwright/test';

export type ExtendedExpect = typeof baseExpect;

export function extendExpect(expect: typeof baseExpect): ExtendedExpect {
    return expect;
}
