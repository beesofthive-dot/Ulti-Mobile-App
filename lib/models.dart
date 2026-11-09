import 'package:flutter/material.dart';

import 'theme.dart';

enum Role { attendant, driver }

enum SessionStatus {
  draft,
  active,
  awaitingReadings,
  awaitingPayment,
  paid,
  exception,
  voided,
}

enum PaymentStatus { initiated, pending, confirmed, failed, reversed }

enum BranchStatus { open, busy, offline, temporarilyClosed, unknown }

enum CardStatus { unlinked, active, blocked, replaced, expired }

enum ShiftStatus { notStarted, active, submitted, reconciled, exception }

enum PayMethod { wallet, card, momo, cash }

/// Label, colour, plain-language explanation and next action for a status.
/// Spec §9: every status shows a label, timestamp and next available action.
class StatusInfo {
  final String label;
  final Color color;
  final String explanation;
  final String nextAction;
  const StatusInfo(this.label, this.color, this.explanation, this.nextAction);
}

StatusInfo sessionInfo(SessionStatus s) => switch (s) {
  SessionStatus.draft => StatusInfo(
    'Draft',
    UC.muted,
    'Saved on this device, not yet started.',
    'Start charge',
  ),
  SessionStatus.active => const StatusInfo(
    'Active',
    UC.info,
    'Software timer running. Charger is operated separately.',
    'Stop charge',
  ),
  SessionStatus.awaitingReadings => const StatusInfo(
    'Awaiting evidence',
    UC.warning,
    'Machine readings not yet confirmed.',
    'Enter machine readings',
  ),
  SessionStatus.awaitingPayment => const StatusInfo(
    'Awaiting payment',
    UC.orange,
    'Readings confirmed. Payment not yet received.',
    'Collect payment',
  ),
  SessionStatus.paid => const StatusInfo(
    'Paid',
    UC.success,
    'Payment confirmed and receipt generated.',
    'View receipt',
  ),
  SessionStatus.exception => const StatusInfo(
    'Exception',
    UC.danger,
    'Needs supervisor review before final closure.',
    'Await supervisor',
  ),
  SessionStatus.voided => StatusInfo(
    'Voided',
    UC.faint,
    'Voided by manager. Event trail retained.',
    '—',
  ),
};

StatusInfo paymentInfo(PaymentStatus s) => switch (s) {
  PaymentStatus.initiated => StatusInfo(
    'Initiated',
    UC.muted,
    'Request created.',
    'Wait for provider',
  ),
  PaymentStatus.pending => const StatusInfo(
    'Pending',
    UC.warning,
    'Waiting for provider confirmation.',
    'Check status',
  ),
  PaymentStatus.confirmed => const StatusInfo(
    'Confirmed',
    UC.success,
    'Provider confirmed payment.',
    'Receipt',
  ),
  PaymentStatus.failed => const StatusInfo(
    'Failed',
    UC.danger,
    'Provider declined or timed out.',
    'Retry safely',
  ),
  PaymentStatus.reversed => const StatusInfo(
    'Reversed',
    UC.purple,
    'Payment was reversed.',
    'Contact support',
  ),
};

StatusInfo branchInfo(BranchStatus s) => switch (s) {
  BranchStatus.open => const StatusInfo(
    'Open',
    UC.success,
    'Staff report chargers available.',
    'Navigate',
  ),
  BranchStatus.busy => const StatusInfo(
    'Busy',
    UC.warning,
    'Staff report a queue.',
    'Call branch',
  ),
  BranchStatus.offline => const StatusInfo(
    'Offline',
    UC.danger,
    'Staff report chargers unavailable.',
    'Try another branch',
  ),
  BranchStatus.temporarilyClosed => StatusInfo(
    'Temporarily closed',
    UC.muted,
    'Branch closed for now.',
    'Call branch',
  ),
  BranchStatus.unknown => StatusInfo(
    'Unknown',
    UC.faint,
    'No recent staff update.',
    'Call branch',
  ),
};

StatusInfo cardInfo(CardStatus s) => switch (s) {
  CardStatus.unlinked => StatusInfo(
    'Unlinked',
    UC.muted,
    'Not linked to an account.',
    'Link card',
  ),
  CardStatus.active => const StatusInfo(
    'Active',
    UC.success,
    'Accepted at all branches.',
    'Block if lost',
  ),
  CardStatus.blocked => const StatusInfo(
    'Blocked',
    UC.danger,
    'Rejected on every scan.',
    'Request replacement',
  ),
  CardStatus.replaced => const StatusInfo(
    'Replaced',
    UC.purple,
    'Superseded by a new card.',
    '—',
  ),
  CardStatus.expired => StatusInfo(
    'Expired',
    UC.faint,
    'Card validity ended.',
    'Request replacement',
  ),
};

StatusInfo shiftInfo(ShiftStatus s) => switch (s) {
  ShiftStatus.notStarted => StatusInfo(
    'Not started',
    UC.muted,
    'Clock in to begin.',
    'Clock in',
  ),
  ShiftStatus.active => const StatusInfo(
    'Shift active',
    UC.success,
    'You are clocked in.',
    'End shift',
  ),
  ShiftStatus.submitted => const StatusInfo(
    'Submitted',
    UC.info,
    'Awaiting supervisor review.',
    'Await review',
  ),
  ShiftStatus.reconciled => const StatusInfo(
    'Reconciled',
    UC.success,
    'Supervisor approved.',
    '—',
  ),
  ShiftStatus.exception => const StatusInfo(
    'Exception',
    UC.danger,
    'Variances need supervisor review.',
    'Await supervisor',
  ),
};

String payMethodLabel(PayMethod m) => switch (m) {
  PayMethod.wallet => 'Ulti wallet',
  PayMethod.card => 'QR card',
  PayMethod.momo => 'Mobile Money',
  PayMethod.cash => 'Cash',
};

/// Sign-in account. The role comes from the account, not a picker.
/// An attendant's terminal (branch + charger) is assigned by the back office.
class Account {
  final String phone;
  String? email;
  String password;
  final Role role;
  final String name;
  final Driver? driver;
  String? branchId;
  String? chargerId;
  // Shift window and opening meter reading come from the back office.
  TimeOfDay? shiftStart;
  TimeOfDay? shiftEnd;
  double? openingReading;
  Account({
    required this.phone,
    this.email,
    required this.password,
    required this.role,
    required this.name,
    this.driver,
    this.branchId,
    this.chargerId,
    this.shiftStart,
    this.shiftEnd,
    this.openingReading,
  });

  String get shiftWindow => shiftStart == null || shiftEnd == null
      ? 'Not scheduled'
      : '${_tod(shiftStart!)} – ${_tod(shiftEnd!)}';
  static String _tod(TimeOfDay t) =>
      '${t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod}:${t.minute.toString().padLeft(2, '0')} ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
}

/// Row label for a charge session in transaction lists.
StatusInfo transactionInfo(ChargeSession s) {
  if (s.paymentStatus == PaymentStatus.failed) {
    return const StatusInfo('Failed', UC.danger, '', '');
  }
  return switch (s.status) {
    SessionStatus.paid => const StatusInfo('Successful', UC.success, '', ''),
    SessionStatus.awaitingPayment => const StatusInfo(
      'Pending',
      UC.warning,
      '',
      '',
    ),
    _ =>
      s.paymentStatus == PaymentStatus.pending
          ? const StatusInfo('Pending', UC.warning, '', '')
          : sessionInfo(s.status),
  };
}

class Branch {
  final String id;
  final String name;
  final String address;
  final String hours;
  final String phone;
  final double tariff;
  final double distanceKm;
  final Offset mapPos; // 0..1 position on the stylised map
  BranchStatus status;
  DateTime statusUpdated;
  final List<Charger> chargers;

  Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.hours,
    required this.phone,
    required this.tariff,
    required this.distanceKm,
    required this.mapPos,
    required this.status,
    required this.statusUpdated,
    required this.chargers,
  });
}

class Charger {
  final String id;
  final String connector;
  const Charger(this.id, this.connector);
  String get label => '$id · $connector';
}

enum WalletEntryKind { load, withdraw, charge }

/// One line of a driver's card-balance history.
class WalletEntry {
  final WalletEntryKind kind;
  final double amount;
  final String label;
  final DateTime at;
  WalletEntry(this.kind, this.amount, this.label, {DateTime? at})
    : at = at ?? DateTime.now();

  bool get isCredit => kind == WalletEntryKind.load;
}

class Driver {
  final String id;
  String name;
  String phone;
  String plate;
  String vehicleType;
  String? cardId;
  bool consent;
  double walletBalance;
  final List<WalletEntry> ledger = [];

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.plate,
    required this.vehicleType,
    this.cardId,
    this.consent = true,
    this.walletBalance = 0,
  });

  String get initials => initialsOf(name);
}

class SessionEvent {
  final DateTime at;
  final String label;
  SessionEvent(this.label) : at = DateTime.now();
  SessionEvent.at(this.at, this.label);
}

class ChargeSession {
  final String id;
  final Driver driver;
  final Branch branch;
  final Charger charger;
  final double tariff;
  final double? startReading;
  final String attendant;
  final DateTime startedAt;
  final String idempotencyKey;
  DateTime? stoppedAt;
  double? kwh;
  double? machineAmount;
  bool photoAttached = false;
  String notes = '';
  String varianceReason = '';
  bool varianceFlag = false;
  String momoNumber = '';
  bool voidRequested = false;
  String voidReason = '';
  bool disputed = false;
  bool synced;
  SessionStatus status;
  PayMethod? payMethod;
  PaymentStatus? paymentStatus;
  String paymentRef = '';
  double paidAmount = 0;
  final List<SessionEvent> events = [];

  ChargeSession({
    required this.id,
    required this.driver,
    required this.branch,
    required this.charger,
    required this.tariff,
    required this.attendant,
    required this.startedAt,
    required this.idempotencyKey,
    this.startReading,
    this.status = SessionStatus.active,
    this.synced = true,
  });

  double? get expected => kwh == null ? null : kwh! * tariff;
  double? get variance => (expected == null || machineAmount == null)
      ? null
      : machineAmount! - expected!;
  double get due => machineAmount ?? expected ?? 0;
  Duration get elapsed => (stoppedAt ?? DateTime.now()).difference(startedAt);
}

class QrCard {
  final String id;
  final String last4;
  CardStatus status;
  DateTime? lastUsed;
  QrCard(this.id, this.last4, this.status, this.lastUsed);
}

class Shift {
  ShiftStatus status = ShiftStatus.notStarted;
  Branch? branch;
  DateTime? startedAt;
  DateTime? endedAt;
  Charger? charger;
  double? openingReading;
  String notes = '';
}

class Offer {
  final String title;
  final String detail;
  final int points;
  final DateTime expires;
  final bool campaignEnabled;
  const Offer(
    this.title,
    this.detail,
    this.points,
    this.expires,
    this.campaignEnabled,
  );
}

// ---- formatting helpers (no intl dependency) ----

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// First letters of the first two words, e.g. "Efua Asante" -> "EA".
String initialsOf(String name) =>
    name.split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join();

String money(num v) => 'GH₵ ${v.toStringAsFixed(2)}';

String two(int n) => n.toString().padLeft(2, '0');

String hm(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${two(d.minute)} ${d.hour < 12 ? 'AM' : 'PM'}';
}

String dmy(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String dm(DateTime d) => '${d.day} ${_months[d.month - 1]}';

String stamp(DateTime d) => '${dm(d)}, ${hm(d)}';

String clock(Duration d) =>
    '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';

String ago(DateTime d) {
  final m = DateTime.now().difference(d).inMinutes;
  if (m < 1) return 'just now';
  if (m < 60) return '$m min ago';
  final h = m ~/ 60;
  if (h < 24) return '$h h ago';
  return dm(d);
}
