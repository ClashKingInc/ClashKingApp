import { mapWithConcurrencyLimit, MAX_CONCURRENT_TAG_REQUESTS } from './bounded-concurrency';

describe('mapWithConcurrencyLimit', () => {
  it('caps work at 25 operations and preserves input order', async () => {
    let active = 0;
    let peakActive = 0;
    const values = Array.from({ length: 60 }, (_, index) => index);
    const results = await mapWithConcurrencyLimit(values, async (value) => {
      active += 1;
      peakActive = Math.max(peakActive, active);
      await Promise.resolve();
      active -= 1;
      return value * 2;
    });

    expect(peakActive).toBe(MAX_CONCURRENT_TAG_REQUESTS);
    expect(results).toEqual(values.map((value) => value * 2));
  });

  it('rejects invalid concurrency limits', async () => {
    await expect(mapWithConcurrencyLimit([1], (value) => value, 0)).rejects.toBeInstanceOf(
      RangeError,
    );
  });

  it('shares the default cap across simultaneous fan-outs', async () => {
    let active = 0;
    let peakActive = 0;
    const operation = async (value: number) => {
      active += 1;
      peakActive = Math.max(peakActive, active);
      await new Promise<void>((resolve) => setTimeout(resolve, 1));
      active -= 1;
      return value;
    };

    await Promise.all([
      mapWithConcurrencyLimit(
        Array.from({ length: 40 }, (_, index) => index),
        operation,
      ),
      mapWithConcurrencyLimit(
        Array.from({ length: 40 }, (_, index) => index),
        operation,
      ),
    ]);
    expect(peakActive).toBeLessThanOrEqual(MAX_CONCURRENT_TAG_REQUESTS);
  });

  it('waits for queued work before rethrowing the first input-ordered error', async () => {
    const finished: number[] = [];
    await expect(
      mapWithConcurrencyLimit(
        [0, 1, 2, 3],
        async (value) => {
          await Promise.resolve();
          finished.push(value);
          if (value === 1 || value === 3) throw new Error(`failure-${value}`);
          return value;
        },
        2,
      ),
    ).rejects.toThrow('failure-1');
    expect(finished.sort()).toEqual([0, 1, 2, 3]);
  });
});
