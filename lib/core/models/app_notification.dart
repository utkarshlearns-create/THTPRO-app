import 'package:flutter/material.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/json_x.dart';

/// An in-app notification from `GET /api/jobs/notifications/`.
class AppNotification {
  const AppNotification({
    required this.id,
    this.title = '',
    this.message = '',
    this.type = 'SYSTEM',
    this.relatedJobId,
    this.isRead = false,
    this.createdAt,
  });

  final int id;
  final String title;
  final String message;

  /// One of the backend's `NOTIFICATION_TYPE_CHOICES` — `JOB_APPROVED`,
  /// `KYC_REJECTED`, `CREDITS_EXPIRING_SOON`, `SYSTEM`, and so on.
  final String type;

  /// Set when the notification is about a specific requirement, so tapping it
  /// can open that job rather than dead-ending on the list.
  final int? relatedJobId;

  final bool isRead;
  final DateTime? createdAt;

  /// What tapping this should open, or null when there is nowhere to go.
  String? get route => relatedJobId == null ? null : '/jobs/$relatedJobId';

  /// The colour this should carry — good news, a warning, or plain information.
  Tone get tone {
    final t = type.toUpperCase();
    if (t.endsWith('_APPROVED') || t == 'JOB_ASSIGNED') return Tone.success;
    if (t.endsWith('_REJECTED') || t == 'CREDITS_EXPIRED') return Tone.critical;
    if (t.endsWith('_RESUBMIT') ||
        t.endsWith('_NEEDED') ||
        t == 'CREDITS_EXPIRING_SOON' ||
        t == 'TEAM_WARNING_ISSUED') {
      return Tone.warning;
    }
    return Tone.info;
  }

  /// An icon matched to what the notification is about, so a glance down the
  /// list separates money from paperwork from a job update.
  IconData get icon {
    final t = type.toUpperCase();
    if (t.startsWith('KYC')) return Icons.badge_outlined;
    if (t.startsWith('CREDITS')) return Icons.account_balance_wallet_outlined;
    if (t.startsWith('JOB')) return Icons.work_outline_rounded;
    if (t.startsWith('TEAM')) return Icons.groups_outlined;
    return Icons.notifications_none_rounded;
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: asInt(json, 'id'),
        title: asString(json, 'title'),
        message: asString(json, 'message'),
        type: asString(json, 'notification_type', fallback: 'SYSTEM'),
        relatedJobId: asIntOrNull(json, 'related_job'),
        isRead: asBool(json, 'is_read'),
        createdAt: asDateOrNull(json, 'created_at'),
      );
}
