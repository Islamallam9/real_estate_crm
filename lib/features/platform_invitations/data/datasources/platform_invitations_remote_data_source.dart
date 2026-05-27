import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../models/platform_invitation_model.dart';

abstract interface class PlatformInvitationsRemoteDataSource {
  Future<CreatedCompanyInvitationModel> createCompanyInvitation({
    required String planId,
    required String planName,
    required int userLimit,
    required int storageLimitMb,
    required Map<String, bool> features,
    required String locale,
    required String timezone,
    required DateTime expiresAt,
    int? trialDays,
    String trialDurationUnit = 'days',
    required String notes,
  });

  Future<List<PlatformInvitationModel>> listCompanyInvitations({
    String? status,
  });

  Future<void> revokeCompanyInvitation({required String invitationId});
}

class FirebasePlatformInvitationsRemoteDataSource
    implements PlatformInvitationsRemoteDataSource {
  FirebasePlatformInvitationsRemoteDataSource({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  @override
  Future<CreatedCompanyInvitationModel> createCompanyInvitation({
    required String planId,
    required String planName,
    required int userLimit,
    required int storageLimitMb,
    required Map<String, bool> features,
    required String locale,
    required String timezone,
    required DateTime expiresAt,
    int? trialDays,
    String trialDurationUnit = 'days',
    required String notes,
  }) async {
    final data = await _callMap('createCompanyInvitation', {
      'planId': planId,
      'planName': planName,
      'userLimit': userLimit,
      'storageLimitMb': storageLimitMb,
      'features': features,
      'locale': locale,
      'timezone': timezone,
      'expiresAt': expiresAt.toIso8601String(),
      if (trialDays != null && trialDays > 0) ...{
        'trialDurationValue': trialDays,
        'trialDurationUnit': trialDurationUnit,
        'trialDays': _legacyTrialDays(trialDays, trialDurationUnit),
      },
      if (notes.trim().isNotEmpty) 'notes': notes.trim(),
      'origin': _safeInvitationOrigin(),
    });
    return CreatedCompanyInvitationModel.fromMap(data);
  }

  @override
  Future<List<PlatformInvitationModel>> listCompanyInvitations({
    String? status,
  }) async {
    final data = await _callMap('listCompanyInvitations', {
      if ((status ?? '').trim().isNotEmpty) 'status': status!.trim(),
    });
    final invitations = data['invitations'];
    if (invitations is List) {
      return invitations
          .whereType<Map>()
          .map((item) {
            return PlatformInvitationModel.fromMap(
              Map<String, dynamic>.from(item),
            );
          })
          .toList();
    }
    return const [];
  }

  @override
  Future<void> revokeCompanyInvitation({required String invitationId}) {
    return _call('revokeCompanyInvitation', {'invitationId': invitationId});
  }

  Future<void> _call(String name, Map<String, Object?> data) async {
    await _callMap(name, data);
  }

  Future<Map<String, dynamic>> _callMap(
    String name,
    Map<String, Object?> data,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call(data);
      final value = result.data;
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return const {};
    } on FirebaseFunctionsException catch (error) {
      throw Exception(error.message ?? AppErrorMessages.permissionDenied);
    } on FirebaseException catch (error) {
      throw Exception(error.message ?? AppErrorMessages.unknown);
    }
  }
}

String _safeInvitationOrigin() {
  final uri = Uri.base;
  final scheme = uri.scheme.toLowerCase();
  if ((scheme == 'http' || scheme == 'https') && uri.host.trim().isNotEmpty) {
    return uri.origin;
  }
  return AppConstants.publicWebBaseUrl;
}

int _legacyTrialDays(int value, String unit) {
  final normalized = unit.trim().toLowerCase();
  if (normalized == 'minutes') {
    return (value / (60 * 24)).ceil().clamp(1, 3650).toInt();
  }
  if (normalized == 'hours') {
    return (value / 24).ceil().clamp(1, 3650).toInt();
  }
  return value;
}
