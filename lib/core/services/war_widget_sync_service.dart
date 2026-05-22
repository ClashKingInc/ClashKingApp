import 'dart:io';

import 'package:clashkingapp/core/utils/debug_utils.dart';
import 'package:clashkingapp/widgets/war_widget.dart';
import 'package:clashkingapp/widgets/widgets_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:workmanager/workmanager.dart';

class WarWidgetSyncService {
  const WarWidgetSyncService();

  void registerPeriodicRefresh() {
    if (!kIsWeb && Platform.isAndroid) {
      Workmanager().registerPeriodicTask(
        '1',
        'simplePeriodicTask',
        frequency: const Duration(minutes: 15),
      );
    }
  }

  Future<void> initializeFromBackground(Uri data) async {
    await updateWidgets();
  }

  Future<void> updateWidgets() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await updateWarWidget();
    }
  }

  Future<void> updateWarWidget() async {
    try {
      final clanTag = await WarWidgetService.getCurrentPlayerClanTag();
      final warInfo = await fetchWarSummary(clanTag);

      await HomeWidget.saveWidgetData<String>('warInfo', warInfo);
      await HomeWidget.updateWidget(
        name: 'WarAppWidgetProvider',
        androidName: 'WarAppWidgetProvider',
      );

      DebugUtils.debugSuccess("War widget updated successfully");
    } catch (exception, stackTrace) {
      Sentry.captureException(exception, stackTrace: stackTrace);
      DebugUtils.debugError(" Error updating war widget: $exception");
    }
  }
}
