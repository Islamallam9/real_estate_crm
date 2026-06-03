import 'package:equatable/equatable.dart';

class ReleaseIntelligenceSummary extends Equatable {
  const ReleaseIntelligenceSummary({
    required this.activeUsers,
    required this.activeDevices,
    required this.activeWebUsers,
    required this.activeWebDevices,
    required this.activeAndroidUsers,
    required this.activeAndroidDevices,
    required this.usersBelowLatestBuild,
    required this.devicesBelowLatestBuild,
    required this.usersBelowMinimumBuild,
    required this.devicesBelowMinimumBuild,
    required this.pushConnected,
    required this.pushBlocked,
    required this.pushMissing,
    required this.pushInvalidFailed,
    required this.pushUnknown,
    required this.releases,
    required this.adoptionRows,
    required this.recentVersionChanges,
    this.latestWebRelease,
    this.latestAndroidRelease,
    this.lastUpdated,
  });

  final int activeUsers;
  final int activeDevices;
  final int activeWebUsers;
  final int activeWebDevices;
  final int activeAndroidUsers;
  final int activeAndroidDevices;
  final int usersBelowLatestBuild;
  final int devicesBelowLatestBuild;
  final int usersBelowMinimumBuild;
  final int devicesBelowMinimumBuild;
  final int pushConnected;
  final int pushBlocked;
  final int pushMissing;
  final int pushInvalidFailed;
  final int pushUnknown;
  final PlatformReleaseRecord? latestWebRelease;
  final PlatformReleaseRecord? latestAndroidRelease;
  final List<PlatformReleaseRecord> releases;
  final List<VersionAdoptionRow> adoptionRows;
  final List<DeviceVersionEventRow> recentVersionChanges;
  final DateTime? lastUpdated;

  @override
  List<Object?> get props => [
        activeUsers,
        activeDevices,
        activeWebUsers,
        activeWebDevices,
        activeAndroidUsers,
        activeAndroidDevices,
        usersBelowLatestBuild,
        devicesBelowLatestBuild,
        usersBelowMinimumBuild,
        devicesBelowMinimumBuild,
        pushConnected,
        pushBlocked,
        pushMissing,
        pushInvalidFailed,
        pushUnknown,
        latestWebRelease,
        latestAndroidRelease,
        releases,
        adoptionRows,
        recentVersionChanges,
        lastUpdated,
      ];
}

class PlatformReleaseRecord extends Equatable {
  const PlatformReleaseRecord({
    required this.id,
    required this.platform,
    required this.appVersion,
    required this.buildNumber,
    required this.channel,
    required this.releaseType,
    required this.status,
    required this.releaseReady,
    required this.enabled,
    required this.minimumSupportedBuildNumber,
    required this.latestBuildNumber,
    required this.updateUrl,
    required this.apkFileName,
    required this.notesEn,
    required this.notesAr,
    required this.createdByName,
    this.createdAt,
    this.updatedAt,
    this.releasedAt,
    this.disabledAt,
  });

  final String id;
  final String platform;
  final String appVersion;
  final int buildNumber;
  final String channel;
  final String releaseType;
  final String status;
  final bool releaseReady;
  final bool enabled;
  final int minimumSupportedBuildNumber;
  final int latestBuildNumber;
  final String updateUrl;
  final String apkFileName;
  final String notesEn;
  final String notesAr;
  final String createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? releasedAt;
  final DateTime? disabledAt;

  @override
  List<Object?> get props => [
        id,
        platform,
        appVersion,
        buildNumber,
        channel,
        releaseType,
        status,
        releaseReady,
        enabled,
        minimumSupportedBuildNumber,
        latestBuildNumber,
        updateUrl,
        apkFileName,
        notesEn,
        notesAr,
        createdByName,
        createdAt,
        updatedAt,
        releasedAt,
        disabledAt,
      ];
}

class VersionAdoptionRow extends Equatable {
  const VersionAdoptionRow({
    required this.platform,
    required this.appVersion,
    required this.buildNumber,
    required this.activeUsers,
    required this.activeDevices,
    required this.activeCompanies,
    required this.status,
    this.latestSeenAt,
  });

  final String platform;
  final String appVersion;
  final int buildNumber;
  final int activeUsers;
  final int activeDevices;
  final int activeCompanies;
  final String status;
  final DateTime? latestSeenAt;

  @override
  List<Object?> get props => [
        platform,
        appVersion,
        buildNumber,
        activeUsers,
        activeDevices,
        activeCompanies,
        status,
        latestSeenAt,
      ];
}

class PlatformDeviceInstallRow extends Equatable {
  const PlatformDeviceInstallRow({
    required this.installId,
    required this.uid,
    required this.companyId,
    required this.companyName,
    required this.fullName,
    required this.email,
    required this.role,
    required this.platform,
    required this.appVersion,
    required this.buildNumber,
    required this.notificationPermission,
    required this.notificationTokenStatus,
    required this.browser,
    required this.os,
    required this.deviceModel,
    required this.tokenHashPrefix,
    this.lastSeenAt,
  });

  final String installId;
  final String uid;
  final String companyId;
  final String companyName;
  final String fullName;
  final String email;
  final String role;
  final String platform;
  final String appVersion;
  final int buildNumber;
  final String notificationPermission;
  final String notificationTokenStatus;
  final String browser;
  final String os;
  final String deviceModel;
  final String tokenHashPrefix;
  final DateTime? lastSeenAt;

  @override
  List<Object?> get props => [
        installId,
        uid,
        companyId,
        companyName,
        fullName,
        email,
        role,
        platform,
        appVersion,
        buildNumber,
        notificationPermission,
        notificationTokenStatus,
        browser,
        os,
        deviceModel,
        tokenHashPrefix,
        lastSeenAt,
      ];
}

class DeviceVersionEventRow extends Equatable {
  const DeviceVersionEventRow({
    required this.eventId,
    required this.uid,
    required this.companyId,
    required this.companyName,
    required this.role,
    required this.platform,
    required this.installId,
    required this.userName,
    required this.oldVersion,
    required this.oldBuildNumber,
    required this.newVersion,
    required this.newBuildNumber,
    required this.source,
    this.createdAt,
  });

  final String eventId;
  final String uid;
  final String companyId;
  final String companyName;
  final String role;
  final String platform;
  final String installId;
  final String userName;
  final String oldVersion;
  final int oldBuildNumber;
  final String newVersion;
  final int newBuildNumber;
  final String source;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        eventId,
        uid,
        companyId,
        companyName,
        role,
        platform,
        installId,
        userName,
        oldVersion,
        oldBuildNumber,
        newVersion,
        newBuildNumber,
        source,
        createdAt,
      ];
}
