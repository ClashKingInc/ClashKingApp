import 'package:clashkingapp/core/utils/bounded_concurrency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('caps work at 25 operations while preserving input order', () async {
    var active = 0;
    var peakActive = 0;

    final results = await mapWithConcurrencyLimit(
      List.generate(60, (index) => index),
      (index) async {
        active++;
        if (active > peakActive) peakActive = active;
        await Future<void>.delayed(Duration.zero);
        active--;
        return index * 2;
      },
    );

    expect(peakActive, maxConcurrentTagRequests);
    expect(results, List.generate(60, (index) => index * 2));
  });

  test('normalizes invalid concurrency limits into an argument error', () {
    expect(
      () => mapWithConcurrencyLimit(
        const [1],
        (value) => value,
        maxConcurrent: 0,
      ),
      throwsArgumentError,
    );
  });

  test('shares the default cap across simultaneous fan-outs', () async {
    var active = 0;
    var peakActive = 0;

    Future<int> operation(int value) async {
      active++;
      if (active > peakActive) peakActive = active;
      await Future<void>.delayed(const Duration(milliseconds: 1));
      active--;
      return value;
    }

    await Future.wait([
      mapWithConcurrencyLimit(List.generate(40, (index) => index), operation),
      mapWithConcurrencyLimit(List.generate(40, (index) => index), operation),
    ]);

    expect(peakActive, lessThanOrEqualTo(maxConcurrentTagRequests));
  });
}
