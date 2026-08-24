import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/repositories/genie_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/api_error.dart';

/// THT Helper — the assistant that answers questions about the platform.
///
/// The conversation lives here, not on the server: `genie/chat/` is stateless
/// and takes the whole history on every turn. That also means closing this
/// screen forgets the thread, which is the honest behaviour to present.
class GenieScreen extends ConsumerStatefulWidget {
  const GenieScreen({super.key});

  @override
  ConsumerState<GenieScreen> createState() => _GenieScreenState();
}

class _GenieScreenState extends ConsumerState<GenieScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _history = <GenieTurn>[];

  bool _thinking = false;
  String? _error;

  /// Openers worth offering, because a blank chat box is a hard thing to start.
  static const _starters = [
    'How do credits work?',
    'How do I get more tuitions?',
    'When do I get paid?',
    'How does verification work?',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('THT Helper'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              onPressed: _thinking
                  ? null
                  : () => setState(() {
                        _history.clear();
                        _error = null;
                      }),
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Start over',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _history.isEmpty ? _intro() : _thread(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                _error!,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Tone.critical
                      .foreground(Theme.of(context).brightness),
                ),
              ),
            ),
          _composer(),
        ],
      ),
    );
  }

  Widget _intro() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 30,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        Text(
          'Ask me anything about THT',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.slate50 : AppColors.slate900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Credits, verification, payments, finding tuitions — whatever you '
          'are stuck on.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.5, color: muted),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final starter in _starters)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: THTCard(
              onTap: _thinking ? null : () => _send(starter),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      starter,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.north_east_rounded, size: 16, color: muted),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _thread() => ListView.builder(
        controller: _scroll,
        reverse: true,
        padding: const EdgeInsets.all(AppSpacing.lg),
        // One extra row at the top of the reversed list for the typing dots.
        itemCount: _history.length + (_thinking ? 1 : 0),
        itemBuilder: (_, i) {
          if (_thinking && i == 0) return const _Typing();
          final turn = _history[
              _history.length - 1 - (i - (_thinking ? 1 : 0))];
          return _Bubble(turn: turn);
        },
      );

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
                enabled: !_thinking,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (v) => _send(v),
                decoration: const InputDecoration(
                  hintText: 'Ask a question',
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
              onPressed: _thinking ? null : () => _send(_input.text),
              icon: _thinking
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

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _thinking) return;

    setState(() {
      _history.add(GenieTurn(role: 'user', content: text));
      _input.clear();
      _thinking = true;
      _error = null;
    });

    try {
      // The user's own number lets the assistant answer about their leads
      // rather than in generalities. Absent when signed out, which the
      // endpoint allows.
      final phone = ref.read(currentUserProvider).valueOrNull?.phone;
      final reply = await ref
          .read(genieRepositoryProvider)
          .chat(List.of(_history), phone: phone);
      if (!mounted) return;
      setState(() => _history.add(
            GenieTurn(role: 'assistant', content: reply),
          ));
    } catch (e) {
      if (!mounted) return;
      final failure = ApiFailure.from(e);
      setState(() {
        // The question stays in the thread so it can be retried by sending
        // again, rather than vanishing with the error.
        _error = failure.statusCode == 429
            ? 'You have asked a lot in a short time. Give it a minute.'
            : failure.message;
      });
    } finally {
      if (mounted) setState(() => _thinking = false);
    }
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.turn});

  final GenieTurn turn;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mine = turn.isMine;
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
                maxWidth: MediaQuery.of(context).size.width * 0.8,
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
              child: SelectableText(
                turn.content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: mine
                      ? Colors.white
                      : (isDark ? AppColors.slate100 : AppColors.slate800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three dots while the assistant composes a reply.
class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate800 : AppColors.slate100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg),
                topRight: Radius.circular(AppRadius.lg),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.slate500 : AppColors.slate400,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
