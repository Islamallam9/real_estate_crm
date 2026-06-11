import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/datasources/user_profile_remote_data_source.dart';
import '../../data/repositories/user_profile_repository_impl.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/watch_active_users_usecase.dart';

typedef ActiveUsersBuilder = Widget Function(
  BuildContext context,
  List<UserProfile> users,
);

class ActiveUsersStreamBuilder extends StatefulWidget {
  const ActiveUsersStreamBuilder({
    super.key,
    required this.companyId,
    required this.builder,
    this.enabled = true,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String companyId;
  final bool enabled;
  final ActiveUsersBuilder builder;
  final WidgetBuilder? loadingBuilder;
  final Widget Function(BuildContext context, Object? error)? errorBuilder;

  @override
  State<ActiveUsersStreamBuilder> createState() =>
      _ActiveUsersStreamBuilderState();
}

class _ActiveUsersStreamBuilderState extends State<ActiveUsersStreamBuilder> {
  Stream<List<UserProfile>>? _stream;
  List<UserProfile> _latestUsers = const <UserProfile>[];
  Object? _latestError;
  Timer? _loadingFallbackTimer;
  bool _allowEmptyFallbackAfterTimeout = false;

  @override
  void initState() {
    super.initState();
    _configureStream();
  }

  @override
  void didUpdateWidget(covariant ActiveUsersStreamBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId ||
        oldWidget.enabled != widget.enabled) {
      _configureStream();
    }
  }

  void _configureStream() {
    _loadingFallbackTimer?.cancel();
    _latestError = null;
    _allowEmptyFallbackAfterTimeout = false;
    if (!widget.enabled || widget.companyId.trim().isEmpty) {
      _stream = null;
      _latestUsers = const <UserProfile>[];
      return;
    }
    final repository = UserProfileRepositoryImpl(
      remoteDataSource: FirestoreUserProfileRemoteDataSource(),
    );
    _stream = WatchActiveUsersUseCase(repository)(companyId: widget.companyId);
    _loadingFallbackTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted || _latestUsers.isNotEmpty || _latestError != null) {
        return;
      }
      setState(() {
        _allowEmptyFallbackAfterTimeout = true;
      });
    });
  }

  @override
  void dispose() {
    _loadingFallbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _stream == null) {
      return widget.builder(context, const <UserProfile>[]);
    }

    return StreamBuilder<List<UserProfile>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _latestUsers = snapshot.data ?? const <UserProfile>[];
          _latestError = null;
          _loadingFallbackTimer?.cancel();
        } else if (snapshot.hasError) {
          _latestError = snapshot.error;
        }

        if (_latestUsers.isEmpty && _latestError != null) {
          final errorBuilder = widget.errorBuilder;
          if (errorBuilder != null) {
            return errorBuilder(context, _latestError);
          }
        }

        if (_latestUsers.isEmpty &&
            snapshot.connectionState == ConnectionState.waiting &&
            !_allowEmptyFallbackAfterTimeout) {
          final loadingBuilder = widget.loadingBuilder;
          if (loadingBuilder != null) {
            return loadingBuilder(context);
          }
        }

        return widget.builder(context, _latestUsers);
      },
    );
  }
}
