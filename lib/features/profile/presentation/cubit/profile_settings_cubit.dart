import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../users/domain/entities/profile_image_upload.dart';
import '../../../users/domain/errors/user_profile_exception.dart';
import '../../../users/domain/usecases/update_own_profile_usecase.dart';
import 'profile_settings_state.dart';

class ProfileSettingsCubit extends Cubit<ProfileSettingsState> {
  ProfileSettingsCubit({
    required UpdateOwnProfileUseCase updateOwnProfileUseCase,
    required UploadOwnProfileImageUseCase uploadOwnProfileImageUseCase,
    required RemoveOwnProfileImageUseCase removeOwnProfileImageUseCase,
  })  : _updateOwnProfileUseCase = updateOwnProfileUseCase,
        _uploadOwnProfileImageUseCase = uploadOwnProfileImageUseCase,
        _removeOwnProfileImageUseCase = removeOwnProfileImageUseCase,
        super(const ProfileSettingsState());

  final UpdateOwnProfileUseCase _updateOwnProfileUseCase;
  final UploadOwnProfileImageUseCase _uploadOwnProfileImageUseCase;
  final RemoveOwnProfileImageUseCase _removeOwnProfileImageUseCase;

  Future<void> updateName({
    required String uid,
    required String companyId,
    required String fullName,
    required bool isPlatformAdmin,
  }) async {
    await _runProfileAction(() {
      return _updateOwnProfileUseCase(
        uid: uid,
        companyId: companyId,
        fullName: fullName,
        isPlatformAdmin: isPlatformAdmin,
      );
    }, platformFullName: fullName.trim());
  }

  Future<void> uploadImage({
    required String uid,
    required String companyId,
    required bool isPlatformAdmin,
    required ProfileImageUpload image,
  }) async {
    await _runProfileAction(() {
      return _uploadOwnProfileImageUseCase(
        uid: uid,
        companyId: companyId,
        isPlatformAdmin: isPlatformAdmin,
        image: image,
      );
    });
  }

  Future<void> removeImage({
    required String uid,
    required String companyId,
    required bool isPlatformAdmin,
  }) async {
    await _runProfileAction(() {
      return _removeOwnProfileImageUseCase(
        uid: uid,
        companyId: companyId,
        isPlatformAdmin: isPlatformAdmin,
      );
    }, platformPhotoUrl: '');
  }

  Future<void> _runProfileAction(
    Future<dynamic> Function() action, {
    String? platformFullName,
    String? platformPhotoUrl,
  }) async {
    emit(state.copyWith(
      status: ProfileSettingsStatus.saving,
      message: '',
      clearUpdatedProfile: true,
      clearPlatformValues: true,
    ));

    try {
      final result = await action();
      emit(state.copyWith(
        status: ProfileSettingsStatus.success,
        updatedProfile: result,
        platformFullName: result == null ? platformFullName : null,
        platformPhotoUrl: result == null ? platformPhotoUrl : null,
      ));
    } on UserProfileException catch (error) {
      emit(state.copyWith(
        status: ProfileSettingsStatus.failure,
        message: error.message,
        clearUpdatedProfile: true,
        clearPlatformValues: true,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: ProfileSettingsStatus.failure,
        message: '',
        clearUpdatedProfile: true,
        clearPlatformValues: true,
      ));
    }
  }
}
