import 'package:flutter/material.dart';

import '../../models.dart';
import '../../state.dart';
import '../../widgets/common.dart';
import 'active_session_screen.dart';
import 'payment_screen.dart';
import 'receipt_screen.dart';
import 'stop_charge_screen.dart';

/// Opens the screen that matches the session's next available action.
void openSession(BuildContext context, ChargeSession s) {
  // Off shift records are view-only: finished charges open as a receipt,
  // anything that still needs an action stays locked.
  if (!AppScope.read(context).onShift) {
    if (s.paymentStatus != null &&
        (s.status == SessionStatus.paid ||
            s.status == SessionStatus.exception ||
            s.status == SessionStatus.voided)) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => ReceiptScreen(s)));
    } else {
      toast(
        context,
        'Start your shift to work on this charge.',
        tone: Tone.warning,
      );
    }
    return;
  }
  final Widget page = switch (s.status) {
    SessionStatus.draft || SessionStatus.active => ActiveSessionScreen(s),
    SessionStatus.awaitingReadings => StopChargeScreen(s),
    SessionStatus.awaitingPayment => PaymentScreen(s),
    SessionStatus.paid || SessionStatus.exception || SessionStatus.voided =>
      s.paymentStatus == null ? PaymentScreen(s) : ReceiptScreen(s),
  };
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}
