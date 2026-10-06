import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Spendings/new_spending.dart';
import 'package:frontend_vesta/Screens/pages/accounts.dart';
import 'package:frontend_vesta/Screens/pages/coach_card.dart';
import 'package:frontend_vesta/Screens/Budgeting/budgeting_screen.dart';
import 'package:frontend_vesta/Screens/Household/household.dart';
import 'package:frontend_vesta/Screens/Savings/savings.dart';
import 'package:frontend_vesta/deep_link_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onOpenWallet});

  /// Switches MainScreen to the Wallet tab. Without it, Wallet is pushed.
  final VoidCallback? onOpenWallet;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;
  String? uname;

  @override
  void initState() {
    super.initState();
    calcTotalBalance();
    fetchCurrentCycleData();
    deepLinkService.init(context);

    deepLinkService.checkPendingLink(context);
    uname = user?.displayName ?? user?.email ?? "User";
  }

  void _openWallet() {
    if (widget.onOpenWallet != null) {
      widget.onOpenWallet!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AccountsPage()),
    );
  }

  num _asNum(dynamic value) =>
      value is num ? value : num.tryParse('${value ?? ''}') ?? 0;

  @override
  Widget build(BuildContext context) {
    final userId = user?.uid;
    String greeting = homePageGreeting();

    return Scaffold(
      body: VestaBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VestaSpace.gutter,
                  10,
                  VestaSpace.gutter,
                  0,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.asset(
                        'assets/images/LOGO_APP-ICON-DARK.png',
                        width: 32,
                        height: 32,
                        cacheWidth: 96,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$greeting $uname',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.vesta.muted),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: userId == null
                    ? const Center(child: Text("Not logged in"))
                    : StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("users")
                            .doc(userId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return const Center(
                              child: Text("No data available"),
                            );
                          }

                          final userData =
                              snapshot.data!.data() as Map<String, dynamic>? ??
                              {};
                          final totalBalance = (userData["totalBalance"] ?? 0)
                              .toDouble();
                          final currency = userData["currency"] ?? "JOD";

                          final totalIncome = userData["totalIncome"];
                          final totalExpense = userData["totalExpense"];

                          return ListView(
                            padding: const EdgeInsets.fromLTRB(
                              VestaSpace.gutter,
                              VestaSpace.lg,
                              VestaSpace.gutter,
                              VestaSpace.gutter,
                            ),
                            children: [
                              _balance(
                                totalBalance,
                                currency,
                                totalIncome,
                                totalExpense,
                              ),
                              const CoachCard(),
                              const SizedBox(height: VestaSpace.xl),
                              _tiles(),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _balance(
    double totalBalance,
    String currency,
    dynamic totalIncome,
    dynamic totalExpense,
  ) {
    final v = context.vesta;
    return Column(
      children: [
        Text('Total balance', style: TextStyle(fontSize: 13, color: v.muted)),
        const SizedBox(height: 6),
        MoneyText.hero(totalBalance, currency: currency),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 14,
          runSpacing: 6,
          children: [
            _stat(
              PhosphorIconsRegular.arrowUpRight,
              '${formatMoney(_asNum(totalExpense), currency: currency)} spent',
              v.neg,
            ),
            GestureDetector(
              onTap: () {
                inputIncome(context, totalIncome);
              },
              child: _stat(
                PhosphorIconsRegular.arrowDownLeft,
                '${formatMoney(_asNum(totalIncome), currency: currency)} income',
                v.pos,
              ),
            ),
            GestureDetector(
              onTap: _openWallet,
              child: _stat(
                PhosphorIconsRegular.caretRight,
                'Accounts',
                v.accentInk,
                iconAfter: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stat(
    IconData icon,
    String text,
    Color color, {
    bool iconAfter = false,
  }) {
    final children = [
      Icon(icon, size: 14, color: color),
      SizedBox(width: iconAfter ? 2 : VestaSpace.xs),
      Text(text, style: TextStyle(fontSize: 13, color: color)),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: iconAfter ? children.reversed.toList() : children,
    );
  }

  Widget _tiles() {
    final tiles = [
      _HomeTile(
        art: PixelArt.budget,
        label: 'Budgeting',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PersonalBudgetScreen(),
            ),
          );
        },
      ),
      _HomeTile(
        art: PixelArt.spend,
        label: 'Spendings',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NewSpendingAnalysis()),
          );
        },
      ),
      _HomeTile(
        art: PixelArt.save,
        label: 'Savings',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SavingsPage()),
          );
        },
      ),
      _HomeTile(
        art: PixelArt.shared,
        label: 'Shared finances',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HouseholdPage()),
          );
        },
      ),
    ];

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: VestaSpace.md,
        crossAxisSpacing: VestaSpace.md,
        mainAxisExtent: 160,
      ),
      children: tiles,
    );
  }
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({
    required this.art,
    required this.label,
    required this.onTap,
  });

  final PixelArt art;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VestaRadius.card),
        side: BorderSide(color: v.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        highlightColor: v.tint,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: VestaSpace.lg,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PixelIcon(art),
              const SizedBox(height: VestaSpace.md),
              Text(
                label,
                textAlign: TextAlign.center,
                style: headingStyle(15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
