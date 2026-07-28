import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tht_app/core/network/api_client.dart';
import 'package:tht_app/core/network/api_config.dart';
import 'package:tht_app/core/network/token_storage.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';

/// One endpoint's result.
class _Probe {
  _Probe(this.label, this.path, {this.needsAuth = true});

  final String label;
  final String path;
  final bool needsAuth;

  int? status;
  String? errorType;
  String? message;
  int millis = 0;
  bool done = false;

  bool get ok => status != null && status! < 400;

  /// A failure with no status at all never reached the app — the browser or the
  /// network refused it. A status means the server answered, even if unhappily.
  bool get neverArrived => done && status == null;

  Tone get tone {
    if (!done) return Tone.neutral;
    if (ok) return Tone.success;
    if (neverArrived) return Tone.critical;
    return Tone.warning;
  }

  String get summary {
    if (!done) return '…';
    if (status != null) return '$status';
    return errorType ?? 'failed';
  }
}

/// What the app is talking to, and what happens when it tries — endpoint by
/// endpoint, using the real signed-in token.
///
/// "You're offline" flattens a wrong hostname, a blocked CORS preflight, a
/// sleeping server, a 401 and a 500 into one sentence. Each needs a different
/// fix. This names the actual one, per endpoint, so a partial failure is
/// visible as a partial failure.
class ConnectionCheckScreen extends StatefulWidget {
  const ConnectionCheckScreen({super.key});

  @override
  State<ConnectionCheckScreen> createState() => _ConnectionCheckScreenState();
}

class _ConnectionCheckScreenState extends State<ConnectionCheckScreen> {
  late List<_Probe> _probes;
  bool _running = false;
  bool _hasToken = false;
  String? _role;

  @override
  void initState() {
    super.initState();
    _probes = _buildProbes();
    _run();
  }

  List<_Probe> _buildProbes() => [
        _Probe('Server health', '/api/health/', needsAuth: false),
        _Probe('Public teacher search', '/api/users/tutors/search/',
            needsAuth: false),
        _Probe('Your account', '/api/users/me/'),
        _Probe('Your wallet', '/api/wallet/me/'),
        _Probe('Notification count', '/api/jobs/notifications/unread-count/'),
        _Probe('Parent dashboard', '/api/jobs/stats/parent/'),
        _Probe('Teacher dashboard', '/api/users/dashboard/stats/'),
        _Probe('Teacher schedule', '/api/jobs/tutor/today-schedule/'),
        _Probe('Open jobs', '/api/jobs/search/', needsAuth: false),
      ];

  Future<void> _run() async {
    final token = await TokenStorage.getAccessToken();
    final role = await TokenStorage.getRole();
    if (!mounted) return;

    setState(() {
      _running = true;
      _hasToken = token != null && token.isNotEmpty;
      _role = role;
      _probes = _buildProbes();
    });

    for (final probe in _probes) {
      if (!mounted) return;
      await _hit(probe);
      if (mounted) setState(() {});
    }

    if (mounted) setState(() => _running = false);
  }

  Future<void> _hit(_Probe probe) async {
    // The real client, so this exercises the same auth header and interceptors
    // the app uses. validateStatus lets a 401 or 404 be reported as itself
    // rather than thrown, which is the distinction that matters here.
    final started = DateTime.now();
    try {
      final res = await ApiClient.instance.get(
        probe.path,
        options: Options(validateStatus: (_) => true),
      );
      probe.status = res.statusCode;
    } on DioException catch (e) {
      probe.status = e.response?.statusCode;
      probe.errorType = e.type.name;
      probe.message = e.message;
    } catch (e) {
      probe.message = e.toString();
    } finally {
      probe.millis = DateTime.now().difference(started).inMilliseconds;
      probe.done = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final finished = _probes.where((p) => p.done).toList();
    final arrived = finished.where((p) => !p.neverArrived).length;

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
                      kIsWeb ? 'In a browser' : 'Native build',
                      dense: true,
                    ),
                    Pill(
                      _hasToken ? 'Signed in' : 'Not signed in',
                      tone: _hasToken ? Tone.success : Tone.warning,
                      dense: true,
                    ),
                    if (_role != null) Pill('Role: $_role', dense: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(
            'Endpoints',
            subtitle: finished.isEmpty
                ? null
                : '$arrived of ${finished.length} reached the server',
          ),
          const SizedBox(height: AppSpacing.md),
          THTCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < _probes.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color:
                          isDark ? AppColors.darkBorder : AppColors.slate200,
                    ),
                  _ProbeRow(probe: _probes[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!_running && finished.isNotEmpty) _Verdict(probes: _probes),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _copy,
            icon: const Icon(Icons.copy_rounded, size: 17),
            label: const Text('Copy all details'),
          ),
        ],
      ),
    );
  }

  Future<void> _copy() async {
    final buffer = StringBuffer()
      ..writeln('URL: ${ApiConfig.baseUrl}')
      ..writeln('Platform: ${kIsWeb ? "web" : defaultTargetPlatform.name}')
      ..writeln('Signed in: $_hasToken   Role: ${_role ?? "unknown"}')
      ..writeln('');
    for (final p in _probes) {
      buffer.writeln(
        '${p.label.padRight(24)} ${p.path.padRight(42)} '
        '${p.status ?? p.errorType ?? "failed"}  ${p.millis}ms',
      );
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) context.showMessage('Details copied.');
  }
}

class _ProbeRow extends StatelessWidget {
  const _ProbeRow({required this.probe});

  final _Probe probe;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: probe.done
                ? Icon(
                    probe.ok
                        ? Icons.check_circle_rounded
                        : probe.neverArrived
                            ? Icons.cloud_off_rounded
                            : Icons.error_outline_rounded,
                    size: 17,
                    color: probe.tone.foreground(brightness),
                  )
                : const CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  probe.label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  probe.path,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.slate400 : AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (probe.done)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Pill(probe.summary, tone: probe.tone, dense: true),
                const SizedBox(height: 2),
                Text(
                  '${probe.millis} ms',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isDark ? AppColors.slate500 : AppColors.slate400,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Reads the whole table and says what it means.
class _Verdict extends StatelessWidget {
  const _Verdict({required this.probes});

  final List<_Probe> probes;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final done = probes.where((p) => p.done).toList();
    final neverArrived = done.where((p) => p.neverArrived).toList();
    final unauthorized = done.where((p) => p.status == 401).toList();
    final forbidden = done.where((p) => p.status == 403).toList();
    final missing = done.where((p) => p.status == 404).toList();
    final serverErrors = done.where((p) => (p.status ?? 0) >= 500).toList();

    final (tone, title, body) = _read(
      total: done.length,
      neverArrived: neverArrived,
      unauthorized: unauthorized,
      forbidden: forbidden,
      missing: missing,
      serverErrors: serverErrors,
    );

    return THTCard(
      background: tone.background(brightness),
      borderColor: tone.border(brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: tone.foreground(brightness),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: tone.foreground(brightness).withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }

  (Tone, String, String) _read({
    required int total,
    required List<_Probe> neverArrived,
    required List<_Probe> unauthorized,
    required List<_Probe> forbidden,
    required List<_Probe> missing,
    required List<_Probe> serverErrors,
  }) {
    if (neverArrived.length == total) {
      return (
        Tone.critical,
        'Nothing reached the server',
        kIsWeb
            ? 'Every request was refused before it arrived. In a browser that '
                'means this origin is not in CORS_ALLOWED_ORIGINS, or the '
                'service is asleep. Wait a minute and run this again — if it '
                'stays the same, it is CORS.'
            : 'Every request failed at the network layer. Check the address '
                'and this device\'s connection.',
      );
    }

    if (neverArrived.isNotEmpty) {
      return (
        Tone.warning,
        '${neverArrived.length} of $total never reached the server',
        'Some endpoints answered and some did not, which rules out both CORS '
            'and a wrong address — those would fail everything equally. The '
            'ones that failed are likely slow enough to time out, or they are '
            'erroring in a way that strips the CORS headers: '
            '${neverArrived.map((p) => p.path).join(", ")}',
      );
    }

    if (serverErrors.isNotEmpty) {
      return (
        Tone.critical,
        'The server is erroring on ${serverErrors.length} endpoint'
            '${serverErrors.length == 1 ? "" : "s"}',
        'These reached Django and it raised an exception: '
            '${serverErrors.map((p) => p.path).join(", ")}. The Render logs '
            'will have the traceback.',
      );
    }

    if (unauthorized.isNotEmpty) {
      return (
        Tone.warning,
        'Signed in, but ${unauthorized.length} endpoint'
            '${unauthorized.length == 1 ? "" : "s"} rejected the token',
        'The connection is fine. A 401 means the access token expired or was '
            'not sent. Signing out and back in usually clears it.',
      );
    }

    if (forbidden.isNotEmpty || missing.isNotEmpty) {
      final paths = [...forbidden, ...missing].map((p) => p.path).join(', ');
      return (
        Tone.success,
        'The connection is working',
        'Everything reached the server. Some endpoints returned 403 or 404, '
            'which is expected — they belong to roles other than yours, or to '
            'data you do not have yet: $paths. If a screen still looks empty, '
            'it is empty, not broken.',
      );
    }

    return (
      Tone.success,
      'Everything is working',
      'All $total endpoints answered normally. Any empty screen is genuinely '
          'empty rather than failing.',
    );
  }
}
