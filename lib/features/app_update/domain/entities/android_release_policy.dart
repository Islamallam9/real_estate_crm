class AndroidReleasePolicy {
  const AndroidReleasePolicy({
    required this.enabled,
    required this.releaseReady,
    required this.updateRequired,
    required this.updateAvailable,
    required this.currentBuildNumber,
    required this.minimumSupportedBuildNumber,
    required this.latestBuildNumber,
    required this.updateUrl,
    required this.serverTime,
    this.gracePeriodStartedAt,
    this.gracePeriodEndsAt,
    this.titleEn = '',
    this.titleAr = '',
    this.bodyEn = '',
    this.bodyAr = '',
  });

  final bool enabled;
  final bool releaseReady;
  final bool updateRequired;
  final bool updateAvailable;
  final int currentBuildNumber;
  final int minimumSupportedBuildNumber;
  final int latestBuildNumber;
  final String updateUrl;
  final DateTime serverTime;
  final DateTime? gracePeriodStartedAt;
  final DateTime? gracePeriodEndsAt;
  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String bodyAr;

  Duration? get totalGracePeriod {
    final start = gracePeriodStartedAt;
    final end = gracePeriodEndsAt;
    if (start == null || end == null || !end.isAfter(start)) {
      return null;
    }
    return end.difference(start);
  }
}
