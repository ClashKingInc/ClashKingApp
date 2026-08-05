import 'package:clashkingapp/common/widgets/loading/skeleton_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('skeleton loader renders with configured dimensions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SkeletonLoader(
            width: 80,
            height: 12,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );

    expect(find.byType(SkeletonLoader), findsOneWidget);
    expect(tester.getSize(find.byType(SkeletonLoader)), const Size(80, 12));
  });

  testWidgets('skeleton action indicator keeps a compact square footprint', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SkeletonActionIndicator(width: 24, height: 8)),
      ),
    );

    expect(
      tester.getSize(find.byType(SkeletonActionIndicator)),
      const Size(24, 24),
    );
    expect(find.byType(SkeletonLoader), findsOneWidget);
  });

  testWidgets('skeleton page composes header and list placeholders', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SkeletonPage(itemCount: 3))),
    );

    expect(find.byType(SkeletonPage), findsOneWidget);
    expect(find.byType(SkeletonList), findsOneWidget);
    expect(find.byType(SkeletonListItem), findsNWidgets(3));
  });

  testWidgets('skeleton loading dialog renders a bounded material surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SkeletonLoadingDialog())),
    );

    expect(find.byType(SkeletonLoadingDialog), findsOneWidget);
    expect(find.byType(Material), findsWidgets);
    expect(find.byType(SkeletonLoader), findsNWidgets(3));
  });

  testWidgets('war and stat skeleton cards render their placeholder shapes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(children: [WarStatsSkeletonCard(), StatCardSkeleton()]),
        ),
      ),
    );

    expect(find.byType(WarStatsSkeletonCard), findsOneWidget);
    expect(find.byType(StatCardSkeleton), findsOneWidget);
    expect(find.byType(SkeletonLoader), findsWidgets);
  });
}
