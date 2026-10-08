import type { Browser, BrowserContext, Page } from '@playwright/test';

export type OverridenPage = Page & {
    /**
     * Specifies whether page is already overridden, to avoid double re-overriding it multiple times
     */
    _overridden: boolean;

    /**
     * Specifies whether this is the default test fixture page (not manually opened)
     */
    _default: boolean;

    /**
     * Exact date when the page was opened
     */
    _openedAt: { date: Date, hrtime: bigint };
};

export type OverridenContext = BrowserContext & {
    /**
     * Specifies whether context is already overridden, to avoid double re-overriding it multiple times
     */
    _overridden: boolean;

    /**
     * Specifies whether this is the default test fixture context (not manually opened)
     */
    _default: boolean;

    /**
     * Exact date when the context was opened
     */
    _openedAt: { date: Date, hrtime: bigint };

    /**
     * Original `.newPage` method
     */
    _newPageOriginal: BrowserContext['newPage'];
};

export type OverridenBrowser = Browser & {
    /**
     * Specifies whether browser is already overridden, to avoid double re-overriding it multiple times
     */
    _overridden: boolean;

    /**
     * Specifies whether this is the default test fixture browser (not manually opened)
     */
    _default: boolean;

    /**
     * Exact date when the browser was opened
     */
    _openedAt: { date: Date, hrtime: bigint };

    /**
     * Original `.newContext` method
     */
    _newContextOriginal: Browser['newContext'];

    /**
     * Original `.newPage` method
     */
    _newPageOriginal: Browser['newPage'];
};
