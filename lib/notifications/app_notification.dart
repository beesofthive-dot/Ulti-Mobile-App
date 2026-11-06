import '../models.dart';

enum Tone { info, warning, danger, success, neutral }

enum NoteCategory { money, session, system }

/// One notification. Persisted ones appear in the notification centre;
/// transient ones (see [NotificationFeed.flash]) only show as a banner.
class AppNotification {
  static int _next = 0;

  final int id = _next++;
  final String title;
  final String body;
  final Tone tone;
  final NoteCategory category;
  final DateTime at;

  /// Who should see it. Null audience means whoever is on screen.
  final Role? audience;
  final Driver? driver;
  final String? phone;
  final bool persist;
  bool read;

  AppNotification({
    required this.title,
    this.body = '',
    this.tone = Tone.info,
    this.category = NoteCategory.system,
    this.audience,
    this.driver,
    this.phone,
    this.persist = true,
    this.read = false,
    DateTime? at,
  }) : at = at ?? DateTime.now();

  bool get isMoney => category == NoteCategory.money;
}
