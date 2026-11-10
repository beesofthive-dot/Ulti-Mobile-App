import 'package:flutter/foundation.dart';

import 'app_notification.dart';

/// Notification store and the one on-screen banner. Mixed into AppState,
/// which decides who the current viewer is.
mixin NotificationFeed on ChangeNotifier {
  final List<AppNotification> notifications = [];

  /// The banner currently shown at the top of the screen, if any.
  AppNotification? banner;

  /// Whether [n] is addressed to whoever is signed in right now.
  bool visibleToViewer(AppNotification n);

  List<AppNotification> get myNotifications =>
      notifications.where(visibleToViewer).toList()
        ..sort((a, b) => b.at.compareTo(a.at));

  int get unreadCount => myNotifications.where((n) => !n.read).length;

  /// Stores [n] and shows it as a banner when it is for the current viewer.
  void notify(AppNotification n) {
    if (n.persist) notifications.add(n);
    if (visibleToViewer(n)) banner = n;
    notifyListeners();
  }

  /// A short message that is not kept in the notification centre.
  void flash(String message, {Tone tone = Tone.info}) {
    banner = AppNotification(title: message, tone: tone, persist: false);
    notifyListeners();
  }

  void dismissBanner() {
    if (banner == null) return;
    banner = null;
    notifyListeners();
  }

  /// Removes one notification from the centre (swipe to dismiss).
  void removeNotification(AppNotification n) {
    notifications.remove(n);
    if (banner == n) banner = null;
    notifyListeners();
  }

  /// Puts a dismissed notification back (undo).
  void restoreNotification(AppNotification n) {
    if (notifications.contains(n)) return;
    notifications.add(n);
    notifyListeners();
  }

  /// Clears everything the signed-in user can see.
  void clearMyNotifications() {
    notifications.removeWhere(visibleToViewer);
    banner = null;
    notifyListeners();
  }

  void markAllRead() {
    for (final n in myNotifications) {
      n.read = true;
    }
    notifyListeners();
  }
}
