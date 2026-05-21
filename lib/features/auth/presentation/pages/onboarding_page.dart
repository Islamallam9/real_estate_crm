import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/masar_brand.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/public_auth_actions.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _seenKey = 'masar_onboarding_seen_v1';

  final _pageController = PageController();
  var _currentPage = 0;
  var _checkingSeenState = true;

  @override
  void initState() {
    super.initState();
    _handleInitialState();
  }

  Future<void> _handleInitialState() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_seenKey) ?? false;
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
    if (seen) {
      context.go(RouteNames.login);
      return;
    }
    setState(() => _checkingSeenState = false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSeenState) {
      return Scaffold(
        backgroundColor: AppColors.appBackground(context),
        body: const SizedBox.shrink(),
      );
    }

    final l = AppLocalizations.of(context)!;
    final cards = _onboardingCards(l);

    return Scaffold(
      backgroundColor: AppColors.appBackground(context),
      body: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? const [Color(0xFF0F1720), Color(0xFF182330), Color(0xFF2F2414)]
                  : const [Color(0xFFFFF8EA), Color(0xFFF7E6BF), Color(0xFFD7E3EA)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    const PublicAuthActions(),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _finish(RouteNames.login),
                      child: Text(l.skip),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 900;
                          if (!wide) {
                            return _MobileOnboardingPager(
                              controller: _pageController,
                              currentPage: _currentPage,
                              cards: cards,
                              onPageChanged: (index) => setState(() => _currentPage = index),
                              onBack: _currentPage == 0 ? null : () => _animateToPage(_currentPage - 1),
                              onNext: _currentPage >= cards.length - 1
                                  ? () => _finish(RouteNames.login)
                                  : () => _animateToPage(_currentPage + 1),
                              onRegister: () => _finish(RouteNames.registerCompany),
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(flex: 5, child: _DesktopHero(onLogin: () => _finish(RouteNames.login), onRegister: () => _finish(RouteNames.registerCompany))),
                              const SizedBox(width: AppSpacing.xl),
                              Expanded(flex: 6, child: _DesktopOnboardingCards(cards: cards)),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _finish(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
    if (!mounted) return;
    context.go(route);
  }

  Future<void> _animateToPage(int page) {
    return _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }
}

List<_OnboardingCardData> _onboardingCards(AppLocalizations l) {
  return [
    _OnboardingCardData(
      visualType: _OnboardingVisualType.workflow,
      title: l.onboardingTitle,
      message: l.onboardingSubtitle,
      icon: Icons.route_outlined,
    ),
    _OnboardingCardData(
      visualType: _OnboardingVisualType.invitation,
      title: l.onboardingInvitationTitle,
      message: l.onboardingInvitationMessage,
      icon: Icons.mark_email_unread_outlined,
    ),
    _OnboardingCardData(
      visualType: _OnboardingVisualType.analytics,
      title: l.onboardingAnalyticsTitle,
      message: l.onboardingAnalyticsMessage,
      icon: Icons.insights_outlined,
    ),
  ];
}

class _DesktopHero extends StatelessWidget {
  const _DesktopHero({required this.onLogin, required this.onRegister});

  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.94, end: 1),
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: Transform.scale(scale: value, child: child),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.cardSurface(context).withValues(alpha: 0.78),
          border: Border.all(color: AppColors.borderColor(context)),
          borderRadius: BorderRadius.circular(34),
          boxShadow: Theme.of(context).brightness == Brightness.dark ? null : AppShadows.shell,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const MasarBrandLogo(height: 58),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l.onboardingTitle,
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.05,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.onboardingSubtitle,
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondaryColor(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppButton(label: l.signInExistingAccount, icon: Icons.login, onPressed: onLogin),
                AppButton(label: l.createAdminWorkspace, icon: Icons.add_circle_outline, variant: AppButtonVariant.secondary, onPressed: onRegister),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileOnboardingPager extends StatelessWidget {
  const _MobileOnboardingPager({
    required this.controller,
    required this.currentPage,
    required this.cards,
    required this.onPageChanged,
    required this.onBack,
    required this.onNext,
    required this.onRegister,
  });

  final PageController controller;
  final int currentPage;
  final List<_OnboardingCardData> cards;
  final ValueChanged<int> onPageChanged;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: MasarBrandLogo(height: 48),
        ),
        Expanded(
          child: PageView.builder(
            controller: controller,
            itemCount: cards.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  double distance = 0;
                  if (controller.hasClients && controller.position.haveDimensions) {
                    distance = (controller.page ?? currentPage.toDouble()) - index.toDouble();
                  } else {
                    distance = (currentPage - index).toDouble();
                  }
                  final scale = (1 - distance.abs() * 0.07).clamp(0.91, 1.0).toDouble();
                  final opacity = (1 - distance.abs() * 0.25).clamp(0.72, 1.0).toDouble();
                  return Opacity(opacity: opacity, child: Transform.scale(scale: scale, child: child));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: _MobileOnboardingCard(data: cards[index]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _PageDots(count: cards.length, activeIndex: currentPage),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: l.back,
                icon: Icons.arrow_back,
                variant: AppButtonVariant.secondary,
                onPressed: onBack,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                label: currentPage >= cards.length - 1 ? l.signInExistingAccount : l.next,
                icon: currentPage >= cards.length - 1 ? Icons.login : Icons.arrow_forward,
                onPressed: onNext,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: onRegister,
          icon: const Icon(Icons.add_circle_outline),
          label: Text(l.createAdminWorkspace),
        ),
      ],
    );
  }
}

class _MobileOnboardingCard extends StatelessWidget {
  const _MobileOnboardingCard({required this.data});

  final _OnboardingCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context).withValues(alpha: 0.82),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: BorderRadius.circular(34),
        boxShadow: Theme.of(context).brightness == Brightness.dark ? null : AppShadows.shell,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 500;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _OnboardingIconBadge(icon: data.icon),
                  ),
                  SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
                  SizedBox(
                    height: compact ? 96 : 146,
                    child: _OnboardingVisual(type: data.visualType),
                  ),
                  SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    textWidthBasis: TextWidthBasis.parent,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.24,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    data.message,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    textWidthBasis: TextWidthBasis.parent,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondaryColor(context),
                          height: 1.6,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DesktopOnboardingCards extends StatelessWidget {
  const _DesktopOnboardingCards({required this.cards});

  final List<_OnboardingCardData> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < cards.length; index++) ...[
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 360 + index * 110),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(offset: Offset(0, 24 * (1 - value)), child: child),
                      );
                    },
                    child: _OnboardingFeatureCard(data: cards[index]),
                  ),
                  if (index != cards.length - 1)
                    const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingFeatureCard extends StatelessWidget {
  const _OnboardingFeatureCard({required this.data});

  final _OnboardingCardData data;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 172),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardSurface(context).withValues(alpha: 0.88),
          border: Border.all(color: AppColors.borderColor(context)),
          borderRadius: AppRadius.xLarge,
          boxShadow: Theme.of(context).brightness == Brightness.dark ? null : AppShadows.subtle,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 520;
            final visualWidth = narrow ? 132.0 : 164.0;

            return Row(
              children: [
                SizedBox(
                  width: visualWidth,
                  height: 140,
                  child: _OnboardingVisual(type: data.visualType, compact: true),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _OnboardingIconBadge(icon: data.icon, compact: true),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              data.title,
                              softWrap: true,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    height: 1.15,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        data.message,
                        softWrap: true,
                        textWidthBasis: TextWidthBasis.parent,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondaryColor(context),
                              height: 1.38,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: index == activeIndex ? 26 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: index == activeIndex ? AppColors.primaryColor(context) : AppColors.borderColor(context),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

class _OnboardingCardData {
  const _OnboardingCardData({
    required this.visualType,
    required this.title,
    required this.message,
    required this.icon,
  });

  final _OnboardingVisualType visualType;
  final String title;
  final String message;
  final IconData icon;
}

enum _OnboardingVisualType { workflow, invitation, analytics }

class _OnboardingIconBadge extends StatelessWidget {
  const _OnboardingIconBadge({required this.icon, this.compact = false});

  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 56.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryColor(context).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 12 : 18),
        border: Border.all(
          color: AppColors.primaryColor(context).withValues(alpha: 0.20),
        ),
      ),
      child: Icon(
        icon,
        color: AppColors.primaryColor(context),
        size: compact ? 18 : 29,
      ),
    );
  }
}

class _OnboardingVisual extends StatelessWidget {
  const _OnboardingVisual({required this.type, this.compact = false});

  final _OnboardingVisualType type;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tight = constraints.maxWidth < 140;
        final padding = compact ? (tight ? 7.0 : 10.0) : AppSpacing.md;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.selectedSurface(context).withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(compact ? 18 : 28),
            border: Border.all(color: AppColors.borderColor(context)),
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: switch (type) {
              _OnboardingVisualType.workflow => _WorkflowVisual(
                  compact: compact,
                  tight: tight,
                ),
              _OnboardingVisualType.invitation => _InvitationVisual(
                  compact: compact,
                  tight: tight,
                ),
              _OnboardingVisualType.analytics => _AnalyticsVisual(
                  compact: compact,
                  tight: tight,
                ),
            },
          ),
        );
      },
    );
  }
}

class _ScaledMiniVisual extends StatelessWidget {
  const _ScaledMiniVisual({required this.designSize, required this.child});

  final Size designSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: designSize.width,
          height: designSize.height,
          child: child,
        ),
      ),
    );
  }
}

class _WorkflowVisual extends StatelessWidget {
  const _WorkflowVisual({required this.compact, required this.tight});

  final bool compact;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryColor(context);
    final blue = AppColors.infoColor(context);
    final green = AppColors.successColor(context);
    final nodeSize = tight ? 28.0 : compact ? 42.0 : 58.0;

    return _ScaledMiniVisual(
      designSize: Size(tight ? 116 : compact ? 128 : 190, tight ? 42 : 64),
      child: Row(
        children: [
          _FlowNode(icon: Icons.person_search_outlined, color: primary, size: nodeSize),
          Expanded(child: _FlowConnector(color: primary)),
          _FlowNode(icon: Icons.key_outlined, color: blue, size: nodeSize),
          Expanded(child: _FlowConnector(color: blue)),
          _FlowNode(icon: Icons.handshake_outlined, color: green, size: nodeSize),
        ],
      ),
    );
  }
}

class _InvitationVisual extends StatelessWidget {
  const _InvitationVisual({required this.compact, required this.tight});

  final bool compact;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryColor(context);
    return _ScaledMiniVisual(
      designSize: Size(tight ? 102 : compact ? 128 : 190, tight ? 86 : compact ? 96 : 108),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              _CodeBlock(widthFactor: 0.34, color: primary),
              SizedBox(width: tight ? 5 : AppSpacing.xs),
              _CodeBlock(widthFactor: 0.22, color: AppColors.infoColor(context)),
              SizedBox(width: tight ? 5 : AppSpacing.xs),
              _CodeBlock(widthFactor: 0.26, color: primary),
            ],
          ),
          SizedBox(height: tight ? 8 : compact ? AppSpacing.sm : AppSpacing.md),
          Container(
            height: tight ? 38 : compact ? 42 : 56,
            padding: EdgeInsets.all(tight ? 6 : compact ? 8 : 10),
            decoration: BoxDecoration(
              color: AppColors.cardSurface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor(context)),
            ),
            child: Row(
              children: [
                Icon(Icons.mark_email_unread_outlined, color: primary, size: tight ? 16 : compact ? 18 : 22),
                SizedBox(width: tight ? 6 : AppSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MiniLine(widthFactor: 0.78, color: primary),
                      const SizedBox(height: 6),
                      const _MiniLine(widthFactor: 0.52),
                    ],
                  ),
                ),
                Icon(Icons.verified_outlined, color: AppColors.successColor(context), size: tight ? 16 : compact ? 18 : 22),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsVisual extends StatelessWidget {
  const _AnalyticsVisual({required this.compact, required this.tight});

  final bool compact;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final bars = tight
        ? const [0.52, 0.78, 0.62]
        : compact ? const [0.46, 0.72, 0.58] : const [0.38, 0.64, 0.86, 0.58];

    return _ScaledMiniVisual(
      designSize: Size(tight ? 102 : compact ? 128 : 190, tight ? 86 : 106),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.insights_outlined, color: AppColors.primaryColor(context), size: tight ? 20 : compact ? 22 : 28),
                SizedBox(height: tight ? 8 : compact ? AppSpacing.sm : AppSpacing.md),
                _MiniLine(widthFactor: 0.84, color: AppColors.primaryColor(context)),
                const SizedBox(height: 8),
                const _MiniLine(widthFactor: 0.58),
                const SizedBox(height: 8),
                const _MiniLine(widthFactor: 0.42),
              ],
            ),
          ),
          SizedBox(width: tight ? 8 : AppSpacing.md),
          for (final bar in bars) ...[
            _MetricBar(heightFactor: bar, width: tight ? 10 : 13),
            SizedBox(width: tight ? 5 : 7),
          ],
        ],
      ),
    );
  }
}

class _FlowNode extends StatelessWidget {
  const _FlowNode({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Icon(icon, color: color, size: size * 0.50),
    );
  }
}

class _FlowConnector extends StatelessWidget {
  const _FlowConnector({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.widthFactor, required this.color});

  final double widthFactor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: (widthFactor * 100).round(),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
      ),
    );
  }
}

class _MiniLine extends StatelessWidget {
  const _MiniLine({required this.widthFactor, this.color});

  final double widthFactor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: (color ?? AppColors.textSecondaryColor(context)).withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({required this.heightFactor, required this.width});

  final double heightFactor;
  final double width;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: heightFactor,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.primaryColor(context).withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
