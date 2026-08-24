import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/conversation.dart';
import 'package:tht_app/core/repositories/messages_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/messages/providers/messages_providers.dart';

/// One conversation, and the box to reply in.
///
/// Opening this marks the other party's messages as read server-side, which is
/// why nothing else in the app watches [threadProvider].
class ThreadScreen extends ConsumerStatefulWidget {
  const ThreadScreen({super.key, required this.conversationId});

  final int conversationId;

  @override
  ConsumerState<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends ConsumerState<ThreadScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thread = ref.watch(threadProvider(widget.conversationId));
    final title = thread.valueOrNull?.otherName;
    final about = thread.valueOrNull?.jobTitle;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          // The app bar gives its title a bounded height, and a Column defaults
          // to filling it — which overflows the moment the subtitle appears.
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title == null || title.trim().isEmpty
                  ? 'Conversation'
                  : Fmt.titleCase(title),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (about != null && about.trim().isNotEmpty)
              Text(
                'About ${about.trim()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: AsyncView<ConversationThread>(
              value: thread,
              onRetry: () =>
                  ref.invalidate(threadProvider(widget.conversationId)),
              // In a ListView, not a Padding: `SkeletonList` is a plain Column
              // and this slot is height-bounded by the composer below it, so a
              // placeholder taller than the gap overflows rather than scrolls.
              loading: const SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: SkeletonList(count: 5, itemHeight: 54),
              ),
              data: (t) => t.messages.isEmpty
                  ? ListView(
                      children: const [
                        EmptyState(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Nothing said yet',
                          message: 'Send the first message below.',
                          compact: true,
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scroll,
                      // Newest at the bottom, which is where a chat is read
                      // from — so the list is reversed and the data with it.
                      reverse: true,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: t.messages.length,
                      itemBuilder: (_, i) => _Bubble(
                        message: t.messages[t.messages.length - 1 - i],
                      ),
                    ),
            ),
          ),
          _composer(),
        ],
      ),
    );
  }

  Widget _composer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.slate200,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Write a message',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              tooltip: 'Send',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    // The server rejects an empty body, and there is nothing to say anyway.
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await ref
          .read(messagesRepositoryProvider)
          .send(widget.conversationId, text);
      if (!mounted) return;
      _input.clear();
      ref
        ..invalidate(threadProvider(widget.conversationId))
        ..invalidate(conversationsProvider);
    } catch (e) {
      if (mounted) context.showFailure(e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mine = message.isMine;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: mine
                    ? primary
                    : (isDark ? AppColors.slate800 : AppColors.slate100),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.lg),
                  topRight: const Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(mine ? AppRadius.lg : 4),
                  bottomRight: Radius.circular(mine ? 4 : AppRadius.lg),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: mine
                          ? Colors.white
                          : (isDark
                              ? AppColors.slate100
                              : AppColors.slate800),
                    ),
                  ),
                  if (message.createdAt != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      Fmt.time(message.createdAt),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: mine
                            ? Colors.white70
                            : (isDark
                                ? AppColors.slate400
                                : AppColors.slate500),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
