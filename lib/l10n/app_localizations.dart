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

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @genericErrorLater.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again later.'**
  String get genericErrorLater;

  /// No description provided for @genericErrorAgain.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get genericErrorAgain;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get tooManyAttempts;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get enterValidEmail;

  /// No description provided for @errorWith.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWith(String error);

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Vesta'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in or create an account to continue.'**
  String get welcomeSubtitle;

  /// No description provided for @unlockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Vesta'**
  String get unlockReason;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @welcomeBackName.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String welcomeBackName(String name);

  /// No description provided for @unlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock to see your money.'**
  String get unlockSubtitle;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @logInWithPassword.
  ///
  /// In en, this message translates to:
  /// **'Log in with password'**
  String get logInWithPassword;

  /// No description provided for @notYou.
  ///
  /// In en, this message translates to:
  /// **'Not you? Use another account or sign up'**
  String get notYou;

  /// No description provided for @blockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone Number Blocked'**
  String get blockedTitle;

  /// No description provided for @blockedVerifyBody.
  ///
  /// In en, this message translates to:
  /// **'Your phone number has been temporarily blocked due to multiple verification attempts.'**
  String get blockedVerifyBody;

  /// No description provided for @blockedOtpBody.
  ///
  /// In en, this message translates to:
  /// **'Your phone number has been temporarily blocked due to multiple failed attempts.'**
  String get blockedOtpBody;

  /// No description provided for @blockedDuration.
  ///
  /// In en, this message translates to:
  /// **'Block Duration: 30 minutes'**
  String get blockedDuration;

  /// No description provided for @blockedRegain.
  ///
  /// In en, this message translates to:
  /// **'To regain access:'**
  String get blockedRegain;

  /// No description provided for @blockedStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Wait for the block period to expire (up to 30 minutes)'**
  String get blockedStep1;

  /// No description provided for @blockedStep2.
  ///
  /// In en, this message translates to:
  /// **'2. Ensure you have access to the phone number'**
  String get blockedStep2;

  /// No description provided for @blockedStep3Later.
  ///
  /// In en, this message translates to:
  /// **'3. Try again after the waiting period'**
  String get blockedStep3Later;

  /// No description provided for @blockedStep3Otp.
  ///
  /// In en, this message translates to:
  /// **'3. Try again with the correct OTP'**
  String get blockedStep3Otp;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Jordan number starting with 7 (e.g. 79xxxxxxx)'**
  String get phoneInvalid;

  /// No description provided for @phoneVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Phone verification failed'**
  String get phoneVerifyFailed;

  /// No description provided for @phoneVerifyStartError.
  ///
  /// In en, this message translates to:
  /// **'Error starting phone verification: {error}'**
  String phoneVerifyStartError(String error);

  /// No description provided for @phoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Your phone number'**
  String get phoneTitle;

  /// No description provided for @phoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a verification code to the provided number.'**
  String get phoneSubtitle;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneLabel;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get fillAllFields;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDontMatch;

  /// No description provided for @passwordRequirementsNotMet.
  ///
  /// In en, this message translates to:
  /// **'Please ensure your password meets all requirements'**
  String get passwordRequirementsNotMet;

  /// No description provided for @usernameRules.
  ///
  /// In en, this message translates to:
  /// **'Username can only contain letters, numbers, and underscores'**
  String get usernameRules;

  /// No description provided for @usernameTaken.
  ///
  /// In en, this message translates to:
  /// **'Username already taken. Please choose another one.'**
  String get usernameTaken;

  /// No description provided for @emailRegistered.
  ///
  /// In en, this message translates to:
  /// **'Email already registered. Please use another email or login.'**
  String get emailRegistered;

  /// No description provided for @referralNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find that referral code. Check it, or leave it empty.'**
  String get referralNotFound;

  /// No description provided for @checkUsernameError.
  ///
  /// In en, this message translates to:
  /// **'Error checking username/email: {error}'**
  String checkUsernameError(String error);

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createAccountTitle;

  /// No description provided for @nextVerifyPhone.
  ///
  /// In en, this message translates to:
  /// **'Next we will verify your phone number.'**
  String get nextVerifyPhone;

  /// No description provided for @useTheseToLogIn.
  ///
  /// In en, this message translates to:
  /// **'You\'ll use these to log in as {username}. Next we will verify your phone number.'**
  String useTheseToLogIn(String username);

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @passwordNeeds.
  ///
  /// In en, this message translates to:
  /// **'Password needs'**
  String get passwordNeeds;

  /// No description provided for @pwMinLength.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get pwMinLength;

  /// No description provided for @pwUppercase.
  ///
  /// In en, this message translates to:
  /// **'At least one uppercase letter (A-Z)'**
  String get pwUppercase;

  /// No description provided for @pwLowercase.
  ///
  /// In en, this message translates to:
  /// **'At least one lowercase letter (a-z)'**
  String get pwLowercase;

  /// No description provided for @pwNumber.
  ///
  /// In en, this message translates to:
  /// **'At least one number (0-9)'**
  String get pwNumber;

  /// No description provided for @repeatPassword.
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get repeatPassword;

  /// No description provided for @referralCode.
  ///
  /// In en, this message translates to:
  /// **'Referral code'**
  String get referralCode;

  /// No description provided for @referralHint.
  ///
  /// In en, this message translates to:
  /// **'Optional, e.g. MAYA-25K9'**
  String get referralHint;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a link to reset your password.'**
  String get resetPasswordMessage;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get enterEmail;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Please check your inbox.'**
  String get resetEmailSent;

  /// No description provided for @resetEmailFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email. Please try again.'**
  String get resetEmailFailed;

  /// No description provided for @invalidLogin.
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password'**
  String get invalidLogin;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get networkError;

  /// No description provided for @accountError.
  ///
  /// In en, this message translates to:
  /// **'Account error. Please contact support.'**
  String get accountError;

  /// No description provided for @biometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric login is not available or not enabled'**
  String get biometricUnavailable;

  /// No description provided for @biometricFailed.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication failed'**
  String get biometricFailed;

  /// No description provided for @noStoredCredentials.
  ///
  /// In en, this message translates to:
  /// **'No stored credentials. Please login with password first.'**
  String get noStoredCredentials;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please login with password.'**
  String get sessionExpired;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in with your username or email.'**
  String get loginSubtitle;

  /// No description provided for @usernameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Username or email'**
  String get usernameOrEmail;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @logInWithBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Log in with biometrics'**
  String get logInWithBiometrics;

  /// No description provided for @enableBiometricsLater.
  ///
  /// In en, this message translates to:
  /// **'Enable biometrics in settings after logging in'**
  String get enableBiometricsLater;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get noAccount;

  /// No description provided for @otpExpired.
  ///
  /// In en, this message translates to:
  /// **'OTP has expired. Please request a new code.'**
  String get otpExpired;

  /// No description provided for @otpEnter6.
  ///
  /// In en, this message translates to:
  /// **'Please enter a 6-digit OTP'**
  String get otpEnter6;

  /// No description provided for @numberHasAccount.
  ///
  /// In en, this message translates to:
  /// **'This number already has a Vesta account. Log in instead.'**
  String get numberHasAccount;

  /// No description provided for @emailHasAccount.
  ///
  /// In en, this message translates to:
  /// **'That email already has a Vesta account. Log in instead.'**
  String get emailHasAccount;

  /// No description provided for @usernameTakenRetry.
  ///
  /// In en, this message translates to:
  /// **'Username is already taken. Please try registering again with a different username.'**
  String get usernameTakenRetry;

  /// No description provided for @emailTakenRetry.
  ///
  /// In en, this message translates to:
  /// **'Email is already registered. Please try logging in or use a different email.'**
  String get emailTakenRetry;

  /// No description provided for @usernameOrEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'Username or email is already taken. Please try registering again with different credentials.'**
  String get usernameOrEmailTaken;

  /// No description provided for @createAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create account: {error}'**
  String createAccountFailed(String error);

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailed;

  /// No description provided for @resendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend OTP'**
  String get resendFailed;

  /// No description provided for @otpResent.
  ///
  /// In en, this message translates to:
  /// **'New OTP sent successfully'**
  String get otpResent;

  /// No description provided for @resendError.
  ///
  /// In en, this message translates to:
  /// **'Error resending OTP: {error}'**
  String resendError(String error);

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get enterCode;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'We texted a code to {phone} to verify your number.'**
  String codeSentTo(String phone);

  /// No description provided for @codeExpiredBelow.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Request a new one below.'**
  String get codeExpiredBelow;

  /// No description provided for @codeExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Code expires in {time}'**
  String codeExpiresIn(String time);

  /// No description provided for @verifyCreate.
  ///
  /// In en, this message translates to:
  /// **'Verify & create account'**
  String get verifyCreate;

  /// No description provided for @didntGetIt.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get it? '**
  String get didntGetIt;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'You can resend the code in {seconds}s'**
  String resendIn(String seconds);

  /// No description provided for @usernameCharsShort.
  ///
  /// In en, this message translates to:
  /// **'Use only letters, numbers and underscores'**
  String get usernameCharsShort;

  /// No description provided for @usernameTakenShort.
  ///
  /// In en, this message translates to:
  /// **'That username is taken'**
  String get usernameTakenShort;

  /// No description provided for @usernameCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check the username: {error}'**
  String usernameCheckFailed(String error);

  /// No description provided for @onbWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get your money into one calm view.'**
  String get onbWelcomeTitle;

  /// No description provided for @onbWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'A few questions and you\'ll have a starting budget, your accounts in one place, and a coach that keeps an eye on your spending.'**
  String get onbWelcomeBody;

  /// No description provided for @chooseUsername.
  ///
  /// In en, this message translates to:
  /// **'Choose a username'**
  String get chooseUsername;

  /// No description provided for @incomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Nice to meet you, {name}. What lands in your account each month?'**
  String incomeTitle(String name);

  /// No description provided for @incomeBody.
  ///
  /// In en, this message translates to:
  /// **'Your take-home pay after taxes. We\'ll suggest a split you can change anytime.'**
  String get incomeBody;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get perMonth;

  /// No description provided for @incomePrivate.
  ///
  /// In en, this message translates to:
  /// **'Stays on your phone until you create your account.'**
  String get incomePrivate;

  /// No description provided for @suggestedSplit.
  ///
  /// In en, this message translates to:
  /// **'SUGGESTED STARTING SPLIT'**
  String get suggestedSplit;

  /// No description provided for @useAsBudget.
  ///
  /// In en, this message translates to:
  /// **'Use this as my starting budget'**
  String get useAsBudget;

  /// No description provided for @bucketNecessities.
  ///
  /// In en, this message translates to:
  /// **'Necessities'**
  String get bucketNecessities;

  /// No description provided for @bucketNecessitiesExamples.
  ///
  /// In en, this message translates to:
  /// **'Rent, groceries, bills'**
  String get bucketNecessitiesExamples;

  /// No description provided for @bucketLuxuries.
  ///
  /// In en, this message translates to:
  /// **'Luxuries'**
  String get bucketLuxuries;

  /// No description provided for @bucketLuxuriesExamples.
  ///
  /// In en, this message translates to:
  /// **'Dining, fun, shopping'**
  String get bucketLuxuriesExamples;

  /// No description provided for @bucketSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get bucketSavings;

  /// No description provided for @bucketSavingsExamples.
  ///
  /// In en, this message translates to:
  /// **'Goals and extra payments'**
  String get bucketSavingsExamples;

  /// No description provided for @focusTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you want to work on first?'**
  String get focusTitle;

  /// No description provided for @focusBody.
  ///
  /// In en, this message translates to:
  /// **'Pick up to three. Your coach will focus here.'**
  String get focusBody;

  /// No description provided for @focusSpend.
  ///
  /// In en, this message translates to:
  /// **'Manage my spendings'**
  String get focusSpend;

  /// No description provided for @focusGoals.
  ///
  /// In en, this message translates to:
  /// **'Start saving goals'**
  String get focusGoals;

  /// No description provided for @focusBills.
  ///
  /// In en, this message translates to:
  /// **'Manage bills and scheduled payments'**
  String get focusBills;

  /// No description provided for @focusShared.
  ///
  /// In en, this message translates to:
  /// **'Manage shared finances'**
  String get focusShared;

  /// No description provided for @focusBudget.
  ///
  /// In en, this message translates to:
  /// **'Build a monthly budget'**
  String get focusBudget;

  /// No description provided for @focusClarity.
  ///
  /// In en, this message translates to:
  /// **'Get financial clarity'**
  String get focusClarity;

  /// No description provided for @banksTitle.
  ///
  /// In en, this message translates to:
  /// **'Which banks do you use?'**
  String get banksTitle;

  /// No description provided for @banksBody.
  ///
  /// In en, this message translates to:
  /// **'Pick any that apply. Nothing gets connected; it helps us set Vesta up around your accounts.'**
  String get banksBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @comingLater.
  ///
  /// In en, this message translates to:
  /// **'This is coming in a later update.'**
  String get comingLater;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning,'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon,'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening,'**
  String get greetingEvening;

  /// No description provided for @greetingNight.
  ///
  /// In en, this message translates to:
  /// **'Good night,'**
  String get greetingNight;

  /// No description provided for @greetingFallbackName.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get greetingFallbackName;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get totalBalance;

  /// No description provided for @amountSpent.
  ///
  /// In en, this message translates to:
  /// **'{amount} spent'**
  String amountSpent(String amount);

  /// No description provided for @amountEarned.
  ///
  /// In en, this message translates to:
  /// **'{amount} earned'**
  String amountEarned(String amount);

  /// No description provided for @accountsLabel.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsLabel;

  /// No description provided for @accountCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 account} other{{count} accounts}}'**
  String accountCount(int count);

  /// No description provided for @tileBudgeting.
  ///
  /// In en, this message translates to:
  /// **'Budgeting'**
  String get tileBudgeting;

  /// No description provided for @tileSpendings.
  ///
  /// In en, this message translates to:
  /// **'Spendings'**
  String get tileSpendings;

  /// No description provided for @tileSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get tileSavings;

  /// No description provided for @tileShared.
  ///
  /// In en, this message translates to:
  /// **'Shared finances'**
  String get tileShared;

  /// No description provided for @monthBudget.
  ///
  /// In en, this message translates to:
  /// **'{month} budget'**
  String monthBudget(String month);

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @noBudgetPlan.
  ///
  /// In en, this message translates to:
  /// **'No budget plan for this month yet.'**
  String get noBudgetPlan;

  /// No description provided for @planYourBudget.
  ///
  /// In en, this message translates to:
  /// **'Plan your budget'**
  String get planYourBudget;

  /// No description provided for @spentOfBudget.
  ///
  /// In en, this message translates to:
  /// **'{spent} of {budget} to spend'**
  String spentOfBudget(String spent, String budget);

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day left} other{{count} days left}}'**
  String daysLeft(int count);

  /// No description provided for @notInPlan.
  ///
  /// In en, this message translates to:
  /// **'Not in the plan'**
  String get notInPlan;

  /// No description provided for @targetReached.
  ///
  /// In en, this message translates to:
  /// **'Target reached'**
  String get targetReached;

  /// No description provided for @amountToGo.
  ///
  /// In en, this message translates to:
  /// **'{amount} to go'**
  String amountToGo(String amount);

  /// No description provided for @amountOver.
  ///
  /// In en, this message translates to:
  /// **'{amount} over'**
  String amountOver(String amount);

  /// No description provided for @amountLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String amountLeft(String amount);

  /// No description provided for @comingUp.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get comingUp;

  /// No description provided for @allBills.
  ///
  /// In en, this message translates to:
  /// **'All bills'**
  String get allBills;

  /// No description provided for @nothingDue.
  ///
  /// In en, this message translates to:
  /// **'Nothing due soon.'**
  String get nothingDue;

  /// No description provided for @addYourBills.
  ///
  /// In en, this message translates to:
  /// **'Add your bills'**
  String get addYourBills;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @noGoals.
  ///
  /// In en, this message translates to:
  /// **'No saving goals yet.'**
  String get noGoals;

  /// No description provided for @createGoal.
  ///
  /// In en, this message translates to:
  /// **'Create a goal'**
  String get createGoal;

  /// No description provided for @goalFallback.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goalFallback;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet.'**
  String get noTransactions;

  /// No description provided for @addOne.
  ///
  /// In en, this message translates to:
  /// **'Add one'**
  String get addOne;

  /// No description provided for @coachLabel.
  ///
  /// In en, this message translates to:
  /// **'YOUR COACH'**
  String get coachLabel;

  /// No description provided for @coachPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s plan this month.'**
  String get coachPlanTitle;

  /// No description provided for @coachPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Set your income and split it into savings, necessities and luxuries. I\'ll tell you how your spending is pacing against it.'**
  String get coachPlanBody;

  /// No description provided for @coachMostlyOnPace.
  ///
  /// In en, this message translates to:
  /// **'You\'re mostly on pace.'**
  String get coachMostlyOnPace;

  /// No description provided for @coachRunningHot.
  ///
  /// In en, this message translates to:
  /// **'Spending is running a little hot.'**
  String get coachRunningHot;

  /// No description provided for @bucketNecessitiesLower.
  ///
  /// In en, this message translates to:
  /// **'necessities'**
  String get bucketNecessitiesLower;

  /// No description provided for @bucketLuxuriesLower.
  ///
  /// In en, this message translates to:
  /// **'luxuries'**
  String get bucketLuxuriesLower;

  /// No description provided for @coachOverWithOther.
  ///
  /// In en, this message translates to:
  /// **'{name} is {by} over its limit. You still have {left} for {other}, about {perDay} a day until {until}.'**
  String coachOverWithOther(
    String name,
    String by,
    String left,
    String other,
    String perDay,
    String until,
  );

  /// No description provided for @coachOverUsedUp.
  ///
  /// In en, this message translates to:
  /// **'{name} is {by} over its limit, and your spending budget is used up until {until}.'**
  String coachOverUsedUp(String name, String by, String until);

  /// No description provided for @coachAheadTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending is running ahead.'**
  String get coachAheadTitle;

  /// No description provided for @coachAheadBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used {used}% of your spending budget with {left}% of the cycle left. {perDay} a day keeps you on track.'**
  String coachAheadBody(String used, String left, String perDay);

  /// No description provided for @coachOnPaceTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re on pace this cycle.'**
  String get coachOnPaceTitle;

  /// No description provided for @coachOnPaceBody.
  ///
  /// In en, this message translates to:
  /// **'{left} left to spend, about {perDay} a day for the next {days, plural, =1{day} other{{days} days}}.'**
  String coachOnPaceBody(String left, String perDay, int days);

  /// No description provided for @coachPlanLink.
  ///
  /// In en, this message translates to:
  /// **'Plan your budget →'**
  String get coachPlanLink;

  /// No description provided for @coachInsightsLink.
  ///
  /// In en, this message translates to:
  /// **'See insights →'**
  String get coachInsightsLink;

  /// No description provided for @amountThisMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} this month'**
  String amountThisMonth(String amount);
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
