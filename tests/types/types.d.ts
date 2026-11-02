declare type MaybeArray<T> = T | Array<T>;
declare type MaybePromise<T> = T | Promise<T>;

declare type RecursiveArray<T> = Array<T | RecursiveArray<T>>;
declare type RecursiveSet<T> = Set<T | RecursiveSet<T>>;
