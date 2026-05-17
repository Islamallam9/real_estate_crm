import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../clients/data/datasources/clients_remote_data_source.dart';
import '../../../clients/data/repositories/client_repository_impl.dart';
import '../../../clients/domain/entities/client.dart';
import '../../../clients/domain/usecases/watch_clients_usecase.dart';
import '../../../leads/data/datasources/leads_remote_data_source.dart';
import '../../../leads/data/repositories/leads_repository_impl.dart';
import '../../../leads/domain/entities/lead.dart';
import '../../../leads/domain/usecases/watch_leads_usecase.dart';
import '../../../properties/data/datasources/properties_remote_data_source.dart';
import '../../../properties/data/repositories/property_repository_impl.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../properties/domain/usecases/watch_properties_usecase.dart';
import '../../../users/data/datasources/user_profile_remote_data_source.dart';
import '../../../users/data/repositories/user_profile_repository_impl.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../../users/domain/usecases/watch_active_users_usecase.dart';

class DealFormData {
  const DealFormData({
    required this.clients,
    required this.leads,
    required this.properties,
    required this.users,
  });

  final List<Client> clients;
  final List<Lead> leads;
  final List<Property> properties;
  final List<UserProfile> users;
}

class DealFormDataLoader extends StatefulWidget {
  const DealFormDataLoader({
    super.key,
    required this.companyId,
    required this.builder,
    this.assignedTo,
    this.managerId,
  });

  final String companyId;
  final String? assignedTo;
  final String? managerId;
  final Widget Function(BuildContext context, DealFormData data) builder;

  @override
  State<DealFormDataLoader> createState() => _DealFormDataLoaderState();
}

class _DealFormDataLoaderState extends State<DealFormDataLoader> {
  Timer? _initialLoadTimer;
  bool _timedOut = false;
  int _retryKey = 0;


  @override
  void initState() {
    super.initState();
    _restartInitialLoad();
  }

  @override
  void dispose() {
    _initialLoadTimer?.cancel();
    super.dispose();
  }

  void _completeInitialLoad() {
    _initialLoadTimer?.cancel();
    _initialLoadTimer = null;
  }

  void _restartInitialLoad() {
    _initialLoadTimer?.cancel();
    _initialLoadTimer = Timer(const Duration(seconds: 18), () {
      if (!mounted) {
        return;
      }
      setState(() => _timedOut = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return StreamBuilder<List<Client>>(
      key: ValueKey(_retryKey),
      stream: _watchClients(
        widget.companyId,
        assignedTo: widget.assignedTo,
        managerId: widget.managerId,
      ),
      builder: (context, clientsSnapshot) {
        if (clientsSnapshot.hasError) {
          return AppErrorView(
            message: localizeThrownErrorMessage(l, clientsSnapshot.error),
          );
        }
        return StreamBuilder<List<Lead>>(
          stream: _watchLeads(
            widget.companyId,
            assignedTo: widget.assignedTo,
            managerId: widget.managerId,
          ),
          builder: (context, leadsSnapshot) {
            if (leadsSnapshot.hasError) {
              return AppErrorView(
                message: localizeThrownErrorMessage(l, leadsSnapshot.error),
              );
            }
            return StreamBuilder<List<Property>>(
              stream: _watchProperties(widget.companyId),
              builder: (context, propertiesSnapshot) {
                if (propertiesSnapshot.hasError) {
                  return AppErrorView(
                    message: localizeThrownErrorMessage(
                      l,
                      propertiesSnapshot.error,
                    ),
                  );
                }
                return StreamBuilder<List<UserProfile>>(
                  stream: _watchActiveUsers(widget.companyId),
                  builder: (context, usersSnapshot) {
                    if (usersSnapshot.hasError) {
                      return AppErrorView(
                        message: localizeThrownErrorMessage(
                          l,
                          usersSnapshot.error,
                        ),
                      );
                    }
                    final hasInitialData = clientsSnapshot.hasData &&
                        leadsSnapshot.hasData &&
                        propertiesSnapshot.hasData &&
                        usersSnapshot.hasData;
                    if (!hasInitialData) {
                      if (_timedOut) {
                        return AppErrorView(
                          message: l.connectionTimeout,
                          onRetry: () {
                            setState(() {
                              _timedOut = false;
                              _retryKey++;
                            });
                            _restartInitialLoad();
                          },
                        );
                      }
                      return const AppLoading();
                    }
                    _completeInitialLoad();
                    return widget.builder(
                      context,
                      DealFormData(
                        clients: clientsSnapshot.data ?? const [],
                        leads: leadsSnapshot.data ?? const [],
                        properties: propertiesSnapshot.data ?? const [],
                        users: usersSnapshot.data ?? const [],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

Stream<List<Client>> _watchClients(
  String companyId, {
  String? assignedTo,
  String? managerId,
}) {
  final repository = ClientRepositoryImpl(
    remoteDataSource: FirestoreClientsRemoteDataSource(),
  );
  return WatchClientsUseCase(repository)(
    companyId: companyId,
    assignedTo: assignedTo,
    managerId: managerId,
    limit: 80,
  );
}

Stream<List<Lead>> _watchLeads(
  String companyId, {
  String? assignedTo,
  String? managerId,
}) {
  final repository = LeadsRepositoryImpl(
    remoteDataSource: FirestoreLeadsRemoteDataSource(),
  );
  return WatchLeadsUseCase(repository)(
    companyId: companyId,
    assignedTo: assignedTo,
    managerId: managerId,
    limit: 80,
  );
}

Stream<List<Property>> _watchProperties(String companyId) {
  final repository = PropertyRepositoryImpl(
    remoteDataSource: FirestorePropertiesRemoteDataSource(),
  );
  return WatchPropertiesUseCase(repository)(companyId: companyId, limit: 80);
}

Stream<List<UserProfile>> _watchActiveUsers(String companyId) {
  final repository = UserProfileRepositoryImpl(
    remoteDataSource: FirestoreUserProfileRemoteDataSource(),
  );
  return WatchActiveUsersUseCase(repository)(companyId: companyId);
}
