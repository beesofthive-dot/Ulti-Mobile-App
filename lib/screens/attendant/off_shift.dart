import 'package:flutter/material.dart';

import '../../state.dart';
import '../../widgets/common.dart';
import 'clock_in_screen.dart';

/// Opens the start-of-shift screen.
void startShiftFlow(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute(builder: (_) => const ClockInScreen()));

/// Shown in place of any operation while the attendant is not on shift.
class OffShiftNotice extends StatelessWidget {
  final String message;
  const OffShiftNotice({
    super.key,
    this.message =
        'You are not on shift. You can look at records, but you cannot record '
        'charges or take payments until you start your shift.',
  });

  @override
  Widget build(BuildContext context) {
    AppScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InfoBanner(
          message,
          tone: Tone.warning,
          icon: Icons.lock_clock_outlined,
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          'Start shift',
          leading: Icons.login_rounded,
          onPressed: () => startShiftFlow(context),
        ),
      ],
    );
  }
}
