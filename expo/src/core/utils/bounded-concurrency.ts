export const MAX_CONCURRENT_TAG_REQUESTS = 25;

class AsyncRequestLimiter {
  private readonly pending: (() => void)[] = [];
  private active = 0;

  constructor(readonly maxConcurrent: number) {}

  run<Result>(operation: () => Result | PromiseLike<Result>): Promise<Result> {
    return new Promise<Result>((resolve, reject) => {
      const start = () => {
        this.active += 1;
        void Promise.resolve()
          .then(operation)
          .then(resolve, reject)
          .finally(() => {
            this.active -= 1;
            this.pending.shift()?.();
          });
      };

      if (this.active < this.maxConcurrent) start();
      else this.pending.push(start);
    });
  }
}

const sharedTagRequestLimiter = new AsyncRequestLimiter(MAX_CONCURRENT_TAG_REQUESTS);

/**
 * Maps values in input order with a bounded number of operations in flight.
 * Queued work finishes before the first input-ordered error is rethrown,
 * matching the frozen Flutter implementation's non-eager Future.wait behavior.
 */
export async function mapWithConcurrencyLimit<Input, Result>(
  items: Iterable<Input>,
  operation: (item: Input) => Result | PromiseLike<Result>,
  maxConcurrent = MAX_CONCURRENT_TAG_REQUESTS,
): Promise<readonly Result[]> {
  if (!Number.isInteger(maxConcurrent) || maxConcurrent < 1) {
    throw new RangeError('maxConcurrent must be an integer greater than or equal to 1.');
  }

  const values = [...items];
  if (values.length === 0) return [];
  const limiter =
    maxConcurrent === MAX_CONCURRENT_TAG_REQUESTS
      ? sharedTagRequestLimiter
      : new AsyncRequestLimiter(maxConcurrent);
  const results: (Result | undefined)[] = new Array(values.length);
  const errors: (unknown | undefined)[] = new Array(values.length);
  let nextIndex = 0;

  const worker = async () => {
    while (nextIndex < values.length) {
      const index = nextIndex;
      nextIndex += 1;
      try {
        results[index] = await limiter.run(() => operation(values[index]!));
      } catch (error) {
        errors[index] = error;
      }
    }
  };

  const workerCount = Math.min(values.length, maxConcurrent);
  await Promise.all(Array.from({ length: workerCount }, worker));
  const firstError = errors.find((error) => error !== undefined);
  if (firstError !== undefined) throw firstError;
  return results as Result[];
}
