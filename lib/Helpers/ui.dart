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
/// and a Pixelify title; [VestaAppBar.large] is the big left-aligned title
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

enum PixelArt { budget, spend, save, shared }

// 12x12 grids copied from the prototype's PIX table.
const Map<PixelArt, List<String>> _pixelGrids = {
  PixelArt.budget: [
    '....XXX.....', '..XXXXX.oo..', '.XXXXXX.ooo.', '.XXXXXX.oooo',
    'XXXXXXX.oooo', 'XXXXXXX.....', 'XXXXXXXXXXXX', 'XXXXXXXXXXXX',
    '.XXXXXXXXXX.', '.XXXXXXXXXX.', '..XXXXXXXX..', '....XXXX....',
  ],
  PixelArt.spend: [
    '.XXXXXXXXXX.', '.XXXXXXXXXX.', '.XXooooooXX.', '.XXXXXXXXXX.',
    '.XXooooXXXX.', '.XXXXXXXXXX.', '.XXooooooXX.', '.XXXXXXXXXX.',
    '.XXoooXXooX.', '.XXXXXXXXXX.', '.XX.XX.XX.X.', '.X..X..X..X.',
  ],
  PixelArt.save: [
    '.....oo.....', '....oooo....', '.....oo.....', '..XXXXXXX...',
    '.XXXXXXXXXX.', 'XXXXXXXXdXXX', 'XXXXXXXXXXXX', 'XXXXXXXXXXXX',
    '.XXXXXXXXXX.', '..XXXXXXXX..', '..XX....XX..', '..XX....XX..',
  ],
  PixelArt.shared: [
    '............', '..XX....oo..', '.XXXX..oooo.', '.XXXX..oooo.',
    '..XX....oo..', '............', '.XXXX..oooo.', 'XXXXXXoooooo',
    'XXXXXXoooooo', 'XXXXXXoooooo', 'XXXXXXoooooo', '............',
  ],
};

Map<String, Color> _pixelPalette(PixelArt art, VestaColors v) => switch (art) {
  PixelArt.budget => {'X': v.pxBlue, 'o': v.pxYellow},
  PixelArt.spend => {'X': v.pxYellow, 'o': v.pxInk},
  PixelArt.save => {'X': v.pxGreen, 'o': v.pxYellow, 'd': v.pxInk},
  PixelArt.shared => {'X': v.pxPurple, 'o': v.pxBlue},
};

/// One of the prototype's 12x12 pixel-art icons, drawn with crisp edges.
class PixelIcon extends StatelessWidget {
  const PixelIcon(this.art, {super.key, this.size = 44});

  final PixelArt art;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _PixelPainter(_pixelGrids[art]!, _pixelPalette(art, context.vesta)),
    );
  }
}

class _PixelPainter extends CustomPainter {
  _PixelPainter(this.rows, this.palette);

  final List<String> rows;
  final Map<String, Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / rows.length;
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < rows[y].length; x++) {
        final color = palette[rows[y][x]];
        if (color == null) continue;
        paint.color = color;
        canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PixelPainter old) =>
      old.rows != rows || !mapEquals(old.palette, palette);
}
