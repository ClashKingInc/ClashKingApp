import 'package:flutter/widgets.dart';
import 'package:workmanager_android/workmanager_android.dart';
import 'package:workmanager_platform_interface/workmanager_platform_interface.dart';

typedef BackgroundTaskHandler =
    Future<bool> Function(String taskName, Map<String, dynamic>? inputData);

class AndroidWorkmanagerService {
  AndroidWorkmanagerService._();

  static final AndroidWorkmanagerService instance =
      AndroidWorkmanagerService._();

  static BackgroundTaskHandler? _backgroundTaskHandler;

  Future<void> initialize(Function callbackDispatcher) {
    WorkmanagerPlatform.instance = WorkmanagerAndroid();
    return WorkmanagerPlatform.instance.initialize(callbackDispatcher);
  }

  void executeTask(BackgroundTaskHandler backgroundTaskHandler) async {
    WidgetsFlutterBinding.ensureInitialized();

    _backgroundTaskHandler = backgroundTaskHandler;
    final flutterApi = _AndroidWorkmanagerFlutterApi();
    WorkmanagerFlutterApi.setUp(flutterApi);

    await flutterApi.backgroundChannelInitialized();
  }

  Future<void> registerPeriodicTask(
    String uniqueName,
    String taskName, {
    Duration? frequency,
  }) {
    WorkmanagerPlatform.instance = WorkmanagerAndroid();
    return WorkmanagerPlatform.instance.registerPeriodicTask(
      uniqueName,
      taskName,
      frequency: frequency,
    );
  }
}

class _AndroidWorkmanagerFlutterApi extends WorkmanagerFlutterApi {
  @override
  Future<void> backgroundChannelInitialized() async {}

  @override
  Future<bool> executeTask(
    String taskName,
    Map<String?, Object?>? inputData,
  ) async {
    final convertedInputData = inputData == null
        ? null
        : {
            for (final entry in inputData.entries)
              if (entry.key != null) entry.key!: entry.value,
          };

    final result = await AndroidWorkmanagerService._backgroundTaskHandler?.call(
      taskName,
      convertedInputData,
    );
    return result ?? false;
  }
}
