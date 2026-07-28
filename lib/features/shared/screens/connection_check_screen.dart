import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tht_app/core/network/api_config.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';

/// What the app is talking to, and what happened when it tried.
///
/// "You're offline" is the right thing to tell a user, but it flattens several
/// very different causes — a hostname that does not resolve, a CORS preflight
/// the browser blocked, a sleeping server, a 500. Each needs a different fix and
/// none of them are visible from the message. This screen names the actual one.
class ConnectionCheckScreen extends StatefulWidget {
  const ConnectionCheckScreen({super.key});

  @override
  State<ConnectionCheckScreen> createState() => _ConnectionCheckScreenState();
}

class _ConnectionCheckScreenState extends State<ConnectionCheckScreen> {
  _Result? _result;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _running = true;
      _result = null;
    });

    // A bare Dio: no auth header, no refresh interceptor. This is a question
    // about reachability, and a 401 from the real client would muddy it.
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      validateStatus: (_) => true,
    ));

    final started = DateTime.now();
    try {
      final res = await dio.get('/api/health/');
      final ms = DateTime.now().difference(started).inMilliseconds;
      setState(() {
        _running = false;
        _result = _Result(
          reachable: true,
          statusCode: res.statusCode,
          millis: ms,
        );
      });
    } on DioException catch (e) {
      final ms = DateTime.now().difference(started).inMilliseconds;
      setState(() {
        _running = false;
        _result = _Result(
          reachable: false,
          errorType: e.type,
          message: e.message ?? e.toString(),
          millis: ms,
        );
      });
    } catch (e) {
      setState(() {
        _running = false;
        _result = _Result(reachable: false, message: e.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection check'),
        actions: [
          IconButton(
            onPressed: _running ? null : _run,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Run again',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SectionHeader('What the app is calling'),
          const SizedBox(height: AppSpacing.md),
          THTCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  ApiConfig.baseUrl,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    Pill(
                      ApiConfig.isProduction ? 'Live backend' : 'Custom URL',
                      tone: ApiConfig.isProduction ? Tone.info : Tone.warning,
                      dense: true,
                    ),
                    Pill(
                      kIsWeb ? 'Running in a browser' : 'Running natively',
                      dense: true,
                    ),
                  ],
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'In a browser the server must allow this page\'s origin in '
                    'CORS_ALLOWED_ORIGINS. On Android and iOS that rule does '
                    'not exist, so a failure here does not always mean a '
                    'failure on a phone.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: isDark ? AppColors.slate400 : AppColors.slate500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader('Result'),
          const SizedBox(height: AppSpacing.md),
          if (_running)
            const THTCard(
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Calling /api/health/… a sleeping free-tier server can '
                      'take up to a minute to wake.',
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            )
          else if (_result != null)
            _ResultCard(result: _result!, onCopy: _copy),
        ],
      ),
    );
  }

  Future<void> _copy() async {
    final r = _result;
    if (r == null) return;
    await Clipboard.setData(ClipboardData(
      text: 'URL: ${ApiConfig.baseUrl}/api/health/\n'
          'Platform: ${kIsWeb ? "web" : defaultTargetPlatform.name}\n'
          'Reachable: ${r.reachable}\n'
          'Status: ${r.statusCode ?? "no response"}\n'
          'Error: ${r.errorType?.name ?? "none"}\n'
          'Message: ${r.message ?? "none"}\n'
          'Took: ${r.millis}ms',
    ));
    if (mounted) context.showMessage('Details copied.');
  }
}

class _Result {
  const _Result({
    required this.reachable,
    this.statusCode,
    this.errorType,
    this.message,
    this.millis = 0,
  });

  final bool reachable;
  final int? statusCode;
  final DioExceptionType? errorType;
  final String? message;
  final int millis;

  /// The plain-language reading of what happened, and what to do about it.
  (Tone, String, String) get verdict {
    if (reachable && (statusCode ?? 0) < 400) {
      return (
        Tone.success,
        'The backend is reachable',
        'The server answered normally. If a screen still says you are offline, '
            'the problem is with that specific request rather than the '
            'connection — check the console for the failing URL.',
      );
    }
    if (reachable) {
      return (
        Tone.warning,
        'Reached the server, but it returned $statusCode',
        'The address is correct and the network is fine. A $statusCode here '
            'usually means the health endpoint moved or the service is '
            'misconfigured.',
      );
    }

    switch (errorType) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return (
          Tone.warning,
          'The server did not answer in time',
          'On a free Render plan the service sleeps after inactivity and takes '
              'roughly a minute to wake. Run the check again before assuming '
              'anything is broken.',
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return (
          Tone.critical,
          'Could not reach the server at all',
          kIsWeb
              ? 'In a browser this is almost always one of two things: the '
                  'origin is not in CORS_ALLOWED_ORIGINS on the server, or the '
                  'hostname is wrong. Try the same build on a phone — if it '
                  'works there, it is CORS.'
              : 'Either the hostname is wrong, the service is down, or this '
                  'device has no internet.',
        );
      case DioExceptionType.badCertificate:
        return (
          Tone.critical,
          'The security certificate was rejected',
          'The address is reachable but its HTTPS certificate did not '
              'validate.',
        );
      default:
        return (
          Tone.critical,
          'The request failed',
          message ?? 'No further detail was reported.',
        );
    }
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.onCopy});

  final _Result result;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final (tone, title, explanation) = result.verdict;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        THTCard(
          background: tone.background(brightness),
          borderColor: tone.border(brightness),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    result.reachable
                        ? Icons.check_circle_outline_rounded
                        : Icons.error_outline_rounded,
                    color: tone.foreground(brightness),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: tone.foreground(brightness),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                explanation,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.55,
                  color: tone.foreground(brightness).withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        THTCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _Row(
                label: 'Status',
                value: result.statusCode?.toString() ?? 'No response',
              ),
              const Divider(height: 1),
              _Row(
                label: 'Failure type',
                value: result.errorType?.name ?? 'none',
              ),
              const Divider(height: 1),
              _Row(label: 'Took', value: '${result.millis} ms'),
              if (result.message != null) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Message',
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              isDark ? AppColors.slate400 : AppColors.slate500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        result.message!,
                        style: const TextStyle(fontSize: 12.5, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: onCopy,
          icon: const Icon(Icons.copy_rounded, size: 17),
          label: const Text('Copy details'),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.slate400 : AppColors.slate500,
              ),
            ),
          ),
          SelectableText(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
