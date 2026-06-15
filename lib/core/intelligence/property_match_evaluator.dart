/// Pure-Dart property matching evaluator.
///
/// This intentionally uses primitive fields instead of importing feature
/// entities. It must stay free from Flutter, Firebase, and UI dependencies.
class PropertyMatchRequest {
  const PropertyMatchRequest({
    required this.preferredLocation,
    required this.preferredPropertyType,
    this.budgetMin,
    this.budgetMax,
  });

  final String preferredLocation;
  final String preferredPropertyType;
  final num? budgetMin;
  final num? budgetMax;

  bool get hasUsablePreferences {
    return preferredLocation.trim().isNotEmpty ||
        preferredPropertyType.trim().isNotEmpty ||
        (budgetMin != null && budgetMin! > 0) ||
        (budgetMax != null && budgetMax! > 0);
  }
}

class PropertyMatchCandidate {
  const PropertyMatchCandidate({
    required this.id,
    required this.title,
    required this.propertyType,
    required this.price,
    required this.location,
    required this.compound,
    required this.status,
    required this.isArchived,
  });

  final String id;
  final String title;
  final String propertyType;
  final num price;
  final String location;
  final String compound;
  final String status;
  final bool isArchived;
}

class PropertyMatchResult {
  const PropertyMatchResult({
    required this.candidate,
    required this.score,
    required this.reasons,
  });

  final PropertyMatchCandidate candidate;
  final int score;
  final List<String> reasons;
}

abstract final class PropertyMatchEvaluator {
  static List<PropertyMatchResult> evaluate({
    required PropertyMatchRequest request,
    required List<PropertyMatchCandidate> candidates,
    int limit = 3,
    int minimumScore = 20,
  }) {
    if (!request.hasUsablePreferences) {
      return const <PropertyMatchResult>[];
    }

    final matches = <PropertyMatchResult>[];
    for (final candidate in candidates) {
      final match = _scoreCandidate(request, candidate);
      if (match != null && match.score >= minimumScore) {
        matches.add(match);
      }
    }

    matches.sort((a, b) {
      final scoreComparison = b.score.compareTo(a.score);
      if (scoreComparison != 0) {
        return scoreComparison;
      }
      final priceComparison = a.candidate.price.compareTo(b.candidate.price);
      if (priceComparison != 0) {
        return priceComparison;
      }
      return a.candidate.title.compareTo(b.candidate.title);
    });

    return matches.take(limit).toList(growable: false);
  }

  static PropertyMatchResult? _scoreCandidate(
    PropertyMatchRequest request,
    PropertyMatchCandidate candidate,
  ) {
    if (candidate.isArchived || candidate.status != 'available') {
      return null;
    }

    var score = 0;
    final reasons = <String>[];

    final locationScore = _locationScore(request, candidate);
    if (locationScore > 0) {
      score += locationScore;
      reasons.add(locationScore >= 42 ? 'sameCompound' : 'sameLocation');
    }

    if (_typeMatches(request.preferredPropertyType, candidate.propertyType)) {
      score += 25;
      reasons.add('samePropertyType');
    }

    final budgetScore = _budgetScore(
      budgetMin: request.budgetMin,
      budgetMax: request.budgetMax,
      price: candidate.price,
    );
    if (budgetScore > 0) {
      score += budgetScore;
      reasons.add(budgetScore >= 30 ? 'withinBudget' : 'closeToBudget');
    }

    if (score > 0) {
      score += 8;
      reasons.add('availableNow');
    }

    return PropertyMatchResult(
      candidate: candidate,
      score: score.clamp(0, 100).toInt(),
      reasons: _unique(reasons),
    );
  }

  static int _locationScore(
    PropertyMatchRequest request,
    PropertyMatchCandidate candidate,
  ) {
    final requested = _normalize(request.preferredLocation);
    if (requested.isEmpty) {
      return 0;
    }

    final location = _normalize(candidate.location);
    final compound = _normalize(candidate.compound);
    if (compound.isNotEmpty && _containsEither(requested, compound)) {
      return 45;
    }
    if (location.isNotEmpty && _containsEither(requested, location)) {
      return 38;
    }

    final requestedTokens = _tokens(requested);
    final candidateTokens = <String>{..._tokens(location), ..._tokens(compound)};
    if (requestedTokens.isEmpty || candidateTokens.isEmpty) {
      return 0;
    }
    final overlap = requestedTokens.intersection(candidateTokens).length;
    if (overlap >= 2) {
      return 30;
    }
    if (overlap == 1) {
      return 18;
    }
    return 0;
  }

  static int _budgetScore({
    required num? budgetMin,
    required num? budgetMax,
    required num price,
  }) {
    if (price <= 0) {
      return 0;
    }
    final min = _positive(budgetMin) ? budgetMin!.toDouble() : null;
    final max = _positive(budgetMax) ? budgetMax!.toDouble() : null;
    final value = price.toDouble();

    if (min == null && max == null) {
      return 0;
    }
    if (min != null && max != null && value >= min && value <= max) {
      return 32;
    }
    if (min == null && max != null && value <= max) {
      return 30;
    }
    if (min != null && max == null && value >= min) {
      return 22;
    }
    if (max != null && value > max && value <= max * 1.1) {
      return 12;
    }
    if (min != null && value < min && value >= min * 0.9) {
      return 8;
    }
    return 0;
  }

  static bool _typeMatches(String requestedType, String candidateType) {
    final requested = _canonicalPropertyType(requestedType);
    final candidate = _canonicalPropertyType(candidateType);
    if (requested.isEmpty || candidate.isEmpty) {
      return false;
    }
    return _containsEither(requested, candidate);
  }

  static String _canonicalPropertyType(String value) {
    final normalized = _normalize(value);
    return switch (normalized) {
      'apartment' || 'flat' || 'شقه' || 'شقة' => 'apartment',
      'villa' || 'فيلا' => 'villa',
      'office' || 'مكتب' => 'office',
      'shop' || 'store' || 'محل' => 'shop',
      'land' || 'ارض' || 'أرض' => 'land',
      'studio' || 'استوديو' => 'studio',
      'duplex' || 'douplex' || 'دوبلكس' => 'duplex',
      'penthouse' || 'بنتهاوس' => 'penthouse',
      _ => normalized,
    };
  }

  static bool _containsEither(String a, String b) {
    return a == b || a.contains(b) || b.contains(a);
  }

  static Set<String> _tokens(String value) {
    return value
        .split(' ')
        .map((token) => token.trim())
        .where((token) => token.length >= 2)
        .toSet();
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<String> _unique(List<String> values) {
    return values.toSet().toList(growable: false);
  }

  static bool _positive(num? value) => value != null && value > 0;
}
