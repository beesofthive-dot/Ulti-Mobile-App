import 'package:flutter/material.dart';

import '../models.dart';
import '../notifications/app_notification.dart';
import '../state.dart';
import '../theme.dart';
import 'motion.dart';

export '../notifications/app_notification.dart' show Tone;

/// Small uppercase, letter-spaced label ("WELCOME BACK", "NEAR YOU").
class Eyebrow extends StatelessWidget {
  final String text;
  final Color color;
  const Eyebrow(this.text, {super.key, this.color = UC.muted});

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      letterSpacing: 1.8,
      fontWeight: FontWeight.w600,
      color: color,
    ),
  );
}

/// Ulti Charge brand logo from assets/brand.
/// [wordmark] shows the full "Ulti Charge" lockup; otherwise the square mark.
class UcLogo extends StatelessWidget {
  final double size;
  final bool wordmark;
  const UcLogo({super.key, this.size = 36, this.wordmark = true});

  @override
  Widget build(BuildContext context) {
    if (!wordmark) {
      return Image.asset(
        'assets/brand/logo_mark.png',
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
      );
    }
    return Image.asset(
      'assets/brand/logo_full.png',
      height: size,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// The main logo (icon with "Ulti"), used on sign-in and the loading screen.
class BrandLogo extends StatelessWidget {
  final double height;
  const BrandLogo({super.key, this.height = 110});

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/logo.png',
    height: height,
    filterQuality: FilterQuality.medium,
  );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? trailing;
  final IconData? leading;
  final bool busy;
  final Color color;
  final double height;
  const PrimaryButton(
    this.label, {
    super.key,
    this.onPressed,
    this.trailing = Icons.chevron_right_rounded,
    this.leading,
    this.busy = false,
    this.color = UC.primary,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: .35),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leading != null) ...[
                    Icon(leading, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                  if (trailing != null) ...[
                    const SizedBox(width: 6),
                    Icon(trailing, size: 20),
                  ],
                ],
              ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  const GhostButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.color = UC.ink,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color == UC.ink ? UC.line : color),
          backgroundColor: UC.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

/// Label above a field, matching the sign-in mockup.
class LabeledField extends StatelessWidget {
  final String label;
  final String? hint;
  final IconData? icon;
  final TextEditingController? controller;
  final bool obscure;
  final Widget? labelTrailing;
  final TextInputType? keyboardType;
  final String? helper;
  final String? errorText;
  final String? suffixText;
  final String? prefixText;
  final int maxLines;
  final bool optional;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final Widget? suffix;

  const LabeledField({
    super.key,
    required this.label,
    this.hint,
    this.icon,
    this.controller,
    this.obscure = false,
    this.labelTrailing,
    this.keyboardType,
    this.helper,
    this.errorText,
    this.suffixText,
    this.prefixText,
    this.maxLines = 1,
    this.optional = false,
    this.readOnly = false,
    this.onChanged,
    this.onTap,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: UC.ink,
              ),
            ),
            if (optional)
              const Text(
                '  Optional',
                style: TextStyle(fontSize: 11.5, color: UC.faint),
              ),
            const Spacer(),
            ?labelTrailing,
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          autocorrect: !obscure,
          enableSuggestions: !obscure,
          textCapitalization: TextCapitalization.none,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          onChanged: onChanged,
          onTap: onTap,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            suffixText: suffixText,
            prefixText: prefixText,
            suffixIcon: suffix,
            prefixIcon: icon == null
                ? null
                : Icon(icon, size: 19, color: UC.faint),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper!,
            style: const TextStyle(fontSize: 11.5, color: UC.muted),
          ),
        ],
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool dot;
  const StatusChip(this.label, this.color, {super.key, this.dot = true});

  factory StatusChip.of(StatusInfo i) => StatusChip(i.label, i.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final VoidCallback? onTap;
  final Color borderColor;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = UC.surface,
    this.borderColor = UC.line,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(UC.radius),
        boxShadow: [
          BoxShadow(
            color: UC.navy.withValues(alpha: .05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UC.radius),
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: UC.teal.withValues(alpha: .12),
          highlightColor: UC.teal.withValues(alpha: .05),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return onTap == null ? card : PressScale(child: card);
  }
}

/// Section heading inside a page: teal accent bar, eyebrow and title.
class SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader(
    this.eyebrow,
    this.title, {
    super.key,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      offset: 10,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [UC.teal, UC.brandGreen],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(eyebrow),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: UC.navy,
                    letterSpacing: -.3,
                  ),
                ),
              ],
            ),
          ),
          if (action != null)
            Material(
              color: UC.limeSoft,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                  child: Row(
                    children: [
                      Text(
                        action!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0B8F80),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Color(0xFF0B8F80),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  final String text;
  final IconData icon;
  final Tone tone;
  final Widget? action;
  const InfoBanner(
    this.text, {
    super.key,
    this.icon = Icons.info_outline_rounded,
    this.tone = Tone.info,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final c = switch (tone) {
      Tone.info => UC.info,
      Tone.warning => UC.warning,
      Tone.danger => UC.danger,
      Tone.success => UC.success,
      Tone.neutral => UC.muted,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: .25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: UC.ink,
              ),
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      ),
    );
  }
}

class KV extends StatelessWidget {
  final String k;
  final String v;
  final bool strong;
  final Color? color;
  const KV(this.k, this.v, {super.key, this.strong = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: const TextStyle(fontSize: 13, color: UC.muted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: strong ? 15 : 13.5,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                color: color ?? UC.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status with explanation, timestamp and next action (spec §9).
class StatusPanel extends StatelessWidget {
  final StatusInfo info;
  final DateTime at;
  const StatusPanel(this.info, this.at, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          StatusChip.of(info),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.explanation,
                  style: const TextStyle(fontSize: 12, color: UC.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  '${stamp(at)} · Next: ${info.nextAction}',
                  style: const TextStyle(fontSize: 11, color: UC.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class IconTile extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final double size;
  const IconTile(this.icon, this.tint, {super.key, this.size = 40});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: tint.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(size * .28),
    ),
    child: Icon(icon, size: size * .5, color: tint),
  );
}

class OfflineBadge extends StatelessWidget {
  const OfflineBadge({super.key});
  @override
  Widget build(BuildContext context) =>
      const StatusChip('UNSYNCED', UC.warning);
}

/// Selectable bordered card used for role choice, payment method, chargers.
class ChoiceCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  const ChoiceCard({
    super.key,
    required this.selected,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected ? UC.limeSoft : UC.surface,
          borderRadius: radius,
          border: Border.all(
            color: selected ? UC.navy : UC.line,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: UC.navy.withValues(alpha: .08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        // Transparent Material above the fill so hover / press highlights
        // show on top of the card and follow its rounded corners.
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: radius,
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              child: Row(
                children: [
                  Icon(icon, size: 19, color: selected ? UC.navy : UC.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: UC.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: UC.navy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required Widget body,
  String confirm = 'Confirm',
  Color color = UC.primary,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      backgroundColor: UC.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: body,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('Back', style: TextStyle(color: UC.muted)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: color),
          onPressed: () => Navigator.pop(c, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return r ?? false;
}

Future<String?> reasonDialog(
  BuildContext context, {
  required String title,
  required String hint,
  String confirm = 'Submit',
}) {
  final ctl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, set) {
        return AlertDialog(
          backgroundColor: UC.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: ctl,
            maxLines: 3,
            autofocus: true,
            onChanged: (_) => set(() {}),
            decoration: InputDecoration(hintText: hint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Cancel', style: TextStyle(color: UC.muted)),
            ),
            FilledButton(
              onPressed: ctl.text.trim().length < 5
                  ? null
                  : () => Navigator.pop(c, ctl.text.trim()),
              child: Text(confirm),
            ),
          ],
        );
      },
    ),
  );
}

/// Short top banner for quick feedback; not kept in the notification centre.
void toast(BuildContext context, String msg, {Tone tone = Tone.info}) =>
    AppScope.read(context).flash(msg, tone: tone);

/// Empty state used across lists.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const EmptyState(this.icon, this.title, this.body, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        children: [
          IconTile(icon, UC.muted, size: 48),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: UC.muted),
          ),
        ],
      ),
    );
  }
}

/// Small inline text action ("Show", "Forgot password?") with a rounded,
/// padded highlight and a hand cursor.
class SmallLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool bold;
  const SmallLink(
    this.label, {
    super.key,
    required this.onTap,
    this.icon,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: UC.muted),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: bold ? 12.5 : 12,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  color: bold ? UC.navy : UC.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// List row for use inside a [Panel]: the hover / press highlight is a
/// rounded shape inset from the panel edges, not a full-width bar.
class InsetTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const InsetTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      ),
    );
  }
}
