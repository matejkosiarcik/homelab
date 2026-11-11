declare module 'p-parallel' {
    export default function pParallel<Result>(
        promiseFactories: Array<() => PromiseLike<Result>>,
        parallelLimit?: number,
    ): Promise<Result[]>;
}
