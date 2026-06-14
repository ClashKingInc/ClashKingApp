import 'dart:io';

import 'package:clashkingapp/core/services/android_workmanager_service.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';
import 'package:clashkingapp/widgets/war_widget.dart';
import 'package:clashkingapp/widgets/widgets_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

const String _widgetAppGroup = 'group.com.clashking.apps';

class WarWidgetSyncService {
  const WarWidgetSyncService();

  void registerPeriodicRefresh() {
    if (!kIsWeb && Platform.isAndroid) {
      AndroidWorkmanagerService.instance.registerPeriodicTask(
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
      if (!kIsWeb && Platform.isIOS) {
        await HomeWidget.setAppGroupId(_widgetAppGroup);
      }
      final clanTag = await WarWidgetService.getCurrentPlayerClanTag();
      final warInfo = await fetchWarSummary(clanTag);

      await HomeWidget.saveWidgetData<String>(
        'warInfo',
        warInfo,
        appGroupId: !kIsWeb && Platform.isIOS ? _widgetAppGroup : null,
      );
      await HomeWidget.updateWidget(
        name: 'WarWidget',
        androidName: 'WarAppWidgetProvider',
        iOSName: 'WarWidget',
      );

      DebugUtils.debugSuccess("War widget updated successfully");
    } catch (exception, stackTrace) {
      Sentry.captureException(exception, stackTrace: stackTrace);
      DebugUtils.debugError(" Error updating war widget: $exception");
    }
  }
}
