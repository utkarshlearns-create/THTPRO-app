import 'package:flutter/material.dart';
import 'package:tht_app/core/theme/app_colors.dart';

/// A board's mark, or its initials when we have no artwork for it.
///
/// The backend seeds ten boards but only six have logos, and an institute admin
/// can add more at any time — so the fallback is the normal case, not the edge.
///
/// Logos always sit on white. Every one of these marks was drawn for print on
/// paper: several are dark-on-transparent and vanish against a dark surface.
class BoardLogo extends StatelessWidget {
  const BoardLogo({
    super.key,
    required this.board,
    this.size = 44,
  });

  /// The board's short name where there is one (`CBSE`, `UP Board`), otherwise
  /// its full name. Matching is case- and space-insensitive.
  final String board;

  final double size;

  /// Short name → asset. Keys are lowercased and stripped of spaces,
  /// underscores and hyphens before lookup.
  static const Map<String, String> _assets = {
    'cbse': 'assets/images/boards/cbse.webp',
    'icse': 'assets/images/boards/icse.jpg',
    // ISC is the CISCE's class 11–12 examination — the same body behind ICSE,
    // and the same mark.
    'isc': 'assets/images/boards/icse.jpg',
    'cisce': 'assets/images/boards/icse.jpg',
    'ib': 'assets/images/boards/ib.webp',
    'internationalbaccalaureate': 'assets/images/boards/ib.webp',
    'igcse': 'assets/images/boards/igcse.png',
    'cambridgeigcse': 'assets/images/boards/igcse.png',
    'nios': 'assets/images/boards/nios.webp',
    'upboard': 'assets/images/boards/up_board.webp',
    'uttarpradeshboard': 'assets/images/boards/up_board.webp',
  };

  static String? assetFor(String board) =>
      _assets[board.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '')];

  /// `UP Board` → `UP`, `WBBSE` → `WB`, `Karnataka State Board` → `KS`.
  static String initialsFor(String board) {
    final cleaned = board.trim();
    if (cleaned.isEmpty) return '?';
    final words =
        cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      return (words[0][0] + words[1][0]).toUpperCase();
    }
    return cleaned.substring(0, cleaned.length < 2 ? 1 : 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final asset = assetFor(board);
    final radius = BorderRadius.circular(size * 0.22);

    if (asset == null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppColors.slate800 : AppColors.slate100,
          borderRadius: radius,
        ),
        child: Text(
          initialsFor(board),
          style: TextStyle(
            fontSize: size * 0.3,
            fontWeight: FontWeight.w800,
            height: 1,
            color: isDark ? AppColors.slate300 : AppColors.slate600,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: AppColors.slate200),
      ),
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        // A missing file falls back to initials rather than a broken-image box.
        errorBuilder: (_, __, ___) => Center(
          child: Text(
            initialsFor(board),
            style: TextStyle(
              fontSize: size * 0.28,
              fontWeight: FontWeight.w800,
              color: AppColors.slate600,
            ),
          ),
        ),
      ),
    );
  }
}
