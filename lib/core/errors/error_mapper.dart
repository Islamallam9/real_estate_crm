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
}

String localizeErrorMessage(AppLocalizations l, String? message) {
  switch (message) {
    case AppErrorMessages.unableToConnect:
      return l.unableToConnect;
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
    case 'Unable to create lead. Please try again.':
      return l.unableToCreateLead;
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
    default:
      return message ?? l.somethingWentWrong;
  }
}
