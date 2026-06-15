import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/protected_company_session.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../property_matching/presentation/widgets/matching_demand_card.dart';
import '../../domain/entities/property.dart';
import '../cubit/properties_cubit.dart';
import '../cubit/properties_state.dart';
import '../widgets/properties_scope.dart';
import '../widgets/property_labels.dart';
import '../../../../core/widgets/masar_loading_view.dart';

class PropertyDetailsPage extends StatelessWidget {
  const PropertyDetailsPage({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final session = authState.protectedCompanySession;
        return PropertiesScope(
          key: ValueKey(
            session?.scopeKey('property-details-scope') ??
                'property-details-scope:loading',
          ),
          child: _PropertyDetailsView(propertyId: propertyId),
        );
      },
    );
  }
}

class _PropertyDetailsView extends StatefulWidget {
  const _PropertyDetailsView({required this.propertyId});

  final String propertyId;

  @override
  State<_PropertyDetailsView> createState() => _PropertyDetailsViewState();
}

class _PropertyDetailsViewState extends State<_PropertyDetailsView> {
  String? _watchKey;

  void _watchPropertyWhenReady(ProtectedCompanySession session) {
    final key =
        '${session.scopeKey('property-details-watch')}:${widget.propertyId}';
    if (_watchKey == key) {
      return;
    }
    _watchKey = key;
    context.read<PropertiesCubit>().watchProperty(
      companyId: session.companyId,
      propertyId: widget.propertyId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final session = authState.protectedCompanySession;

    if (authState.isWaitingForProtectedCompanySession) {
      return CrmAppShell(
        selectedItem: CrmNavigationItem.properties,
        title: l.propertyDetails,
        child: const AppLoading(),
      );
    }

    final role = session?.profile.role;
    final canEdit =
        role != null && PermissionService.can(role, AppPermission.editProperty);
    final canDeactivate =
        role != null && PermissionService.can(role, AppPermission.editProperty);
    final uid = session?.uid ?? '';
    final companyId = session?.companyId ?? '';
    if (session != null) {
      _watchPropertyWhenReady(session);
    }

    return CrmAppShell(
      selectedItem: CrmNavigationItem.properties,
      title: l.propertyDetails,
      child: session == null
          ? AppErrorView(message: l.missingCompanyProfile)
          : BlocBuilder<PropertiesCubit, PropertiesState>(
        builder: (context, state) {
          if (state.status == PropertiesStatus.initial ||
              (state.status == PropertiesStatus.loading &&
                  state.properties.isEmpty)) {
            return const AppLoading();
          }

          final property = _findPropertyById(
            properties: state.properties,
            propertyId: widget.propertyId,
          );
          if (property == null || companyId.isEmpty) {
            return AppErrorView(
              message: l.propertyNotFoundMessage,
              onRetry: () {
                context.read<PropertiesCubit>().watchProperty(
                  companyId: companyId,
                  propertyId: widget.propertyId,
                );
              },
            );
          }

          return Stack(
            children: [
              ListView(
                primary: true,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                property.title.trim().isEmpty
                                    ? l.notAvailable
                                    : property.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            AppStatusBadge(
                              label: propertyStatusLabel(l, property.status),
                              tone: propertyStatusTone(property.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            AppButton(
                              label: l.backToProperties,
                              variant: AppButtonVariant.secondary,
                              onPressed: () =>
                                  context.go(RouteNames.properties),
                            ),
                            if (canEdit)
                              AppButton(
                                label: l.editProperty,
                                onPressed: () => context.go(
                                  RouteNames.propertyEdit(property.id),
                                ),
                              ),
                            if (canDeactivate &&
                                property.status != PropertyStatus.inactive)
                              AppButton(
                                label: l.deactivateProperty,
                                variant: AppButtonVariant.secondary,
                                onPressed: () => _confirmDeactivateFromDetails(
                                  context,
                                  companyId: companyId,
                                  propertyId: property.id,
                                  updatedBy: uid,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _PropertyImagesSection(property: property),
                        const SizedBox(height: AppSpacing.md),
                        MatchingDemandCard(
                          companyId: companyId,
                          property: property,
                          role: role!,
                          currentUserId: uid,
                          currentUserTeamId: session.profile.teamId,
                          currentUserManagerId: session.profile.managerId,
                          canViewLeads: PermissionService.can(
                            role,
                            AppPermission.viewLeads,
                          ),
                          canViewClients: PermissionService.can(
                            role,
                            AppPermission.viewClients,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _DetailsSection(
                          title: l.details,
                          children: [
                            _detail(
                              context,
                              l.description,
                              _valueOrNotAvailable(l, property.description),
                            ),
                            _detail(
                              context,
                              l.propertyType,
                              propertyTypeLabel(l, property.propertyType),
                            ),
                            _detail(
                              context,
                              l.listingType,
                              propertyListingTypeLabel(l, property.listingType),
                            ),
                            _detail(
                              context,
                              l.status,
                              propertyStatusLabel(l, property.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _DetailsSection(
                          title: l.propertyMetrics,
                          children: [
                            _detail(
                              context,
                              l.price,
                              _formatNumber(context, property.price),
                            ),
                            _detail(
                              context,
                              l.area,
                              _formatNumber(context, property.area),
                            ),
                            _detail(
                              context,
                              l.bedrooms,
                              property.bedrooms.toString(),
                            ),
                            _detail(
                              context,
                              l.bathrooms,
                              property.bathrooms.toString(),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _DetailsSection(
                          title: l.propertyLocationSection,
                          children: [
                            _detail(
                              context,
                              l.location,
                              _valueOrNotAvailable(l, property.location),
                            ),
                            _detail(
                              context,
                              l.compound,
                              _valueOrNotAvailable(l, property.compound),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _DetailsSection(
                          title: l.propertyOwnerSection,
                          children: [
                            _detail(
                              context,
                              l.ownerName,
                              _valueOrNotAvailable(l, property.ownerName),
                            ),
                            _detail(
                              context,
                              l.ownerPhone,
                              _valueOrNotAvailable(l, property.ownerPhone),
                            ),
                            _detail(
                              context,
                              l.assignedToLabel,
                              _valueOrNotAvailable(l, property.assignedTo),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _DetailsSection(
                          title: l.auditInfo,
                          children: [
                            _detail(
                              context,
                              l.createdAt,
                              _formatDate(context, property.createdAt),
                            ),
                            _detail(
                              context,
                              l.updatedAt,
                              _formatDate(context, property.updatedAt),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (state.status == PropertiesStatus.loading)
                Positioned.fill(
                  child: AbsorbPointer(
                    child: Container(
                      color: AppColors.appBackground(
                        context,
                      ).withValues(alpha: 0.55),
                      child: const Center(child: MasarLogoLoader(size: 42)),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _confirmDeactivateFromDetails(
  BuildContext context, {
  required String companyId,
  required String propertyId,
  required String updatedBy,
}) async {
  final l = AppLocalizations.of(context)!;
  final cubit = context.read<PropertiesCubit>();
  var isSubmitting = false;
  var didSubmit = false;
  var mutationSucceeded = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l.deactivateProperty),
            content: Text(l.deactivatePropertyConfirmation),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: Text(l.cancel),
              ),
              AppButton(
                label: l.deactivate,
                isLoading: isSubmitting,
                onPressed: () async {
                  didSubmit = true;
                  setDialogState(() => isSubmitting = true);
                  mutationSucceeded = await cubit.deactivateProperty(
                    companyId: companyId,
                    propertyId: propertyId,
                    updatedBy: updatedBy,
                  );
                  if (mutationSucceeded && dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    return;
                  }
                  if (dialogContext.mounted) {
                    setDialogState(() => isSubmitting = false);
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
  if (!context.mounted) {
    return;
  }
  if (!didSubmit) {
    return;
  }
  if (mutationSucceeded) {
    AppFeedback.success(context, l.propertyDeactivatedSuccessfully);
  } else {
    AppFeedback.error(context, l.unableToDeactivateProperty);
  }
}

class _PropertyImagesSection extends StatelessWidget {
  const _PropertyImagesSection({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final imageUrls = property.imageUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .take(10)
        .toList(growable: false);

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
            l.propertyImages,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 158,
            child: imageUrls.isEmpty
                ? _PropertyImagePreviewPlaceholder(message: l.noPropertyImagesYet)
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: imageUrls.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      return _PropertyImagePreviewCard(
                        imageUrl: imageUrls[index],
                        index: index + 1,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PropertyImagePreviewCard extends StatelessWidget {
  const _PropertyImagePreviewCard({required this.imageUrl, required this.index});

  final String imageUrl;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 230,
        height: 158,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              errorBuilder: (context, error, stackTrace) => ColoredBox(
                color: AppColors.appBackground(context),
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 38,
                  color: AppColors.textMutedColor(context),
                ),
              ),
            ),
            PositionedDirectional(
              start: AppSpacing.sm,
              top: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  index.toString(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyImagePreviewPlaceholder extends StatelessWidget {
  const _PropertyImagePreviewPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.appBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.real_estate_agent_outlined,
            size: 42,
            color: AppColors.textMutedColor(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.title, required this.children});

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
        Text(value, maxLines: 3, overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}

Property? _findPropertyById({
  required List<Property> properties,
  required String propertyId,
}) {
  for (final property in properties) {
    if (property.id == propertyId) {
      return property;
    }
  }
  return null;
}

String _valueOrNotAvailable(AppLocalizations l, String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? l.notAvailable : trimmed;
}

String _formatDate(BuildContext context, DateTime value) {
  final localeName = Localizations.localeOf(context).toString();
  return DateFormat.yMd(localeName).add_jm().format(value.toLocal());
}

String _formatNumber(BuildContext context, num value) {
  final localeName = Localizations.localeOf(context).toString();
  return NumberFormat.decimalPattern(localeName).format(value);
}
