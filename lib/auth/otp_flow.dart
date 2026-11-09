import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models.dart';
import '../notifications/app_notification.dart';
import '../notifications/notification_feed.dart';

/// One-time codes for sign-in and password reset.
///
/// There is no SMS gateway yet: [demoSmsCode] exposes the last code "sent" so
/// the screens can show it as a simulated text message. Swap [sendOtp]'s
/// delivery for a real provider and remove the demo getter when one exists.
mixin OtpFlow on ChangeNotifier, NotificationFeed {
  List<Account> get accounts;
  String normalizePhone(String phone);

  static const otpLength = 6;
  static const otpTtl = Duration(minutes: 5);
  static const otpResendWait = Duration(seconds: 30);
  static const otpMaxAttempts = 5;

  final Map<String, _Challenge> _otps = {};
  final _otpRng = Random.secure();

  /// The account behind a phone number or an email address.
  Account? accountForId(String id) {
    if (id.contains('@')) {
      final e = id.trim().toLowerCase();
      for (final a in accounts) {
        if (a.email?.toLowerCase() == e) return a;
      }
      return null;
    }
    final p = normalizePhone(id);
    for (final a in accounts) {
      if (normalizePhone(a.phone) == p) return a;
    }
    return null;
  }

  /// Challenges are kept per account (its phone), so a code asked for with an
  /// email can't be reused through the phone and vice versa.
  String _otpKey(String id) {
    final a = accountForId(id);
    if (a != null) return normalizePhone(a.phone);
    return id.contains('@')
        ? 'x:${id.trim().toLowerCase()}'
        : normalizePhone(id);
  }

  /// "email" or "SMS": where the code goes for [id].
  String otpChannel(String id) => id.contains('@') ? 'email' : 'SMS';

  /// Sends a fresh code to the phone or email [phone]. Returns false when a resend is requested
  /// before [otpResendWait] has passed. Unknown numbers get the same answer
  /// as known ones (no code is created) so numbers cannot be probed.
  bool sendOtp(String phone) {
    final key = _otpKey(phone);
    final now = DateTime.now();
    final old = _otps[key];
    if (old != null && now.isBefore(old.resendAt)) return false;
    if (accountForId(phone) != null) {
      final code = List.generate(otpLength, (_) => _otpRng.nextInt(10)).join();
      _otps[key] = _Challenge(code, now.add(otpTtl), now.add(otpResendWait));
    } else {
      // Same timing and throttle, but nothing to verify later.
      _otps[key] = _Challenge('', now.add(otpTtl), now.add(otpResendWait));
    }
    notifyListeners();
    return true;
  }

  /// When the next resend is allowed, or null if no code was requested.
  DateTime? otpResendAt(String phone) => _otps[_otpKey(phone)]?.resendAt;

  /// Demo only: the code that was "texted" to [phone].
  String? demoSmsCode(String phone) {
    final c = _otps[_otpKey(phone)]?.code;
    return (c == null || c.isEmpty) ? null : c;
  }

  /// Checks [code]. On success the code is used up and the account returned.
  ({Account? account, String? error}) verifyOtp(String phone, String code) {
    final key = _otpKey(phone);
    final c = _otps[key];
    if (c == null || c.code.isEmpty) {
      return (
        account: null,
        error: 'That code is not right. Check it or request a new one.',
      );
    }
    if (c.attempts >= otpMaxAttempts) {
      return (account: null, error: 'Too many attempts. Request a new code.');
    }
    if (DateTime.now().isAfter(c.expires)) {
      return (
        account: null,
        error: 'This code has expired. Request a new one.',
      );
    }
    if (code.trim() != c.code) {
      c.attempts++;
      final left = otpMaxAttempts - c.attempts;
      return (
        account: null,
        error: left > 0
            ? 'That code is not right. $left ${left == 1 ? 'try' : 'tries'} left.'
            : 'Too many attempts. Request a new code.',
      );
    }
    _otps.remove(key);
    return (account: accountForId(phone), error: null);
  }

  /// Sets a new password for the account behind [phone] (after a verified
  /// code). Returns false when there is no such account.
  bool resetPassword(String phone, String newPassword) {
    final a = accountForId(phone);
    if (a == null) return false;
    a.password = newPassword.trim();
    // Kept for the account and shown in its feed the next time it signs in.
    notify(
      AppNotification(
        title: 'Password changed',
        body: 'Your password was reset with a one-time code.',
        tone: Tone.success,
        category: NoteCategory.system,
        audience: a.role,
        driver: a.driver,
        phone: a.phone,
      ),
    );
    return true;
  }
}

class _Challenge {
  final String code;
  final DateTime expires;
  final DateTime resendAt;
  int attempts = 0;
  _Challenge(this.code, this.expires, this.resendAt);
}
