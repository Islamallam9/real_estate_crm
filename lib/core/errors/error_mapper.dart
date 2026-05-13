import '../../l10n/app_localizations.dart';

abstract final class AppErrorMessages {
  static const unableToConnect =
      'Unable to connect. Check your internet connection and try again.';
  static const permissionDenied =
      'You do not have permission to perform this action.';
  static const unauthenticated =
      'Your session has expired. Please sign in again.';
  static const notFound = 'The requested data could not be found.';
  static const cancelled = 'The request was cancelled. Please try again.';
  static const unknown = 'Something went wrong. Please try again.';
  static const connectionTimeout =
      'Unable to load data. Check your connection and try again.';
  static const propertyImageInvalidType = 'Only image files are allowed.';
  static const propertyImageTooLarge =
      'Each property image must be 5 MB or smaller.';
}

String localizeErrorMessage(AppLocalizations l, String? message) {
  switch (message) {
    case AppErrorMessages.unableToConnect:
      return l.unableToConnect;
    case AppErrorMessages.connectionTimeout:
      return l.connectionTimeout;
    case AppErrorMessages.permissionDenied:
      return l.permissionDenied;
    case AppErrorMessages.unauthenticated:
      return l.authErrorProfileMissing;
    case AppErrorMessages.notFound:
      return l.noData;
    case AppErrorMessages.cancelled:
    case AppErrorMessages.unknown:
      return l.somethingWentWrong;
    case 'Unable to load your user profile.':
      return l.authErrorProfileMissing;
    case 'Unable to load leads. Please try again.':
      return l.unableToLoadLeads;
    case 'Unable to load properties. Please try again.':
      return l.unableToLoadProperties;
    case 'Unable to create lead. Please try again.':
      return l.unableToCreateLead;
    case 'A lead with this phone or email already exists.':
      return l.duplicateLeadFound;
    case 'Unable to update lead. Please try again.':
      return l.leadUpdateFailed;
    case 'Unable to archive lead. Please try again.':
      return l.unableToArchiveLead;
    case 'Unable to load lead.':
      return l.unableToLoadLeads;
    case 'Unable to add note. Please try again.':
      return l.unableToAddNote;
    case 'Unable to load lead timeline.':
      return l.somethingWentWrong;
    case AppErrorMessages.propertyImageInvalidType:
      return l.propertyImageInvalidType;
    case AppErrorMessages.propertyImageTooLarge:
    case 'Property image must be 5 MB or smaller.':
      return l.propertyImageTooLarge;
    default:
      return message ?? l.somethingWentWrong;
  }
}

String localizeThrownErrorMessage(
  AppLocalizations l,
  Object? error, {
  String? fallbackMessage,
}) {
  final text = error?.toString().toLowerCase() ?? '';

  if (text.contains('permission-denied') ||
      text.contains('permission denied')) {
    return l.permissionDenied;
  }

  if (text.contains('unavailable') ||
      text.contains('network') ||
      text.contains('timeout')) {
    return l.unableToConnect;
  }

  return fallbackMessage == null
      ? l.unableToConnect
      : localizeErrorMessage(l, fallbackMessage);
}
