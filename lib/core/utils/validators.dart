import '../../l10n/app_localizations.dart';

abstract final class AppValidators {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phonePattern = RegExp(r'^[0-9+()\-\s]{7,24}$');
  static final _companyIdPattern = RegExp(r'^[a-z0-9][a-z0-9_-]{2,48}[a-z0-9]$');
  static final _invitationPattern = RegExp(r'^MASAR-[A-Z0-9]{4}-[A-Z0-9]{4}$');
  static final _lowercasePattern = RegExp(r'[a-z]');
  static final _uppercasePattern = RegExp(r'[A-Z]');
  static final _numberPattern = RegExp(r'\d');

  static String? requiredText(String? value, AppLocalizations l) {
    return (value ?? '').trim().isEmpty ? l.requiredField : null;
  }

  static String? personName(String? value, AppLocalizations l) {
    final clean = (value ?? '').trim();
    if (clean.isEmpty) return l.requiredField;
    if (clean.length < 2 || clean.length > 120 || RegExp(r'[<>]').hasMatch(clean)) {
      return l.invalidName;
    }
    return null;
  }

  static String? email(String? value, AppLocalizations l) {
    final clean = (value ?? '').trim();
    if (clean.isEmpty) return l.requiredField;
    if (!_emailPattern.hasMatch(clean)) return l.invalidEmail;
    return null;
  }

  static String? optionalEmail(String? value, AppLocalizations l) {
    final clean = (value ?? '').trim();
    if (clean.isEmpty) return null;
    if (!_emailPattern.hasMatch(clean)) return l.invalidEmail;
    return null;
  }

  static String? phone(String? value, AppLocalizations l) {
    final clean = (value ?? '').trim();
    if (clean.isEmpty) return l.requiredField;
    if (!_phonePattern.hasMatch(clean)) return l.invalidPhone;
    return null;
  }

  static String? optionalPhone(String? value, AppLocalizations l) {
    final clean = (value ?? '').trim();
    if (clean.isEmpty) return null;
    if (!_phonePattern.hasMatch(clean)) return l.invalidPhone;
    return null;
  }

  static String? companyName(String? value, AppLocalizations l) {
    final clean = (value ?? '').trim();
    if (clean.isEmpty) return l.requiredField;
    if (clean.length < 2 || clean.length > 160 || RegExp(r'[<>]').hasMatch(clean)) {
      return l.invalidName;
    }
    return null;
  }

  static String? companyId(String? value, AppLocalizations l) {
    final clean = (value ?? '').trim();
    if (clean.isEmpty) return l.requiredField;
    if (!_companyIdPattern.hasMatch(clean)) return l.companyIdInvalid;
    return null;
  }

  static String? invitationCode(String? value, AppLocalizations l) {
    final clean = (value ?? '').trim().toUpperCase();
    if (clean.isEmpty) return l.requiredField;
    if (!_invitationPattern.hasMatch(clean)) return l.invitationInvalid;
    return null;
  }

  static String? password(
    String? value,
    AppLocalizations l, {
    String? requiredMessage,
  }) {
    final clean = value ?? '';
    if (clean.trim().isEmpty) return requiredMessage ?? l.passwordRequired;
    if (clean.length < 8) return l.newPasswordTooShort;
    if (!_lowercasePattern.hasMatch(clean)) return l.passwordMustIncludeLowercase;
    if (!_uppercasePattern.hasMatch(clean)) return l.passwordMustIncludeUppercase;
    if (!_numberPattern.hasMatch(clean)) return l.passwordMustIncludeNumber;
    return null;
  }

  static String? confirmPassword(
    String? value,
    String password,
    AppLocalizations l,
  ) {
    final clean = value ?? '';
    if (clean.isEmpty) return l.requiredField;
    if (clean != password) return l.passwordsDoNotMatch;
    return null;
  }

  static String? optionalUrl(String? value, AppLocalizations l) {
    final clean = (value ?? '').trim();
    if (clean.isEmpty) return null;
    final uri = Uri.tryParse(clean);
    if (uri == null || !uri.hasScheme || uri.host.trim().isEmpty) {
      return l.invalidUrl;
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return l.invalidUrl;
    }
    return null;
  }

  static String slugFromName(String value) {
    final slug = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final clipped = slug.length > 48 ? slug.substring(0, 48) : slug;
    final clean = clipped.replaceAll(RegExp(r'^-+|-+$'), '');
    if (clean.isNotEmpty) {
      return clean;
    }
    final source = value.trim();
    if (source.isEmpty) {
      return '';
    }
    var hash = 0;
    for (final codeUnit in source.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return 'company-${hash.toRadixString(36)}';
  }
}
