import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tht_app/core/network/api_config.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';

/// A person's picture, or their initials when there isn't one.
///
/// Every avatar in the app comes through here so the fallback is identical
/// everywhere. That matters more than it sounds: most teachers have no photo
/// uploaded, so the initials state is the common case, not the exception.
class THTAvatar extends StatelessWidget {
  const THTAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 48,
    this.verified = false,
    this.onTap,
    this.squared = false,
  });

  final String name;

  /// Absolute URL. Blank, null and broken all fall back to initials.
  final String? imageUrl;

  final double size;

  /// Draws a verification tick over the bottom-right corner.
  final bool verified;

  final VoidCallback? onTap;

  /// Rounded-rectangle instead of a circle — for institutes, which read as
  /// organisations rather than people.
  final bool squared;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final radius = squared
        ? BorderRadius.circular(size * 0.28)
        : BorderRadius.circular(size);

    Widget initials() => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryOrangeLight,
            borderRadius: radius,
          ),
          child: Text(
            Fmt.initials(name),
            style: TextStyle(
              fontSize: size * 0.36,
              fontWeight: FontWeight.w800,
              height: 1,
              color: AppColors.primaryOrangeDark,
            ),
          ),
        );

    // Resolve first: Django returns a relative /media/... path whenever media
    // is served locally rather than from Cloudinary, and that loads nothing.
    final url = ApiConfig.absoluteUrl(imageUrl) ?? '';
    Widget avatar = url.isEmpty
        ? initials()
        : ClipRRect(
            borderRadius: radius,
            child: CachedNetworkImage(
              imageUrl: url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              // Show the initials while loading and if it fails, so the slot
              // never collapses or flashes an empty box.
              placeholder: (_, __) => initials(),
              errorWidget: (_, __, ___) => initials(),
            ),
          );

    if (verified) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_rounded,
                size: size * 0.3,
                color: Tone.info.foreground(brightness),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap == null) return avatar;

    return Semantics(
      button: true,
      label: '$name, open profile',
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: avatar,
      ),
    );
  }
}
