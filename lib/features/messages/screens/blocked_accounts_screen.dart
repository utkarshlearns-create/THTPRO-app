import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/conversation.dart';
import 'package:tht_app/core/repositories/messages_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/theme/app_type.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/entrance.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_avatar.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/messages/providers/messages_providers.dart';

/// Everyone this user has blocked, and the way back.
///
/// A block has to be undoable from inside the app, not only placeable — so
/// this screen exists for the undo as much as for the list.
class BlockedAccountsScreen extends ConsumerWidget {
  const BlockedAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(blockedAccountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Blocked accounts')),
      body: AsyncView<List<BlockedAccount>>(
        value: blocked,
        onRetry: () => ref.invalidate(blockedAccountsProvider),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SkeletonList(count: 3, itemHeight: 64),
        ),
        data: (list) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(blockedAccountsProvider);
            await ref.read(blockedAccountsProvider.future);
          },
          child: list.isEmpty
              ? ListView(
                  children: const [
                    EmptyState(
                      icon: Icons.block_rounded,
                      title: 'Nobody is blocked',
                      message: 'If a chat ever goes wrong, you can block or '
                          'report the other person from inside that '
                          'conversation.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.base,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) => ThtEntrance(
                    index: i,
                    child: _BlockedRow(account: list[i]),
                  ),
                ),
        ),
      ),
    );
  }
}

class _BlockedRow extends ConsumerStatefulWidget {
  const _BlockedRow({required this.account});

  final BlockedAccount account;

  @override
  ConsumerState<_BlockedRow> createState() => _BlockedRowState();
}

class _BlockedRowState extends ConsumerState<_BlockedRow> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final a = widget.account;
    final name = a.name.trim().isEmpty ? 'User' : a.name.trim();

    // The second line says when, and what they said it was about — enough to
    // remember a block placed weeks ago before undoing it.
    final sub = <String>[
      if (a.role != null && a.role!.trim().isNotEmpty) Fmt.titleCase(a.role!),
      if (a.reason.trim().isNotEmpty) a.reason.trim(),
      if (a.blockedAt != null) 'Blocked ${Fmt.relative(a.blockedAt)}',
    ].join(' · ');

    return THTCard(
      child: Row(
        children: [
          THTAvatar(name: name, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Fmt.titleCase(name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: ThtType.bodyStrong,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.slate50 : AppColors.slate900,
                  ),
                ),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: ThtType.caption,
                      height: 1.35,
                      color: muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _working
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : TextButton(
                  onPressed: _unblock,
                  child: const Text('Unblock'),
                ),
        ],
      ),
    );
  }

  Future<void> _unblock() async {
    final name = widget.account.name.trim().isEmpty
        ? 'this person'
        : widget.account.name.trim();

    setState(() => _working = true);
    try {
      await ref
          .read(messagesRepositoryProvider)
          .unblockUser(widget.account.userId);
      if (!mounted) return;
      ref
        ..invalidate(blockedAccountsProvider)
        ..invalidate(conversationsProvider)
        ..invalidate(unreadMessagesProvider);
      context.showMessage('$name is unblocked');
    } catch (e) {
      if (mounted) context.showFailure(e);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }
}
