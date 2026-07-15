import 'package:clashkingapp/core/app/my_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS uses the standard Cupertino transition and edge-back gesture', () {
    final transition =
        MyApp.darkTheme.pageTransitionsTheme.builders[TargetPlatform.iOS];

    expect(transition, isA<CupertinoPageTransitionsBuilder>());
  });
}
