import 'package:equatable/equatable.dart';

class AndroidVersionAdoptionSummary extends Equatable {
  const AndroidVersionAdoptionSummary({
    required this.versions,
    required this.totalActiveUsers,
    required this.totalActiveDevices,
  });

  final List<AndroidVersionAdoption> versions;
  final int totalActiveUsers;
  final int totalActiveDevices;

  @override
  List<Object?> get props => [versions, totalActiveUsers, totalActiveDevices];
}

class AndroidVersionAdoption extends Equatable {
  const AndroidVersionAdoption({
    required this.appVersion,
    required this.buildNumber,
    required this.userCount,
    required this.deviceCount,
    required this.companyCount,
    this.latestSeenAt,
  });

  final String appVersion;
  final int buildNumber;
  final int userCount;
  final int deviceCount;
  final int companyCount;
  final DateTime? latestSeenAt;

  @override
  List<Object?> get props => [
        appVersion,
        buildNumber,
        userCount,
        deviceCount,
        companyCount,
        latestSeenAt,
      ];
}
