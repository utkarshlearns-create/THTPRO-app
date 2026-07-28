import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/utils/api_error.dart';

/// Renders an [AsyncValue] as loading, error or data — the same way every time.
///
/// Screens pass the skeleton that matches their own layout, so the placeholder
/// is the shape of the content rather than a spinner in the middle of nowhere.
/// On refresh the previous data stays on screen instead of flashing back to a
/// skeleton, which is what makes pull-to-refresh feel like a refresh.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.data,
    required this.onRetry,
    this.loading,
    this.compactError = false,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;

  /// Re-runs the request. Wire this to `ref.invalidate(theProvider)`.
  final VoidCallback onRetry;

  /// The skeleton to show on first load.
  final Widget? loading;

  final bool compactError;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      data: data,
      loading: () => loading ?? const SkeletonList(),
      error: (e, _) => ErrorView(
        failure: ApiFailure.from(e),
        onRetry: onRetry,
        compact: compactError,
      ),
    );
  }
}

/// Shows a message on the current screen — used for the result of an action
/// (unlocking a contact, marking attendance) rather than for page state.
extension Feedback on BuildContext {
  void showMessage(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Reports a failed action in the user's language, never a raw exception.
  void showFailure(Object error) {
    final failure = ApiFailure.from(error);
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: Theme.of(this).colorScheme.error,
        ),
      );
  }
}
