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

  @override
  String get signUp => 'Sign up';

  @override
  String get logIn => 'Log in';

  @override
  String get continueLabel => 'Continue';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get ok => 'OK';

  @override
  String get back => 'Back';

  @override
  String get skip => 'Skip';

  @override
  String get goBack => 'Go Back';

  @override
  String get genericErrorLater => 'An error occurred. Please try again later.';

  @override
  String get genericErrorAgain => 'An error occurred. Please try again.';

  @override
  String get tooManyAttempts => 'Too many attempts. Please try again later.';

  @override
  String get enterValidEmail => 'Please enter a valid email address';

  @override
  String errorWith(String error) {
    return 'Error: $error';
  }

  @override
  String get welcomeTitle => 'Welcome to Vesta';

  @override
  String get welcomeSubtitle => 'Log in or create an account to continue.';

  @override
  String get unlockReason => 'Unlock Vesta';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String welcomeBackName(String name) {
    return 'Welcome back, $name';
  }

  @override
  String get unlockSubtitle => 'Unlock to see your money.';

  @override
  String get unlock => 'Unlock';

  @override
  String get logInWithPassword => 'Log in with password';

  @override
  String get notYou => 'Not you? Use another account or sign up';

  @override
  String get blockedTitle => 'Phone Number Blocked';

  @override
  String get blockedVerifyBody =>
      'Your phone number has been temporarily blocked due to multiple verification attempts.';

  @override
  String get blockedOtpBody =>
      'Your phone number has been temporarily blocked due to multiple failed attempts.';

  @override
  String get blockedDuration => 'Block Duration: 30 minutes';

  @override
  String get blockedRegain => 'To regain access:';

  @override
  String get blockedStep1 =>
      '1. Wait for the block period to expire (up to 30 minutes)';

  @override
  String get blockedStep2 => '2. Ensure you have access to the phone number';

  @override
  String get blockedStep3Later => '3. Try again after the waiting period';

  @override
  String get blockedStep3Otp => '3. Try again with the correct OTP';

  @override
  String get phoneInvalid =>
      'Enter a valid Jordan number starting with 7 (e.g. 79xxxxxxx)';

  @override
  String get phoneVerifyFailed => 'Phone verification failed';

  @override
  String phoneVerifyStartError(String error) {
    return 'Error starting phone verification: $error';
  }

  @override
  String get phoneTitle => 'Your phone number';

  @override
  String get phoneSubtitle =>
      'We\'ll send you a verification code to the provided number.';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get sendCode => 'Send code';

  @override
  String get fillAllFields => 'Please fill all fields';

  @override
  String get passwordsDontMatch => 'Passwords do not match';

  @override
  String get passwordRequirementsNotMet =>
      'Please ensure your password meets all requirements';

  @override
  String get usernameRules =>
      'Username can only contain letters, numbers, and underscores';

  @override
  String get usernameTaken =>
      'Username already taken. Please choose another one.';

  @override
  String get emailRegistered =>
      'Email already registered. Please use another email or login.';

  @override
  String get referralNotFound =>
      'We couldn\'t find that referral code. Check it, or leave it empty.';

  @override
  String checkUsernameError(String error) {
    return 'Error checking username/email: $error';
  }

  @override
  String get createAccountTitle => 'Create your account';

  @override
  String get nextVerifyPhone => 'Next we will verify your phone number.';

  @override
  String useTheseToLogIn(String username) {
    return 'You\'ll use these to log in as $username. Next we will verify your phone number.';
  }

  @override
  String get username => 'Username';

  @override
  String get passwordNeeds => 'Password needs';

  @override
  String get pwMinLength => 'At least 6 characters';

  @override
  String get pwUppercase => 'At least one uppercase letter (A-Z)';

  @override
  String get pwLowercase => 'At least one lowercase letter (a-z)';

  @override
  String get pwNumber => 'At least one number (0-9)';

  @override
  String get repeatPassword => 'Repeat password';

  @override
  String get referralCode => 'Referral code';

  @override
  String get referralHint => 'Optional, e.g. MAYA-25K9';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordMessage =>
      'Enter your email and we\'ll send you a link to reset your password.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get enterEmail => 'Please enter your email address';

  @override
  String get resetEmailSent =>
      'Password reset email sent. Please check your inbox.';

  @override
  String get resetEmailFailed =>
      'Failed to send reset email. Please try again.';

  @override
  String get invalidLogin => 'Invalid username or password';

  @override
  String get networkError => 'Network error. Please check your connection.';

  @override
  String get accountError => 'Account error. Please contact support.';

  @override
  String get biometricUnavailable =>
      'Biometric login is not available or not enabled';

  @override
  String get biometricFailed => 'Biometric authentication failed';

  @override
  String get noStoredCredentials =>
      'No stored credentials. Please login with password first.';

  @override
  String get sessionExpired => 'Session expired. Please login with password.';

  @override
  String get loginSubtitle => 'Log in with your username or email.';

  @override
  String get usernameOrEmail => 'Username or email';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get logInWithBiometrics => 'Log in with biometrics';

  @override
  String get enableBiometricsLater =>
      'Enable biometrics in settings after logging in';

  @override
  String get noAccount => 'Don\'t have an account? ';

  @override
  String get otpExpired => 'OTP has expired. Please request a new code.';

  @override
  String get otpEnter6 => 'Please enter a 6-digit OTP';

  @override
  String get numberHasAccount =>
      'This number already has a Vesta account. Log in instead.';

  @override
  String get emailHasAccount =>
      'That email already has a Vesta account. Log in instead.';

  @override
  String get usernameTakenRetry =>
      'Username is already taken. Please try registering again with a different username.';

  @override
  String get emailTakenRetry =>
      'Email is already registered. Please try logging in or use a different email.';

  @override
  String get usernameOrEmailTaken =>
      'Username or email is already taken. Please try registering again with different credentials.';

  @override
  String createAccountFailed(String error) {
    return 'Failed to create account: $error';
  }

  @override
  String get verificationFailed => 'Verification failed';

  @override
  String get resendFailed => 'Failed to resend OTP';

  @override
  String get otpResent => 'New OTP sent successfully';

  @override
  String resendError(String error) {
    return 'Error resending OTP: $error';
  }

  @override
  String get enterCode => 'Enter the code';

  @override
  String codeSentTo(String phone) {
    return 'We texted a code to $phone to verify your number.';
  }

  @override
  String get codeExpiredBelow =>
      'This code has expired. Request a new one below.';

  @override
  String codeExpiresIn(String time) {
    return 'Code expires in $time';
  }

  @override
  String get verifyCreate => 'Verify & create account';

  @override
  String get didntGetIt => 'Didn\'t get it? ';

  @override
  String get resendCode => 'Resend code';

  @override
  String resendIn(String seconds) {
    return 'You can resend the code in ${seconds}s';
  }

  @override
  String get usernameCharsShort => 'Use only letters, numbers and underscores';

  @override
  String get usernameTakenShort => 'That username is taken';

  @override
  String usernameCheckFailed(String error) {
    return 'Couldn\'t check the username: $error';
  }

  @override
  String get onbWelcomeTitle => 'Let\'s get your money into one calm view.';

  @override
  String get onbWelcomeBody =>
      'A few questions and you\'ll have a starting budget, your accounts in one place, and a coach that keeps an eye on your spending.';

  @override
  String get chooseUsername => 'Choose a username';

  @override
  String incomeTitle(String name) {
    return 'Nice to meet you, $name. What lands in your account each month?';
  }

  @override
  String get incomeBody =>
      'Your take-home pay after taxes. We\'ll suggest a split you can change anytime.';

  @override
  String get perMonth => '/ month';

  @override
  String get incomePrivate =>
      'Stays on your phone until you create your account.';

  @override
  String get suggestedSplit => 'SUGGESTED STARTING SPLIT';

  @override
  String get useAsBudget => 'Use this as my starting budget';

  @override
  String get bucketNecessities => 'Necessities';

  @override
  String get bucketNecessitiesExamples => 'Rent, groceries, bills';

  @override
  String get bucketLuxuries => 'Luxuries';

  @override
  String get bucketLuxuriesExamples => 'Dining, fun, shopping';

  @override
  String get bucketSavings => 'Savings';

  @override
  String get bucketSavingsExamples => 'Goals and extra payments';

  @override
  String get focusTitle => 'What do you want to work on first?';

  @override
  String get focusBody => 'Pick up to three. Your coach will focus here.';

  @override
  String get focusSpend => 'Manage my spendings';

  @override
  String get focusGoals => 'Start saving goals';

  @override
  String get focusBills => 'Manage bills and scheduled payments';

  @override
  String get focusShared => 'Manage shared finances';

  @override
  String get focusBudget => 'Build a monthly budget';

  @override
  String get focusClarity => 'Get financial clarity';

  @override
  String get banksTitle => 'Which banks do you use?';

  @override
  String get banksBody =>
      'Pick any that apply. Nothing gets connected; it helps us set Vesta up around your accounts.';

  @override
  String get cancel => 'Cancel';

  @override
  String get yes => 'Yes';

  @override
  String get add => 'Add';

  @override
  String get remove => 'Remove';

  @override
  String get done => 'Done';

  @override
  String get close => 'Close';

  @override
  String get comingLater => 'This is coming in a later update.';

  @override
  String get greetingMorning => 'Good morning,';

  @override
  String get greetingAfternoon => 'Good afternoon,';

  @override
  String get greetingEvening => 'Good evening,';

  @override
  String get greetingNight => 'Good night,';

  @override
  String get greetingFallbackName => 'there';

  @override
  String get noData => 'No data available';

  @override
  String get totalBalance => 'Total balance';

  @override
  String amountSpent(String amount) {
    return '$amount spent';
  }

  @override
  String amountEarned(String amount) {
    return '$amount earned';
  }

  @override
  String get accountsLabel => 'Accounts';

  @override
  String accountCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count accounts',
      one: '1 account',
    );
    return '$_temp0';
  }

  @override
  String get tileBudgeting => 'Budgeting';

  @override
  String get tileSpendings => 'Spendings';

  @override
  String get tileSavings => 'Savings';

  @override
  String get tileShared => 'Shared finances';

  @override
  String monthBudget(String month) {
    return '$month budget';
  }

  @override
  String get seeAll => 'See all';

  @override
  String get noBudgetPlan => 'No budget plan for this month yet.';

  @override
  String get planYourBudget => 'Plan your budget';

  @override
  String spentOfBudget(String spent, String budget) {
    return '$spent of $budget to spend';
  }

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String get notInPlan => 'Not in the plan';

  @override
  String get targetReached => 'Target reached';

  @override
  String amountToGo(String amount) {
    return '$amount to go';
  }

  @override
  String amountOver(String amount) {
    return '$amount over';
  }

  @override
  String amountLeft(String amount) {
    return '$amount left';
  }

  @override
  String get comingUp => 'Coming up';

  @override
  String get allBills => 'All bills';

  @override
  String get nothingDue => 'Nothing due soon.';

  @override
  String get addYourBills => 'Add your bills';

  @override
  String get goals => 'Goals';

  @override
  String get noGoals => 'No saving goals yet.';

  @override
  String get createGoal => 'Create a goal';

  @override
  String get goalFallback => 'Goal';

  @override
  String get recent => 'Recent';

  @override
  String get noTransactions => 'No transactions yet.';

  @override
  String get addOne => 'Add one';

  @override
  String get coachLabel => 'YOUR COACH';

  @override
  String get coachPlanTitle => 'Let\'s plan this month.';

  @override
  String get coachPlanBody =>
      'Set your income and split it into savings, necessities and luxuries. I\'ll tell you how your spending is pacing against it.';

  @override
  String get coachMostlyOnPace => 'You\'re mostly on pace.';

  @override
  String get coachRunningHot => 'Spending is running a little hot.';

  @override
  String get bucketNecessitiesLower => 'necessities';

  @override
  String get bucketLuxuriesLower => 'luxuries';

  @override
  String coachOverWithOther(
    String name,
    String by,
    String left,
    String other,
    String perDay,
    String until,
  ) {
    return '$name is $by over its limit. You still have $left for $other, about $perDay a day until $until.';
  }

  @override
  String coachOverUsedUp(String name, String by, String until) {
    return '$name is $by over its limit, and your spending budget is used up until $until.';
  }

  @override
  String get coachAheadTitle => 'Spending is running ahead.';

  @override
  String coachAheadBody(String used, String left, String perDay) {
    return 'You\'ve used $used% of your spending budget with $left% of the cycle left. $perDay a day keeps you on track.';
  }

  @override
  String get coachOnPaceTitle => 'You\'re on pace this cycle.';

  @override
  String coachOnPaceBody(String left, String perDay, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: 'day',
    );
    return '$left left to spend, about $perDay a day for the next $_temp0.';
  }

  @override
  String get coachPlanLink => 'Plan your budget →';

  @override
  String get coachInsightsLink => 'See insights →';

  @override
  String amountThisMonth(String amount) {
    return '$amount this month';
  }
}
