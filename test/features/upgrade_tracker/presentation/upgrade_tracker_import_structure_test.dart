import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('snapshot import invalidates page loads only after validation', () {
    final source = File(
      'lib/features/upgrade_tracker/presentation/upgrade_tracker_page.dart',
    ).readAsStringSync();
    final methodStart = source.indexOf(
      'Future<void> _importSnapshotBytes(List<int> bytes)',
    );
    final importCall = source.indexOf(
      'await _repository.importSnapshotBytes(',
      methodStart,
    );
    final generationIncrement = source.indexOf(
      '++_selectionGeneration;',
      methodStart,
    );
    final stateUpdate = source.indexOf('setState(() {', importCall);

    expect(methodStart, greaterThanOrEqualTo(0));
    expect(importCall, greaterThan(methodStart));
    expect(generationIncrement, greaterThan(importCall));
    expect(generationIncrement, lessThan(stateUpdate));
  });
}
