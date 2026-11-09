import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import 'common.dart';

/// Paginated transaction table for the attendant workspace:
/// status pill, station, driver, a verify button and a person button per row.
class TransactionList extends StatefulWidget {
  final List<ChargeSession> sessions;
  final void Function(ChargeSession) onVerify;
  final int pageSize;
  const TransactionList({
    super.key,
    required this.sessions,
    required this.onVerify,
    this.pageSize = 7,
  });

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  int page = 0;

  int get pages => (widget.sessions.length / widget.pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    final total = pages;
    final current = page.clamp(0, total == 0 ? 0 : total - 1);
    final start = current * widget.pageSize;
    final rows = widget.sessions.skip(start).take(widget.pageSize).toList();
    return Container(
      decoration: BoxDecoration(
        color: UC.surface,
        borderRadius: BorderRadius.circular(UC.radius),
        border: Border.all(color: UC.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final s in rows) ...[
            TransactionRow(s, onVerify: () => widget.onVerify(s)),
            const Divider(),
          ],
          _Pager(
            page: current,
            pages: total,
            onPage: (p) => setState(() => page = p),
          ),
        ],
      ),
    );
  }
}

class TransactionRow extends StatelessWidget {
  final ChargeSession s;
  final VoidCallback onVerify;
  const TransactionRow(this.s, {super.key, required this.onVerify});

  @override
  Widget build(BuildContext context) {
    final info = transactionInfo(s);
    final done = s.status == SessionStatus.paid;
    final tint = done ? UC.info : UC.warning;
    final text = TextStyle(fontSize: 14, height: 1.35, color: UC.ink);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      child: Row(
        children: [
          SizedBox(width: 92, child: _Pill(info.label, info.color)),
          const SizedBox(width: 10),
          Expanded(flex: 5, child: Text(s.branch.name, style: text)),
          const SizedBox(width: 8),
          Expanded(flex: 4, child: Text(s.driver.name, style: text)),
          _SquareButton(
            icon: Icons.task_alt_rounded,
            color: tint,
            tooltip: done ? 'Open transaction' : 'Verify payment',
            onTap: onVerify,
          ),
          IconButton(
            tooltip: 'Driver details',
            onPressed: () => _showPerson(context, s),
            icon: Icon(Icons.person_outline_rounded, color: UC.ink),
          ),
        ],
      ),
    );
  }
}

void _showPerson(BuildContext context, ChargeSession s) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(s.driver.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KV('Phone', s.driver.phone),
          KV('Plate', s.driver.plate),
          KV('Branch', s.branch.name),
          KV('Attendant', s.attendant),
          KV('Amount', money(s.due)),
          KV('Started', stamp(s.startedAt)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _SquareButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: .6)),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

/// "Page 2 of 44  Previous 1 2 3 4 5 Next" footer.
class _Pager extends StatelessWidget {
  final int page;
  final int pages;
  final ValueChanged<int> onPage;
  const _Pager({required this.page, required this.pages, required this.onPage});

  /// Up to five consecutive page numbers around the current page.
  List<int> get _window {
    final first = (page - 2).clamp(0, (pages - 5).clamp(0, pages));
    return [for (var i = first; i < pages && i < first + 5; i++) i];
  }

  @override
  Widget build(BuildContext context) {
    if (pages <= 1) return const SizedBox(height: 4);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Text(
            'Page ${page + 1}\nof $pages',
            style: TextStyle(fontSize: 13.5, color: UC.muted),
          ),
          const SizedBox(width: 8),
          _PageButton(
            label: 'Previous',
            icon: Icons.chevron_left_rounded,
            onTap: page == 0 ? null : () => onPage(page - 1),
          ),
          for (final p in _window)
            _PageButton(
              label: '${p + 1}',
              selected: p == page,
              onTap: () => onPage(p),
            ),
          _PageButton(
            label: 'Next',
            trailingIcon: Icons.chevron_right_rounded,
            onTap: page >= pages - 1 ? null : () => onPage(page + 1),
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool selected;
  final VoidCallback? onTap;
  const _PageButton({
    required this.label,
    this.icon,
    this.trailingIcon,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = onTap == null ? UC.faint : UC.ink;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: selected ? const Color(0xFFF7D117) : UC.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: selected ? Colors.transparent : UC.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) Icon(icon, size: 20, color: fg),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: fg,
                  ),
                ),
                if (trailingIcon != null)
                  Icon(trailingIcon, size: 20, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
