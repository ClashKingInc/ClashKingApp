import 'dart:io';

import 'package:clashkingapp/core/config/app_feature_flags.dart';
import 'package:clashkingapp/core/services/android_workmanager_service.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';
import 'package:clashkingapp/core/services/remote_feature_flag_service.dart';
import 'package:clashkingapp/widgets/war_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:clashkingapp/core/services/error_reporter.dart';

const String _widgetAppGroup = 'group.com.clashking.apps';

class WarWidgetSyncService {
  const WarWidgetSyncService();

  static Future<bool> areWarWidgetsEnabled({
    RemoteFeatureFlagService? featureFlagService,
  }) async {
    final service = featureFlagService ?? RemoteFeatureFlagService();
    try {
      await service.refresh();
    } catch (_) {
      // Established widget behavior fails open if remote config is unavailable.
    }
    return service.isEnabled(
      AppFeatureFlags.warWidgets,
      fallback: AppFeatureFlags.defaultValue(AppFeatureFlags.warWidgets),
    );
  }

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
      final cachedClans = await WarWidgetService.getCachedClanOptions();
      if (cachedClans.isNotEmpty) {
        await WarWidgetService.prepareClanWidgets(cachedClans);
        DebugUtils.debugSuccess("War widgets updated successfully");
        return;
      }

      final clanTag = await WarWidgetService.getCurrentPlayerClanTag();
      if (clanTag != null && clanTag.isNotEmpty) {
        await WarWidgetService.refreshWarInfoForClan(
          clanTag,
          makeDefault: true,
        );
      }
      await HomeWidget.updateWidget(
        name: 'WarWidget',
        androidName: 'WarAppWidgetProvider',
        iOSName: 'WarWidget',
      );

      DebugUtils.debugSuccess("War widget updated successfully");
    } catch (exception, stackTrace) {
      ErrorReporter.captureException(
        exception,
        stackTrace: stackTrace,
        operation: 'widget.update',
      );
      DebugUtils.debugError(" Error updating war widget: $exception");
    }
  }
}
