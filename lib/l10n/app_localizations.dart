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

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteNameTitle(String name);

  /// No description provided for @deleteAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'This also deletes every transaction in the account. It cannot be undone.'**
  String get deleteAccountMessage;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get accountDeleted;

  /// No description provided for @accountDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account: {error}'**
  String accountDeleteFailed(String error);

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get walletTitle;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccount;

  /// No description provided for @removeAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Remove an account'**
  String get removeAnAccount;

  /// No description provided for @noAccountsYet.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet. Tap + to add one.'**
  String get noAccountsYet;

  /// No description provided for @netWorth.
  ///
  /// In en, this message translates to:
  /// **'Net worth'**
  String get netWorth;

  /// No description provided for @acrossAccounts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Across 1 account} other{Across {count} accounts}}'**
  String acrossAccounts(int count);

  /// No description provided for @unknownBank.
  ///
  /// In en, this message translates to:
  /// **'Unknown Bank'**
  String get unknownBank;

  /// No description provided for @unknownType.
  ///
  /// In en, this message translates to:
  /// **'Unknown Type'**
  String get unknownType;

  /// No description provided for @typeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current account'**
  String get typeCurrent;

  /// No description provided for @typeSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings account'**
  String get typeSavings;

  /// No description provided for @typeCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get typeCreditCard;

  /// No description provided for @typeLoan.
  ///
  /// In en, this message translates to:
  /// **'Loan'**
  String get typeLoan;

  /// No description provided for @typeInvestment.
  ///
  /// In en, this message translates to:
  /// **'Investment account'**
  String get typeInvestment;

  /// No description provided for @typeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get typeCash;

  /// No description provided for @enterBalanceNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter the balance as a number'**
  String get enterBalanceNumber;

  /// No description provided for @accountAdded.
  ///
  /// In en, this message translates to:
  /// **'Account added'**
  String get accountAdded;

  /// No description provided for @accountAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add the account: {error}'**
  String accountAddFailed(String error);

  /// No description provided for @addAccountManually.
  ///
  /// In en, this message translates to:
  /// **'Add account manually'**
  String get addAccountManually;

  /// No description provided for @bank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bank;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get accountType;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get accountName;

  /// No description provided for @accountNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Salary account'**
  String get accountNameHint;

  /// No description provided for @last4Digits.
  ///
  /// In en, this message translates to:
  /// **'Last 4 digits'**
  String get last4Digits;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @amountOwed.
  ///
  /// In en, this message translates to:
  /// **'Amount owed'**
  String get amountOwed;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get currentBalance;

  /// No description provided for @manualAccountsNote.
  ///
  /// In en, this message translates to:
  /// **'Manual accounts don\'t sync. You\'ll add transactions and update the balance yourself.'**
  String get manualAccountsNote;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @bucketNecessity.
  ///
  /// In en, this message translates to:
  /// **'Necessity'**
  String get bucketNecessity;

  /// No description provided for @bucketLuxury.
  ///
  /// In en, this message translates to:
  /// **'Luxury'**
  String get bucketLuxury;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @catFoodDrinks.
  ///
  /// In en, this message translates to:
  /// **'Food And Drinks'**
  String get catFoodDrinks;

  /// No description provided for @catGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get catGroceries;

  /// No description provided for @catEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get catEntertainment;

  /// No description provided for @catOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get catOthers;

  /// No description provided for @catRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get catRent;

  /// No description provided for @catShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get catShopping;

  /// No description provided for @catTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get catTransport;

  /// No description provided for @catHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get catHealth;

  /// No description provided for @catBills.
  ///
  /// In en, this message translates to:
  /// **'Bills & Utilities'**
  String get catBills;

  /// No description provided for @catSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get catSavings;

  /// No description provided for @budgetDayHelp.
  ///
  /// In en, this message translates to:
  /// **'Your budget cycle starts on this day each month, usually payday.'**
  String get budgetDayHelp;

  /// No description provided for @dayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day of month'**
  String get dayOfMonth;

  /// No description provided for @enterDay.
  ///
  /// In en, this message translates to:
  /// **'Please enter a day'**
  String get enterDay;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @dayRange.
  ///
  /// In en, this message translates to:
  /// **'Day must be between 1 and 31'**
  String get dayRange;

  /// No description provided for @currentDay.
  ///
  /// In en, this message translates to:
  /// **'Current: day {day}'**
  String currentDay(String day);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @budgetDayUpdated.
  ///
  /// In en, this message translates to:
  /// **'Budget reset day updated to {day}'**
  String budgetDayUpdated(String day);

  /// No description provided for @budgetDayFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update day. Try again.'**
  String get budgetDayFailed;

  /// No description provided for @allAccounts.
  ///
  /// In en, this message translates to:
  /// **'All accounts'**
  String get allAccounts;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @categoryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated category to {name}'**
  String categoryUpdated(String name);

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get merchant;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @sourceManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get sourceManual;

  /// No description provided for @sourceSms.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get sourceSms;

  /// No description provided for @sourceBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get sourceBank;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @addedBy.
  ///
  /// In en, this message translates to:
  /// **'Added by'**
  String get addedBy;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @assignToHousehold.
  ///
  /// In en, this message translates to:
  /// **'Assign to household'**
  String get assignToHousehold;

  /// No description provided for @transactionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get transactionDeleted;

  /// No description provided for @transactionDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting transaction: {error}'**
  String transactionDeleteError(String error);

  /// No description provided for @deleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction'**
  String get deleteTransaction;

  /// No description provided for @removeFromHousehold.
  ///
  /// In en, this message translates to:
  /// **'Remove from household'**
  String get removeFromHousehold;

  /// No description provided for @notInAnyHousehold.
  ///
  /// In en, this message translates to:
  /// **'You are not part of any household.'**
  String get notInAnyHousehold;

  /// No description provided for @transactionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Transaction not found'**
  String get transactionNotFound;

  /// No description provided for @assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to \'{name}\' successfully!'**
  String assignedTo(String name);

  /// No description provided for @loadTransactionsFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load transactions'**
  String get loadTransactionsFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsTitle;

  /// No description provided for @addFirstTransaction.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first one.'**
  String get addFirstTransaction;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @noMatchingTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions match these filters'**
  String get noMatchingTransactions;

  /// No description provided for @tryOtherFilters.
  ///
  /// In en, this message translates to:
  /// **'Try a different account, category or date.'**
  String get tryOtherFilters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @selectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select Month'**
  String get selectMonth;

  /// No description provided for @periodAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get periodAll;

  /// No description provided for @periodLast7.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get periodLast7;

  /// No description provided for @periodLast30.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get periodLast30;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @transactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTitle;

  /// No description provided for @deleteTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this transaction?'**
  String get deleteTransactionTitle;

  /// No description provided for @deleteTxnReturned.
  ///
  /// In en, this message translates to:
  /// **'It will be removed and {amount} returned to the account balance.'**
  String deleteTxnReturned(String amount);

  /// No description provided for @deleteTxnTakenOff.
  ///
  /// In en, this message translates to:
  /// **'It will be removed and {amount} taken off the account balance.'**
  String deleteTxnTakenOff(String amount);

  /// No description provided for @transactionDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the transaction: {error}'**
  String transactionDeleteFailed(String error);

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get addTransaction;

  /// No description provided for @removeATransaction.
  ///
  /// In en, this message translates to:
  /// **'Remove a transaction'**
  String get removeATransaction;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount.'**
  String get enterValidAmount;

  /// No description provided for @selectAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Select an account.'**
  String get selectAnAccount;

  /// No description provided for @transactionAdded.
  ///
  /// In en, this message translates to:
  /// **'Transaction added.'**
  String get transactionAdded;

  /// No description provided for @smsNoAmount.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find an amount in this message. Try the Manual tab.'**
  String get smsNoAmount;

  /// No description provided for @addATransaction.
  ///
  /// In en, this message translates to:
  /// **'Add a transaction'**
  String get addATransaction;

  /// No description provided for @pasteBankSms.
  ///
  /// In en, this message translates to:
  /// **'Paste your bank SMS'**
  String get pasteBankSms;

  /// No description provided for @trySample.
  ///
  /// In en, this message translates to:
  /// **'Try a sample message'**
  String get trySample;

  /// No description provided for @readMessage.
  ///
  /// In en, this message translates to:
  /// **'Read message'**
  String get readMessage;

  /// No description provided for @smsWillFill.
  ///
  /// In en, this message translates to:
  /// **'We\'ll fill in the details so you can check them before saving.'**
  String get smsWillFill;

  /// No description provided for @filledFromSms.
  ///
  /// In en, this message translates to:
  /// **'Filled from your SMS. Check the details below.'**
  String get filledFromSms;

  /// No description provided for @noAccountsAddInWallet.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet. Add one in Wallet first.'**
  String get noAccountsAddInWallet;

  /// No description provided for @amountIn.
  ///
  /// In en, this message translates to:
  /// **'Amount ({currency})'**
  String amountIn(String currency);

  /// No description provided for @merchantFrom.
  ///
  /// In en, this message translates to:
  /// **'Merchant / From'**
  String get merchantFrom;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @transactionCountRecent.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transaction · Most recent} other{{count} transactions · Most recent}}'**
  String transactionCountRecent(int count);

  /// No description provided for @spendingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Spendings'**
  String get spendingsTitle;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @latestTransactions.
  ///
  /// In en, this message translates to:
  /// **'Latest transactions'**
  String get latestTransactions;

  /// No description provided for @spentInMonthSoFar.
  ///
  /// In en, this message translates to:
  /// **'Spent in {month} so far'**
  String spentInMonthSoFar(String month);

  /// No description provided for @percentUsed.
  ///
  /// In en, this message translates to:
  /// **'{percent}% used'**
  String percentUsed(String percent);

  /// No description provided for @ofAmount.
  ///
  /// In en, this message translates to:
  /// **'of {amount}'**
  String ofAmount(String amount);

  /// No description provided for @noBudgetThisCycle.
  ///
  /// In en, this message translates to:
  /// **'No budget plan for this cycle yet'**
  String get noBudgetThisCycle;

  /// No description provided for @daysToGo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day to go} other{{count} days to go}}'**
  String daysToGo(int count);

  /// No description provided for @noCategorizedSpending.
  ///
  /// In en, this message translates to:
  /// **'No categorized spending yet.\nAssign categories to transactions to see them here.'**
  String get noCategorizedSpending;

  /// No description provided for @loadBudgetError.
  ///
  /// In en, this message translates to:
  /// **'Error loading budget: {error}'**
  String loadBudgetError(String error);

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insightsTitle;

  /// No description provided for @vsMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} vs {month}'**
  String vsMonth(String amount, String month);

  /// No description provided for @categoryDown.
  ///
  /// In en, this message translates to:
  /// **'{name} is down {amount}'**
  String categoryDown(String name, String amount);

  /// No description provided for @categoryUp.
  ///
  /// In en, this message translates to:
  /// **'{name} is up {amount}'**
  String categoryUp(String name, String amount);

  /// No description provided for @comparedWithMonth.
  ///
  /// In en, this message translates to:
  /// **'Compared with this point in {month}.'**
  String comparedWithMonth(String month);

  /// No description provided for @biggestDrop.
  ///
  /// In en, this message translates to:
  /// **'Compared with this point in {month}. That\'s the biggest drop of any category.'**
  String biggestDrop(String month);

  /// No description provided for @byCategory.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get byCategory;

  /// No description provided for @noSpendingTwoMonths.
  ///
  /// In en, this message translates to:
  /// **'No spending yet this month or last.'**
  String get noSpendingTwoMonths;

  /// No description provided for @onePurchase.
  ///
  /// In en, this message translates to:
  /// **'Most of it came from one purchase on {date}. Worth a look before the month closes.'**
  String onePurchase(String date);

  /// No description provided for @categoryAdded.
  ///
  /// In en, this message translates to:
  /// **'Category added'**
  String get categoryAdded;

  /// No description provided for @deleteCategoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Its transactions keep their amounts but will have no category.'**
  String get deleteCategoryMessage;

  /// No description provided for @categoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category \"{name}\" deleted and unassigned.'**
  String categoryDeleted(String name);

  /// No description provided for @categoryDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting category: {error}'**
  String categoryDeleteError(String error);

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortHigh.
  ///
  /// In en, this message translates to:
  /// **'Highest spent'**
  String get sortHigh;

  /// No description provided for @sortLow.
  ///
  /// In en, this message translates to:
  /// **'Lowest spent'**
  String get sortLow;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name (A–Z)'**
  String get sortName;

  /// No description provided for @sortLimit.
  ///
  /// In en, this message translates to:
  /// **'Closest to limit'**
  String get sortLimit;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @filterCount.
  ///
  /// In en, this message translates to:
  /// **'Filter · {count}'**
  String filterCount(String count);

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @removeACategory.
  ///
  /// In en, this message translates to:
  /// **'Remove a category'**
  String get removeACategory;

  /// No description provided for @noCategoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No categories yet. Tap + to create one.'**
  String get noCategoriesYet;

  /// No description provided for @noCategoriesMatch.
  ///
  /// In en, this message translates to:
  /// **'No categories match this filter.'**
  String get noCategoriesMatch;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get clearFilter;

  /// No description provided for @noBudgetPlanned.
  ///
  /// In en, this message translates to:
  /// **'No budget planned'**
  String get noBudgetPlanned;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @onlyWithSpending.
  ///
  /// In en, this message translates to:
  /// **'Only categories with spending'**
  String get onlyWithSpending;

  /// No description provided for @onlyOverLimit.
  ///
  /// In en, this message translates to:
  /// **'Only categories over their limit'**
  String get onlyOverLimit;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @showResults.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get showResults;

  /// No description provided for @giveCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Give the category a name.'**
  String get giveCategoryName;

  /// No description provided for @categoryExists.
  ///
  /// In en, this message translates to:
  /// **'You already have a category called \"{name}\".'**
  String categoryExists(String name);

  /// No description provided for @categoryAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add the category: {error}'**
  String categoryAddFailed(String error);

  /// No description provided for @addNewCategory.
  ///
  /// In en, this message translates to:
  /// **'Add a new category'**
  String get addNewCategory;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @monthlyLimit.
  ///
  /// In en, this message translates to:
  /// **'Monthly spending limit'**
  String get monthlyLimit;

  /// No description provided for @noLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get noLimit;

  /// No description provided for @necessitiesBudget.
  ///
  /// In en, this message translates to:
  /// **'Necessities budget'**
  String get necessitiesBudget;

  /// No description provided for @luxuriesBudget.
  ///
  /// In en, this message translates to:
  /// **'Luxuries budget'**
  String get luxuriesBudget;

  /// No description provided for @notPlanned.
  ///
  /// In en, this message translates to:
  /// **'Not planned'**
  String get notPlanned;

  /// No description provided for @thisLimit.
  ///
  /// In en, this message translates to:
  /// **'This limit'**
  String get thisLimit;

  /// No description provided for @percentOfBudget.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of budget'**
  String percentOfBudget(String percent);

  /// No description provided for @budgetingTitle.
  ///
  /// In en, this message translates to:
  /// **'Budgeting'**
  String get budgetingTitle;

  /// No description provided for @noBudgetPlanYet.
  ///
  /// In en, this message translates to:
  /// **'No budget plan yet'**
  String get noBudgetPlanYet;

  /// No description provided for @budgetEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Split your income into savings, necessities and luxuries, and see how each cycle tracks against it.'**
  String get budgetEmptyBody;

  /// No description provided for @createBudgetPlan.
  ///
  /// In en, this message translates to:
  /// **'Create budget plan'**
  String get createBudgetPlan;

  /// No description provided for @spendingByBucket.
  ///
  /// In en, this message translates to:
  /// **'Spending by bucket'**
  String get spendingByBucket;

  /// No description provided for @noSpendingSixMonths.
  ///
  /// In en, this message translates to:
  /// **'No spending in the last six months yet'**
  String get noSpendingSixMonths;

  /// No description provided for @budgetPlanFor.
  ///
  /// In en, this message translates to:
  /// **'Budget plan for {month}'**
  String budgetPlanFor(String month);

  /// No description provided for @editBudgetPlan.
  ///
  /// In en, this message translates to:
  /// **'Edit budget plan'**
  String get editBudgetPlan;

  /// No description provided for @totalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total income'**
  String get totalIncome;

  /// No description provided for @spentSoFar.
  ///
  /// In en, this message translates to:
  /// **'Spent so far'**
  String get spentSoFar;

  /// No description provided for @upcomingPayments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming payments'**
  String get upcomingPayments;

  /// No description provided for @addABill.
  ///
  /// In en, this message translates to:
  /// **'Add a bill'**
  String get addABill;

  /// No description provided for @removeABill.
  ///
  /// In en, this message translates to:
  /// **'Remove a bill'**
  String get removeABill;

  /// No description provided for @billDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the bill: {error}'**
  String billDeleteFailed(String error);

  /// No description provided for @noUpcomingPayments.
  ///
  /// In en, this message translates to:
  /// **'No upcoming payments yet. Tap + to add a bill.'**
  String get noUpcomingPayments;

  /// No description provided for @seeAllCount.
  ///
  /// In en, this message translates to:
  /// **'See all {count}'**
  String seeAllCount(String count);

  /// No description provided for @noDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get noDate;

  /// No description provided for @nextDate.
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String nextDate(String date);

  /// No description provided for @fromAccount.
  ///
  /// In en, this message translates to:
  /// **'From {account}'**
  String fromAccount(String account);

  /// No description provided for @paymentsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String paymentsLeft(String count);

  /// No description provided for @yourBudgetPlan.
  ///
  /// In en, this message translates to:
  /// **'Your budget plan'**
  String get yourBudgetPlan;

  /// No description provided for @totalMonthlyIncome.
  ///
  /// In en, this message translates to:
  /// **'Total monthly income'**
  String get totalMonthlyIncome;

  /// No description provided for @planSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the plan: {error}'**
  String planSaveFailed(String error);

  /// No description provided for @savePlan.
  ///
  /// In en, this message translates to:
  /// **'Save plan'**
  String get savePlan;

  /// No description provided for @enterAmountToPlan.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount to plan it.'**
  String get enterAmountToPlan;

  /// No description provided for @overBy.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String overBy(String amount);

  /// No description provided for @allPlanned.
  ///
  /// In en, this message translates to:
  /// **'All of it is planned'**
  String get allPlanned;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @savingsGoalAdded.
  ///
  /// In en, this message translates to:
  /// **'Savings goal added'**
  String get savingsGoalAdded;

  /// No description provided for @allocateToGoal.
  ///
  /// In en, this message translates to:
  /// **'Allocate to {goal}'**
  String allocateToGoal(String goal);

  /// No description provided for @availableAmount.
  ///
  /// In en, this message translates to:
  /// **'Available: {amount}'**
  String availableAmount(String amount);

  /// No description provided for @inThisGoal.
  ///
  /// In en, this message translates to:
  /// **'In this goal: {amount}'**
  String inThisGoal(String amount);

  /// No description provided for @stillNeeded.
  ///
  /// In en, this message translates to:
  /// **'Still needed: {amount}'**
  String stillNeeded(String amount);

  /// No description provided for @amountToAllocate.
  ///
  /// In en, this message translates to:
  /// **'Amount to allocate'**
  String get amountToAllocate;

  /// No description provided for @removeFromGoal.
  ///
  /// In en, this message translates to:
  /// **'Remove from goal'**
  String get removeFromGoal;

  /// No description provided for @allocate.
  ///
  /// In en, this message translates to:
  /// **'Allocate'**
  String get allocate;

  /// No description provided for @insufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient available balance'**
  String get insufficientBalance;

  /// No description provided for @goalFullyFunded.
  ///
  /// In en, this message translates to:
  /// **'This goal is already fully funded'**
  String get goalFullyFunded;

  /// No description provided for @allocatingCapped.
  ///
  /// In en, this message translates to:
  /// **'Allocating {amount} (capped to remaining goal amount)'**
  String allocatingCapped(String amount);

  /// No description provided for @deleteGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this goal?'**
  String get deleteGoalTitle;

  /// No description provided for @deleteGoalMessage.
  ///
  /// In en, this message translates to:
  /// **'The goal and its progress will be removed. It cannot be undone.'**
  String get deleteGoalMessage;

  /// No description provided for @goalDeleted.
  ///
  /// In en, this message translates to:
  /// **'Savings goal deleted successfully'**
  String get goalDeleted;

  /// No description provided for @goalDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting goal: {error}'**
  String goalDeleteError(String error);

  /// No description provided for @removeFromGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from {goal}'**
  String removeFromGoalTitle(String goal);

  /// No description provided for @amountToRemove.
  ///
  /// In en, this message translates to:
  /// **'Amount to remove'**
  String get amountToRemove;

  /// No description provided for @removeAll.
  ///
  /// In en, this message translates to:
  /// **'Remove all'**
  String get removeAll;

  /// No description provided for @amountExceedsAllocation.
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds current allocation'**
  String get amountExceedsAllocation;

  /// No description provided for @amountAllocated.
  ///
  /// In en, this message translates to:
  /// **'{amount} allocated successfully!'**
  String amountAllocated(String amount);

  /// No description provided for @amountRemovedFromGoal.
  ///
  /// In en, this message translates to:
  /// **'{amount} removed successfully!'**
  String amountRemovedFromGoal(String amount);

  /// No description provided for @noSavingsGoalsYet.
  ///
  /// In en, this message translates to:
  /// **'No savings goals yet'**
  String get noSavingsGoalsYet;

  /// No description provided for @savingsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create a goal and move money from your savings into it as you go.'**
  String get savingsEmptyBody;

  /// No description provided for @createSavingsGoal.
  ///
  /// In en, this message translates to:
  /// **'Create a savings goal'**
  String get createSavingsGoal;

  /// No description provided for @savingGoals.
  ///
  /// In en, this message translates to:
  /// **'Saving goals'**
  String get savingGoals;

  /// No description provided for @newGoal.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get newGoal;

  /// No description provided for @removeAGoal.
  ///
  /// In en, this message translates to:
  /// **'Remove a goal'**
  String get removeAGoal;

  /// No description provided for @totalSaved.
  ///
  /// In en, this message translates to:
  /// **'Total saved'**
  String get totalSaved;

  /// No description provided for @allocatedToGoals.
  ///
  /// In en, this message translates to:
  /// **'Allocated to goals'**
  String get allocatedToGoals;

  /// No description provided for @leftToAllocate.
  ///
  /// In en, this message translates to:
  /// **'Left to allocate'**
  String get leftToAllocate;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @amountOfAmount.
  ///
  /// In en, this message translates to:
  /// **'{current} of {target}'**
  String amountOfAmount(String current, String target);

  /// No description provided for @perMonthByDate.
  ///
  /// In en, this message translates to:
  /// **'{amount} a month · by {date}'**
  String perMonthByDate(String amount, String date);

  /// No description provided for @perMonthFor.
  ///
  /// In en, this message translates to:
  /// **'{amount} a month · {duration}'**
  String perMonthFor(String amount, String duration);

  /// No description provided for @monthsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month} other{{count} months}}'**
  String monthsCount(int count);

  /// No description provided for @yearsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year} other{{count} years}}'**
  String yearsCount(int count);

  /// No description provided for @yearsAndMonths.
  ///
  /// In en, this message translates to:
  /// **'{years} and {months}'**
  String yearsAndMonths(String years, String months);

  /// No description provided for @giveGoalName.
  ///
  /// In en, this message translates to:
  /// **'Give the goal a name.'**
  String get giveGoalName;

  /// No description provided for @enterSaveAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter how much you want to save.'**
  String get enterSaveAmount;

  /// No description provided for @enterMonthsOrDate.
  ///
  /// In en, this message translates to:
  /// **'Enter how many months, or pick a target date.'**
  String get enterMonthsOrDate;

  /// No description provided for @goalAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add the goal: {error}'**
  String goalAddFailed(String error);

  /// No description provided for @newSavingsGoal.
  ///
  /// In en, this message translates to:
  /// **'New savings goal'**
  String get newSavingsGoal;

  /// No description provided for @addGoal.
  ///
  /// In en, this message translates to:
  /// **'Add goal'**
  String get addGoal;

  /// No description provided for @goalName.
  ///
  /// In en, this message translates to:
  /// **'Goal name'**
  String get goalName;

  /// No description provided for @totalTargetAmount.
  ///
  /// In en, this message translates to:
  /// **'Total target amount'**
  String get totalTargetAmount;

  /// No description provided for @targetPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Target amount per month'**
  String get targetPerMonth;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get months;

  /// No description provided for @targetDate.
  ///
  /// In en, this message translates to:
  /// **'Target date'**
  String get targetDate;

  /// No description provided for @deleteBillTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this bill?'**
  String get deleteBillTitle;

  /// No description provided for @willBeRemoved.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be removed.'**
  String willBeRemoved(String name);

  /// No description provided for @billUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the bill: {error}'**
  String billUpdateFailed(String error);

  /// No description provided for @billSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the bill: {error}'**
  String billSaveFailed(String error);

  /// No description provided for @billsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bills & subscriptions'**
  String get billsTitle;

  /// No description provided for @stillDueThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Still due this month'**
  String get stillDueThisMonth;

  /// No description provided for @perMo.
  ///
  /// In en, this message translates to:
  /// **'/mo'**
  String get perMo;

  /// No description provided for @noBillsYet.
  ///
  /// In en, this message translates to:
  /// **'No bills yet'**
  String get noBillsYet;

  /// No description provided for @billsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add rent, phone, subscriptions and anything else you pay each month. Standing orders from your bank show up here too.'**
  String get billsEmptyBody;

  /// No description provided for @bills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get bills;

  /// No description provided for @billsFootnote.
  ///
  /// In en, this message translates to:
  /// **'Toggle on to mark a bill as autopay. Standing orders are set up at your bank.'**
  String get billsFootnote;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @wasDue.
  ///
  /// In en, this message translates to:
  /// **'Was due {date}'**
  String wasDue(String date);

  /// No description provided for @noDateSet.
  ///
  /// In en, this message translates to:
  /// **'No date set'**
  String get noDateSet;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// No description provided for @dueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get dueTomorrow;

  /// No description provided for @dueInDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Due in 1 day} other{Due in {count} days}}'**
  String dueInDays(int count);

  /// No description provided for @incoming.
  ///
  /// In en, this message translates to:
  /// **'incoming'**
  String get incoming;

  /// No description provided for @autopayLower.
  ///
  /// In en, this message translates to:
  /// **'autopay'**
  String get autopayLower;

  /// No description provided for @editBill.
  ///
  /// In en, this message translates to:
  /// **'Edit bill'**
  String get editBill;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @billNameHint.
  ///
  /// In en, this message translates to:
  /// **'Rent, phone, Netflix...'**
  String get billNameHint;

  /// No description provided for @dueEveryMonthOn.
  ///
  /// In en, this message translates to:
  /// **'Due every month on'**
  String get dueEveryMonthOn;

  /// No description provided for @dayN.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String dayN(int day);

  /// No description provided for @shorterMonthsNote.
  ///
  /// In en, this message translates to:
  /// **'In shorter months it falls on the last day.'**
  String get shorterMonthsNote;

  /// No description provided for @paidFrom.
  ///
  /// In en, this message translates to:
  /// **'Paid from'**
  String get paidFrom;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @subscriptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Counted in your monthly subscriptions'**
  String get subscriptionSubtitle;

  /// No description provided for @autopay.
  ///
  /// In en, this message translates to:
  /// **'Autopay'**
  String get autopay;

  /// No description provided for @autopaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Comes out automatically'**
  String get autopaySubtitle;

  /// No description provided for @addBill.
  ///
  /// In en, this message translates to:
  /// **'Add bill'**
  String get addBill;

  /// No description provided for @deleteBill.
  ///
  /// In en, this message translates to:
  /// **'Delete bill'**
  String get deleteBill;

  /// No description provided for @billFallback.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get billFallback;

  /// No description provided for @scheduledPayment.
  ///
  /// In en, this message translates to:
  /// **'Scheduled payment'**
  String get scheduledPayment;

  /// No description provided for @accountFallback.
  ///
  /// In en, this message translates to:
  /// **'Account {id}'**
  String accountFallback(String id);

  /// No description provided for @hhInviteShare.
  ///
  /// In en, this message translates to:
  /// **'Join my household \'{name}\' on Vesta! Click here: {link}'**
  String hhInviteShare(String name, String link);

  /// No description provided for @hhInviteSubject.
  ///
  /// In en, this message translates to:
  /// **'You\'re invited to join my household!'**
  String get hhInviteSubject;

  /// No description provided for @aHousehold.
  ///
  /// In en, this message translates to:
  /// **'a household'**
  String get aHousehold;

  /// No description provided for @inviteCreateError.
  ///
  /// In en, this message translates to:
  /// **'Error creating invite: {error}'**
  String inviteCreateError(String error);

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @household.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get household;

  /// No description provided for @noLongerInHousehold.
  ///
  /// In en, this message translates to:
  /// **'You\'re no longer in this household'**
  String get noLongerInHousehold;

  /// No description provided for @noLongerInHouseholdBody.
  ///
  /// In en, this message translates to:
  /// **'It was deleted, or its owner removed you.'**
  String get noLongerInHouseholdBody;

  /// No description provided for @backToShared.
  ///
  /// In en, this message translates to:
  /// **'Back to Shared finances'**
  String get backToShared;

  /// No description provided for @nameAdmin.
  ///
  /// In en, this message translates to:
  /// **'{name} (admin)'**
  String nameAdmin(String name);

  /// No description provided for @nameYou.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String nameYou(String name);

  /// No description provided for @noHouseholdBudget.
  ///
  /// In en, this message translates to:
  /// **'No household budget yet'**
  String get noHouseholdBudget;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @overTag.
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get overTag;

  /// No description provided for @overall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get overall;

  /// No description provided for @atRisk.
  ///
  /// In en, this message translates to:
  /// **'At risk'**
  String get atRisk;

  /// No description provided for @financialHealth.
  ///
  /// In en, this message translates to:
  /// **'Financial health'**
  String get financialHealth;

  /// No description provided for @noSharedSpendingSixMonths.
  ///
  /// In en, this message translates to:
  /// **'No shared spending in the last six months yet'**
  String get noSharedSpendingSixMonths;

  /// No description provided for @householdBudgetPlan.
  ///
  /// In en, this message translates to:
  /// **'Household budget plan'**
  String get householdBudgetPlan;

  /// No description provided for @totalMonthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Total monthly budget'**
  String get totalMonthlyBudget;

  /// No description provided for @totalBudget.
  ///
  /// In en, this message translates to:
  /// **'Total budget'**
  String get totalBudget;

  /// No description provided for @noBudgetTapPencil.
  ///
  /// In en, this message translates to:
  /// **'No budget set yet. Tap the pencil to plan one.'**
  String get noBudgetTapPencil;

  /// No description provided for @overThisCycleSplit.
  ///
  /// In en, this message translates to:
  /// **'{amount} over this cycle. Tap the pencil to split the budget into buckets.'**
  String overThisCycleSplit(String amount);

  /// No description provided for @leftThisCycleSplit.
  ///
  /// In en, this message translates to:
  /// **'{amount} left this cycle. Tap the pencil to split the budget into buckets.'**
  String leftThisCycleSplit(String amount);

  /// No description provided for @householdBudgetLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading household budget: {error}'**
  String householdBudgetLoadError(String error);

  /// No description provided for @noSharedCategorized.
  ///
  /// In en, this message translates to:
  /// **'No categorized spending yet.\nAssign categories to shared transactions to see them here.'**
  String get noSharedCategorized;

  /// No description provided for @transactionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transaction} other{{count} transactions}}'**
  String transactionCount(int count);

  /// No description provided for @noSharedTransactions.
  ///
  /// In en, this message translates to:
  /// **'No shared transactions yet.\nAssign one from a transaction\'s details.'**
  String get noSharedTransactions;

  /// No description provided for @noHouseholdsYet.
  ///
  /// In en, this message translates to:
  /// **'No households yet'**
  String get noHouseholdsYet;

  /// No description provided for @householdsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create a household to run a budget with the people you live with.'**
  String get householdsEmptyBody;

  /// No description provided for @createHousehold.
  ///
  /// In en, this message translates to:
  /// **'Create a household'**
  String get createHousehold;

  /// No description provided for @sharedHouseholds.
  ///
  /// In en, this message translates to:
  /// **'Shared households'**
  String get sharedHouseholds;

  /// No description provided for @newHousehold.
  ///
  /// In en, this message translates to:
  /// **'New household'**
  String get newHousehold;

  /// No description provided for @leaveOrDeleteHousehold.
  ///
  /// In en, this message translates to:
  /// **'Leave or delete a household'**
  String get leaveOrDeleteHousehold;

  /// No description provided for @thisHousehold.
  ///
  /// In en, this message translates to:
  /// **'this household'**
  String get thisHousehold;

  /// No description provided for @unnamedHousehold.
  ///
  /// In en, this message translates to:
  /// **'Unnamed household'**
  String get unnamedHousehold;

  /// No description provided for @memberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String memberCount(int count);

  /// No description provided for @noBudgetOpenToSet.
  ///
  /// In en, this message translates to:
  /// **'No budget yet. Open to set one.'**
  String get noBudgetOpenToSet;

  /// No description provided for @noBudgetSetYet.
  ///
  /// In en, this message translates to:
  /// **'No budget set yet'**
  String get noBudgetSetYet;

  /// No description provided for @logInToSeeHouseholds.
  ///
  /// In en, this message translates to:
  /// **'Please log in to see your households.'**
  String get logInToSeeHouseholds;

  /// No description provided for @userDataNotFound.
  ///
  /// In en, this message translates to:
  /// **'User data not found.'**
  String get userDataNotFound;

  /// No description provided for @joiningHousehold.
  ///
  /// In en, this message translates to:
  /// **'Joining the household...'**
  String get joiningHousehold;

  /// No description provided for @inviteDeclined.
  ///
  /// In en, this message translates to:
  /// **'Invite declined'**
  String get inviteDeclined;

  /// No description provided for @inviteAnswerFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t answer the invite: {error}'**
  String inviteAnswerFailed(String error);

  /// No description provided for @invitedYouToJoin.
  ///
  /// In en, this message translates to:
  /// **'{inviter} invited you to join {household}.'**
  String invitedYouToJoin(String inviter, String household);

  /// No description provided for @someone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get someone;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @deleteHouseholdMessage.
  ///
  /// In en, this message translates to:
  /// **'The household and its shared budget are removed for every member. This cannot be undone.'**
  String get deleteHouseholdMessage;

  /// No description provided for @householdDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the household: {error}'**
  String householdDeleteFailed(String error);

  /// No description provided for @leaveNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave {name}?'**
  String leaveNameTitle(String name);

  /// No description provided for @leaveHouseholdMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll stop seeing its budget and transactions. The owner can invite you again.'**
  String get leaveHouseholdMessage;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @householdLeaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t leave the household: {error}'**
  String householdLeaveFailed(String error);

  /// No description provided for @removeNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeNameTitle(String name);

  /// No description provided for @removeMemberMessage.
  ///
  /// In en, this message translates to:
  /// **'They\'ll lose access to this household. You can invite them again later.'**
  String get removeMemberMessage;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeMember;

  /// No description provided for @memberRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove {name}: {error}'**
  String memberRemoveFailed(String name, String error);

  /// No description provided for @logInToInvite.
  ///
  /// In en, this message translates to:
  /// **'Log in again to invite someone.'**
  String get logInToInvite;

  /// No description provided for @enterUsernameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a username or email.'**
  String get enterUsernameOrEmail;

  /// No description provided for @noUserGoesBy.
  ///
  /// In en, this message translates to:
  /// **'No Vesta user goes by \"{query}\".'**
  String noUserGoesBy(String query);

  /// No description provided for @thatsYou.
  ///
  /// In en, this message translates to:
  /// **'That\'s you.'**
  String get thatsYou;

  /// No description provided for @alreadyInHousehold.
  ///
  /// In en, this message translates to:
  /// **'They\'re already in this household.'**
  String get alreadyInHousehold;

  /// No description provided for @giveHouseholdName.
  ///
  /// In en, this message translates to:
  /// **'Give the household a name.'**
  String get giveHouseholdName;

  /// No description provided for @householdCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the household: {error}'**
  String householdCreateFailed(String error);

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @householdName.
  ///
  /// In en, this message translates to:
  /// **'Household name'**
  String get householdName;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save: {error}'**
  String saveFailed(String error);

  /// No description provided for @inviteSentTo.
  ///
  /// In en, this message translates to:
  /// **'Invite sent to {name}. They can accept it in Shared finances.'**
  String inviteSentTo(String name);

  /// No description provided for @inviteSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the invite: {error}'**
  String inviteSendFailed(String error);

  /// No description provided for @editHousehold.
  ///
  /// In en, this message translates to:
  /// **'Edit household'**
  String get editHousehold;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @youParen.
  ///
  /// In en, this message translates to:
  /// **'(you)'**
  String get youParen;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @shareInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Share invite link'**
  String get shareInviteLink;

  /// No description provided for @youAreAdmin.
  ///
  /// In en, this message translates to:
  /// **'You\'re the admin because you created this household. Only the admin can add or remove members.'**
  String get youAreAdmin;

  /// No description provided for @onlyAdminNamed.
  ///
  /// In en, this message translates to:
  /// **'Only the admin ({name}) can add or remove members.'**
  String onlyAdminNamed(String name);

  /// No description provided for @onlyAdmin.
  ///
  /// In en, this message translates to:
  /// **'Only the admin can add or remove members.'**
  String get onlyAdmin;

  /// No description provided for @deleteHousehold.
  ///
  /// In en, this message translates to:
  /// **'Delete household'**
  String get deleteHousehold;

  /// No description provided for @willBeRemovedForEveryone.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be removed for everyone.'**
  String willBeRemovedForEveryone(String name);

  /// No description provided for @addSharedBill.
  ///
  /// In en, this message translates to:
  /// **'Add a shared bill'**
  String get addSharedBill;

  /// No description provided for @noSharedBills.
  ///
  /// In en, this message translates to:
  /// **'No shared bills yet. Add rent, utilities, or subscriptions you split.'**
  String get noSharedBills;

  /// No description provided for @whenToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get whenToday;

  /// No description provided for @whenTomorrow.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get whenTomorrow;

  /// No description provided for @whenInDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{in 1 day} other{in {count} days}}'**
  String whenInDays(int count);

  /// No description provided for @billDueLine.
  ///
  /// In en, this message translates to:
  /// **'Due {date} · {when} · Monthly'**
  String billDueLine(String date, String when);

  /// No description provided for @giveBillName.
  ///
  /// In en, this message translates to:
  /// **'Give the bill a name.'**
  String get giveBillName;

  /// No description provided for @enterTheAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount.'**
  String get enterTheAmount;

  /// No description provided for @pickDueDay.
  ///
  /// In en, this message translates to:
  /// **'Pick a due day from 1 to 31.'**
  String get pickDueDay;

  /// No description provided for @sharesDontAddUp.
  ///
  /// In en, this message translates to:
  /// **'The shares add up to {total}, not {amount}.'**
  String sharesDontAddUp(String total, String amount);

  /// No description provided for @newSharedBill.
  ///
  /// In en, this message translates to:
  /// **'New shared bill'**
  String get newSharedBill;

  /// No description provided for @egRent.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rent'**
  String get egRent;

  /// No description provided for @dueDay.
  ///
  /// In en, this message translates to:
  /// **'Due day'**
  String get dueDay;

  /// No description provided for @splitEvenly.
  ///
  /// In en, this message translates to:
  /// **'Split evenly'**
  String get splitEvenly;

  /// No description provided for @amountEach.
  ///
  /// In en, this message translates to:
  /// **'{amount} each'**
  String amountEach(String amount);

  /// No description provided for @setEachPays.
  ///
  /// In en, this message translates to:
  /// **'Or set what each member pays'**
  String get setEachPays;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {error}'**
  String somethingWentWrong(String error);

  /// No description provided for @sharedGoalAdded.
  ///
  /// In en, this message translates to:
  /// **'Shared goal added'**
  String get sharedGoalAdded;

  /// No description provided for @deleteSharedGoalMessage.
  ///
  /// In en, this message translates to:
  /// **'It\'s removed for everyone. What members put in goes back to their free share.'**
  String get deleteSharedGoalMessage;

  /// No description provided for @sharedByMembers.
  ///
  /// In en, this message translates to:
  /// **'Shared by members'**
  String get sharedByMembers;

  /// No description provided for @allocatedShared.
  ///
  /// In en, this message translates to:
  /// **'Allocated / shared'**
  String get allocatedShared;

  /// No description provided for @setHowMuchYouShare.
  ///
  /// In en, this message translates to:
  /// **'Set how much you share'**
  String get setHowMuchYouShare;

  /// No description provided for @setMonthlyPlanHint.
  ///
  /// In en, this message translates to:
  /// **'Set what you plan to add each month to track the household\'s monthly savings.'**
  String get setMonthlyPlanHint;

  /// No description provided for @monthSavingsGoal.
  ///
  /// In en, this message translates to:
  /// **'{month} savings goal {amount}'**
  String monthSavingsGoal(String month, String amount);

  /// No description provided for @reached.
  ///
  /// In en, this message translates to:
  /// **'Reached'**
  String get reached;

  /// No description provided for @notYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYet;

  /// No description provided for @savedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} saved this month.'**
  String savedThisMonth(String amount);

  /// No description provided for @savedSoFarToGo.
  ///
  /// In en, this message translates to:
  /// **'{saved} saved so far, {toGo} to go with {days} left.'**
  String savedSoFarToGo(String saved, String toGo, String days);

  /// No description provided for @plansPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Plans {amount} a month'**
  String plansPerMonth(String amount);

  /// No description provided for @noMonthlyPlan.
  ///
  /// In en, this message translates to:
  /// **'No monthly plan yet'**
  String get noMonthlyPlan;

  /// No description provided for @amountFree.
  ///
  /// In en, this message translates to:
  /// **'{amount} free'**
  String amountFree(String amount);

  /// No description provided for @newSharedGoal.
  ///
  /// In en, this message translates to:
  /// **'New shared goal'**
  String get newSharedGoal;

  /// No description provided for @noSharedGoals.
  ///
  /// In en, this message translates to:
  /// **'No shared goals yet. Add one to save for something together.'**
  String get noSharedGoals;

  /// No description provided for @byDate.
  ///
  /// In en, this message translates to:
  /// **'By {date}'**
  String byDate(String date);

  /// No description provided for @shareAtLeast.
  ///
  /// In en, this message translates to:
  /// **'You already put {amount} into goals, so share at least that.'**
  String shareAtLeast(String amount);

  /// No description provided for @yourSavingsShare.
  ///
  /// In en, this message translates to:
  /// **'Your savings share'**
  String get yourSavingsShare;

  /// No description provided for @savingsShareMessage.
  ///
  /// In en, this message translates to:
  /// **'How much of your savings you share with the household, and what you plan to add each month. Everyone in it sees these.'**
  String get savingsShareMessage;

  /// No description provided for @amountYouShare.
  ///
  /// In en, this message translates to:
  /// **'Amount you share'**
  String get amountYouShare;

  /// No description provided for @planToAddMonthly.
  ///
  /// In en, this message translates to:
  /// **'You plan to add each month'**
  String get planToAddMonthly;

  /// No description provided for @enterAnAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount.'**
  String get enterAnAmount;

  /// No description provided for @youHaveInGoal.
  ///
  /// In en, this message translates to:
  /// **'You have {amount} in this goal.'**
  String youHaveInGoal(String amount);

  /// No description provided for @freeShareIs.
  ///
  /// In en, this message translates to:
  /// **'Your free share is {amount}. Share more first with \"Set how much you share\".'**
  String freeShareIs(String amount);

  /// No description provided for @takeOut.
  ///
  /// In en, this message translates to:
  /// **'Take out'**
  String get takeOut;

  /// No description provided for @savedOfTarget.
  ///
  /// In en, this message translates to:
  /// **'{saved} of {target} saved'**
  String savedOfTarget(String saved, String target);

  /// No description provided for @fromYouFreeShare.
  ///
  /// In en, this message translates to:
  /// **'From you: {mine} · Your free share: {free}'**
  String fromYouFreeShare(String mine, String free);

  /// No description provided for @amountToTakeOut.
  ///
  /// In en, this message translates to:
  /// **'Amount to take out'**
  String get amountToTakeOut;

  /// No description provided for @amountToAdd.
  ///
  /// In en, this message translates to:
  /// **'Amount to add'**
  String get amountToAdd;

  /// No description provided for @emailLinkSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a link to {email}. Your email changes once you open it.'**
  String emailLinkSent(String email);

  /// No description provided for @emailTakenByOther.
  ///
  /// In en, this message translates to:
  /// **'That email already has a Vesta account.'**
  String get emailTakenByOther;

  /// No description provided for @notAdded.
  ///
  /// In en, this message translates to:
  /// **'Not added'**
  String get notAdded;

  /// No description provided for @changeNumberSupport.
  ///
  /// In en, this message translates to:
  /// **'To change your number, contact support.'**
  String get changeNumberSupport;

  /// No description provided for @userId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userId;

  /// No description provided for @userIdCopied.
  ///
  /// In en, this message translates to:
  /// **'User ID copied'**
  String get userIdCopied;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @userIdFixed.
  ///
  /// In en, this message translates to:
  /// **'Your user ID is given to you and can\'t be changed.'**
  String get userIdFixed;

  /// No description provided for @deleteVestaAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Vesta account'**
  String get deleteVestaAccount;

  /// No description provided for @profilePicture.
  ///
  /// In en, this message translates to:
  /// **'Profile picture'**
  String get profilePicture;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @takeAPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takeAPhoto;

  /// No description provided for @imageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image: {error}'**
  String imageUploadFailed(String error);

  /// No description provided for @passwordWrong.
  ///
  /// In en, this message translates to:
  /// **'That password isn\'t right.'**
  String get passwordWrong;

  /// No description provided for @tooManyTries.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait a little, then try again.'**
  String get tooManyTries;

  /// No description provided for @somethingWentWrongCode.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong ({code}).'**
  String somethingWentWrongCode(String code);

  /// No description provided for @confirmItsYou.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you'**
  String get confirmItsYou;

  /// No description provided for @enterPasswordToContinue.
  ///
  /// In en, this message translates to:
  /// **'Enter your Vesta password to continue.'**
  String get enterPasswordToContinue;

  /// No description provided for @fingerprintReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to turn on fingerprint unlock'**
  String get fingerprintReason;

  /// No description provided for @fingerprintFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t confirm your fingerprint'**
  String get fingerprintFailed;

  /// No description provided for @changeOrResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Change or reset your password'**
  String get changeOrResetPassword;

  /// No description provided for @fingerprintUnlock.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint unlock'**
  String get fingerprintUnlock;

  /// No description provided for @notAvailableOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Not available on this phone'**
  String get notAvailableOnPhone;

  /// No description provided for @unlockWithBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Unlock Vesta with your fingerprint or face'**
  String get unlockWithBiometrics;

  /// No description provided for @unlockQuickly.
  ///
  /// In en, this message translates to:
  /// **'Unlock quickly instead of typing your password'**
  String get unlockQuickly;

  /// No description provided for @dataConsent.
  ///
  /// In en, this message translates to:
  /// **'Data consent'**
  String get dataConsent;

  /// No description provided for @dataConsentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What we read from your bank accounts'**
  String get dataConsentSubtitle;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @passwordRule.
  ///
  /// In en, this message translates to:
  /// **'Use 6 or more characters with an uppercase letter, a lowercase letter, and a number.'**
  String get passwordRule;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password.'**
  String get enterCurrentPassword;

  /// No description provided for @newPasswordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'The new passwords don\'t match.'**
  String get newPasswordsDontMatch;

  /// No description provided for @pickDifferentPassword.
  ///
  /// In en, this message translates to:
  /// **'Pick a password you are not using now.'**
  String get pickDifferentPassword;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get passwordUpdated;

  /// No description provided for @currentPasswordWrong.
  ///
  /// In en, this message translates to:
  /// **'Your current password isn\'t right.'**
  String get currentPasswordWrong;

  /// No description provided for @passwordTooWeak.
  ///
  /// In en, this message translates to:
  /// **'That password is too weak.'**
  String get passwordTooWeak;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a reset link to {email}.'**
  String resetLinkSent(String email);

  /// No description provided for @linkSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the link ({code}).'**
  String linkSendFailed(String code);

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters, with an uppercase letter, a lowercase letter, and a number.'**
  String get passwordHint;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get updatePassword;

  /// No description provided for @forgotMyPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot my password'**
  String get forgotMyPassword;

  /// No description provided for @twoFactor.
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication'**
  String get twoFactor;

  /// No description provided for @twoFactorSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon: a code by SMS when you sign in'**
  String get twoFactorSoon;

  /// No description provided for @planFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get planFree;

  /// No description provided for @planFeatCore.
  ///
  /// In en, this message translates to:
  /// **'Budgeting, Spendings, and Savings'**
  String get planFeatCore;

  /// No description provided for @planFeat2Banks.
  ///
  /// In en, this message translates to:
  /// **'Up to 2 linked bank accounts'**
  String get planFeat2Banks;

  /// No description provided for @planFeatHealth.
  ///
  /// In en, this message translates to:
  /// **'Monthly financial health score'**
  String get planFeatHealth;

  /// No description provided for @planFeatAllFree.
  ///
  /// In en, this message translates to:
  /// **'Everything in Free'**
  String get planFeatAllFree;

  /// No description provided for @planFeatUnlimitedBanks.
  ///
  /// In en, this message translates to:
  /// **'Unlimited bank accounts'**
  String get planFeatUnlimitedBanks;

  /// No description provided for @planFeatShared1.
  ///
  /// In en, this message translates to:
  /// **'Shared finances with 1 household and up to 3 shared goals'**
  String get planFeatShared1;

  /// No description provided for @planFeatReminders.
  ///
  /// In en, this message translates to:
  /// **'Smart reminders and alerts'**
  String get planFeatReminders;

  /// No description provided for @planFeatAllPlus.
  ///
  /// In en, this message translates to:
  /// **'Everything in Plus'**
  String get planFeatAllPlus;

  /// No description provided for @planFeatShared3.
  ///
  /// In en, this message translates to:
  /// **'Up to 3 households with unlimited shared goals'**
  String get planFeatShared3;

  /// No description provided for @planFeatInsights.
  ///
  /// In en, this message translates to:
  /// **'Advanced insights and exports'**
  String get planFeatInsights;

  /// No description provided for @planFeatPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority customer service'**
  String get planFeatPriority;

  /// No description provided for @paidPlansSoon.
  ///
  /// In en, this message translates to:
  /// **'Paid plans are coming soon'**
  String get paidPlansSoon;

  /// No description provided for @paidPlansSoonBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be able to subscribe here once they launch. Until then, everything in Vesta is free.'**
  String get paidPlansSoonBody;

  /// No description provided for @noSubscription.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have a subscription'**
  String get noSubscription;

  /// No description provided for @onFreePlan.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the Free plan. Pick a plan to unlock more.'**
  String get onFreePlan;

  /// No description provided for @aMonth.
  ///
  /// In en, this message translates to:
  /// **'a month'**
  String get aMonth;

  /// No description provided for @getPlan.
  ///
  /// In en, this message translates to:
  /// **'Get {plan}'**
  String getPlan(String plan);

  /// No description provided for @howReferralsWork.
  ///
  /// In en, this message translates to:
  /// **'How referrals work'**
  String get howReferralsWork;

  /// No description provided for @referralsHowBody.
  ///
  /// In en, this message translates to:
  /// **'Share your code. When a friend enters it while signing up, you get {reward} points and they get {welcome}. 1,000 points get you a free month of Plus, and 1,500 a free month of Premium.'**
  String referralsHowBody(String reward, String welcome);

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @enoughPremium.
  ///
  /// In en, this message translates to:
  /// **'Enough for a free month of Premium'**
  String get enoughPremium;

  /// No description provided for @enoughPlusMore.
  ///
  /// In en, this message translates to:
  /// **'Enough for a free month of Plus · {points} more for Premium'**
  String enoughPlusMore(String points);

  /// No description provided for @moreForPlus.
  ///
  /// In en, this message translates to:
  /// **'{points} more for a free month of Plus'**
  String moreForPlus(String points);

  /// No description provided for @yourPoints.
  ///
  /// In en, this message translates to:
  /// **'Your points'**
  String get yourPoints;

  /// No description provided for @pointsShort.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String pointsShort(String points);

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorks;

  /// No description provided for @usePoints.
  ///
  /// In en, this message translates to:
  /// **'Use points'**
  String get usePoints;

  /// No description provided for @yourReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Your referral code'**
  String get yourReferralCode;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopied;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @referralShareText.
  ///
  /// In en, this message translates to:
  /// **'I use Vesta to plan my money. Join with my code {code}: {link}'**
  String referralShareText(String code, String link);

  /// No description provided for @peopleInvited.
  ///
  /// In en, this message translates to:
  /// **'People you\'ve invited'**
  String get peopleInvited;

  /// No description provided for @peopleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String peopleCount(int count);

  /// No description provided for @noOneInvitedYet.
  ///
  /// In en, this message translates to:
  /// **'No one yet. Share your code, and the friends who join show up here.'**
  String get noOneInvitedYet;

  /// No description provided for @friend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get friend;

  /// No description provided for @joinedOn.
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String joinedOn(String date);

  /// No description provided for @reasonNotEnough.
  ///
  /// In en, this message translates to:
  /// **'I don\'t use it enough'**
  String get reasonNotEnough;

  /// No description provided for @reasonPrivacy.
  ///
  /// In en, this message translates to:
  /// **'I have privacy concerns'**
  String get reasonPrivacy;

  /// No description provided for @reasonMissingFeatures.
  ///
  /// In en, this message translates to:
  /// **'It\'s missing features I need'**
  String get reasonMissingFeatures;

  /// No description provided for @reasonSwitching.
  ///
  /// In en, this message translates to:
  /// **'I\'m switching to another app'**
  String get reasonSwitching;

  /// No description provided for @reasonExpensive.
  ///
  /// In en, this message translates to:
  /// **'It\'s too expensive'**
  String get reasonExpensive;

  /// No description provided for @reasonTechnical.
  ///
  /// In en, this message translates to:
  /// **'I\'m having technical issues'**
  String get reasonTechnical;

  /// No description provided for @pickReason.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one reason.'**
  String get pickReason;

  /// No description provided for @deleteVestaAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your Vesta account?'**
  String get deleteVestaAccountTitle;

  /// No description provided for @deleteVestaAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'Everything in it is removed for good. This cannot be undone.'**
  String get deleteVestaAccountMessage;

  /// No description provided for @vestaAccountDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the account: {error}'**
  String vestaAccountDeleteFailed(String error);

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @whyDelete.
  ///
  /// In en, this message translates to:
  /// **'Why do you want to delete your account?'**
  String get whyDelete;

  /// No description provided for @tellUsMore.
  ///
  /// In en, this message translates to:
  /// **'Tell us more (optional)'**
  String get tellUsMore;

  /// No description provided for @deleteWarning.
  ///
  /// In en, this message translates to:
  /// **'If you delete your account, all of your information will be gone: your budgets, transactions, savings goals, accounts, and shared finances.'**
  String get deleteWarning;

  /// No description provided for @iconSecFood.
  ///
  /// In en, this message translates to:
  /// **'Food & drink'**
  String get iconSecFood;

  /// No description provided for @iconSecHome.
  ///
  /// In en, this message translates to:
  /// **'Home & bills'**
  String get iconSecHome;

  /// No description provided for @iconSecTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport & travel'**
  String get iconSecTransport;

  /// No description provided for @iconSecLifestyle.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get iconSecLifestyle;

  /// No description provided for @iconSecPeople.
  ///
  /// In en, this message translates to:
  /// **'People & other'**
  String get iconSecPeople;

  /// No description provided for @chooseAnIcon.
  ///
  /// In en, this message translates to:
  /// **'Choose an icon'**
  String get chooseAnIcon;
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
