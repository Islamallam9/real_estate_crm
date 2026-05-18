import 'package:equatable/equatable.dart';

import '../../domain/entities/global_search_result.dart';

enum GlobalSearchStatus { initial, loading, ready, failure }

class GlobalSearchState extends Equatable {
  const GlobalSearchState({
    this.status = GlobalSearchStatus.initial,
    this.query = '',
    this.results = const [],
    this.message = '',
  });

  final GlobalSearchStatus status;
  final String query;
  final List<GlobalSearchResult> results;
  final String message;

  GlobalSearchState copyWith({
    GlobalSearchStatus? status,
    String? query,
    List<GlobalSearchResult>? results,
    String? message,
  }) {
    return GlobalSearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, query, results, message];
}
