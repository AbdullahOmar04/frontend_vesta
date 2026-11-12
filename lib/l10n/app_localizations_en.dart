// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabHome => 'Home';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get tabWallet => 'Wallet';

  @override
  String get tabProfile => 'Profile';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get currencyJod => 'JOD';

  @override
  String get profileTitle => 'Profile';

  @override
  String get notLoggedIn => 'Not logged in';

  @override
  String get profilePersonalInfo => 'Personal information';

  @override
  String get profileBankAccounts => 'Bank accounts management';

  @override
  String get profileSubscriptions => 'Subscriptions';

  @override
  String get profileFreePlan => 'Free plan';

  @override
  String get profileReferrals => 'Referrals';

  @override
  String profilePoints(String points) {
    return '$points points';
  }

  @override
  String get profilePreferences => 'Preferences';

  @override
  String get profileSecurity => 'Password and security';

  @override
  String get profileTerms => 'Terms and conditions';

  @override
  String get logOut => 'Log out';

  @override
  String get logOutTitle => 'Log out of Vesta?';

  @override
  String get logOutMessage => 'You\'ll need to log in again to see your money.';

  @override
  String get prefsTitle => 'Preferences';

  @override
  String get prefsDisplay => 'Display';

  @override
  String get prefsDisplaySubtitle => 'Appearance, language, and currency';

  @override
  String get prefsResetDay => 'Budget reset day';

  @override
  String prefsResetDaySubtitle(String day) {
    return 'Day $day of each month';
  }

  @override
  String get prefsFeatures => 'Features management';

  @override
  String get prefsReminders => 'Reminders and alerts';

  @override
  String get prefsRemindersSubtitle => 'Upcoming payments, budgets, and goals';

  @override
  String get prefsNotifications => 'Notifications';

  @override
  String get displayTitle => 'Display';

  @override
  String get displayAppearance => 'Appearance';

  @override
  String get displayLight => 'Light';

  @override
  String get displayDark => 'Dark';

  @override
  String get displayAuto => 'Auto';

  @override
  String get displayAutoNote => 'Auto follows your phone\'s setting.';

  @override
  String get displayLanguage => 'Language';

  @override
  String get displayCurrency => 'Currency';

  @override
  String get displayCurrencyJod => 'JOD · Jordanian dinar';

  @override
  String get displayMoreCurrencies => 'More currencies are coming.';

  @override
  String get remindersIntro => 'Choose what Vesta should remind you about.';

  @override
  String get remindersUpcoming => 'Upcoming payments';

  @override
  String get remindersUpcomingSubtitle => 'Before a scheduled payment is due';

  @override
  String get remindersRemindMe => 'Remind me';

  @override
  String remindersDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get remindersOverBudget => 'Going over budget';

  @override
  String get remindersOverBudgetSubtitle =>
      'When your spending gets close to the budget';

  @override
  String get remindersAlertAt => 'Alert at';

  @override
  String get remindersCategoryLimits => 'Category limits';

  @override
  String get remindersCategoryLimitsSubtitle =>
      'When a category reaches its monthly limit';

  @override
  String get remindersSavings => 'Savings goals';

  @override
  String get remindersSavingsSubtitle =>
      'When you haven\'t reached this month\'s target';

  @override
  String get remindersLarge => 'Large transactions';

  @override
  String remindersLargeSubtitle(String amount) {
    return 'When a single transaction is over $amount';
  }

  @override
  String get remindersNotYet =>
      'Vesta doesn\'t send these yet. Your choices are saved for when it does.';

  @override
  String get notificationsIntro =>
      'Choose which notifications you want to get.';

  @override
  String get notificationsPerTransaction => 'Per transaction';

  @override
  String get notificationsPerTransactionSubtitle =>
      'Every time money comes in or goes out';

  @override
  String get notificationsRequired => 'Required actions';

  @override
  String get notificationsRequiredSubtitle =>
      'Things that need you, like a bill to confirm';

  @override
  String get notificationsMotivational => 'Motivational';

  @override
  String get notificationsMotivationalSubtitle =>
      'Milestones and encouragement';

  @override
  String get notificationsPromotional => 'Promotional and app updates';

  @override
  String get notificationsPromotionalSubtitle => 'Offers and new features';

  @override
  String get notificationsSupport => 'Customer service';

  @override
  String get notificationsSupportSubtitle => 'Replies to your support requests';
}
