import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('sizes memory decoding without distorting the source ratio', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(devicePixelRatio: 2),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 20,
                height: 30,
                child: MobileWebImage(imageUrl: 'https://example.com/icon.png'),
              ),
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.memCacheWidth, 40);
    expect(image.memCacheHeight, isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}
