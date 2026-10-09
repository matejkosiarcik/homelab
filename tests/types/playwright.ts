import type { Browser, BrowserContext, Page } from '@playwright/test';

export type OverridenPage = Page & {
    /**
     * Specifies whether this is the default test fixture page (not manually opened)
     */
    _default: boolean;

    /**
     * Exact date when the page was opened
     */
    _openedAt: { date: Date, hrtime: bigint };

    /**
     * Specifies whether page is already overridden, to avoid double re-overriding it multiple times
     */
    _overridden: boolean;

    /**
     * Playwright test ID of the test during which this page was opened
     */
    _testid: string;
};

export type OverridenContext = BrowserContext & {
    /**
     * Specifies whether this is the default test fixture context (not manually opened)
     */
    _default: boolean;

    /**
     * Original `.newPage` method
     */
    _newPageOriginal: BrowserContext['newPage'];

    /**
     * Exact date when the context was opened
     */
    _openedAt: { date: Date, hrtime: bigint };

    /**
     * Specifies whether context is already overridden, to avoid double re-overriding it multiple times
     */
    _overridden: boolean;

    /**
     * Playwright test ID of the test during which this page was opened
     */
    _testid: string;
};

export type OverridenBrowser = Browser & {
    /**
     * Specifies whether this is the default test fixture browser (not manually opened)
     */
    _default: boolean;

    /**
     * Original `.newContext` method
     */
    _newContextOriginal: Browser['newContext'];

    /**
     * Original `.newPage` method
     */
    _newPageOriginal: Browser['newPage'];

    /**
     * Exact date when the browser was opened
     */
    _openedAt: { date: Date, hrtime: bigint };

    /**
     * Specifies whether browser is already overridden, to avoid double re-overriding it multiple times
     */
    _overridden: boolean;
};
