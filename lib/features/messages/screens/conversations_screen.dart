import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/models/conversation.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_avatar.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/messages/providers/messages_providers.dart';

/// The message inbox, shared by parents and teachers.
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: AsyncView<List<Conversation>>(
        value: conversations,
        onRetry: () => ref.invalidate(conversationsProvider),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SkeletonList(count: 4, itemHeight: 72),
        ),
        data: (list) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(conversationsProvider);
            await ref.read(conversationsProvider.future);
          },
          child: list.isEmpty
              ? ListView(
                  children: const [
                    EmptyState(
                      icon: Icons.forum_outlined,
                      title: 'No messages yet',
                      message: 'Conversations about a tuition appear here once '
                          'one of you starts it.',
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
                  itemBuilder: (_, i) => _ConversationRow(conversation: list[i]),
                ),
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final c = conversation;
    final name = c.otherName.trim().isEmpty ? 'Conversation' : c.otherName;

    return THTCard(
      onTap: () => context.push('/messages/${c.id}'),
      child: Row(
        children: [
          THTAvatar(name: name, size: 42),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        Fmt.titleCase(name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? AppColors.slate50 : AppColors.slate900,
                        ),
                      ),
                    ),
                    if (c.lastMessageAt != null)
                      Text(
                        Fmt.relative(c.lastMessageAt),
                        style: TextStyle(fontSize: 11.5, color: muted),
                      ),
                  ],
                ),
                if (c.jobTitle != null && c.jobTitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    'About ${c.jobTitle!.trim()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: muted),
                  ),
                ],
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.lastMessage.trim().isEmpty
                            ? 'No messages yet'
                            : c.lastMessage.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          fontStyle: c.lastMessage.trim().isEmpty
                              ? FontStyle.italic
                              : null,
                          // An unread thread reads bolder — the count alone is
                          // easy to miss on a busy list.
                          fontWeight:
                              c.hasUnread ? FontWeight.w600 : FontWeight.w400,
                          color: c.hasUnread
                              ? (isDark
                                  ? AppColors.slate100
                                  : AppColors.slate800)
                              : muted,
                        ),
                      ),
                    ),
                    if (c.hasUnread) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        constraints: const BoxConstraints(minWidth: 20),
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          c.unreadCount > 9 ? '9+' : '${c.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
