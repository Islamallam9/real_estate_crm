import 'package:equatable/equatable.dart';

enum GlobalSearchModule {
  leads,
  clients,
  properties,
  deals,
  tasks,
  users,
}

class GlobalSearchResult extends Equatable {
  const GlobalSearchResult({
    required this.id,
    required this.module,
    required this.title,
    required this.subtitle,
    required this.route,
    this.status = '',
    this.owner = '',
  });

  final String id;
  final GlobalSearchModule module;
  final String title;
  final String subtitle;
  final String route;
  final String status;
  final String owner;

  @override
  List<Object?> get props => [
        id,
        module,
        title,
        subtitle,
        route,
        status,
        owner,
      ];
}
