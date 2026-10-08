import { expect as baseExpect } from '@playwright/test';

const customExpect = baseExpect;

export const expect = customExpect;
