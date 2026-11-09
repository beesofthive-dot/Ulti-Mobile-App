import 'dart:math';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter/widgets.dart';

import 'auth/otp_flow.dart';
import 'models.dart';
import 'notifications/app_notification.dart';
import 'notifications/notification_feed.dart';
import 'payments/payment_flow.dart';
import 'payments/wallet_flow.dart';

/// In-memory app state with seed data. No backend: the spec excludes it.
/// Start/Stop only record software timestamps; nothing talks to a charger.
class AppState extends ChangeNotifier
    with NotificationFeed, PaymentFlow, WalletFlow, OtpFlow {
  AppState() {
    _seed();
  }

  final _rng = Random();

  Role? role;
  @override
  bool online = true;

  // ---------- reference data ----------
  late final List<Branch> branches;
  final List<Driver> drivers = [];
  final List<ChargeSession> sessions = [];
  final List<QrCard> cards = [];
  final List<Offer> offers = [];
  int rewardPoints = 340;
  final List<String> redemptions = ['12 Oct · Free 5 kWh top-up · −250 pts'];

  // ---------- accounts ----------
  @override
  final List<Account> accounts = [];

  @override
  String normalizePhone(String phone) => localPhone(phone);
  Account? account;

  // ---------- attendant ----------
  String attendantName = 'Efua Asante';
  Branch? branch;
  // Each attendant account keeps its own shift, so logging out mid-shift
  // and back in resumes it, and another attendant never sees it.
  final Map<String, Shift> _shifts = {};
  Shift get shift => _shifts.putIfAbsent(account?.phone ?? '', Shift.new);

  /// Terminal (branch + charger) assigned to [a]; null if unassigned.
  Branch? branchOf(Account a) {
    for (final b in branches) {
      if (b.id == a.branchId) return b;
    }
    return null;
  }

  Charger? chargerOf(Account a) {
    final b = branchOf(a);
    if (b == null) return null;
    for (final c in b.chargers) {
      if (c.id == a.chargerId) return c;
    }
    return b.chargers.first;
  }

  /// The signed-in attendant's assigned charger.
  Charger? get assignedCharger => account == null ? null : chargerOf(account!);

  // ---------- driver ----------
  @override
  late Driver me;

  void _seed() {
    final now = DateTime.now();
    const chargers = [
      Charger('DC-01', 'CCS2'),
      Charger('DC-02', 'CCS2'),
      Charger('AC-01', 'Type 2'),
    ];
    branches = [
      Branch(
        id: 'mm37',
        name: 'MaxMart 37',
        address: '37 Liberation Road, Accra',
        hours: 'Daily · 6:00 AM – 10:00 PM',
        phone: '+233 30 222 0137',
        tariff: 4.80,
        distanceKm: 2.4,
        mapPos: const Offset(.42, .38),
        status: BranchStatus.open,
        statusUpdated: now.subtract(const Duration(minutes: 6)),
        chargers: chargers,
      ),
      Branch(
        id: 'atomic',
        name: 'Atomic Roundabout',
        address: 'Atomic Junction, Haatso, Accra',
        hours: 'Daily · 6:00 AM – 11:00 PM',
        phone: '+233 30 222 0412',
        tariff: 4.80,
        distanceKm: 9.8,
        mapPos: const Offset(.58, .16),
        status: BranchStatus.busy,
        statusUpdated: now.subtract(const Duration(minutes: 18)),
        chargers: chargers.take(2).toList(),
      ),
      Branch(
        id: 'spintex',
        name: 'Spintex Road',
        address: 'Spintex Rd, near Coca-Cola Rbt, Accra',
        hours: 'Mon – Sat · 7:00 AM – 9:00 PM',
        phone: '+233 30 222 0566',
        tariff: 5.10,
        distanceKm: 11.3,
        mapPos: const Offset(.78, .62),
        status: BranchStatus.offline,
        statusUpdated: now.subtract(const Duration(hours: 2)),
        chargers: chargers.take(1).toList(),
      ),
      Branch(
        id: 'osu',
        name: 'Osu Oxford St',
        address: 'Oxford Street, Osu, Accra',
        hours: 'Daily · 8:00 AM – 8:00 PM',
        phone: '+233 30 222 0890',
        tariff: 5.00,
        distanceKm: 4.1,
        mapPos: const Offset(.30, .74),
        status: BranchStatus.temporarilyClosed,
        statusUpdated: now.subtract(const Duration(hours: 5)),
        chargers: chargers.take(2).toList(),
      ),
    ];

    me = Driver(
      id: 'D-1001',
      name: 'Kwame Mensah',
      phone: '024 555 0187',
      plate: 'GR 2451-24',
      vehicleType: 'Sedan EV',
      cardId: 'UC-7714-2018',
      walletBalance: 184.50,
    );
    drivers.addAll([
      me,
      Driver(
        id: 'D-1002',
        name: 'Ama Owusu',
        phone: '020 811 4432',
        plate: 'GT 9921-23',
        vehicleType: 'Hatchback EV',
        cardId: 'UC-7714-3301',
        walletBalance: 62.00,
      ),
      Driver(
        id: 'D-1003',
        name: 'Yaw Boateng',
        phone: '055 300 7719',
        plate: 'AS 4410-22',
        vehicleType: 'SUV EV',
        walletBalance: 0,
      ),
      Driver(
        id: 'D-1004',
        name: 'Akosua Darko',
        phone: '027 640 2210',
        plate: 'GE 1187-24',
        vehicleType: 'Electric motorbike',
        walletBalance: 15.20,
      ),
    ]);

    accounts.addAll([
      Account(
        phone: '020 000 0001',
        email: 'efua.asante@ulticharge.com',
        password: 'attend123',
        role: Role.attendant,
        name: 'Efua Asante',
        branchId: 'mm37',
        chargerId: 'DC-01',
        shiftStart: const TimeOfDay(hour: 6, minute: 0),
        shiftEnd: const TimeOfDay(hour: 14, minute: 0),
        openingReading: 18452.6,
      ),
      Account(
        phone: '020 000 0002',
        email: 'kofi.annan@ulticharge.com',
        password: 'attend123',
        role: Role.attendant,
        name: 'Kofi Annan',
        branchId: 'atomic',
        chargerId: 'DC-01',
        shiftStart: const TimeOfDay(hour: 14, minute: 0),
        shiftEnd: const TimeOfDay(hour: 22, minute: 0),
        openingReading: 9120.0,
      ),
      Account(
        phone: '020 000 0003',
        email: 'esi.quaye@ulticharge.com',
        password: 'attend123',
        role: Role.attendant,
        name: 'Esi Quaye',
      ),
      Account(
        phone: me.phone,
        email: 'kwame.mensah@example.com',
        password: 'driver123',
        role: Role.driver,
        name: me.name,
        driver: me,
      ),
    ]);

    cards.addAll([
      QrCard(
        'UC-7714-2018',
        '2018',
        CardStatus.active,
        now.subtract(const Duration(days: 2)),
      ),
      QrCard(
        'UC-7714-0951',
        '0951',
        CardStatus.replaced,
        now.subtract(const Duration(days: 64)),
      ),
    ]);

    offers.addAll([
      Offer(
        'Free 5 kWh top-up',
        'Redeem at any branch on your next charge.',
        250,
        now.add(const Duration(days: 21)),
        true,
      ),
      Offer(
        '10% off weekend charging',
        'Saturdays and Sundays at MaxMart 37.',
        400,
        now.add(const Duration(days: 9)),
        true,
      ),
      Offer(
        'Double points in December',
        'Campaign launches 1 Dec.',
        0,
        DateTime(now.year, 12, 31),
        false,
      ),
    ]);

    // Historic sessions for the driver history and attendant "Today" view.
    final mm = branches.first;
    final past =
        ChargeSession(
            id: 'CS-24-08812',
            driver: me,
            branch: mm,
            charger: mm.chargers.first,
            tariff: mm.tariff,
            attendant: attendantName,
            startedAt: now.subtract(
              const Duration(days: 2, hours: 1, minutes: 12),
            ),
            idempotencyKey: _key(),
            status: SessionStatus.paid,
          )
          ..stoppedAt = now.subtract(const Duration(days: 2, minutes: 18))
          ..kwh = 24.6
          ..machineAmount = 118.08
          ..payMethod = PayMethod.wallet
          ..paymentStatus = PaymentStatus.confirmed
          ..paidAmount = 118.08
          ..paymentRef = 'WAL-55102';
    final older =
        ChargeSession(
            id: 'CS-24-08390',
            driver: me,
            branch: branches[1],
            charger: branches[1].chargers.last,
            tariff: branches[1].tariff,
            attendant: 'Kofi Annan',
            startedAt: now.subtract(const Duration(days: 9, hours: 3)),
            idempotencyKey: _key(),
            status: SessionStatus.paid,
          )
          ..stoppedAt = now.subtract(const Duration(days: 9, hours: 2))
          ..kwh = 31.2
          ..machineAmount = 149.76
          ..payMethod = PayMethod.momo
          ..paymentStatus = PaymentStatus.confirmed
          ..paidAmount = 149.76
          ..paymentRef = 'MOMO-881204';
    final oldest =
        ChargeSession(
            id: 'CS-24-07702',
            driver: me,
            branch: mm,
            charger: mm.chargers[1],
            tariff: mm.tariff,
            attendant: attendantName,
            startedAt: now.subtract(const Duration(days: 23, hours: 5)),
            idempotencyKey: _key(),
            status: SessionStatus.paid,
          )
          ..stoppedAt = now.subtract(const Duration(days: 23, hours: 4))
          ..kwh = 18.0
          ..machineAmount = 86.40
          ..payMethod = PayMethod.card
          ..paymentStatus = PaymentStatus.confirmed
          ..paidAmount = 86.40
          ..paymentRef = 'CARD-2018-4410';
    for (final s in [past, older, oldest]) {
      s.events
        ..add(SessionEvent.at(s.startedAt, 'Charge started'))
        ..add(SessionEvent.at(s.stoppedAt!, 'Charge stopped'))
        ..add(SessionEvent.at(s.stoppedAt!, 'Payment confirmed'));
    }
    sessions.addAll([past, older, oldest]);
    me.ledger.addAll([
      WalletEntry(
        WalletEntryKind.charge,
        past.paidAmount,
        'Charge ${past.id}',
        at: past.stoppedAt,
      ),
      WalletEntry(
        WalletEntryKind.load,
        200,
        'MoMo 0245550187',
        at: now.subtract(const Duration(days: 4)),
      ),
    ]);
    notifications.add(
      AppNotification(
        title: 'Payment successful',
        body:
            '${money(past.paidAmount)} via Ulti wallet for ${past.id}. Receipt is ready.',
        tone: Tone.success,
        category: NoteCategory.money,
        audience: Role.driver,
        driver: me,
        read: true,
        at: past.stoppedAt,
      ),
    );
    _seedBranchActivity(now);
  }

  /// Older activity from other drivers so the shift list has several pages.
  void _seedBranchActivity(DateTime now) {
    for (var i = 0; i < 16; i++) {
      final b = branches[i % 2];
      final pending = i % 5 == 3;
      final started = now.subtract(Duration(hours: 5 + i * 7));
      final kwh = 10.0 + i * 1.5;
      final s =
          ChargeSession(
              id: 'CS-24-${7000 + i}',
              driver: drivers[1 + i % 3],
              branch: b,
              charger: b.chargers[i % b.chargers.length],
              tariff: b.tariff,
              attendant: i % 2 == 0 ? 'Efua Asante' : 'Kofi Annan',
              startedAt: started,
              idempotencyKey: _key(),
              status: pending
                  ? SessionStatus.awaitingPayment
                  : SessionStatus.paid,
            )
            ..stoppedAt = started.add(const Duration(minutes: 50))
            ..kwh = kwh
            ..machineAmount = kwh * b.tariff
            ..payMethod = pending ? PayMethod.momo : PayMethod.wallet
            ..paymentStatus = pending
                ? PaymentStatus.pending
                : PaymentStatus.confirmed
            ..paidAmount = pending ? 0 : kwh * b.tariff
            ..paymentRef = 'SEED-${7000 + i}';
      s.events
        ..add(SessionEvent.at(s.startedAt, 'Charge started'))
        ..add(SessionEvent.at(s.stoppedAt!, 'Charge stopped'));
      sessions.add(s);
    }
  }

  String _key() =>
      List.generate(16, (_) => '0123456789abcdef'[_rng.nextInt(16)]).join();

  String _sessionId() => 'CS-24-${(9000 + _rng.nextInt(999)).toString()}';

  // ================= notifications =================
  @override
  bool visibleToViewer(AppNotification n) {
    if (n.audience == null) return true;
    if (n.audience != role) return false;
    return switch (role) {
      Role.driver => n.driver == null || n.driver == me,
      Role.attendant => n.phone == null || n.phone == account?.phone,
      null => false,
    };
  }

  /// Phone of the attendant who recorded [s] (their account), so their
  /// notices reach them whichever role is signed in when the event happens.
  String? _attendantPhone(ChargeSession s) {
    for (final a in accounts) {
      if (a.role == Role.attendant && a.name == s.attendant) return a.phone;
    }
    return account?.phone;
  }

  /// Money event on [s]: told to the attendant who handled it and to the
  /// driver who paid, each in their own words.
  @override
  void moneyNote(
    ChargeSession s, {
    required Tone tone,
    required String attendantTitle,
    required String driverTitle,
    required String detail,
  }) {
    // Addressed to the attendant who handled the charge, not to whoever is
    // signed in now: a driver's approval arrives while the driver is.
    notify(
      AppNotification(
        title: attendantTitle,
        body: detail,
        tone: tone,
        category: NoteCategory.money,
        audience: Role.attendant,
        phone: _attendantPhone(s),
      ),
    );
    notify(
      AppNotification(
        title: driverTitle,
        body: detail,
        tone: tone,
        category: NoteCategory.money,
        audience: Role.driver,
        driver: s.driver,
      ),
    );
  }

  // ================= auth =================
  static String digits(String phone) => phone.replaceAll(RegExp(r'\D'), '');

  static bool isEmail(String s) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s.trim());

  /// Phone numbers become 0XXXXXXXXX; emails are trimmed and lower-cased.
  static String normalizeId(String s) =>
      s.contains('@') ? s.trim().toLowerCase() : localPhone(s);

  /// A sign-in identifier that is a valid email or a 10-digit phone number.
  static bool validId(String s) =>
      s.contains('@') ? isEmail(s) : localPhone(s).length == 10;

  /// Normalises a Ghana mobile number to local form (0XXXXXXXXX), so
  /// "+233 20 000 0001", "233200000001", "20 000 0001" and "020 000 0001"
  /// all match the same account.
  static String localPhone(String phone) {
    var d = digits(phone);
    if (d.startsWith('233') && d.length == 12) d = '0${d.substring(3)}';
    if (d.length == 9 && !d.startsWith('0')) d = '0$d';
    return d;
  }

  /// The account decides the workspace: attendant or driver.
  /// Signs in with a phone number or an email address plus the password.
  Account? authenticate(String identifier, String password) {
    final a = accountForId(identifier);
    return (a != null && a.password == password.trim()) ? a : null;
  }

  void signIn(Account a, {bool viaCode = false}) {
    account = a;
    role = a.role;
    if (a.role == Role.driver) {
      me = a.driver!;
    } else if (a.role == Role.attendant) {
      attendantName = a.name;
      branch = shift.status == ShiftStatus.active ? shift.branch : branchOf(a);
    }
    if (viaCode) {
      notify(
        AppNotification(
          title: 'Signed in with a one-time code',
          body: 'If this was not you, reset your password right away.',
          tone: Tone.info,
          category: NoteCategory.system,
          audience: a.role,
          driver: a.driver,
          phone: a.phone,
        ),
      );
      return;
    }
    notifyListeners();
  }

  /// Shift running time for the signed-in attendant.
  Duration get shiftElapsed => shift.startedAt == null
      ? Duration.zero
      : DateTime.now().difference(shift.startedAt!);

  /// Things the attendant should act on (spec §9 alerts).
  List<ChargeSession> get attentionSessions => todaySessions
      .where(
        (s) =>
            s.status == SessionStatus.exception ||
            s.status == SessionStatus.awaitingReadings ||
            s.status == SessionStatus.awaitingPayment ||
            s.paymentStatus == PaymentStatus.failed ||
            s.voidRequested,
      )
      .toList();

  void signOut() {
    if (shift.status == ShiftStatus.submitted ||
        shift.status == ShiftStatus.exception) {
      resetShift();
    }
    role = null;
    account = null;
    branch = null;
    notifyListeners();
  }

  Account registerDriverAccount(
    String name,
    String phone,
    String plate,
    String vehicleType,
    String password, {
    String? email,
  }) {
    final d = registerDriver(name, phone, plate, vehicleType);
    final a = Account(
      phone: phone,
      email: (email == null || email.trim().isEmpty)
          ? null
          : email.trim().toLowerCase(),
      password: password,
      role: Role.driver,
      name: name,
      driver: d,
    );
    accounts.add(a);
    return a;
  }

  void setOnline(bool v) {
    online = v;
    if (v) {
      for (final s in sessions) {
        if (!s.synced) {
          s.synced = true;
          s.events.add(SessionEvent('Synced to server'));
        }
      }
    }
    notifyListeners();
  }

  // ================= attendant: shift =================
  /// Starts the shift on the assigned terminal. The charger and opening
  /// reading come from the account; the attendant types nothing.
  void clockIn() {
    shift
      ..status = ShiftStatus.active
      ..branch = branch
      ..startedAt = DateTime.now()
      ..charger = assignedCharger
      ..openingReading = account?.openingReading;
    notifyListeners();
  }

  List<ChargeSession> get todaySessions {
    final start = shift.startedAt;
    if (start == null) return [];
    return sessions
        .where(
          (s) =>
              s.branch == branch &&
              s.attendant == attendantName &&
              !s.startedAt.isBefore(start),
        )
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  /// Confirmed card and MoMo payments collected this shift.
  double get collected => todaySessions
      .where((s) => s.paymentStatus == PaymentStatus.confirmed)
      .fold(0, (t, s) => t + s.paidAmount);

  double get kwhToday => todaySessions.fold(0, (t, s) => t + (s.kwh ?? 0));

  int get pendingPayments => todaySessions
      .where(
        (s) =>
            s.status == SessionStatus.awaitingPayment ||
            s.paymentStatus == PaymentStatus.pending ||
            s.paymentStatus == PaymentStatus.failed,
      )
      .length;

  List<ChargeSession> get activeSessions =>
      todaySessions.where((s) => s.status == SessionStatus.active).toList();

  void submitShift(String notes) {
    final hasExceptions = todaySessions.any(
      (s) =>
          s.status == SessionStatus.exception ||
          s.status == SessionStatus.awaitingReadings,
    );
    shift
      ..notes = notes
      ..endedAt = DateTime.now()
      ..status = hasExceptions ? ShiftStatus.exception : ShiftStatus.submitted;
    notify(
      AppNotification(
        title: hasExceptions ? 'Shift needs review' : 'Shift submitted',
        body: hasExceptions
            ? '${money(collected)} collected. Some sessions need supervisor review.'
            : '${money(collected)} collected this shift. Nothing to reconcile.',
        tone: hasExceptions ? Tone.warning : Tone.success,
        category: NoteCategory.money,
        audience: Role.attendant,
        phone: account?.phone,
      ),
    );
  }

  void resetShift() {
    shift
      ..status = ShiftStatus.notStarted
      ..branch = null
      ..startedAt = null
      ..endedAt = null
      ..charger = null
      ..openingReading = null
      ..notes = '';
    notifyListeners();
  }

  // ================= attendant: drivers =================
  List<Driver> searchDrivers(String q) {
    final t = q.trim().toLowerCase().replaceAll(' ', '');
    if (t.isEmpty) return drivers;
    return drivers.where((d) {
      return d.phone.replaceAll(' ', '').contains(t) ||
          (d.cardId ?? '')
              .toLowerCase()
              .replaceAll('-', '')
              .contains(t.replaceAll('-', '')) ||
          d.id.toLowerCase().contains(t) ||
          d.name.toLowerCase().replaceAll(' ', '').contains(t) ||
          d.plate.toLowerCase().replaceAll(' ', '').contains(t);
    }).toList();
  }

  /// Returns the existing driver if phone or plate already registered.
  Driver? findDuplicate(String phone, String plate) {
    final p = localPhone(phone);
    final pl = plate.replaceAll(' ', '').toLowerCase();
    for (final d in drivers) {
      if (p.isNotEmpty && localPhone(d.phone) == p) return d;
      if (pl.isNotEmpty && d.plate.replaceAll(' ', '').toLowerCase() == pl) {
        return d;
      }
    }
    return null;
  }

  Driver registerDriver(
    String name,
    String phone,
    String plate,
    String vehicleType,
  ) {
    final d = Driver(
      id: 'D-${1000 + drivers.length + 1}',
      name: name,
      phone: phone,
      plate: plate.toUpperCase(),
      vehicleType: vehicleType,
      consent: true,
    );
    drivers.add(d);
    notifyListeners();
    return d;
  }

  // ================= attendant: sessions =================
  ChargeSession? activeOn(Charger c) {
    for (final s in sessions) {
      if (s.branch == branch &&
          s.charger.id == c.id &&
          s.status == SessionStatus.active) {
        return s;
      }
    }
    return null;
  }

  ChargeSession startSession({
    required Driver driver,
    required Charger charger,
    double? startReading,
    bool override = false,
  }) {
    final b = branch!;
    final s = ChargeSession(
      id: _sessionId(),
      driver: driver,
      branch: b,
      charger: charger,
      tariff: b.tariff,
      startReading: startReading,
      attendant: attendantName,
      startedAt: DateTime.now(),
      idempotencyKey: _key(),
      synced: online,
    );
    s.events.add(
      SessionEvent('Charge started${override ? ' (connector override)' : ''}'),
    );
    if (!online) s.events.add(SessionEvent('Saved locally — UNSYNCED'));
    sessions.add(s);
    _chargeNote(
      s,
      driverTitle: 'Charging started',
      driverBody:
          '${s.charger.id} at ${b.name}. You will be told the amount when it ends.',
      attendantTitle: 'Charge started',
      attendantBody: '${driver.name} on ${s.charger.id}.',
    );
    return s;
  }

  /// Records a finished charge in one step (kWh and amount already worked out
  /// at the tariff) and leaves it awaiting payment. The driver is told the
  /// amount due and the attendant that it was recorded.
  ChargeSession recordCharge({
    required Driver driver,
    required Charger charger,
    required double kwh,
    required double amount,
  }) {
    final b = branch!;
    final s = ChargeSession(
      id: _sessionId(),
      driver: driver,
      branch: b,
      charger: charger,
      tariff: b.tariff,
      attendant: attendantName,
      startedAt: DateTime.now(),
      idempotencyKey: _key(),
      synced: online,
    );
    s.events.add(SessionEvent('Charge recorded'));
    if (!online) s.events.add(SessionEvent('Saved locally — UNSYNCED'));
    sessions.add(s);
    // Stops it, stores the readings and tells the driver what is due.
    recordReadings(
      s,
      kwh: kwh,
      amount: amount,
      photo: false,
      notes: '',
      varianceReason: '',
    );
    notify(
      AppNotification(
        title: 'Charge recorded',
        body:
            '${s.id} · ${charger.id} · ${kwh.toStringAsFixed(3)} kWh · '
            '${money(amount)} to collect from ${driver.name}.',
        tone: Tone.success,
        category: NoteCategory.session,
        audience: Role.attendant,
        phone: account?.phone,
      ),
    );
    return s;
  }

  /// A charge-session event, told to the driver and to the attendant.
  void _chargeNote(
    ChargeSession s, {
    required String driverTitle,
    required String driverBody,
    required String attendantTitle,
    required String attendantBody,
    Tone tone = Tone.info,
  }) {
    notify(
      AppNotification(
        title: attendantTitle,
        body: attendantBody,
        tone: tone,
        category: NoteCategory.session,
        audience: Role.attendant,
        phone: _attendantPhone(s),
      ),
    );
    notify(
      AppNotification(
        title: driverTitle,
        body: driverBody,
        tone: tone,
        category: NoteCategory.session,
        audience: Role.driver,
        driver: s.driver,
      ),
    );
  }

  void stopSession(ChargeSession s) {
    if (s.stoppedAt == null) {
      s.stoppedAt = DateTime.now();
      s.events.add(SessionEvent('Charge stopped (software timestamp)'));
    }
    notifyListeners();
  }

  void recordReadings(
    ChargeSession s, {
    required double kwh,
    required double amount,
    required bool photo,
    required String notes,
    required String varianceReason,
  }) {
    stopSession(s);
    s
      ..kwh = kwh
      ..machineAmount = amount
      ..photoAttached = photo
      ..notes = notes
      ..varianceReason = varianceReason
      ..synced = s.synced && online;
    final v = s.variance ?? 0;
    s.varianceFlag = v.abs() >= 0.01;
    s.status = SessionStatus.awaitingPayment;
    s.events.add(
      SessionEvent(
        'Readings confirmed: ${kwh.toStringAsFixed(2)} kWh, ${money(amount)}',
      ),
    );
    notify(
      AppNotification(
        title: 'Charge complete · ${money(s.due)} due',
        body:
            '${kwh.toStringAsFixed(2)} kWh at ${s.branch.name}. Show your QR '
            'or approve the Mobile Money prompt to pay.',
        tone: Tone.warning,
        category: NoteCategory.money,
        audience: Role.driver,
        driver: s.driver,
      ),
    );
    if (s.varianceFlag) {
      s.events.add(
        SessionEvent(
          'Variance ${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)} flagged for supervisor',
        ),
      );
      notify(
        AppNotification(
          title: 'Amount variance flagged',
          body:
              '${s.id}: machine ${money(amount)} vs expected ${money(s.expected ?? 0)}. A supervisor will review.',
          tone: Tone.warning,
          category: NoteCategory.money,
          audience: Role.attendant,
          phone: account?.phone,
        ),
      );
      return;
    }
    notifyListeners();
  }

  void markAwaitingEvidence(ChargeSession s, String notes) {
    stopSession(s);
    s
      ..status = SessionStatus.awaitingReadings
      ..notes = notes;
    s.events.add(
      SessionEvent('Machine display unavailable — awaiting evidence'),
    );
    notifyListeners();
  }

  void requestVoid(ChargeSession s, String reason) {
    s
      ..voidRequested = true
      ..voidReason = reason;
    s.events.add(SessionEvent('Void requested: $reason'));
    notifyListeners();
  }

  // ================= driver =================
  List<ChargeSession> get myHistory =>
      sessions.where((s) => s.driver == me).toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

  void dispute(ChargeSession s, String reason) {
    s.disputed = true;
    s.events.add(SessionEvent('Driver dispute: $reason'));
    notifyListeners();
  }

  void blockCard(QrCard c) {
    c.status = CardStatus.blocked;
    if (me.cardId == c.id) me.cardId = null;
    notifyListeners();
  }

  void requestReplacement(QrCard c) {
    c.status = CardStatus.replaced;
    notifyListeners();
  }

  /// Returns null on success or a rejection reason.
  String? linkCard(String code) {
    final c = code.trim().toUpperCase();
    if (!RegExp(r'^UC-\d{4}-\d{4}$').hasMatch(c)) {
      return 'Card code must look like UC-0000-0000.';
    }
    for (final k in cards) {
      if (k.id == c) {
        return k.status == CardStatus.blocked
            ? 'This card is blocked and cannot be linked.'
            : 'This card is already linked to an account.';
      }
    }
    if (drivers.any((d) => d.cardId == c)) {
      return 'This card is already linked to another account.';
    }
    if (cards.any((k) => k.status == CardStatus.active)) {
      return 'You already have an active card. Block it before linking a new one.';
    }
    cards.insert(
      0,
      QrCard(c, c.substring(c.length - 4), CardStatus.active, null),
    );
    me.cardId = c;
    notifyListeners();
    return null;
  }

  QrCard? get activeCard {
    for (final c in cards) {
      if (c.status == CardStatus.active) return c;
    }
    return null;
  }

  bool redeem(Offer o) {
    if (!o.campaignEnabled || rewardPoints < o.points) return false;
    rewardPoints -= o.points;
    redemptions.insert(
      0,
      '${dm(DateTime.now())} · ${o.title} · −${o.points} pts',
    );
    notifyListeners();
    return true;
  }

  void touch() => notifyListeners();
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
