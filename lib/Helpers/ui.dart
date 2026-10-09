import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:intl/intl.dart';
import 'package:frontend_vesta/Helpers/icons.dart';

// Shared building blocks for the redesign. Screens compose these instead of
// styling Containers by hand, so the look stays in colors.dart and here.

/// Page background: a soft gradient from the header colour into the page
/// colour over the first 340px, as in the prototype. Also sets the status bar
/// icons for screens that have no AppBar.
class VestaBackground extends StatelessWidget {
  const VestaBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: theme.scaffoldBackgroundColor)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 340,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [context.vesta.bgTop, theme.scaffoldBackgroundColor],
                ),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// Header bar. The default shows a back arrow (when there is a route to pop)
/// and a heading-font title; [VestaAppBar.large] is the big left-aligned title
/// used on tab pages such as Wallet and Profile.
class VestaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const VestaAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
  }) : large = false;

  const VestaAppBar.large({super.key, required this.title, this.actions})
    : large = true,
      showBack = false;

  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final bool large;

  @override
  Size get preferredSize => Size.fromHeight(large ? 64 : 52);

  @override
  Widget build(BuildContext context) {
    final canPop = showBack && (ModalRoute.of(context)?.canPop ?? false);
    return AppBar(
      toolbarHeight: preferredSize.height,
      automaticallyImplyLeading: false,
      titleSpacing: canPop ? 0 : VestaSpace.gutter,
      leading: canPop
          ? IconButton(
              icon: const Icon(PhosphorIconsRegular.arrowLeft),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => Navigator.maybePop(context),
            )
          : null,
      title: Text(
        title,
        style: large ? Theme.of(context).textTheme.headlineMedium : null,
      ),
      actions: [...?actions, const SizedBox(width: VestaSpace.sm)],
    );
  }
}

class VestaNavItem {
  const VestaNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Bottom tab bar: a tinted pill behind the selected icon, filled icon when
/// selected, outline otherwise.
class VestaBottomBar extends StatelessWidget {
  const VestaBottomBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<VestaNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.vesta.divider)),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinations: [
          for (final item in items)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}

/// Rounded surface block. Light mode draws a hairline edge; dark mode doesn't.
class VestaCard extends StatelessWidget {
  const VestaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(VestaSpace.lg),
    this.radius = VestaRadius.card,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: context.vesta.edge),
    );
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Card title with an optional text action ("See all") or trailing widgets.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final List<Widget>? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: headingStyle(16)),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: TextStyle(fontSize: 13, color: context.vesta.accentInk),
            ),
          ),
        ...?trailing,
      ],
    );
  }
}

/// Small square icon button with an outline, used beside section titles
/// (the prototype's + and − buttons).
class OutlineIconButton extends StatelessWidget {
  const OutlineIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.vesta.accentInk;
    return Padding(
      padding: const EdgeInsets.only(left: VestaSpace.sm),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: c),
        style: IconButton.styleFrom(
          fixedSize: const Size(32, 32),
          minimumSize: const Size(32, 32),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VestaRadius.md),
            side: BorderSide(color: context.vesta.divider),
          ),
        ),
      ),
    );
  }
}

/// The + and − pair beside a list's title, the same on every list that can
/// grow or shrink: + adds, − turns a remove mode on and off (a tick while
/// it is on). Rows show a [RemoveBadge] while removing.
class AddRemoveButtons extends StatelessWidget {
  const AddRemoveButtons({
    super.key,
    required this.onAdd,
    required this.removing,
    required this.onToggleRemove,
    this.canRemove = true,
    this.addTooltip = 'Add',
    this.removeTooltip = 'Remove',
  });

  final VoidCallback? onAdd;
  final bool removing;
  final VoidCallback onToggleRemove;

  /// False hides − while the list is empty.
  final bool canRemove;
  final String addTooltip;
  final String removeTooltip;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlineIconButton(
          icon: PhosphorIconsRegular.plus,
          tooltip: addTooltip,
          onPressed: onAdd,
        ),
        if (canRemove || removing)
          OutlineIconButton(
            icon: removing
                ? PhosphorIconsRegular.check
                : PhosphorIconsRegular.minus,
            color: removing ? null : context.vesta.neg,
            tooltip: removing ? 'Done' : removeTooltip,
            onPressed: onToggleRemove,
          ),
      ],
    );
  }
}

/// Red minus at the start of a row while its list is in remove mode.
class RemoveBadge extends StatelessWidget {
  const RemoveBadge({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final neg = context.vesta.neg;
    return Material(
      color: neg.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 26,
          height: 26,
          child: Icon(PhosphorIconsRegular.minus, size: 14, color: neg),
        ),
      ),
    );
  }
}

/// Small outlined text button for app bar actions (the prototype's
/// "Manage" button).
class HeaderButton extends StatelessWidget {
  const HeaderButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ink = context.vesta.accentInk;
    return Padding(
      padding: const EdgeInsets.only(right: VestaSpace.xs),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: ink),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VestaRadius.md),
          ),
          textStyle: const TextStyle(fontFamily: bodyFont, fontSize: 13),
        ),
        child: Text(label),
      ),
    );
  }
}

final NumberFormat _money = NumberFormat('#,##0.00', 'en_US');

/// Formats an amount the way the prototype does: "JOD 1,234.50", and
/// "-JOD 5.75" for negatives.
String formatMoney(num amount, {String currency = 'JOD', bool showPlus = false}) {
  final sign = amount < 0 ? '-' : (showPlus && amount > 0 ? '+' : '');
  return '$sign$currency ${_money.format(amount.abs())}';
}

/// An amount in Poppins Medium with fixed-width digits.
/// [MoneyText.hero] is the big balance: small muted currency, large number.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.currency = 'JOD',
    this.size = 14,
    this.color,
    this.showPlus = false,
  }) : hero = false;

  const MoneyText.hero(
    this.amount, {
    super.key,
    this.currency = 'JOD',
    this.size = 42,
    this.color,
  }) : hero = true,
       showPlus = false;

  final num amount;
  final String currency;
  final double size;
  final Color? color;
  final bool showPlus;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    if (!hero) {
      return Text(
        formatMoney(amount, currency: currency, showPlus: showPlus),
        style: amountStyle(size, color: color),
        maxLines: 1,
      );
    }
    final sign = amount < 0 ? '-' : '';
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '$sign$currency',
            style: TextStyle(fontSize: size * 0.38, color: context.vesta.muted),
          ),
          const SizedBox(width: VestaSpace.sm),
          Text(
            _money.format(amount.abs()),
            style: amountStyle(size, color: color).copyWith(
              height: 1.05,
              letterSpacing: -size * 0.025,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded progress bar. [marker] draws a thin vertical line at that fraction
/// (the prototype's "even pace" line).
class VestaProgressBar extends StatelessWidget {
  const VestaProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 6,
    this.marker,
  });

  final double value;
  final Color? color;
  final double height;
  final double? marker;

  @override
  Widget build(BuildContext context) {
    final fill = color ?? Theme.of(context).colorScheme.primary;
    final radius = BorderRadius.circular(height / 2);
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.vesta.track,
                    borderRadius: radius,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: w * value.clamp(0.0, 1.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: fill, borderRadius: radius),
                ),
              ),
              if (marker != null)
                Positioned(
                  left: (w * marker!.clamp(0.0, 1.0)) - 1,
                  top: -4,
                  bottom: -4,
                  width: 2,
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Icon on a raised background: a circle for transactions, a rounded square
/// for categories.
class IconBadge extends StatelessWidget {
  const IconBadge(
    this.icon, {
    super.key,
    this.color,
    this.size = 36,
    this.circle = true,
  });

  final IconData icon;
  final Color? color;
  final double size;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.vesta.raised,
        borderRadius: BorderRadius.circular(circle ? size / 2 : 12),
      ),
      child: Icon(icon, size: size * 0.46, color: color),
    );
  }
}

// Monogram and brand colour per Jordanian bank, from the prototype's bank
// list. Matched against the account name in order, so longer names go first.
const List<(String, String, Color)> _banks = [
  ('arab jordan investment', 'AJ', Color(0xFF3C4A8F)),
  ('ajib', 'AJ', Color(0xFF3C4A8F)),
  ('arab bank', 'AB', Color(0xFF1F6F5C)),
  ('housing bank', 'HB', Color(0xFF2A5EA8)),
  ('hbtf', 'HB', Color(0xFF2A5EA8)),
  ('etihad', 'BE', Color(0xFF6B3FA0)),
  ('cairo amman', 'CA', Color(0xFFB0472D)),
  ('capital bank', 'CB', Color(0xFF1D3557)),
  ('jordan kuwait', 'JK', Color(0xFF00707A)),
  ('ahli', 'JA', Color(0xFF8A2B45)),
  ('bank of jordan', 'BJ', Color(0xFF7A5A12)),
  ('jordan islamic', 'JI', Color(0xFF2F7A3A)),
  ('safwa', 'SW', Color(0xFF4B6B2A)),
  ('investbank', 'IB', Color(0xFFA03030)),
  ('jordan commercial', 'JC', Color(0xFF2B5F8A)),
  ('société générale', 'SG', Color(0xFF9A2632)),
  ('societe generale', 'SG', Color(0xFF9A2632)),
  ('bank abc', 'BA', Color(0xFF5A3D7A)),
];

/// Banks operating in Jordan, for pickers (onboarding, adding an account).
const jordanBanks = [
  'Arab Bank',
  'Housing Bank',
  'Bank al Etihad',
  'Capital Bank',
  'Cairo Amman Bank',
  'Jordan Ahli Bank',
  'Jordan Kuwait Bank',
  'Bank of Jordan',
  'Jordan Islamic Bank',
  'Safwa Islamic Bank',
  'Arab Jordan Investment Bank',
  'Investbank',
  'Jordan Commercial Bank',
  'Société Générale de Banque – Jordanie',
  'Bank ABC',
];

/// Rounded square with an account's monogram: the bank's own colour for
/// known Jordanian banks, otherwise the name's initials on the accent.
class BankBadge extends StatelessWidget {
  const BankBadge(this.name, {super.key, this.size = 36});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final lower = name.toLowerCase();
    String? mono;
    Color? color;
    for (final (key, m, c) in _banks) {
      if (lower.contains(key)) {
        mono = m;
        color = c;
        break;
      }
    }
    if (mono == null) {
      final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
      mono = words.length > 1
          ? words.take(2).map((w) => w[0]).join()
          : name.trim().padRight(2).substring(0, 2).trim();
      mono = mono.toUpperCase();
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        mono,
        style: headingStyle(13, color: Colors.white).copyWith(
          fontVariations: const [FontVariation('wght', 600)],
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// One row of a list: leading widget, title with optional subtitle (or any
/// widget below it), trailing widget.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.below,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.titleColor,
    this.padding = const EdgeInsets.symmetric(vertical: VestaSpace.sm),
  });

  final String title;
  final Widget? leading;
  final String? subtitle;
  final Widget? below;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? titleColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: VestaSpace.md)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: titleColor),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (below != null) ...[const SizedBox(height: VestaSpace.xs), below!],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: VestaSpace.sm), trailing!],
          ],
        ),
      ),
    );
  }
}

/// Small label. The default is outlined in [color] (category types such as
/// "Necessity"); [TagChip.pill] is a rounded wash (shared tags, "Coming soon").
class TagChip extends StatelessWidget {
  const TagChip(this.label, {super.key, required Color this.color})
    : pill = false,
      icon = null;

  const TagChip.pill(this.label, {super.key, this.icon, this.color})
    : pill = true;

  final String label;
  final Color? color;
  final IconData? icon;
  final bool pill;

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final fg = color ?? v.accentInk;
    if (!pill) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
        decoration: BoxDecoration(
          border: Border.all(color: fg),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color == null ? v.accentWash : v.raised,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: VestaSpace.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, height: 1.2, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill for picking one option (date filters, categories): tinted with an
/// accent outline when selected, a plain outline otherwise.
class ChoiceTag extends StatelessWidget {
  const ChoiceTag({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? v.tintText : scheme.onSurface;
    final shape = StadiumBorder(
      side: BorderSide(color: selected ? scheme.primary : v.divider),
    );
    return Material(
      color: selected ? v.tint : Colors.transparent,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: 6),
              ],
              Text(label, style: TextStyle(fontSize: 13, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// One slice of a card that a lazy list builds row by row: rounded corners
/// on the first and last slices, and a hairline above every slice but the
/// first when [divider] is set.
class CardSegment extends StatelessWidget {
  const CardSegment({
    super.key,
    required this.child,
    this.first = false,
    this.last = false,
    this.divider = false,
  });

  final Widget child;
  final bool first;
  final bool last;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    const r = Radius.circular(VestaRadius.card);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.vertical(
          top: first ? r : Radius.zero,
          bottom: last ? r : Radius.zero,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        VestaSpace.lg,
        0,
        VestaSpace.lg,
        last ? 6 : 0,
      ),
      child: divider
          ? DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: context.vesta.divider)),
              ),
              child: child,
            )
          : child,
    );
  }
}

/// Icon for a category name, by keyword, so user-made categories get a
/// sensible icon too.
IconData categoryIcon(String? name) {
  final n = (name ?? '').toLowerCase();
  bool has(String s) => n.contains(s);
  if (n.isEmpty) return PhosphorIconsRegular.tag;
  if (has('grocer') || has('supermarket')) return PhosphorIconsRegular.shoppingCart;
  if (has('food') || has('drink') || has('restaurant') || has('dining') || has('coffee')) {
    return PhosphorIconsRegular.forkKnife;
  }
  if (has('entertain') || has('cinema') || has('fun') || has('game')) {
    return PhosphorIconsRegular.popcorn;
  }
  if (has('saving')) return PhosphorIconsRegular.piggyBank;
  if (has('salary') || has('income') || has('payroll') || has('wage')) {
    return PhosphorIconsRegular.briefcase;
  }
  if (has('subscri') || has('netflix') || has('spotify')) return PhosphorIconsRegular.repeat;
  if (has('transport') || has('taxi') || has('bus') || has('ride')) return PhosphorIconsRegular.bus;
  if (has('fuel') || has('gas') || RegExp(r'\bcar\b').hasMatch(n)) {
    return PhosphorIconsRegular.gasPump;
  }
  if (has('bill') || has('electric') || has('water') || has('internet') || has('utilit')) {
    return PhosphorIconsRegular.lightning;
  }
  if (has('health') || has('pharm') || has('medic') || has('doctor')) {
    return PhosphorIconsRegular.heartbeat;
  }
  if (has('rent') || has('home') || has('house')) return PhosphorIconsRegular.houseLine;
  if (has('travel') || has('flight')) return PhosphorIconsRegular.airplaneTilt;
  if (has('shop') || has('cloth')) return PhosphorIconsRegular.shoppingBag;
  if (has('gift')) return PhosphorIconsRegular.gift;
  if (has('educat') || has('school') || has('universit')) {
    return PhosphorIconsRegular.graduationCap;
  }
  return PhosphorIconsRegular.tag;
}

/// Label and colour for a category's budget bucket, as the app stores it
/// ('essential', 'luxury', 'savings', 'income').
({String label, Color color}) bucketStyle(String bucket, VestaColors v) {
  switch (bucket) {
    case 'essential':
      return (label: 'Necessity', color: v.bucketEssential);
    case 'luxury':
      return (label: 'Luxury', color: v.bucketLuxury);
    case 'savings':
      return (label: 'Savings', color: v.bucketSavings);
    case 'income':
      return (label: 'Income', color: v.pos);
    default:
      return (label: bucket.isEmpty ? 'Other' : bucket, color: v.muted);
  }
}

const _monthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Today", "Yesterday", "Oct 19", or "Oct 19, 2025" outside this year.
String shortDateLabel(DateTime dt) {
  if (dt.millisecondsSinceEpoch == 0) return '—';
  final now = DateTime.now();
  final day = DateTime(dt.year, dt.month, dt.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  final base = '${_monthAbbr[dt.month - 1]} ${dt.day}';
  return dt.year == now.year ? base : '$base, ${dt.year}';
}

/// Rounds a chart's top value up to a tidy number with a tidy midpoint.
double niceChartTop(double maxY) {
  if (maxY <= 0) return 100;
  final half = maxY / 2;
  final mag = math.pow(10, (math.log(half) / math.ln10).floor()).toDouble();
  for (final m in [1, 1.5, 2, 2.5, 3, 5, 10]) {
    if (m * mag >= half) return m * mag * 2;
  }
  return 20 * mag;
}

/// Short axis label: 1500 -> "1.5k", 2 -> "2", 1.5 -> "1.5".
String compactAmount(double value) {
  if (value >= 1000) {
    final k = value / 1000;
    return '${k == k.roundToDouble() ? k.toStringAsFixed(0) : k.toStringAsFixed(1)}k';
  }
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

/// Settings row with an icon, label, optional description and a switch.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.icon,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 19, color: context.vesta.accentInk),
            const SizedBox(width: VestaSpace.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                if (subtitle != null)
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Full-width primary action: accent outline on an accent wash.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}

/// Full-width secondary action: plain outline.
class OutlineButton extends StatelessWidget {
  const OutlineButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

/// Full-width destructive action: red-tinted fill with a red outline, as on
/// the prototype's "Yes" in a delete confirmation.
class DangerButton extends StatelessWidget {
  const DangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final neg = context.vesta.neg;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: neg.withValues(alpha: 0.16),
          foregroundColor: neg,
          side: BorderSide(color: neg),
        ),
        child: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: neg),
              )
            : Text(label),
      ),
    );
  }
}

/// The prototype's dialog, used instead of Material's AlertDialog everywhere.
/// With an [icon] it is a confirmation: the icon in a tinted circle above a
/// centred title and message. Without one it is a form: a title with a close
/// button above [content]. Either way Cancel and the action sit side by side.
class VestaDialog extends StatelessWidget {
  const VestaDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.icon,
    this.iconColor,
    this.cancelLabel = 'Cancel',
    this.onCancel,
    this.confirmLabel,
    this.onConfirm,
    this.destructive = false,
    this.loading = false,
  });

  final String title;
  final String? message;
  final Widget? content;
  final IconData? icon;

  /// Defaults to red for [destructive] dialogs, else the accent.
  final Color? iconColor;

  /// Null hides Cancel (and the close button on forms).
  final String? cancelLabel;

  /// Defaults to closing the dialog.
  final VoidCallback? onCancel;

  /// Null hides the action button.
  final String? confirmLabel;
  final VoidCallback? onConfirm;

  /// A red action, for deleting or leaving.
  final bool destructive;

  /// Spinner on the action and both buttons disabled while work runs.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final confirmation = icon != null;
    final cancel = loading
        ? null
        : (onCancel ?? () => Navigator.of(context).pop());
    final tint = iconColor ?? (destructive ? v.neg : v.accentInk);

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VestaRadius.sheet),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: confirmation
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.stretch,
          children: [
            if (confirmation) ...[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tint.withValues(alpha: 0.16),
                ),
                child: Icon(icon, size: 24, color: tint),
              ),
              const SizedBox(height: 14),
              Text(title, textAlign: TextAlign.center, style: headingStyle(18)),
            ] else
              Row(
                children: [
                  Expanded(child: Text(title, style: headingStyle(18))),
                  if (cancelLabel != null)
                    IconButton(
                      tooltip: 'Close',
                      onPressed: cancel,
                      icon: Icon(PhosphorIconsRegular.x, color: v.muted),
                    ),
                ],
              ),
            if (message != null) ...[
              const SizedBox(height: VestaSpace.sm),
              Text(
                message!,
                textAlign: confirmation ? TextAlign.center : TextAlign.start,
                style: TextStyle(fontSize: 14, color: v.muted),
              ),
            ],
            if (content != null) ...[
              const SizedBox(height: VestaSpace.lg),
              Flexible(child: SingleChildScrollView(child: content)),
            ],
            if (cancelLabel != null || confirmLabel != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  if (cancelLabel != null)
                    Expanded(
                      child: OutlineButton(label: cancelLabel!, onPressed: cancel),
                    ),
                  if (cancelLabel != null && confirmLabel != null)
                    const SizedBox(width: 10),
                  if (confirmLabel != null)
                    Expanded(
                      child: destructive
                          ? DangerButton(
                              label: confirmLabel!,
                              onPressed: onConfirm,
                              loading: loading,
                            )
                          : PrimaryButton(
                              label: confirmLabel!,
                              onPressed: onConfirm,
                              loading: loading,
                            ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Asks a yes/no question in the prototype's confirmation style. True only
/// when the action was chosen.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = 'Yes',
  String cancelLabel = 'Cancel',
  bool destructive = true,
  IconData? icon,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => VestaDialog(
      icon:
          icon ??
          (destructive
              ? PhosphorIconsRegular.trash
              : PhosphorIconsRegular.question),
      title: title,
      message: message,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
      destructive: destructive,
      onCancel: () => Navigator.pop(ctx, false),
      onConfirm: () => Navigator.pop(ctx, true),
    ),
  );
  return ok == true;
}

enum PixelArt { budget, spend, save, shared }

// The prototype's pixel icons on a 32x32 grid, in its own compact form:
// every 4 characters are one pixel, x and y in base 36, a palette key and a
// shade (k, d and m darken; l and w lighten; anything else is plain).
const Map<PixelArt, String> _pixelData = {
  PixelArt.budget:
    'h2Bdi2Bdj2Bdk2Bdh3Bdi3Blj3Bbk3Bbl3Bdm3Bdn3Bdh4Bdi4Blj4Bbk4Bbl4Bb'
    'm4Bbn4Bbo4Bka5Adb5Adc5Add5Ade5Adh5Bdi5Blj5Bbk5Bbl5Bbm5Bbn5Bbo5Bm'
    'p5Bk86Ad96Ada6Awb6Awc6Ald6Ale6Adh6Bdi6Blj6Bbk6Bbl6Bbm6Bbn6Bbo6Bm'
    'p6Bmq6Bk77Ad87Aw97Awa7Awb7Awc7Ald7Ale7Adh7Bdi7Bbj7Bbk7Bbl7Bbm7Bb'
    'n7Bbo7Bmp7Bmq7Bmr7Bk68Ad78Aw88Aw98Awa8Awb8Awc8Ald8Ale8Adh8Bdi8Bb'
    'j8Bbk8Bbl8Bbm8Bbn8Bmo8Bmp8Bmq8Bmr8Bds8Bk59Ad69Aw79Aw89Aw99Awa9Aw'
    'b9Alc9Ald9Ale9Adh9Bdi9Bbj9Bbk9Bbl9Bbm9Bbn9Bmo9Bmp9Bmq9Bmr9Bds9Bk'
    '4aAd5aAw6aAw7aAw8aAw9aAwaaAlbaAlcaAldaAleaAdhaBdiaBbjaBbkaBblaBb'
    'maBmnaBmoaBmpaBmqaBdraBdsaBdtaBk3bAd4bAw5bAw6bAw7bAw8bAw9bAwabAl'
    'bbAlcbAldbAlebAdhbBdibBbjbBbkbBblbBbmbBmnbBmobBmpbBmqbBdrbBdsbBd'
    'tbBk3cAd4cAw5cAw6cAw7cAw8cAl9cAlacAlbcAlccAldcAlecAdhcBdicBbjcBb'
    'kcBblcBmmcBmncBmocBmpcBmqcBdrcBdscBktcBk3dAd4dAl5dAw6dAl7dAl8dAl'
    '9dAladAlbdAlcdAlddAbedAdhdBdidBbjdBbkdBmldBmmdBmndBmodBmpdBdqdBd'
    'rdBdsdBktdBk2eAd3eAl4eAl5eAl6eAl7eAl8eAl9eAlaeAlbeAlceAbdeAbeeAd'
    'heBdieBdjeBdkeBkleBkmeBkneBkoeBkpeBkqeBkreBkseBkteBk2fAd3fAl4fAl'
    '5fAl6fAl7fAl8fAl9fAlafAlbfAbcfAbdfAbefAd2gAd3gAl4gAl5gAl6gAl7gAl'
    '8gAl9gAlagAbbgAbcgAbdgAbegAd2hAd3hAl4hAl5hAl6hAl7hAb8hAb9hAbahAb'
    'bhAbchAbdhAbehAbfhAdghAdhhAkihAkjhAkkhAklhAkmhAknhAkohAkphAkqhAk'
    'rhAk2iAd3iAb4iAb5iAb6iAb7iAb8iAb9iAbaiAbbiAbciAbdiAbeiAmfiCmgiCd'
    'hiCdiiCdjiCdkiCdliCkmiCkniCkoiCkpiCkqiCkriCk2jAd3jAb4jAb5jAb6jAb'
    '7jAb8jAb9jAbajAbbjAbcjAbdjAmejCdfjCmgjCmhjCmijCmjjCmkjCdljCdmjCd'
    'njCkojCkpjCkqjCkrjCk2kAd3kAb4kAb5kAb6kAb7kAb8kAb9kAbakAbbkAbckAb'
    'dkAdekCdfkCmgkCmhkCmikCmjkCdkkCdlkCdmkCdnkCkokCkpkCkqkCkrkCk3lAd'
    '4lAb5lAb6lAb7lAb8lAb9lAbalAbblAmclAddlCdelCmflCmglCmhlCmilCdjlCd'
    'klCdllCdmlCknlCkolCkplCkqlCk3mAd4mAb5mAb6mAb7mAb8mAb9mAmamAmbmAm'
    'cmAddmCdemCmfmCmgmCmhmCdimCdjmCdkmCdlmCkmmCknmCkomCkpmCkqmCk3nAk'
    '4nAm5nAm6nAm7nAm8nAm9nAmanAmbnAmcnAddnCdenCmfnCdgnCdhnCdinCdjnCd'
    'knCklnCkmnCknnCkonCkpnCkqnCk4oAk5oAm6oAm7oAm8oAm9oAmaoAmboAdcoCd'
    'doCmeoCdfoCdgoCdhoCdioCdjoCkkoCkloCkmoCknoCkooCkpoCk5pAk6pAm7pAm'
    '8pAm9pAmapAmbpAkcpCkdpCdepCdfpCdgpCdhpCkipCkjpCkkpCklpCkmpCknpCk'
    'opCk6qAk7qAd8qAd9qAdaqAkbqCkcqCddqCdeqCdfqCdgqCkhqCkiqCkjqCkkqCk'
    'lqCkmqCknqCk7rAk8rAd9rAdarAkbrCkcrCddrCderCkfrCkgrCkhrCkirCkjrCk'
    'krCklrCkmrCk8sAk9sAkasAkbsCkcsCkdsCkesCkfsCkgsCkhsCkisCkjsCkksCk'
    'lsCkatCkbtCkctCkdtCketCkftCkgtCkhtCkitCkjtCk',
  PixelArt.spend:
    '47Ad57Ad67Ad77Ad87Ad97Ada7Adb7Adc7Add7Ade7Adf7Adg7Adh7Adi7Adj7Ad'
    'k7Adl7Adm7Adn7Ado7Adp7Adq7Adr7Ad38Ad48Al58Al68Al78Al88Al98Ala8Al'
    'b8Alc8Ald8Ale8Abf8Abg8Abh8Abi8Abj8Abk8Abl8Abm8Abn8Abo8Abp8Abq8Ab'
    'r8Abs8Ad29Ad39Al49Al59Al69Al79Al89Al99Ala9Alb9Alc9Ald9Abe9Abf9Ab'
    'g9Abh9Abi9Abj9Abk9Abl9Abm9Abn9Abo9Abp9Abq9Abr9Abs9Abt9Ad2aSd3aSb'
    '4aSb5aSb6aSb7aSm8aSm9aSmaaSmbaSmcaSmdaSmeaSmfaSmgaSmhaSmiaSmjaSm'
    'kaSmlaSmmaSmnaSmoaSmpaSmqaSmraSmsaSmtaSk2bSd3bSb4bSb5bSb6bSb7bSm'
    '8bSm9bSmabSmbbSmcbSmdbSmebSmfbSmgbSmhbSmibSmjbSmkbSmlbSmmbSmnbSm'
    'obSmpbSmqbSmrbSmsbSmtbSk2cSd3cSb4cSb5cSb6cSb7cSm8cSm9cSmacSmbcSm'
    'ccSmdcSmecSmfcSmgcSmhcSmicSmjcSmkcSmlcSmmcSmncSmocSmpcSmqcSmrcSm'
    'scSmtcSk2dAd3dAl4dAl5dAl6dAl7dAb8dAb9dAbadAbbdAbcdAbddAbedAbfdAb'
    'gdAbhdAbidAbjdAbkdAbldAbmdAbndAbodAbpdAbqdAbrdAmsdAmtdAk2eAd3eAl'
    '4eAl5eAb6eAb7eAb8eAb9eAbaeAbbeAbceAbdeAbeeAbfeAbgeAbheAbieAbjeAb'
    'keAbleAbmeAbneAboeAbpeAmqeAmreAmseAmteAk2fAd3fAl4fAb5fPl6fPl7fPm'
    '8fPb9fPbafPbbfAbcfAbdfAbefAbffAbgfAbhfAbifAbjfAbkfAblfAbmfAbnfAw'
    'ofAlpfAlqfAmrfAmsfAmtfAk2gAd3gAb4gAb5gPl6gPb7gPm8gPb9gPbagPbbgAb'
    'cgAbdgAbegAbfgAbggAbhgAbigAbjgAbkgAblgAbmgAwngAwogAlpgAlqgAlrgAm'
    'sgAmtgAk2hAd3hAb4hAb5hPm6hPm7hPd8hPd9hPdahPdbhAbchAbdhAbehAbfhAb'
    'ghAbhhAbihAbjhAbkhAblhAmmhAwnhAwohAlphAlqhAlrhAmshAmthAk2iAd3iAb'
    '4iAb5iPb6iPb7iPd8iPm9iPmaiPmbiAbciAbdiAbeiAbfiAbgiAbhiAbiiAbjiAm'
    'kiAmliAmmiAwniAwoiAlpiAlqiAlriAmsiAmtiAk2jAd3jAb4jAb5jPb6jPm7jPd'
    '8jPm9jPmajPmbjAbcjAbdjAbejAbfjAbgjAbhjAbijAmjjAmkjAmljAmmjAmnjAw'
    'ojAlpjAlqjAmrjAmsjAmtjAk2kAd3kAb4kAb5kAb6kAb7kAb8kAb9kAbakAbbkAb'
    'ckAbdkAbekAbfkAbgkAmhkAmikAmjkAmkkAmlkAmmkAmnkAmokAmpkAmqkAmrkAm'
    'skAmtkAk2lAd3lAb4lAb5lAb6lAb7lAb8lAb9lAbalAbblAbclAbdlAbelAbflAm'
    'glAmhlAmilAmjlAmklAmllAmmlAmnlAmolAmplAmqlAmrlAmslAmtlAk2mAd3mAb'
    '4mAb5mAw6mAw7mAb8mAw9mAwamAbbmAwcmAwdmAmemAwfmAwgmAmhmAmimAwjmAw'
    'kmAmlmAmmmAmnmAmomAmpmAmqmAmrmAmsmAmtmAk2nAd3nAb4nAb5nAb6nAb7nAb'
    '8nAb9nAbanAbbnAbcnAmdnAmenAmfnAmgnAmhnAminAmjnAmknAmlnAmmnAmnnAm'
    'onAmpnAmqnAmrnAmsnAmtnAk3oAd4oAb5oAb6oAb7oAb8oAb9oAbaoAmboAmcoAm'
    'doAmeoAmfoAmgoAmhoAmioAmjoAmkoAmloAmmoAmnoAmooAmpoAmqoAmroAmsoAk'
    '4pAd5pAd6pAd7pAd8pAd9pAkapAkbpAkcpAkdpAkepAkfpAkgpAkhpAkipAkjpAk'
    'kpAklpAkmpAknpAkopAkppAkqpAkrpAk',
  PixelArt.save:
    'e1Pdf1Pdg1Pdh1Pkd2Pde2Pwf2Plg2Pbh2Pbi2Pkd3Pde3Plf3Pmg3Pmh3Pmi3Pk'
    'c4Pdd4Ple4Pbf4Pmg4Pmh4Pmi4Pkj4Pkd5Pde5Pbf5Pmg5Pmh5Pdi5Pkd6Pke6Pm'
    'f6Pdg6Pkh6Pki6Pke7Pmf7Pdg7Pdh7Pdj7Adk7Adl7Adm7Aki8Adj8Awk8All8Ab'
    'm8Amn8Akc9Add9Ade9Adf9Adg9Adh9Adi9Abj9Alk9Abl9Amm9Adn9Ak9aAdaaAd'
    'baAdcaAldaEmeaEmfaEmgaEmhaEmiaEmjaAbkaAmlaAmmaAknaAk7bAd8bAd9bAw'
    'abAwbbAwcbAwdbAlebAlfbAlgbAlhbAbibAbjbAbkbAblbAmmbAmnbAk6cAd7cAw'
    '8cAw9cAwacAwbcAwccAwdcAlecAlfcAlgcAbhcAbicAbjcAbkcAblcAmmcAmncAd'
    'ocAk5dAd6dAw7dAw8dAw9dAwadAwbdAwcdAlddAledAlfdAlgdAbhdAbidAbjdAb'
    'kdAmldAmmdAmndAdodAdpdAk1eAk4eAd5eAl6eAw7eAw8eAw9eAwaeAwbeAlceAl'
    'deAleeAlfeAbgeAbheAbieAbjeAbkeAmleAmmeAmneAdoeEwpeEbqeAkreNd2fAk'
    '4fAd5fAl6fAl7fAw8fAw9fAlafAlbfAlcfAldfAlefAbffAbgfAbhfAbifAbjfAm'
    'kfAmlfAmmfAmnfAdofEbpfEbqfNbrfNbsfNdtfNk2gAk4gAd5gAl6gAl7gAl8gAl'
    '9gAlagAlbgAlcgAldgAbegAbfgAbggAbhgAbigAmjgAmkgAmlgAmmgAdngAdogAk'
    'pgNbqgNlrgNdsgNmtgNk4hAd5hAl6hAl7hAl8hAl9hAlahAlbhAbchAbdhAbehAb'
    'fhAbghAbhhAmihAmjhAmkhAmlhAdmhAdnhAdohAkphNmqhNbrhNbshNmthNk4iAd'
    '5iAb6iAb7iAb8iAb9iAbaiAbbiAbciAbdiAbeiAbfiAbgiAmhiAmiiAmjiAmkiAd'
    'liAdmiAdniAkoiAkpiNdqiNmriNdsiNdtiNk4jAd5jAb6jAb7jAb8jAb9jAbajAb'
    'bjAbcjAbdjAbejAmfjAmgjAmhjAmijAmjjAdkjAdljAdmjAknjAkojAkpjNkqjNk'
    'rjNksjNktjNk4kAk5kAb6kAb7kAb8kAb9kAbakAbbkAbckAmdkAmekAmfkAmgkAm'
    'hkAmikAdjkAdkkAdlkAkmkAknkAkokAkpkAkqkAkrkNk4lAk5lAm6lAm7lAm8lAm'
    '9lAmalAmblAmclAmdlAmelAmflAmglAdhlAdilAdjlAdklAkllAkmlAknlAkolAk'
    'plAkqlAk5mAk6mAm7mAm8mAm9mAmamAmbmAmcmAmdmAmemAdfmAdgmAdhmAdimAk'
    'jmAkkmAklmAkmmAknmAkomAkpmAk6nAk7nAd8nAd9nAdanAdbnAdcnAddnAdenAd'
    'fnAdgnAkhnAkinAkjnAkknAklnAkmnAknnAkonAk7oAk8oAd9oAdaoAdboAdcoAk'
    'doAkeoAkfoAkgoAkhoAkioAkjoAkkoAkloAkmoAknoAk8pAd9pAkapAkbpAkcpAk'
    'dpAkepAkfpAkgpAkhpAkipAkjpAkkpAklpAkmpAk8qAd9qAmaqAmbqAmcqAkdqAk'
    'eqAkfqAkgqAkhqAkiqAkjqAbkqAmlqAmmqAk8rAk9rAmarAmbrAkjrAkkrAmlrAm'
    'mrAk8sAk9sAdasAdbsAkjsAkksAdlsAdmsAk8tAk9tAkatAkbtAkjtAkktAkltAk'
    'mtAk',
  PixelArt.shared:
    'a3Adb3Ad84Ad94Ada4Alb4Abc4Add4Ak75Ad85Aw95Awa5Alb5Abc5Abd5Ame5Ak'
    '66Ad76Aw86Aw96Ala6Alb6Abc6Abd6Ame6Adf6Akk6Bdl6Bdm6Bdn6Bd67Ad77Al'
    '87Al97Ala7Abb7Abc7Amd7Ame7Adf7Aki7Bdj7Bdk7Bwl7Blm7Bbn7Bbo7Bkp7Bk'
    '68Ad78Al88Ab98Aba8Abb8Abc8Amd8Ade8Akf8Aki8Bdj8Bwk8Bwl8Blm8Bbn8Bb'
    'o8Bmp8Bk69Ad79Ab89Ab99Aba9Amb9Amc9Add9Ade9Akf9Akh9Bdi9Bwj9Blk9Bl'
    'l9Blm9Bbn9Bbo9Bmp9Bdq9Bk6aAk7aAm8aAm9aAmaaAmbaAdcaAddaAkeaAkfaAk'
    'haBdiaBljaBlkaBblaBbmaBbnaBmoaBmpaBdqaBk7bAk8bAm9bAdabAdbbAkcbAk'
    'dbAkebAkhbBdibBbjbBbkbBblbBbmbBmnbBmobBdpbBkqbBk8cAk9cAkacAkbcAk'
    'ccAkdcAkhcBkicBbjcBbkcBmlcBmmcBmncBdocBkpcBkqcBkadAkbdAkidBkjdBm'
    'kdBmldBdmdBdndBkodBkpdBkieBkjeBkkeBdleBkmeBkneBkoeBkpeBkkfBklfBk'
    'mfBknfBk8hAd9hAdahAdbhAdchAddhAk6iAd7iAd8iAl9iAlaiAlbiAbciAbdiAb'
    'eiAkfiAk5jAd6jAw7jAw8jAw9jAlajAlbjAlcjAbdjAbejAbfjAmgjAkjjBdkjBd'
    'ljBdmjBdnjBdojBk4kAd5kAw6kAw7kAw8kAw9kAlakAlbkAlckAbdkAbekAbfkAm'
    'gkAdhkBdikBdjkBlkkBllkBlmkBbnkBbokBbpkBkqkBk4lAd5lAw6lAw7lAw8lAw'
    '9lAlalAlblAlclAbdlAbelAbflAdglBbhlBwilBwjlBwklBlllBlmlBlnlBbolBb'
    'plBbqlBmrlBk3mAd4mAw5mAw6mAw7mAw8mAw9mAlamAlbmAlcmAbdmAbemAmfmBb'
    'gmBwhmBwimBwjmBwkmBllmBlmmBlnmBbomBbpmBbqmBmrmBmsmBk3nAd4nAw5nAw'
    '6nAw7nAw8nAl9nAlanAlbnAbcnAbdnAbenAmfnBlgnBwhnBwinBwjnBwknBllnBl'
    'mnBlnnBbonBbpnBbqnBmrnBmsnBk2oAd3oAw4oAw5oAw6oAw7oAl8oAl9oAlaoAl'
    'boAbcoAbdoAmeoBbfoBwgoBwhoBwioBwjoBlkoBlloBlmoBbnoBbooBbpoBbqoBm'
    'roBmsoBdtoBk2pAd3pAl4pAw5pAw6pAl7pAl8pAl9pAlapAbbpAbcpAbdpAmepBb'
    'fpBwgpBwhpBwipBwjpBlkpBllpBlmpBbnpBbopBbppBmqpBmrpBmspBdtpBk2qAd'
    '3qAl4qAl5qAl6qAl7qAl8qAl9qAbaqAbbqAbcqAmdqBmeqBlfqBwgqBwhqBwiqBl'
    'jqBlkqBllqBbmqBbnqBboqBbpqBmqqBmrqBdsqBdtqBkuqBk2rAd3rAl4rAl5rAl'
    '6rAl7rAl8rAb9rAbarAbbrAbcrAmdrBberBlfrBlgrBlhrBlirBljrBlkrBllrBb'
    'mrBbnrBborBbprBmqrBmrrBdsrBdtrBkurBk2sAd3sAl4sAl5sAl6sAl7sAb8sAb'
    '9sAbasAbbsAbcsAddsBmesBlfsBlgsBlhsBlisBljsBlksBblsBbmsBbnsBbosBm'
    'psBmqsBmrsBdssBktsBkusBk2tAd3tAb4tAb5tAb6tAb7tAb8tAb9tAbatAbbtAb'
    'ctAddtBmetBlftBlgtBlhtBlitBbjtBbktBbltBbmtBbntBmotBmptBmqtBdrtBd'
    'stBkttBkutBk2uAd3uAd4uAd5uAd6uAd7uAd8uAd9uAdauAdbuAkcuAkduBdeuBd'
    'fuBdguBdhuBdiuBdjuBdkuBdluBdmuBdnuBkouBkpuBkquBkruBksuBktuBkuuBk',
};

/// Each icon's palette keys, mapped to the theme's pixel colours.
const Map<PixelArt, Map<String, String>> _pixelKeys = {
  PixelArt.budget: {'A': 'blue', 'B': 'yellow', 'C': 'teal'},
  PixelArt.spend: {'A': 'blue', 'S': 'ink', 'P': 'yellow'},
  PixelArt.save: {'A': 'green', 'P': 'yellow', 'N': 'green', 'E': 'ink'},
  PixelArt.shared: {'A': 'teal', 'B': 'blue'},
};

/// Shades as (mix with white?, amount), like the prototype's color-mix.
const Map<String, (bool, double)> _pixelShades = {
  'k': (false, 0.55),
  'd': (false, 0.35),
  'm': (false, 0.17),
  'l': (true, 0.28),
  'w': (true, 0.55),
};

Color _pixelColor(String name, VestaColors v) => switch (name) {
  'blue' => v.pxBlue,
  'yellow' => v.pxYellow,
  'green' => v.pxGreen,
  'teal' => v.pxTeal,
  'purple' => v.pxPurple,
  _ => v.pxInk,
};

/// The icon's pixels in this theme's colours.
List<(int, int, Color)> _pixels(PixelArt art, VestaColors v) {
  final s = _pixelData[art]!;
  final keys = _pixelKeys[art]!;
  return [
    for (var i = 0; i + 3 < s.length; i += 4)
      () {
        final base = _pixelColor(keys[s[i + 2]] ?? '', v);
        final shade = _pixelShades[s[i + 3]];
        return (
          int.parse(s[i], radix: 36),
          int.parse(s[i + 1], radix: 36),
          shade == null
              ? base
              : Color.lerp(
                  base,
                  shade.$1 ? Colors.white : Colors.black,
                  shade.$2,
                )!,
        );
      }(),
  ];
}

/// One of the prototype's pixel-art icons, drawn with crisp edges.
class PixelIcon extends StatelessWidget {
  const PixelIcon(this.art, {super.key, this.size = 44});

  final PixelArt art;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _PixelPainter(_pixels(art, context.vesta)),
    );
  }
}

class _PixelPainter extends CustomPainter {
  _PixelPainter(this.pixels);

  final List<(int, int, Color)> pixels;

  static const _grid = 32;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _grid;
    final paint = Paint()..isAntiAlias = false;
    for (final (x, y, color) in pixels) {
      paint.color = color;
      canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
    }
  }

  @override
  bool shouldRepaint(_PixelPainter old) => !listEquals(old.pixels, pixels);
}
