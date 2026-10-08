import { test as baseTest } from '@playwright/test';
import { expect as baseExpect } from './expect.ts';

const customExpect = baseExpect;
const customTest = baseTest;
customTest.expect = baseExpect;

export const test = customTest;
export const expect = customExpect;
