import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';

// Shared pieces for the bank linking screens in choose_bank.dart, built on
// the redesign's widgets. Kept in their own file so master never touches it.

/// "IBAN: ..." for an account card, or a plain note when the bank gave none.
/// [shorten] keeps the first 6 and last 4 characters of a long IBAN.
String ibanLine(Object? raw, {bool shorten = false}) {
  final iban = raw?.toString().trim() ?? '';
  if (iban.isEmpty) return 'No IBAN available';
  if (shorten && iban.length > 16) {
    return 'IBAN: ${iban.substring(0, 6)}...${iban.substring(iban.length - 4)}';
  }
  return 'IBAN: $iban';
}

/// Page for one bank's linking flow: header, page background, and a bottom
/// "Link" button once the user can pick accounts.
class BankLinkScaffold extends StatelessWidget {
  const BankLinkScaffold({
    super.key,
    required this.title,
    required this.body,
    this.syncing = false,
    this.onResync,
    this.showLinkBar = false,
    this.selectedCount = 0,
    this.onLink,
  });

  final String title;
  final Widget body;
  final bool syncing;

  /// Shows a re-sync button in the header when set.
  final VoidCallback? onResync;
  final bool showLinkBar;
  final int selectedCount;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VestaAppBar(
        title: title,
        actions: [
          if (onResync != null)
            IconButton(
              onPressed: syncing ? null : onResync,
              icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
              tooltip: 'Re-sync',
            ),
        ],
      ),
      body: VestaBackground(child: body),
      bottomNavigationBar: showLinkBar
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  VestaSpace.gutter,
                  VestaSpace.sm,
                  VestaSpace.gutter,
                  VestaSpace.md,
                ),
                child: PrimaryButton(
                  label: selectedCount == 0
                      ? 'Select accounts to link'
                      : selectedCount == 1
                      ? 'Link 1 account'
                      : 'Link $selectedCount accounts',
                  onPressed: selectedCount == 0 ? null : onLink,
                ),
              ),
            )
          : null,
    );
  }
}

/// Centred spinner with an optional line of text.
class BankLoadingState extends StatelessWidget {
  const BankLoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: VestaSpace.lg),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: context.vesta.muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Centred problem message with one action, for failed or expired links.
class BankErrorState extends StatelessWidget {
  const BankErrorState({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.reconnect = false,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  /// A link that needs renewing rather than a failure.
  final bool reconnect;

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VestaSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              reconnect
                  ? PhosphorIconsRegular.linkSimple
                  : PhosphorIconsRegular.warningCircle,
              size: 48,
              color: reconnect ? v.accentInk : v.neg,
            ),
            const SizedBox(height: VestaSpace.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: VestaSpace.xl),
            PrimaryButton(label: actionLabel, onPressed: onAction),
          ],
        ),
      ),
    );
  }
}

/// Card for a bank's own sign-in step: heading, optional line under it,
/// the fields, then one primary button.
class BankLoginCard extends StatelessWidget {
  const BankLoginCard({
    super.key,
    required this.bankName,
    required this.title,
    required this.fields,
    required this.submitLabel,
    required this.onSubmit,
    this.subtitle,
    this.loading = false,
    this.footer,
  });

  final String bankName;
  final String title;
  final String? subtitle;
  final List<Widget> fields;
  final String submitLabel;
  final VoidCallback? onSubmit;
  final bool loading;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        VestaSpace.gutter,
        VestaSpace.sm,
        VestaSpace.gutter,
        VestaSpace.xl,
      ),
      children: [
        Row(
          children: [
            BankBadge(bankName, size: 44),
            const SizedBox(width: VestaSpace.md),
            Expanded(child: Text(title, style: headingStyle(20))),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: VestaSpace.sm),
          Text(
            subtitle!,
            style: TextStyle(fontSize: 14, color: context.vesta.muted),
          ),
        ],
        const SizedBox(height: VestaSpace.xl),
        for (final field in fields) ...[
          field,
          const SizedBox(height: 14),
        ],
        const SizedBox(height: VestaSpace.sm),
        PrimaryButton(label: submitLabel, onPressed: onSubmit, loading: loading),
        if (footer != null) ...[
          const SizedBox(height: VestaSpace.md),
          Center(child: footer!),
        ],
      ],
    );
  }
}

/// The consent step, after the prototype: the Vesta logo and the bank's
/// badge, what will be shared, and Cancel / Allow.
class BankConsentCard extends StatelessWidget {
  const BankConsentCard({
    super.key,
    required this.bankName,
    required this.message,
    required this.scopes,
    required this.onCancel,
    required this.onAllow,
    this.title,
    this.note,
    this.cancelLabel = 'Cancel',
    this.allowLabel = 'Allow & continue',
    this.busy = false,
    this.extraActions = const [],
  });

  final String bankName;

  /// Optional heading above [message].
  final String? title;
  final String message;
  final List<(IconData, String)> scopes;
  final String? note;
  final String cancelLabel;
  final String allowLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onAllow;
  final bool busy;

  /// Extra text buttons under the main pair (e.g. "Open the app again").
  final List<Widget> extraActions;

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        VestaSpace.gutter,
        VestaSpace.lg,
        VestaSpace.gutter,
        VestaSpace.xl,
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/LOGO_APP-ICON-DARK.png',
                width: 44,
                height: 44,
                cacheWidth: 132,
              ),
            ),
            const SizedBox(width: 10),
            Icon(PhosphorIconsRegular.arrowsLeftRight, size: 20, color: v.muted),
            const SizedBox(width: 10),
            BankBadge(bankName, size: 44),
          ],
        ),
        const SizedBox(height: VestaSpace.lg),
        if (title != null) ...[
          Text(title!, textAlign: TextAlign.center, style: headingStyle(18)),
          const SizedBox(height: VestaSpace.sm),
        ],
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: title != null ? v.muted : null,
          ),
        ),
        const SizedBox(height: VestaSpace.lg),
        VestaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "You'll be asked to share",
                style: TextStyle(fontSize: 12, color: v.muted),
              ),
              const SizedBox(height: 10),
              for (final (icon, label) in scopes)
                Padding(
                  padding: const EdgeInsets.only(bottom: VestaSpace.sm),
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: v.accentInk),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(label, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: VestaSpace.md),
          Text(note!, style: TextStyle(fontSize: 12, color: v.muted)),
        ],
        const SizedBox(height: VestaSpace.xl),
        Row(
          children: [
            Expanded(
              child: OutlineButton(label: cancelLabel, onPressed: onCancel),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                label: allowLabel,
                onPressed: onAllow,
                loading: busy,
              ),
            ),
          ],
        ),
        if (extraActions.isNotEmpty) ...[
          const SizedBox(height: VestaSpace.sm),
          Row(
            children: [for (final a in extraActions) Expanded(child: a)],
          ),
        ],
      ],
    );
  }
}

/// "Select accounts to link" heading with Skip, and a progress line while
/// the bank sync runs.
class BankSelectHeader extends StatelessWidget {
  const BankSelectHeader({
    super.key,
    required this.syncing,
    required this.onSkip,
    this.below,
  });

  final bool syncing;
  final VoidCallback onSkip;
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VestaSpace.gutter,
        VestaSpace.xs,
        VestaSpace.gutter,
        VestaSpace.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (syncing) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: VestaSpace.sm),
          ],
          SectionHeader(
            title: 'Select accounts to link',
            actionLabel: 'Skip',
            onAction: onSkip,
          ),
          if (below != null) ...[const SizedBox(height: VestaSpace.sm), below!],
        ],
      ),
    );
  }
}

/// One account the user can tick for linking. Accounts that are already
/// linked show a Linked tag and can't be unticked.
class LinkableAccountTile extends StatelessWidget {
  const LinkableAccountTile({
    super.key,
    required this.title,
    required this.balance,
    required this.currency,
    required this.checked,
    required this.linked,
    required this.onToggle,
    this.lines = const [],
    this.badgeName,
    this.neutralBalance = false,
    this.extra,
  });

  final String title;

  /// Grey lines under the title: account type, IBAN, customer name...
  final List<String> lines;
  final num balance;
  final String currency;
  final bool checked;
  final bool linked;
  final VoidCallback onToggle;

  /// Name used for the badge when it differs from [title].
  final String? badgeName;

  /// Loans: an amount owed, shown without the negative colour.
  final bool neutralBalance;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: VestaCard(
        radius: VestaRadius.lg,
        padding: const EdgeInsets.fromLTRB(6, 12, 14, 12),
        onTap: linked ? null : onToggle,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: checked,
              onChanged: linked ? null : (_) => onToggle(),
            ),
            BankBadge(badgeName ?? title),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: VestaSpace.sm),
                      MoneyText(
                        balance,
                        currency: currency,
                        color: balance < 0 && !neutralBalance ? v.neg : null,
                      ),
                    ],
                  ),
                  for (final line in lines)
                    Text(
                      line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (extra != null) ...[
                    const SizedBox(height: VestaSpace.sm),
                    extra!,
                  ],
                  if (linked) ...[
                    const SizedBox(height: VestaSpace.sm),
                    TagChip.pill(
                      'Linked',
                      icon: PhosphorIconsRegular.check,
                      color: v.pos,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// List body for the account picker, with the bottom padding the link
/// button needs.
class LinkableAccountList extends StatelessWidget {
  const LinkableAccountList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        VestaSpace.gutter,
        0,
        VestaSpace.gutter,
        VestaSpace.xl,
      ),
      children: children,
    );
  }
}

/// Plain centred message for an empty account list.
class BankEmptyState extends StatelessWidget {
  const BankEmptyState({
    super.key,
    required this.title,
    this.message,
    this.action,
  });

  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VestaSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsRegular.bank, size: 48, color: v.muted),
            const SizedBox(height: VestaSpace.md),
            Text(title, textAlign: TextAlign.center, style: headingStyle(17)),
            if (message != null) ...[
              const SizedBox(height: VestaSpace.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: v.muted),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: VestaSpace.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
