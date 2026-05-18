import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../users/data/datasources/user_profile_remote_data_source.dart';
import '../../../users/data/repositories/user_profile_repository_impl.dart';
import '../../../users/domain/entities/profile_image_upload.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../../users/domain/usecases/update_own_profile_usecase.dart';
import '../cubit/profile_settings_cubit.dart';
import '../cubit/profile_settings_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final remoteDataSource = FirestoreUserProfileRemoteDataSource();
    final repository = UserProfileRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    return BlocProvider(
      create: (_) => ProfileSettingsCubit(
        updateOwnProfileUseCase: UpdateOwnProfileUseCase(repository),
        uploadOwnProfileImageUseCase: UploadOwnProfileImageUseCase(repository),
        removeOwnProfileImageUseCase: RemoveOwnProfileImageUseCase(repository),
      ),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final profile = authState.userProfile;
    final user = authState.user;
    _debugProfileImageSources(
      source: 'profile page',
      authPhotoUrl: user?.photoUrl ?? '',
      companyPhotoUrl: profile?.photoUrl ?? '',
      companyPhotoStoragePath: profile?.photoStoragePath ?? '',
    );
    _nameController = TextEditingController(
      text: profile?.fullName ??
          user?.fullName ??
          user?.displayName ??
          '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final profile = authState.userProfile;
    final user = authState.user;

    return BlocListener<ProfileSettingsCubit, ProfileSettingsState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ProfileSettingsStatus.success) {
          if (state.updatedProfile != null) {
            context.read<AuthBloc>().add(
                  AuthProfileUpdated(profile: state.updatedProfile),
                );
            _nameController.text = state.updatedProfile!.fullName;
          } else if (state.platformFullName != null ||
              state.platformPhotoUrl != null) {
            context.read<AuthBloc>().add(
                  AuthProfileUpdated(
                    fullName: state.platformFullName,
                    photoUrl: state.platformPhotoUrl,
                  ),
                );
          } else {
            context.read<AuthBloc>().add(const AuthStarted());
          }
          AppFeedback.success(context, l.profileUpdatedSuccessfully);
        }
        if (state.status == ProfileSettingsStatus.failure) {
          AppFeedback.error(
            context,
            localizeThrownErrorMessage(
              l,
              state.message,
              fallbackMessage: AppErrorMessages.unknown,
            ),
          );
        }
      },
      child: CrmAppShell(
        selectedItem: CrmNavigationItem.more,
        title: l.myProfile,
        child: user == null
            ? AppErrorView(message: l.missingCompanyProfile)
            : profile == null && authState.isPlatformAdmin
                ? _PlatformOwnerProfileContent(
                    nameController: _nameController,
                    user: user,
                    photoUrl: user.photoUrl ?? '',
                    isPlatformAdmin: authState.isPlatformAdmin,
                  )
                : profile == null
                    ? AppErrorView(message: l.missingCompanyProfile)
                    : ListView(
                primary: true,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileHeader(
                          name: profile.fullName,
                          email: profile.email,
                          role: roleLabel(l, profile.role),
                          isActive: profile.isActive,
                          photoUrl: profile.photoUrl,
                          onUploadImage: () => _pickAndUploadImage(
                            context,
                            profile,
                            authState.isPlatformAdmin,
                          ),
                          onRemoveImage: profile.photoUrl.trim().isEmpty
                              ? null
                              : () => _removeImage(
                                    context,
                                    profile,
                                    authState.isPlatformAdmin,
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _EditableNameSection(
                          controller: _nameController,
                          profile: profile,
                          isPlatformAdmin: authState.isPlatformAdmin,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _Section(
                          title: l.profileInformation,
                          children: [
                            _detail(context, l.email, _value(l, profile.email)),
                            _detail(context, l.phone, _value(l, profile.phone)),
                            _detail(context, l.role, roleLabel(l, profile.role)),
                            _detail(
                              context,
                              l.accountStatus,
                              profile.isActive ? l.active : l.inactive,
                            ),
                            _detail(
                              context,
                              l.createdAt,
                              _formatDate(context, profile.createdAt),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          label: l.settings,
                          icon: Icons.settings_outlined,
                          onPressed: () => context.go(RouteNames.settings),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(
    BuildContext context,
    UserProfile profile,
    bool isPlatformAdmin,
  ) async {
    final l = AppLocalizations.of(context)!;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      final file = result?.files.single;
      final bytes = file?.bytes;
      if (file == null || bytes == null) {
        return;
      }
      if (!context.mounted) {
        return;
      }
      await context.read<ProfileSettingsCubit>().uploadImage(
            uid: profile.uid,
            companyId: profile.companyId,
            isPlatformAdmin: isPlatformAdmin,
            image: ProfileImageUpload(
              fileName: file.name,
              bytes: bytes,
              contentType: _contentTypeForFile(file.name),
            ),
          );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      AppFeedback.error(context, l.unableToPickProfileImage);
    }
  }

  Future<void> _removeImage(
    BuildContext context,
    UserProfile profile,
    bool isPlatformAdmin,
  ) {
    return context.read<ProfileSettingsCubit>().removeImage(
          uid: profile.uid,
          companyId: profile.companyId,
          isPlatformAdmin: isPlatformAdmin,
        );
  }
}


class _PlatformOwnerProfileContent extends StatelessWidget {
  const _PlatformOwnerProfileContent({
    required this.nameController,
    required this.user,
    required this.photoUrl,
    required this.isPlatformAdmin,
  });

  final TextEditingController nameController;
  final AppUser user;
  final String photoUrl;
  final bool isPlatformAdmin;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final name = (user.fullName ?? user.displayName ?? '').trim();
    final email = (user.email ?? '').trim();

    return ListView(
      primary: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileHeader(
                name: name,
                email: email,
                role: l.platform,
                isActive: true,
                photoUrl: photoUrl,
                onUploadImage: () => _pickPlatformImage(
                  context,
                  user.uid,
                  isPlatformAdmin,
                ),
                onRemoveImage: photoUrl.trim().isEmpty
                    ? null
                    : () => context.read<ProfileSettingsCubit>().removeImage(
                          uid: user.uid,
                          companyId: '',
                          isPlatformAdmin: isPlatformAdmin,
                        ),
              ),
              const SizedBox(height: AppSpacing.md),
              _EditablePlatformNameSection(
                controller: nameController,
                uid: user.uid,
                isPlatformAdmin: isPlatformAdmin,
              ),
              const SizedBox(height: AppSpacing.md),
              _Section(
                title: l.profileInformation,
                children: [
                  _detail(context, l.email, _value(l, email)),
                  _detail(context, l.role, l.platform),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l.settings,
                icon: Icons.settings_outlined,
                onPressed: () => context.go(RouteNames.settings),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickPlatformImage(
    BuildContext context,
    String uid,
    bool isPlatformAdmin,
  ) async {
    final l = AppLocalizations.of(context)!;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      final file = result?.files.single;
      final bytes = file?.bytes;
      if (file == null || bytes == null) {
        return;
      }
      if (!context.mounted) {
        return;
      }
      await context.read<ProfileSettingsCubit>().uploadImage(
            uid: uid,
            companyId: '',
            isPlatformAdmin: isPlatformAdmin,
            image: ProfileImageUpload(
              fileName: file.name,
              bytes: bytes,
              contentType: _contentTypeForFile(file.name),
            ),
          );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      AppFeedback.error(context, l.unableToPickProfileImage);
    }
  }
}

class _EditablePlatformNameSection extends StatelessWidget {
  const _EditablePlatformNameSection({
    required this.controller,
    required this.uid,
    required this.isPlatformAdmin,
  });

  final TextEditingController controller;
  final String uid;
  final bool isPlatformAdmin;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _Section(
      title: l.editProfile,
      children: [
        AppTextField(
          controller: controller,
          label: l.fullName,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: AppSpacing.sm),
        BlocBuilder<ProfileSettingsCubit, ProfileSettingsState>(
          builder: (context, state) {
            final isSaving = state.status == ProfileSettingsStatus.saving;
            return AppButton(
              label: l.save,
              icon: Icons.save_outlined,
              isLoading: isSaving,
              onPressed: isSaving
                  ? null
                  : () {
                      final name = controller.text.trim();
                      if (name.isEmpty) {
                        AppFeedback.error(context, l.fullNameRequired);
                        return;
                      }
                      context.read<ProfileSettingsCubit>().updateName(
                            uid: uid,
                            companyId: '',
                            fullName: name,
                            isPlatformAdmin: isPlatformAdmin,
                          );
                    },
            );
          },
        ),
      ],
    );
  }
}

class _EditableNameSection extends StatelessWidget {
  const _EditableNameSection({
    required this.controller,
    required this.profile,
    required this.isPlatformAdmin,
  });

  final TextEditingController controller;
  final UserProfile profile;
  final bool isPlatformAdmin;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _Section(
      title: l.editProfile,
      children: [
        AppTextField(
          controller: controller,
          label: l.fullName,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: AppSpacing.sm),
        BlocBuilder<ProfileSettingsCubit, ProfileSettingsState>(
          builder: (context, state) {
            final isSaving = state.status == ProfileSettingsStatus.saving;
            return AppButton(
              label: l.save,
              icon: Icons.save_outlined,
              isLoading: isSaving,
              onPressed: isSaving
                  ? null
                  : () {
                      final name = controller.text.trim();
                      if (name.isEmpty) {
                        AppFeedback.error(context, l.fullNameRequired);
                        return;
                      }
                      context.read<ProfileSettingsCubit>().updateName(
                            uid: profile.uid,
                            companyId: profile.companyId,
                            fullName: name,
                            isPlatformAdmin: isPlatformAdmin,
                          );
                    },
            );
          },
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.photoUrl,
    required this.onUploadImage,
    required this.onRemoveImage,
  });

  final String name;
  final String email;
  final String role;
  final bool isActive;
  final String photoUrl;
  final VoidCallback onUploadImage;
  final VoidCallback? onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _ProfileAvatar(name: name, photoUrl: photoUrl, radius: 34),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _value(l, name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _value(l, email),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondaryColor(context),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        AppStatusBadge(label: role),
                        AppStatusBadge(
                          label: isActive ? l.active : l.inactive,
                          tone: isActive
                              ? AppStatusTone.success
                              : AppStatusTone.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          BlocBuilder<ProfileSettingsCubit, ProfileSettingsState>(
            builder: (context, state) {
              final isSaving = state.status == ProfileSettingsStatus.saving;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppButton(
                    label: l.uploadProfileImage,
                    icon: Icons.photo_camera_outlined,
                    variant: AppButtonVariant.secondary,
                    isLoading: isSaving,
                    onPressed: isSaving ? null : onUploadImage,
                  ),
                  AppButton(
                    label: l.removeProfileImage,
                    icon: Icons.delete_outline,
                    variant: AppButtonVariant.secondary,
                    onPressed: isSaving ? null : onRemoveImage,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.name,
    required this.photoUrl,
    required this.radius,
  });

  final String name;
  final String photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cleanUrl = photoUrl.trim();
    final initial = name.trim().isEmpty ? 'M' : name.trim().substring(0, 1);
    final fallback = _ProfileInitialAvatar(
      initial: initial,
      radius: radius,
    );

    if (cleanUrl.isEmpty) {
      return fallback;
    }

    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Image.network(
          cleanUrl,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          errorBuilder: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}

class _ProfileInitialAvatar extends StatelessWidget {
  const _ProfileInitialAvatar({
    required this.initial,
    required this.radius,
  });

  final String initial;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryColor(context),
      child: Text(
        initial.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

Widget _detail(BuildContext context, String label, String value) {
  return Padding(
    padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}

String roleLabel(AppLocalizations l, UserRole role) {
  switch (role) {
    case UserRole.admin:
      return l.admin;
    case UserRole.manager:
      return l.manager;
    case UserRole.salesAgent:
      return l.salesAgent;
    case UserRole.marketing:
      return l.marketing;
    case UserRole.viewer:
      return l.viewer;
  }
}

String _value(AppLocalizations l, String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? l.notAvailable : trimmed;
}

String _formatDate(BuildContext context, DateTime value) {
  final localeName = Localizations.localeOf(context).toString();
  return DateFormat.yMd(localeName).add_jm().format(value.toLocal());
}

String _contentTypeForFile(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  if (lower.endsWith('.gif')) {
    return 'image/gif';
  }
  return 'image/jpeg';
}

void _debugProfileImageSources({
  required String source,
  required String authPhotoUrl,
  required String companyPhotoUrl,
  required String companyPhotoStoragePath,
}) {
  // Intentionally silent. Avoid noisy profile image logs and URL/token output.
  return;
}
