import 'package:flutter/material.dart';

import '../../models.dart';
import 'active_session_screen.dart';
import 'payment_screen.dart';
import 'receipt_screen.dart';
import 'stop_charge_screen.dart';

/// Opens the screen that matches the session's next available action.
void openSession(BuildContext context, ChargeSession s) {
  final Widget page = switch (s.status) {
    SessionStatus.draft || SessionStatus.active => ActiveSessionScreen(s),
    SessionStatus.awaitingReadings => StopChargeScreen(s),
    SessionStatus.awaitingPayment => PaymentScreen(s),
    SessionStatus.paid || SessionStatus.exception || SessionStatus.voided =>
      s.paymentStatus == null ? PaymentScreen(s) : ReceiptScreen(s),
  };
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}
