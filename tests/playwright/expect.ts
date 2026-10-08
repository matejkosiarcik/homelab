import { expect as baseExpect } from '@playwright/test';
import { extendExpect } from './expect-library';

const customExpect = extendExpect(baseExpect);

export const expect = customExpect;
