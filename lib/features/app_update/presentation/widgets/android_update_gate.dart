import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/masar_brand.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/datasources/android_apk_update_installer.dart';
import '../../data/datasources/app_update_remote_data_source.dart';
import '../../domain/entities/android_release_policy.dart';

class AndroidUpdateGate extends StatefulWidget {
  const AndroidUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<AndroidUpdateGate> createState() => _AndroidUpdateGateState();
}

class _AndroidUpdateGateState extends State<AndroidUpdateGate> {
  late Future<AndroidReleasePolicy?> _policyFuture;

  @override
  void initState() {
    super.initState();
    _policyFuture = _loadPolicy();
  }

  Future<AndroidReleasePolicy?> _loadPolicy() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    try {
      return await AppUpdateRemoteDataSource()
          .getAndroidReleasePolicy()
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Never brick the installed APK if the update-policy function/network fails.
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (_shouldBypassGateForAuthState(authState)) {
      return widget.child;
    }

    return FutureBuilder<AndroidReleasePolicy?>(
      future: _policyFuture,
      builder: (context, snapshot) {
        if (!kIsWeb &&
            defaultTargetPlatform == TargetPlatform.android &&
            snapshot.connectionState != ConnectionState.done) {
          return const _AndroidUpdateCheckingScreen();
        }

        final policy = snapshot.data;
        if (policy == null || !policy.updateRequired) {
          return widget.child;
        }

        return _AndroidForcedUpdateScreen(policy: policy);
      },
    );
  }

  bool _shouldBypassGateForAuthState(AuthState authState) {
    if (authState.isPlatformAdmin) {
      return true;
    }
    return authState.status == AuthStatus.initial ||
        authState.status == AuthStatus.loading ||
        authState.status == AuthStatus.unauthenticated;
  }
}

class _AndroidUpdateCheckingScreen extends StatelessWidget {
  const _AndroidUpdateCheckingScreen();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Material(
      color: AppColors.appBackground(context),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _UpdateGateLogo(label: l.appName),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.primaryColor(context),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.androidUpdateChecking,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryColor(context),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AndroidForcedUpdateScreen extends StatefulWidget {
  const _AndroidForcedUpdateScreen({required this.policy});

  final AndroidReleasePolicy policy;

  @override
  State<_AndroidForcedUpdateScreen> createState() =>
      _AndroidForcedUpdateScreenState();
}

class _AndroidForcedUpdateScreenState extends State<_AndroidForcedUpdateScreen> {
  final AndroidApkUpdateInstaller _installer = AndroidApkUpdateInstaller();

  late DateTime _estimatedServerNow;
  Timer? _timer;
  Timer? _downloadPollTimer;
  int? _downloadId;
  AndroidApkDownloadStatus? _downloadStatus;
  bool _downloadStarted = false;
  bool _openingInstaller = false;
  String? _downloadMessage;

  @override
  void initState() {
    super.initState();
    _estimatedServerNow = widget.policy.serverTime;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _estimatedServerNow = _estimatedServerNow.add(const Duration(seconds: 1));
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _downloadPollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final isArabic = localeCode == 'ar';
    final title = isArabic
        ? _firstText(widget.policy.titleAr, widget.policy.titleEn, l.androidUpdateTitle)
        : _firstText(widget.policy.titleEn, widget.policy.titleAr, l.androidUpdateTitle);
    final body = isArabic
        ? _firstText(widget.policy.bodyAr, widget.policy.bodyEn, l.androidUpdateBody)
        : _firstText(widget.policy.bodyEn, widget.policy.bodyAr, l.androidUpdateBody);
    final remaining = _remainingDuration(widget.policy);
    final progress = _remainingProgress(widget.policy, remaining);
    final textTheme = Theme.of(context).textTheme;
    final currentBuildNumber = int.tryParse(AppConstants.appBuildNumber) ?? 0;
    final latestBuildNumber = widget.policy.latestBuildNumber > 0
        ? widget.policy.latestBuildNumber
        : widget.policy.minimumSupportedBuildNumber;
    final latestVersionName = _latestVersionName(latestBuildNumber);
    final downloadProgress = _downloadStatus?.progress;
    final downloadStatus = _downloadStatus;
    final canStartDownload = !_downloadStarted || downloadStatus?.isFailed == true;
    final canInstall = downloadStatus?.isSuccessful == true && !_openingInstaller;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Material(
        color: AppColors.appBackground(context),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface(context),
                    borderRadius: AppRadius.xLarge,
                    border: Border.all(color: AppColors.borderColor(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 28,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: _UpdateGateLogo(label: l.appName, compact: true),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Icon(
                          Icons.system_update_alt_rounded,
                          color: AppColors.primaryColor(context),
                          size: 42,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          title,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryColor(context),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          body,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondaryColor(context),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _VersionInfoRow(
                          label: l.androidUpdateCurrentVersion,
                          value: _versionBuildLabel(
                            l,
                            version: AppConstants.appVersion,
                            buildNumber: currentBuildNumber,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _VersionInfoRow(
                          label: l.androidUpdateLatestVersion,
                          value: _versionBuildLabel(
                            l,
                            version: latestVersionName,
                            buildNumber: latestBuildNumber,
                          ),
                        ),
                        if (remaining != null) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            l.androidUpdateRemainingTime,
                            style: textTheme.labelLarge?.copyWith(
                              color: AppColors.textPrimaryColor(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            remaining.isNegative || remaining == Duration.zero
                                ? l.androidUpdateExpired
                                : _formatRemaining(remaining, isArabic: isArabic),
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryColor(context),
                            ),
                          ),
                        ],
                        if (_downloadStarted || _downloadMessage != null) ...[
                          const SizedBox(height: AppSpacing.lg),
                          _DownloadProgressCard(
                            title: _downloadTitle(l),
                            message: _downloadMessage,
                            progress: downloadProgress,
                            bytesDownloaded: downloadStatus?.bytesDownloaded ?? 0,
                            totalBytes: downloadStatus?.totalBytes ?? 0,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          label: canInstall
                              ? l.androidUpdateInstallButton
                              : _downloadStarted && downloadStatus?.isSuccessful != true
                                  ? l.androidUpdateDownloading
                                  : l.androidUpdateButton,
                          icon: canInstall
                              ? Icons.install_mobile_rounded
                              : Icons.download_rounded,
                          isExpanded: true,
                          isLoading: _openingInstaller ||
                              (_downloadStarted &&
                                  downloadStatus?.isSuccessful != true &&
                                  downloadStatus?.isFailed != true),
                          onPressed: widget.policy.updateUrl.trim().isEmpty
                              ? null
                              : canInstall
                                  ? _openInstaller
                                  : canStartDownload
                                      ? _startDownload
                                      : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startDownload() async {
    final l = AppLocalizations.of(context)!;
    final updateUrl = widget.policy.updateUrl.trim();
    if (updateUrl.isEmpty) return;

    setState(() {
      _downloadStarted = true;
      _downloadStatus = null;
      _downloadMessage = l.androidUpdateDownloadStarting;
    });

    try {
      _downloadId = await _installer.startDownload(
        url: updateUrl,
        fileName: _apkFileName(),
      );
      _startPollingDownload();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _downloadStatus = const AndroidApkDownloadStatus(
          status: 'failed',
          bytesDownloaded: 0,
          totalBytes: 0,
        );
        _downloadMessage = l.androidUpdateDownloadFailed;
      });
    }
  }

  void _startPollingDownload() {
    _downloadPollTimer?.cancel();
    _downloadPollTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      _refreshDownloadStatus();
    });
    _refreshDownloadStatus();
  }

  Future<void> _refreshDownloadStatus() async {
    final downloadId = _downloadId;
    if (downloadId == null) return;
    final l = AppLocalizations.of(context)!;

    try {
      final status = await _installer.getStatus(downloadId);
      if (!mounted) return;
      setState(() {
        _downloadStatus = status;
        if (status.isSuccessful) {
          _downloadMessage = l.androidUpdateReadyToInstall;
        } else if (status.isFailed) {
          _downloadMessage = status.isInvalidApk
              ? l.androidUpdateInvalidPackage
              : l.androidUpdateDownloadFailed;
        } else {
          _downloadMessage = l.androidUpdateDownloading;
        }
      });

      if (status.isSuccessful) {
        _downloadPollTimer?.cancel();
        await _openInstaller();
      } else if (status.isFailed) {
        _downloadPollTimer?.cancel();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _downloadMessage = l.androidUpdateDownloadFailed;
      });
    }
  }

  Future<void> _openInstaller() async {
    final downloadId = _downloadId;
    if (downloadId == null || _openingInstaller) return;
    final l = AppLocalizations.of(context)!;

    setState(() {
      _openingInstaller = true;
      _downloadMessage = l.androidUpdateInstalling;
    });

    try {
      await _installer.installDownloadedApk(downloadId);
      if (!mounted) return;
      setState(() {
        _downloadMessage = l.androidUpdateReadyToInstall;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _downloadMessage = error.code == 'install_permission_required'
            ? l.androidUpdateInstallPermissionRequired
            : error.code == 'install_failed' &&
                    (error.message ?? '').contains('invalid_apk')
                ? l.androidUpdateInvalidPackage
                : l.androidUpdateOpenFailed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _downloadMessage = l.androidUpdateOpenFailed;
      });
    } finally {
      if (mounted) {
        setState(() {
          _openingInstaller = false;
        });
      }
    }
  }

  String _apkFileName() {
    final latestBuild = widget.policy.latestBuildNumber > 0
        ? widget.policy.latestBuildNumber
        : widget.policy.minimumSupportedBuildNumber;
    final latestVersion = _latestVersionName(latestBuild);
    final fileVersion = latestVersion.isEmpty ? AppConstants.appVersion : latestVersion;
    return 'masar-crm-$fileVersion-$latestBuild.apk';
  }

  String _latestVersionName(int latestBuildNumber) {
    final fromPolicy = widget.policy.latestVersionName.trim();
    if (fromPolicy.isNotEmpty) {
      return fromPolicy;
    }

    final fromUrl = _versionNameFromUpdateUrl(
      widget.policy.updateUrl,
      latestBuildNumber,
    );
    if (fromUrl.isNotEmpty) {
      return fromUrl;
    }

    final currentBuildNumber = int.tryParse(AppConstants.appBuildNumber) ?? 0;
    if (latestBuildNumber <= 0 || latestBuildNumber == currentBuildNumber) {
      return AppConstants.appVersion;
    }

    return '';
  }

  String _versionNameFromUpdateUrl(String updateUrl, int buildNumber) {
    if (updateUrl.trim().isEmpty || buildNumber <= 0) {
      return '';
    }
    final parsed = Uri.tryParse(updateUrl.trim());
    final path = parsed?.path.trim().isNotEmpty == true
        ? parsed!.path
        : updateUrl.trim();
    final fileName = Uri.decodeFull(path).split('/').last;
    final suffix = '-$buildNumber.apk';
    if (!fileName.toLowerCase().endsWith(suffix)) {
      return '';
    }
    final nameWithoutSuffix =
        fileName.substring(0, fileName.length - suffix.length);
    const prefix = 'masar-crm-';
    if (!nameWithoutSuffix.toLowerCase().startsWith(prefix)) {
      return '';
    }
    return nameWithoutSuffix.substring(prefix.length).trim();
  }

  String _versionBuildLabel(
    AppLocalizations l, {
    required String version,
    required int buildNumber,
  }) {
    final cleanVersion = version.trim();
    if (cleanVersion.isEmpty && buildNumber <= 0) {
      return l.notAvailable;
    }
    if (cleanVersion.isEmpty) {
      return '${l.notAvailable} (${l.buildNumber}: $buildNumber)';
    }
    if (buildNumber <= 0) {
      return cleanVersion;
    }
    return '$cleanVersion ($buildNumber)';
  }

  String _downloadTitle(AppLocalizations l) {
    final status = _downloadStatus;
    if (status?.isSuccessful == true) return l.androidUpdateReadyToInstall;
    if (status?.isFailed == true) return l.androidUpdateDownloadFailed;
    if (_openingInstaller) return l.androidUpdateInstalling;
    return l.androidUpdateDownloading;
  }

  Duration? _remainingDuration(AndroidReleasePolicy policy) {
    final end = policy.gracePeriodEndsAt;
    if (end == null) {
      return null;
    }
    final remaining = end.difference(_estimatedServerNow);
    if (remaining.isNegative) {
      return Duration.zero;
    }
    return remaining;
  }

  double? _remainingProgress(AndroidReleasePolicy policy, Duration? remaining) {
    final total = policy.totalGracePeriod;
    if (total == null || remaining == null || total.inSeconds <= 0) {
      return null;
    }
    return (remaining.inSeconds / total.inSeconds).clamp(0.0, 1.0);
  }

  String _formatRemaining(Duration duration, {required bool isArabic}) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    if (isArabic) {
      if (days > 0) {
        return '$days يوم و $hours ساعة و $minutes دقيقة';
      }
      if (hours > 0) {
        return '$hours ساعة و $minutes دقيقة';
      }
      return '$minutes دقيقة';
    }
    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    }
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _firstText(String primary, String secondary, String fallback) {
    final cleanPrimary = primary.trim();
    if (cleanPrimary.isNotEmpty) return cleanPrimary;
    final cleanSecondary = secondary.trim();
    if (cleanSecondary.isNotEmpty) return cleanSecondary;
    return fallback;
  }
}

class _DownloadProgressCard extends StatelessWidget {
  const _DownloadProgressCard({
    required this.title,
    required this.message,
    required this.progress,
    required this.bytesDownloaded,
    required this.totalBytes,
  });

  final String title;
  final String? message;
  final double? progress;
  final int bytesDownloaded;
  final int totalBytes;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final percent = progress == null ? null : (progress! * 100).clamp(0, 100).round();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.textPrimaryColor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (percent != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '$percent%',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
            ),
            if (message != null && message!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  height: 1.45,
                ),
              ),
            ],
            if (totalBytes > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${_formatSize(bytesDownloaded)} / ${_formatSize(totalBytes)}',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 MB';
    final mb = bytes / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    final kb = bytes / 1024;
    return '${kb.toStringAsFixed(0)} KB';
  }
}

class _UpdateGateLogo extends StatelessWidget {
  const _UpdateGateLogo({
    required this.label,
    this.compact = false,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final markSize = compact ? 46.0 : 64.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MasarBrandMark(size: markSize),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: (compact ? textTheme.titleMedium : textTheme.titleLarge)?.copyWith(
            color: AppColors.textPrimaryColor(context),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _VersionInfoRow extends StatelessWidget {
  const _VersionInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        borderRadius: AppRadius.medium,
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimaryColor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
