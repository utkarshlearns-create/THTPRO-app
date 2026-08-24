import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/utils/api_error.dart';

/// Nothing here yet — and what to do about it.
///
/// An empty list is not a failure, so it never borrows the error styling. It
/// says what would appear here and offers the action that would fill it.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Tighter version for use inside a card rather than a full page.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: compact ? AppSpacing.xl : AppSpacing.huge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate800 : AppColors.slate100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: compact ? 22 : 28,
              color: isDark ? AppColors.slate400 : AppColors.slate400,
            ),
          ),
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.base),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 14.5 : 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.slate200 : AppColors.slate800,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: isDark ? AppColors.slate400 : AppColors.slate500,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: compact ? AppSpacing.base : AppSpacing.lg),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Something went wrong, said plainly, with a way forward.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.failure,
    this.onRetry,
    this.compact = false,
  });

  final ApiFailure failure;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final offline = failure.isConnectionProblem;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: compact ? AppSpacing.xl : AppSpacing.huge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x26EF4444) : AppColors.errorBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              size: compact ? 22 : 28,
              color: isDark ? const Color(0xFFF87171) : AppColors.error,
            ),
          ),
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.base),
          Text(
            offline ? "You're offline" : "That didn't work",
            style: TextStyle(
              fontSize: compact ? 14.5 : 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.slate200 : AppColors.slate800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            failure.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: isDark ? AppColors.slate400 : AppColors.slate500,
            ),
          ),
          if (onRetry != null) ...[
            SizedBox(height: compact ? AppSpacing.base : AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try again'),
                ),
                // "Offline" covers a bad hostname, a blocked CORS preflight and
                // a sleeping server equally, and those need different fixes.
                // Offer the answer rather than making someone open DevTools.
                if (offline)
                  TextButton(
                    onPressed: () => context.push('/connection-check'),
                    child: const Text('Why?'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A shimmering placeholder shaped like the content that is loading.
///
/// Sized to the real thing so the layout doesn't jump when data arrives.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.height = 16,
    this.width,
    this.radius = AppRadius.sm,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.slate800 : AppColors.slate200,
      highlightColor: isDark ? AppColors.slate700 : AppColors.slate100,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: isDark ? AppColors.slate800 : AppColors.slate200,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// A stack of card-shaped skeletons, for a list that is still loading.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 3, this.itemHeight = 96});

  final int count;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          THTCard(
            child: Row(
              children: [
                const SkeletonBox(height: 44, width: 44, radius: AppRadius.md),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonBox(height: 14, width: 140),
                      const SizedBox(height: AppSpacing.sm),
                      SkeletonBox(height: 12, width: itemHeight * 2),
                      const SizedBox(height: AppSpacing.sm),
                      const SkeletonBox(height: 12, width: 90),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// A row of stat-tile skeletons matching the dashboard grid.
class SkeletonTiles extends StatelessWidget {
  const SkeletonTiles({
    super.key,
    this.count = 4,
    this.crossAxisCount = 2,
    this.childAspectRatio,
  });

  final int count;
  final int crossAxisCount;

  /// Must match the grid this is standing in for. The default suits two
  /// columns; three across the same width gives tiles too short for the
  /// contents, which overflows rather than shrinking.
  final double? childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio:
            childAspectRatio ?? (crossAxisCount >= 3 ? 0.95 : 1.45),
      ),
      itemBuilder: (_, __) => const THTCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 30, width: 30, radius: AppRadius.sm),
            Spacer(),
            SkeletonBox(height: 22, width: 64),
            SizedBox(height: AppSpacing.sm),
            SkeletonBox(height: 11, width: 88),
          ],
        ),
      ),
    );
  }
}
