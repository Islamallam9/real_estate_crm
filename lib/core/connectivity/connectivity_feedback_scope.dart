import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../l10n/app_localizations.dart';
import '../widgets/app_feedback.dart';
import 'connectivity_cubit.dart';

class ConnectivityFeedbackScope extends StatelessWidget {
  const ConnectivityFeedbackScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MasarConnectivityCubit()..start(),
      child: _ConnectivityFeedbackListener(child: child),
    );
  }
}

class _ConnectivityFeedbackListener extends StatefulWidget {
  const _ConnectivityFeedbackListener({required this.child});

  final Widget child;

  @override
  State<_ConnectivityFeedbackListener> createState() =>
      _ConnectivityFeedbackListenerState();
}

class _ConnectivityFeedbackListenerState
    extends State<_ConnectivityFeedbackListener> {
  MasarConnectivityStatus? _lastAnnouncedStatus;

  @override
  Widget build(BuildContext context) {
    return BlocListener<MasarConnectivityCubit, MasarConnectivityState>(
      listenWhen: (previous, current) =>
          previous.status != current.status && current.hasChecked,
      listener: (context, state) {
        final l = AppLocalizations.of(context)!;
        final previousStatus = _lastAnnouncedStatus;
        _lastAnnouncedStatus = state.status;

        if (state.status == MasarConnectivityStatus.offline) {
          AppFeedback.error(context, l.connectionLostSnackbar);
          return;
        }
        if (state.status == MasarConnectivityStatus.online &&
            previousStatus == MasarConnectivityStatus.offline) {
          AppFeedback.success(context, l.connectionRestoredSnackbar);
        }
      },
      child: widget.child,
    );
  }
}
