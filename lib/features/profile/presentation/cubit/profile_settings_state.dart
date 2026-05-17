import 'package:equatable/equatable.dart';

import '../../../users/domain/entities/user_profile.dart';

enum ProfileSettingsStatus { initial, saving, success, failure }

class ProfileSettingsState extends Equatable {
  const ProfileSettingsState({
    this.status = ProfileSettingsStatus.initial,
    this.updatedProfile,
    this.platformFullName,
    this.platformPhotoUrl,
    this.message = '',
  });

  final ProfileSettingsStatus status;
  final UserProfile? updatedProfile;
  final String? platformFullName;
  final String? platformPhotoUrl;
  final String message;

  ProfileSettingsState copyWith({
    ProfileSettingsStatus? status,
    UserProfile? updatedProfile,
    String? platformFullName,
    String? platformPhotoUrl,
    String? message,
    bool clearUpdatedProfile = false,
    bool clearPlatformValues = false,
  }) {
    return ProfileSettingsState(
      status: status ?? this.status,
      updatedProfile: clearUpdatedProfile
          ? null
          : updatedProfile ?? this.updatedProfile,
      platformFullName: clearPlatformValues
          ? null
          : platformFullName ?? this.platformFullName,
      platformPhotoUrl: clearPlatformValues
          ? null
          : platformPhotoUrl ?? this.platformPhotoUrl,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
        status,
        updatedProfile,
        platformFullName,
        platformPhotoUrl,
        message,
      ];
}
