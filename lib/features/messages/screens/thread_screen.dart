import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/conversation.dart';
import 'package:tht_app/core/repositories/messages_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/theme/app_type.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/utils/api_error.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/messages/providers/messages_providers.dart';
import 'package:tht_app/features/messages/widgets/report_sheet.dart';

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
    // A block closes the thread for both sides, so the server refuses it with
    // a `blocked` flag. That is a state to explain, not an error to retry.
    final blocked = _isBlocked(thread);

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
                style: const TextStyle(fontSize: ThtType.caption),
              ),
          ],
        ),
        actions: [
          // Report and block sit on the thread itself, one tap from any
          // message. Google Play's User Generated Content policy wants them
          // where the content is, not buried in a settings page. Once the
          // chat is already closed there is nothing left to do here — the
          // undo lives in Messages → Blocked accounts.
          if (!blocked)
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (value) {
                if (value == 'report') {
                  _report(title);
                } else if (value == 'block') {
                  _block(title);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'report',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.flag_outlined),
                    title: Text('Report this person'),
                  ),
                ),
                PopupMenuItem(
                  value: 'block',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.block_rounded),
                    title: Text('Block this person'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: blocked
          ? ListView(
              children: const [
                EmptyState(
                  icon: Icons.block_rounded,
                  title: 'This chat is closed',
                  message: 'One of you blocked the other, so this conversation '
                      'can no longer be opened. If you placed the block, undo '
                      'it from Messages → Blocked accounts.',
                ),
              ],
            )
          : Column(
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

  /// True once the server has refused the thread because of a block.
  bool _isBlocked(AsyncValue<ConversationThread> thread) {
    final error = thread.error;
    return error != null && ApiFailure.from(error).flag('blocked');
  }

  Future<void> _report(String? name) async {
    final reported = await ReportSheet.show(
      context,
      conversationId: widget.conversationId,
      otherName: name ?? '',
    );
    // The report may have blocked them too, in which case the thread is now
    // closed — let the screen hear that from the server rather than guess.
    if (reported == true && mounted) {
      ref.invalidate(threadProvider(widget.conversationId));
    }
  }

  Future<void> _block(String? name) async {
    final blocked = await confirmAndBlock(
      context,
      ref,
      conversationId: widget.conversationId,
      otherName: name ?? '',
    );
    if (blocked && mounted) {
      ref.invalidate(threadProvider(widget.conversationId));
    }
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
                      fontSize: ThtType.bodyStrong,
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
                        fontSize: ThtType.micro,
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
