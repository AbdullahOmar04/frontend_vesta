import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get tabDashboard;

  /// No description provided for @tabWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get tabWallet;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// Short label for the Jordanian dinar, shown next to amounts.
  ///
  /// In en, this message translates to:
  /// **'JOD'**
  String get currencyJod;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get notLoggedIn;

  /// No description provided for @profilePersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get profilePersonalInfo;

  /// No description provided for @profileBankAccounts.
  ///
  /// In en, this message translates to:
  /// **'Bank accounts management'**
  String get profileBankAccounts;

  /// No description provided for @profileSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get profileSubscriptions;

  /// No description provided for @profileFreePlan.
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get profileFreePlan;

  /// No description provided for @profileReferrals.
  ///
  /// In en, this message translates to:
  /// **'Referrals'**
  String get profileReferrals;

  /// No description provided for @profilePoints.
  ///
  /// In en, this message translates to:
  /// **'{points} points'**
  String profilePoints(String points);

  /// No description provided for @profilePreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profilePreferences;

  /// No description provided for @profileSecurity.
  ///
  /// In en, this message translates to:
  /// **'Password and security'**
  String get profileSecurity;

  /// No description provided for @profileTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms and conditions'**
  String get profileTerms;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @logOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out of Vesta?'**
  String get logOutTitle;

  /// No description provided for @logOutMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to log in again to see your money.'**
  String get logOutMessage;

  /// No description provided for @prefsTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get prefsTitle;

  /// No description provided for @prefsDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get prefsDisplay;

  /// No description provided for @prefsDisplaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance, language, and currency'**
  String get prefsDisplaySubtitle;

  /// No description provided for @prefsResetDay.
  ///
  /// In en, this message translates to:
  /// **'Budget reset day'**
  String get prefsResetDay;

  /// No description provided for @prefsResetDaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of each month'**
  String prefsResetDaySubtitle(String day);

  /// No description provided for @prefsFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features management'**
  String get prefsFeatures;

  /// No description provided for @prefsReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders and alerts'**
  String get prefsReminders;

  /// No description provided for @prefsRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming payments, budgets, and goals'**
  String get prefsRemindersSubtitle;

  /// No description provided for @prefsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get prefsNotifications;

  /// No description provided for @displayTitle.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get displayTitle;

  /// No description provided for @displayAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get displayAppearance;

  /// No description provided for @displayLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get displayLight;

  /// No description provided for @displayDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get displayDark;

  /// No description provided for @displayAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get displayAuto;

  /// No description provided for @displayAutoNote.
  ///
  /// In en, this message translates to:
  /// **'Auto follows your phone\'s setting.'**
  String get displayAutoNote;

  /// No description provided for @displayLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get displayLanguage;

  /// No description provided for @displayCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get displayCurrency;

  /// No description provided for @displayCurrencyJod.
  ///
  /// In en, this message translates to:
  /// **'JOD · Jordanian dinar'**
  String get displayCurrencyJod;

  /// No description provided for @displayMoreCurrencies.
  ///
  /// In en, this message translates to:
  /// **'More currencies are coming.'**
  String get displayMoreCurrencies;

  /// No description provided for @remindersIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose what Vesta should remind you about.'**
  String get remindersIntro;

  /// No description provided for @remindersUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming payments'**
  String get remindersUpcoming;

  /// No description provided for @remindersUpcomingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Before a scheduled payment is due'**
  String get remindersUpcomingSubtitle;

  /// No description provided for @remindersRemindMe.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get remindersRemindMe;

  /// No description provided for @remindersDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String remindersDays(int count);

  /// No description provided for @remindersOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Going over budget'**
  String get remindersOverBudget;

  /// No description provided for @remindersOverBudgetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When your spending gets close to the budget'**
  String get remindersOverBudgetSubtitle;

  /// No description provided for @remindersAlertAt.
  ///
  /// In en, this message translates to:
  /// **'Alert at'**
  String get remindersAlertAt;

  /// No description provided for @remindersCategoryLimits.
  ///
  /// In en, this message translates to:
  /// **'Category limits'**
  String get remindersCategoryLimits;

  /// No description provided for @remindersCategoryLimitsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When a category reaches its monthly limit'**
  String get remindersCategoryLimitsSubtitle;

  /// No description provided for @remindersSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings goals'**
  String get remindersSavings;

  /// No description provided for @remindersSavingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When you haven\'t reached this month\'s target'**
  String get remindersSavingsSubtitle;

  /// No description provided for @remindersLarge.
  ///
  /// In en, this message translates to:
  /// **'Large transactions'**
  String get remindersLarge;

  /// No description provided for @remindersLargeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When a single transaction is over {amount}'**
  String remindersLargeSubtitle(String amount);

  /// No description provided for @remindersNotYet.
  ///
  /// In en, this message translates to:
  /// **'Vesta doesn\'t send these yet. Your choices are saved for when it does.'**
  String get remindersNotYet;

  /// No description provided for @notificationsIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose which notifications you want to get.'**
  String get notificationsIntro;

  /// No description provided for @notificationsPerTransaction.
  ///
  /// In en, this message translates to:
  /// **'Per transaction'**
  String get notificationsPerTransaction;

  /// No description provided for @notificationsPerTransactionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every time money comes in or goes out'**
  String get notificationsPerTransactionSubtitle;

  /// No description provided for @notificationsRequired.
  ///
  /// In en, this message translates to:
  /// **'Required actions'**
  String get notificationsRequired;

  /// No description provided for @notificationsRequiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Things that need you, like a bill to confirm'**
  String get notificationsRequiredSubtitle;

  /// No description provided for @notificationsMotivational.
  ///
  /// In en, this message translates to:
  /// **'Motivational'**
  String get notificationsMotivational;

  /// No description provided for @notificationsMotivationalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Milestones and encouragement'**
  String get notificationsMotivationalSubtitle;

  /// No description provided for @notificationsPromotional.
  ///
  /// In en, this message translates to:
  /// **'Promotional and app updates'**
  String get notificationsPromotional;

  /// No description provided for @notificationsPromotionalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offers and new features'**
  String get notificationsPromotionalSubtitle;

  /// No description provided for @notificationsSupport.
  ///
  /// In en, this message translates to:
  /// **'Customer service'**
  String get notificationsSupport;

  /// No description provided for @notificationsSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replies to your support requests'**
  String get notificationsSupportSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
