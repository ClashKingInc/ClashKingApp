class SubscriptionStatus {
  const SubscriptionStatus({
    this.provider = 'stripe',
    this.status = 'none',
    this.active = false,
    this.bookmarkNotificationsLimit = 0,
    this.rosterAssistantMonthlyCreditUsd = 0,
  });

  final String provider;
  final String status;
  final bool active;
  final int bookmarkNotificationsLimit;
  final double rosterAssistantMonthlyCreditUsd;

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      provider: json['provider']?.toString() ?? 'stripe',
      status: json['status']?.toString() ?? 'none',
      active: json['active'] == true,
      bookmarkNotificationsLimit:
          (json['bookmarkNotificationsLimit'] as num?)?.toInt() ?? 0,
      rosterAssistantMonthlyCreditUsd:
          (json['rosterAssistantMonthlyCreditUsd'] as num?)?.toDouble() ?? 0,
    );
  }
}
