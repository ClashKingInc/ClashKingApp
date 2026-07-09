import 'dart:io';

import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _kWarStateGroup = 'War state';

class NotificationDebugService {
  static const MethodChannel _channel = MethodChannel(
    'clashking/notification_debug',
  );

  static bool get isSupportedPlatform => !kIsWeb && Platform.isIOS;

  static List<NotificationSample> get fallbackSamples => [
    NotificationSample(
      id: 'leagueDefense',
      label: 'League defense',
      group: 'Battles',
      title: 'League defense result',
      body: 'Lord Clasher attacked Magic Jr. • 90% • 2 stars',
      assetUrl: ImageAssets.legendBlazon,
    ),
    NotificationSample(
      id: 'warDefense',
      label: 'War attack',
      group: 'Battles',
      title: 'War attack on TH18',
      body: 'Pine Riders attacked Magic Jr. • 78% • 2 stars',
      assetUrl: ImageAssets.war,
    ),
    NotificationSample(
      id: 'warMatched',
      label: 'War matched',
      group: _kWarStateGroup,
      title: 'War matched',
      body: 'Home Clan matched with Pine Riders. Preparation day started.',
      assetUrl: ImageAssets.warClan,
    ),
    NotificationSample(
      id: 'warStarted',
      label: 'War started',
      group: _kWarStateGroup,
      title: 'Battle day started',
      body: 'Home Clan vs Pine Riders is live. Good luck.',
      assetUrl: ImageAssets.sword,
    ),
    NotificationSample(
      id: 'warEnded',
      label: 'War ended',
      group: _kWarStateGroup,
      title: 'War ended',
      body: 'Home Clan 86-82 Pine Riders.',
      assetUrl: ImageAssets.warClan,
    ),
    NotificationSample(
      id: 'warReminder60',
      label: 'War reminder: 1h',
      group: 'Reminders',
      title: '1 hour left',
      body: 'Magic Jr. has remaining war attacks. 1 hour left.',
      assetUrl: ImageAssets.iconClock,
    ),
    NotificationSample(
      id: 'warReminder30',
      label: 'War reminder: 30m',
      group: 'Reminders',
      title: '30 minutes left',
      body: 'Magic Jr. has remaining war attacks. 30 minutes left.',
      assetUrl: ImageAssets.iconClock,
    ),
    NotificationSample(
      id: 'warReminder15',
      label: 'War reminder: 15m',
      group: 'Reminders',
      title: '15 minutes left',
      body: 'Magic Jr. has remaining war attacks. 15 minutes left.',
      assetUrl: ImageAssets.iconClock,
    ),
    NotificationSample(
      id: 'clanGamesStarted',
      label: 'Clan Games',
      group: 'Events',
      title: 'Clan Games started',
      body: 'Your clan can start earning Clan Games points.',
      assetUrl: ImageAssets.clanGamesMedals,
    ),
    NotificationSample(
      id: 'cwlStarted',
      label: 'CWL started',
      group: 'Events',
      title: 'CWL started',
      body: 'Your clan can begin Clan War League preparation.',
      assetUrl: ImageAssets.cwlSwordsNoBorder,
    ),
    NotificationSample(
      id: 'raidWeekendStarted',
      label: 'Raid Weekend',
      group: 'Events',
      title: 'Raid Weekend started',
      body: 'Your clan can start Capital Raid attacks.',
      assetUrl: ImageAssets.raidAttacks,
    ),
    NotificationSample(
      id: 'monthlySupport',
      label: 'Monthly support',
      group: 'Support',
      title: 'Support ClashKing',
      body:
          'Monthly support helps keep ClashKing available and improving. Thank you.',
      assetUrl: ImageAssets.darkModeLogo,
    ),
    NotificationSample(
      id: 'upgradeComplete',
      label: 'Upgrade finished',
      group: 'Progress',
      title: 'Archer Queen is ready',
      body: 'Level 106 finished. Upgrade complete.',
      assetUrl: ImageAssets.getHeroImage('Archer Queen'),
    ),
  ];

  Future<Map<String, dynamic>> showSample(NotificationSample sample) async {
    if (!isSupportedPlatform) {
      throw PlatformException(
        code: 'unsupported',
        message: 'Test notifications are currently wired for iOS.',
      );
    }

    final result = await _channel.invokeMapMethod<String, dynamic>(
      'showSample',
      sample.toPayload(),
    );
    return result ?? <String, dynamic>{};
  }
}

class NotificationSample {
  const NotificationSample({
    required this.id,
    required this.label,
    required this.group,
    required this.title,
    required this.body,
    required this.assetUrl,
  });

  final String id;
  final String label;
  final String group;
  final String title;
  final String body;
  final String assetUrl;

  Map<String, dynamic> toPayload() {
    return {
      'sampleId': id,
      'title': title,
      'body': body,
      'assetUrl': assetUrl,
      'assetUrls': [assetUrl],
      'threadIdentifier': group,
    };
  }
}
