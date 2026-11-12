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

  @override
  String get delete => 'Delete';

  @override
  String deleteNameTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteAccountMessage =>
      'This also deletes every transaction in the account. It cannot be undone.';

  @override
  String get accountDeleted => 'Account deleted';

  @override
  String accountDeleteFailed(String error) {
    return 'Failed to delete account: $error';
  }

  @override
  String get walletTitle => 'Wallet';

  @override
  String get addAccount => 'Add account';

  @override
  String get removeAnAccount => 'Remove an account';

  @override
  String get noAccountsYet => 'No accounts yet. Tap + to add one.';

  @override
  String get netWorth => 'Net worth';

  @override
  String acrossAccounts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Across $count accounts',
      one: 'Across 1 account',
    );
    return '$_temp0';
  }

  @override
  String get unknownBank => 'Unknown Bank';

  @override
  String get unknownType => 'Unknown Type';

  @override
  String get typeCurrent => 'Current account';

  @override
  String get typeSavings => 'Savings account';

  @override
  String get typeCreditCard => 'Credit card';

  @override
  String get typeLoan => 'Loan';

  @override
  String get typeInvestment => 'Investment account';

  @override
  String get typeCash => 'Cash';

  @override
  String get enterBalanceNumber => 'Enter the balance as a number';

  @override
  String get accountAdded => 'Account added';

  @override
  String accountAddFailed(String error) {
    return 'Couldn\'t add the account: $error';
  }

  @override
  String get addAccountManually => 'Add account manually';

  @override
  String get bank => 'Bank';

  @override
  String get accountType => 'Account type';

  @override
  String get accountName => 'Account name';

  @override
  String get accountNameHint => 'e.g. Salary account';

  @override
  String get last4Digits => 'Last 4 digits';

  @override
  String get optional => 'Optional';

  @override
  String get amountOwed => 'Amount owed';

  @override
  String get currentBalance => 'Current balance';

  @override
  String get manualAccountsNote =>
      'Manual accounts don\'t sync. You\'ll add transactions and update the balance yourself.';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get bucketNecessity => 'Necessity';

  @override
  String get bucketLuxury => 'Luxury';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get other => 'Other';

  @override
  String get catFoodDrinks => 'Food And Drinks';

  @override
  String get catGroceries => 'Groceries';

  @override
  String get catEntertainment => 'Entertainment';

  @override
  String get catOthers => 'Others';

  @override
  String get catRent => 'Rent';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catTransport => 'Transport';

  @override
  String get catHealth => 'Health';

  @override
  String get catBills => 'Bills & Utilities';

  @override
  String get catSavings => 'Savings';

  @override
  String get budgetDayHelp =>
      'Your budget cycle starts on this day each month, usually payday.';

  @override
  String get dayOfMonth => 'Day of month';

  @override
  String get enterDay => 'Please enter a day';

  @override
  String get enterValidNumber => 'Please enter a valid number';

  @override
  String get dayRange => 'Day must be between 1 and 31';

  @override
  String currentDay(String day) {
    return 'Current: day $day';
  }

  @override
  String get save => 'Save';

  @override
  String budgetDayUpdated(String day) {
    return 'Budget reset day updated to $day';
  }

  @override
  String get budgetDayFailed => 'Failed to update day. Try again.';

  @override
  String get allAccounts => 'All accounts';

  @override
  String get allCategories => 'All categories';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String categoryUpdated(String name) {
    return 'Updated category to $name';
  }

  @override
  String get category => 'Category';

  @override
  String get type => 'Type';

  @override
  String get merchant => 'Merchant';

  @override
  String get account => 'Account';

  @override
  String get source => 'Source';

  @override
  String get sourceManual => 'Manual';

  @override
  String get sourceSms => 'SMS';

  @override
  String get sourceBank => 'Bank';

  @override
  String get description => 'Description';

  @override
  String get addedBy => 'Added by';

  @override
  String get date => 'Date';

  @override
  String get assignToHousehold => 'Assign to household';

  @override
  String get transactionDeleted => 'Transaction deleted';

  @override
  String transactionDeleteError(String error) {
    return 'Error deleting transaction: $error';
  }

  @override
  String get deleteTransaction => 'Delete transaction';

  @override
  String get removeFromHousehold => 'Remove from household';

  @override
  String get notInAnyHousehold => 'You are not part of any household.';

  @override
  String get transactionNotFound => 'Transaction not found';

  @override
  String assignedTo(String name) {
    return 'Assigned to \'$name\' successfully!';
  }

  @override
  String get loadTransactionsFailed => 'Couldn\'t load transactions';

  @override
  String get retry => 'Retry';

  @override
  String get noTransactionsTitle => 'No transactions yet';

  @override
  String get addFirstTransaction => 'Tap + to add your first one.';

  @override
  String get refresh => 'Refresh';

  @override
  String get noMatchingTransactions => 'No transactions match these filters';

  @override
  String get tryOtherFilters => 'Try a different account, category or date.';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get selectMonth => 'Select Month';

  @override
  String get periodAll => 'All';

  @override
  String get periodLast7 => 'Last 7 days';

  @override
  String get periodLast30 => 'Last 30 days';

  @override
  String get month => 'Month';

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get deleteTransactionTitle => 'Delete this transaction?';

  @override
  String deleteTxnReturned(String amount) {
    return 'It will be removed and $amount returned to the account balance.';
  }

  @override
  String deleteTxnTakenOff(String amount) {
    return 'It will be removed and $amount taken off the account balance.';
  }

  @override
  String transactionDeleteFailed(String error) {
    return 'Couldn\'t delete the transaction: $error';
  }

  @override
  String get addTransaction => 'Add transaction';

  @override
  String get removeATransaction => 'Remove a transaction';

  @override
  String get enterValidAmount => 'Enter a valid amount.';

  @override
  String get selectAnAccount => 'Select an account.';

  @override
  String get transactionAdded => 'Transaction added.';

  @override
  String get smsNoAmount =>
      'We couldn\'t find an amount in this message. Try the Manual tab.';

  @override
  String get addATransaction => 'Add a transaction';

  @override
  String get pasteBankSms => 'Paste your bank SMS';

  @override
  String get trySample => 'Try a sample message';

  @override
  String get readMessage => 'Read message';

  @override
  String get smsWillFill =>
      'We\'ll fill in the details so you can check them before saving.';

  @override
  String get filledFromSms => 'Filled from your SMS. Check the details below.';

  @override
  String get noAccountsAddInWallet =>
      'No accounts yet. Add one in Wallet first.';

  @override
  String amountIn(String currency) {
    return 'Amount ($currency)';
  }

  @override
  String get merchantFrom => 'Merchant / From';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String transactionCountRecent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions · Most recent',
      one: '1 transaction · Most recent',
    );
    return '$_temp0';
  }

  @override
  String get spendingsTitle => 'Spendings';

  @override
  String get categories => 'Categories';

  @override
  String get latestTransactions => 'Latest transactions';

  @override
  String spentInMonthSoFar(String month) {
    return 'Spent in $month so far';
  }

  @override
  String percentUsed(String percent) {
    return '$percent% used';
  }

  @override
  String ofAmount(String amount) {
    return 'of $amount';
  }

  @override
  String get noBudgetThisCycle => 'No budget plan for this cycle yet';

  @override
  String daysToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days to go',
      one: '1 day to go',
    );
    return '$_temp0';
  }

  @override
  String get noCategorizedSpending =>
      'No categorized spending yet.\nAssign categories to transactions to see them here.';

  @override
  String loadBudgetError(String error) {
    return 'Error loading budget: $error';
  }

  @override
  String get insightsTitle => 'Insights';

  @override
  String vsMonth(String amount, String month) {
    return '$amount vs $month';
  }

  @override
  String categoryDown(String name, String amount) {
    return '$name is down $amount';
  }

  @override
  String categoryUp(String name, String amount) {
    return '$name is up $amount';
  }

  @override
  String comparedWithMonth(String month) {
    return 'Compared with this point in $month.';
  }

  @override
  String biggestDrop(String month) {
    return 'Compared with this point in $month. That\'s the biggest drop of any category.';
  }

  @override
  String get byCategory => 'By category';

  @override
  String get noSpendingTwoMonths => 'No spending yet this month or last.';

  @override
  String onePurchase(String date) {
    return 'Most of it came from one purchase on $date. Worth a look before the month closes.';
  }

  @override
  String get categoryAdded => 'Category added';

  @override
  String get deleteCategoryMessage =>
      'Its transactions keep their amounts but will have no category.';

  @override
  String categoryDeleted(String name) {
    return 'Category \"$name\" deleted and unassigned.';
  }

  @override
  String categoryDeleteError(String error) {
    return 'Error deleting category: $error';
  }

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortHigh => 'Highest spent';

  @override
  String get sortLow => 'Lowest spent';

  @override
  String get sortName => 'Name (A–Z)';

  @override
  String get sortLimit => 'Closest to limit';

  @override
  String get filter => 'Filter';

  @override
  String filterCount(String count) {
    return 'Filter · $count';
  }

  @override
  String get sort => 'Sort';

  @override
  String get newCategory => 'New category';

  @override
  String get removeACategory => 'Remove a category';

  @override
  String get noCategoriesYet => 'No categories yet. Tap + to create one.';

  @override
  String get noCategoriesMatch => 'No categories match this filter.';

  @override
  String get clearFilter => 'Clear filter';

  @override
  String get noBudgetPlanned => 'No budget planned';

  @override
  String get show => 'Show';

  @override
  String get onlyWithSpending => 'Only categories with spending';

  @override
  String get onlyOverLimit => 'Only categories over their limit';

  @override
  String get reset => 'Reset';

  @override
  String get showResults => 'Show results';

  @override
  String get giveCategoryName => 'Give the category a name.';

  @override
  String categoryExists(String name) {
    return 'You already have a category called \"$name\".';
  }

  @override
  String categoryAddFailed(String error) {
    return 'Couldn\'t add the category: $error';
  }

  @override
  String get addNewCategory => 'Add a new category';

  @override
  String get addCategory => 'Add category';

  @override
  String get categoryName => 'Category name';

  @override
  String get budget => 'Budget';

  @override
  String get monthlyLimit => 'Monthly spending limit';

  @override
  String get noLimit => 'No limit';

  @override
  String get necessitiesBudget => 'Necessities budget';

  @override
  String get luxuriesBudget => 'Luxuries budget';

  @override
  String get notPlanned => 'Not planned';

  @override
  String get thisLimit => 'This limit';

  @override
  String percentOfBudget(String percent) {
    return '$percent% of budget';
  }

  @override
  String get budgetingTitle => 'Budgeting';

  @override
  String get noBudgetPlanYet => 'No budget plan yet';

  @override
  String get budgetEmptyBody =>
      'Split your income into savings, necessities and luxuries, and see how each cycle tracks against it.';

  @override
  String get createBudgetPlan => 'Create budget plan';

  @override
  String get spendingByBucket => 'Spending by bucket';

  @override
  String get noSpendingSixMonths => 'No spending in the last six months yet';

  @override
  String budgetPlanFor(String month) {
    return 'Budget plan for $month';
  }

  @override
  String get editBudgetPlan => 'Edit budget plan';

  @override
  String get totalIncome => 'Total income';

  @override
  String get spentSoFar => 'Spent so far';

  @override
  String get upcomingPayments => 'Upcoming payments';

  @override
  String get addABill => 'Add a bill';

  @override
  String get removeABill => 'Remove a bill';

  @override
  String billDeleteFailed(String error) {
    return 'Couldn\'t delete the bill: $error';
  }

  @override
  String get noUpcomingPayments =>
      'No upcoming payments yet. Tap + to add a bill.';

  @override
  String seeAllCount(String count) {
    return 'See all $count';
  }

  @override
  String get noDate => 'No date';

  @override
  String nextDate(String date) {
    return 'Next: $date';
  }

  @override
  String fromAccount(String account) {
    return 'From $account';
  }

  @override
  String paymentsLeft(String count) {
    return '$count left';
  }

  @override
  String get yourBudgetPlan => 'Your budget plan';

  @override
  String get totalMonthlyIncome => 'Total monthly income';

  @override
  String planSaveFailed(String error) {
    return 'Couldn\'t save the plan: $error';
  }

  @override
  String get savePlan => 'Save plan';

  @override
  String get enterAmountToPlan => 'Enter an amount to plan it.';

  @override
  String overBy(String amount) {
    return 'Over by $amount';
  }

  @override
  String get allPlanned => 'All of it is planned';

  @override
  String get amount => 'Amount';

  @override
  String get savingsGoalAdded => 'Savings goal added';

  @override
  String allocateToGoal(String goal) {
    return 'Allocate to $goal';
  }

  @override
  String availableAmount(String amount) {
    return 'Available: $amount';
  }

  @override
  String inThisGoal(String amount) {
    return 'In this goal: $amount';
  }

  @override
  String stillNeeded(String amount) {
    return 'Still needed: $amount';
  }

  @override
  String get amountToAllocate => 'Amount to allocate';

  @override
  String get removeFromGoal => 'Remove from goal';

  @override
  String get allocate => 'Allocate';

  @override
  String get insufficientBalance => 'Insufficient available balance';

  @override
  String get goalFullyFunded => 'This goal is already fully funded';

  @override
  String allocatingCapped(String amount) {
    return 'Allocating $amount (capped to remaining goal amount)';
  }

  @override
  String get deleteGoalTitle => 'Delete this goal?';

  @override
  String get deleteGoalMessage =>
      'The goal and its progress will be removed. It cannot be undone.';

  @override
  String get goalDeleted => 'Savings goal deleted successfully';

  @override
  String goalDeleteError(String error) {
    return 'Error deleting goal: $error';
  }

  @override
  String removeFromGoalTitle(String goal) {
    return 'Remove from $goal';
  }

  @override
  String get amountToRemove => 'Amount to remove';

  @override
  String get removeAll => 'Remove all';

  @override
  String get amountExceedsAllocation => 'Amount exceeds current allocation';

  @override
  String amountAllocated(String amount) {
    return '$amount allocated successfully!';
  }

  @override
  String amountRemovedFromGoal(String amount) {
    return '$amount removed successfully!';
  }

  @override
  String get noSavingsGoalsYet => 'No savings goals yet';

  @override
  String get savingsEmptyBody =>
      'Create a goal and move money from your savings into it as you go.';

  @override
  String get createSavingsGoal => 'Create a savings goal';

  @override
  String get savingGoals => 'Saving goals';

  @override
  String get newGoal => 'New goal';

  @override
  String get removeAGoal => 'Remove a goal';

  @override
  String get totalSaved => 'Total saved';

  @override
  String get allocatedToGoals => 'Allocated to goals';

  @override
  String get leftToAllocate => 'Left to allocate';

  @override
  String get completed => 'Completed';

  @override
  String amountOfAmount(String current, String target) {
    return '$current of $target';
  }

  @override
  String perMonthByDate(String amount, String date) {
    return '$amount a month · by $date';
  }

  @override
  String perMonthFor(String amount, String duration) {
    return '$amount a month · $duration';
  }

  @override
  String monthsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String yearsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '1 year',
    );
    return '$_temp0';
  }

  @override
  String yearsAndMonths(String years, String months) {
    return '$years and $months';
  }

  @override
  String get giveGoalName => 'Give the goal a name.';

  @override
  String get enterSaveAmount => 'Enter how much you want to save.';

  @override
  String get enterMonthsOrDate =>
      'Enter how many months, or pick a target date.';

  @override
  String goalAddFailed(String error) {
    return 'Couldn\'t add the goal: $error';
  }

  @override
  String get newSavingsGoal => 'New savings goal';

  @override
  String get addGoal => 'Add goal';

  @override
  String get goalName => 'Goal name';

  @override
  String get totalTargetAmount => 'Total target amount';

  @override
  String get targetPerMonth => 'Target amount per month';

  @override
  String get months => 'Months';

  @override
  String get targetDate => 'Target date';

  @override
  String get deleteBillTitle => 'Delete this bill?';

  @override
  String willBeRemoved(String name) {
    return '\"$name\" will be removed.';
  }

  @override
  String billUpdateFailed(String error) {
    return 'Couldn\'t update the bill: $error';
  }

  @override
  String billSaveFailed(String error) {
    return 'Couldn\'t save the bill: $error';
  }

  @override
  String get billsTitle => 'Bills & subscriptions';

  @override
  String get stillDueThisMonth => 'Still due this month';

  @override
  String get perMo => '/mo';

  @override
  String get noBillsYet => 'No bills yet';

  @override
  String get billsEmptyBody =>
      'Add rent, phone, subscriptions and anything else you pay each month. Standing orders from your bank show up here too.';

  @override
  String get bills => 'Bills';

  @override
  String get billsFootnote =>
      'Toggle on to mark a bill as autopay. Standing orders are set up at your bank.';

  @override
  String get paid => 'Paid';

  @override
  String wasDue(String date) {
    return 'Was due $date';
  }

  @override
  String get noDateSet => 'No date set';

  @override
  String get dueToday => 'Due today';

  @override
  String get dueTomorrow => 'Due tomorrow';

  @override
  String dueInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Due in $count days',
      one: 'Due in 1 day',
    );
    return '$_temp0';
  }

  @override
  String get incoming => 'incoming';

  @override
  String get autopayLower => 'autopay';

  @override
  String get editBill => 'Edit bill';

  @override
  String get name => 'Name';

  @override
  String get billNameHint => 'Rent, phone, Netflix...';

  @override
  String get dueEveryMonthOn => 'Due every month on';

  @override
  String dayN(int day) {
    return 'Day $day';
  }

  @override
  String get shorterMonthsNote => 'In shorter months it falls on the last day.';

  @override
  String get paidFrom => 'Paid from';

  @override
  String get notSet => 'Not set';

  @override
  String get subscription => 'Subscription';

  @override
  String get subscriptionSubtitle => 'Counted in your monthly subscriptions';

  @override
  String get autopay => 'Autopay';

  @override
  String get autopaySubtitle => 'Comes out automatically';

  @override
  String get addBill => 'Add bill';

  @override
  String get deleteBill => 'Delete bill';

  @override
  String get billFallback => 'Bill';

  @override
  String get scheduledPayment => 'Scheduled payment';

  @override
  String accountFallback(String id) {
    return 'Account $id';
  }

  @override
  String hhInviteShare(String name, String link) {
    return 'Join my household \'$name\' on Vesta! Click here: $link';
  }

  @override
  String get hhInviteSubject => 'You\'re invited to join my household!';

  @override
  String get aHousehold => 'a household';

  @override
  String inviteCreateError(String error) {
    return 'Error creating invite: $error';
  }

  @override
  String get member => 'Member';

  @override
  String get manage => 'Manage';

  @override
  String get household => 'Household';

  @override
  String get noLongerInHousehold => 'You\'re no longer in this household';

  @override
  String get noLongerInHouseholdBody =>
      'It was deleted, or its owner removed you.';

  @override
  String get backToShared => 'Back to Shared finances';

  @override
  String nameAdmin(String name) {
    return '$name (admin)';
  }

  @override
  String nameYou(String name) {
    return '$name (you)';
  }

  @override
  String get noHouseholdBudget => 'No household budget yet';

  @override
  String get good => 'Good';

  @override
  String get overTag => 'Over';

  @override
  String get overall => 'Overall';

  @override
  String get atRisk => 'At risk';

  @override
  String get financialHealth => 'Financial health';

  @override
  String get noSharedSpendingSixMonths =>
      'No shared spending in the last six months yet';

  @override
  String get householdBudgetPlan => 'Household budget plan';

  @override
  String get totalMonthlyBudget => 'Total monthly budget';

  @override
  String get totalBudget => 'Total budget';

  @override
  String get noBudgetTapPencil =>
      'No budget set yet. Tap the pencil to plan one.';

  @override
  String overThisCycleSplit(String amount) {
    return '$amount over this cycle. Tap the pencil to split the budget into buckets.';
  }

  @override
  String leftThisCycleSplit(String amount) {
    return '$amount left this cycle. Tap the pencil to split the budget into buckets.';
  }

  @override
  String householdBudgetLoadError(String error) {
    return 'Error loading household budget: $error';
  }

  @override
  String get noSharedCategorized =>
      'No categorized spending yet.\nAssign categories to shared transactions to see them here.';

  @override
  String transactionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return '$_temp0';
  }

  @override
  String get noSharedTransactions =>
      'No shared transactions yet.\nAssign one from a transaction\'s details.';

  @override
  String get noHouseholdsYet => 'No households yet';

  @override
  String get householdsEmptyBody =>
      'Create a household to run a budget with the people you live with.';

  @override
  String get createHousehold => 'Create a household';

  @override
  String get sharedHouseholds => 'Shared households';

  @override
  String get newHousehold => 'New household';

  @override
  String get leaveOrDeleteHousehold => 'Leave or delete a household';

  @override
  String get thisHousehold => 'this household';

  @override
  String get unnamedHousehold => 'Unnamed household';

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get noBudgetOpenToSet => 'No budget yet. Open to set one.';

  @override
  String get noBudgetSetYet => 'No budget set yet';

  @override
  String get logInToSeeHouseholds => 'Please log in to see your households.';

  @override
  String get userDataNotFound => 'User data not found.';

  @override
  String get joiningHousehold => 'Joining the household...';

  @override
  String get inviteDeclined => 'Invite declined';

  @override
  String inviteAnswerFailed(String error) {
    return 'Couldn\'t answer the invite: $error';
  }

  @override
  String invitedYouToJoin(String inviter, String household) {
    return '$inviter invited you to join $household.';
  }

  @override
  String get someone => 'Someone';

  @override
  String get decline => 'Decline';

  @override
  String get accept => 'Accept';

  @override
  String get deleteHouseholdMessage =>
      'The household and its shared budget are removed for every member. This cannot be undone.';

  @override
  String householdDeleteFailed(String error) {
    return 'Couldn\'t delete the household: $error';
  }

  @override
  String leaveNameTitle(String name) {
    return 'Leave $name?';
  }

  @override
  String get leaveHouseholdMessage =>
      'You\'ll stop seeing its budget and transactions. The owner can invite you again.';

  @override
  String get leave => 'Leave';

  @override
  String householdLeaveFailed(String error) {
    return 'Couldn\'t leave the household: $error';
  }

  @override
  String removeNameTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get removeMemberMessage =>
      'They\'ll lose access to this household. You can invite them again later.';

  @override
  String get removeMember => 'Remove';

  @override
  String memberRemoveFailed(String name, String error) {
    return 'Couldn\'t remove $name: $error';
  }

  @override
  String get logInToInvite => 'Log in again to invite someone.';

  @override
  String get enterUsernameOrEmail => 'Enter a username or email.';

  @override
  String noUserGoesBy(String query) {
    return 'No Vesta user goes by \"$query\".';
  }

  @override
  String get thatsYou => 'That\'s you.';

  @override
  String get alreadyInHousehold => 'They\'re already in this household.';

  @override
  String get giveHouseholdName => 'Give the household a name.';

  @override
  String householdCreateFailed(String error) {
    return 'Couldn\'t create the household: $error';
  }

  @override
  String get create => 'Create';

  @override
  String get householdName => 'Household name';

  @override
  String saveFailed(String error) {
    return 'Couldn\'t save: $error';
  }

  @override
  String inviteSentTo(String name) {
    return 'Invite sent to $name. They can accept it in Shared finances.';
  }

  @override
  String inviteSendFailed(String error) {
    return 'Couldn\'t send the invite: $error';
  }

  @override
  String get editHousehold => 'Edit household';

  @override
  String get members => 'Members';

  @override
  String get youParen => '(you)';

  @override
  String get admin => 'Admin';

  @override
  String get invite => 'Invite';

  @override
  String get shareInviteLink => 'Share invite link';

  @override
  String get youAreAdmin =>
      'You\'re the admin because you created this household. Only the admin can add or remove members.';

  @override
  String onlyAdminNamed(String name) {
    return 'Only the admin ($name) can add or remove members.';
  }

  @override
  String get onlyAdmin => 'Only the admin can add or remove members.';

  @override
  String get deleteHousehold => 'Delete household';

  @override
  String willBeRemovedForEveryone(String name) {
    return '\"$name\" will be removed for everyone.';
  }

  @override
  String get addSharedBill => 'Add a shared bill';

  @override
  String get noSharedBills =>
      'No shared bills yet. Add rent, utilities, or subscriptions you split.';

  @override
  String get whenToday => 'today';

  @override
  String get whenTomorrow => 'tomorrow';

  @override
  String whenInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count days',
      one: 'in 1 day',
    );
    return '$_temp0';
  }

  @override
  String billDueLine(String date, String when) {
    return 'Due $date · $when · Monthly';
  }

  @override
  String get giveBillName => 'Give the bill a name.';

  @override
  String get enterTheAmount => 'Enter the amount.';

  @override
  String get pickDueDay => 'Pick a due day from 1 to 31.';

  @override
  String sharesDontAddUp(String total, String amount) {
    return 'The shares add up to $total, not $amount.';
  }

  @override
  String get newSharedBill => 'New shared bill';

  @override
  String get egRent => 'e.g. Rent';

  @override
  String get dueDay => 'Due day';

  @override
  String get splitEvenly => 'Split evenly';

  @override
  String amountEach(String amount) {
    return '$amount each';
  }

  @override
  String get setEachPays => 'Or set what each member pays';

  @override
  String somethingWentWrong(String error) {
    return 'Something went wrong: $error';
  }

  @override
  String get sharedGoalAdded => 'Shared goal added';

  @override
  String get deleteSharedGoalMessage =>
      'It\'s removed for everyone. What members put in goes back to their free share.';

  @override
  String get sharedByMembers => 'Shared by members';

  @override
  String get allocatedShared => 'Allocated / shared';

  @override
  String get setHowMuchYouShare => 'Set how much you share';

  @override
  String get setMonthlyPlanHint =>
      'Set what you plan to add each month to track the household\'s monthly savings.';

  @override
  String monthSavingsGoal(String month, String amount) {
    return '$month savings goal $amount';
  }

  @override
  String get reached => 'Reached';

  @override
  String get notYet => 'Not yet';

  @override
  String savedThisMonth(String amount) {
    return '$amount saved this month.';
  }

  @override
  String savedSoFarToGo(String saved, String toGo, String days) {
    return '$saved saved so far, $toGo to go with $days left.';
  }

  @override
  String plansPerMonth(String amount) {
    return 'Plans $amount a month';
  }

  @override
  String get noMonthlyPlan => 'No monthly plan yet';

  @override
  String amountFree(String amount) {
    return '$amount free';
  }

  @override
  String get newSharedGoal => 'New shared goal';

  @override
  String get noSharedGoals =>
      'No shared goals yet. Add one to save for something together.';

  @override
  String byDate(String date) {
    return 'By $date';
  }

  @override
  String shareAtLeast(String amount) {
    return 'You already put $amount into goals, so share at least that.';
  }

  @override
  String get yourSavingsShare => 'Your savings share';

  @override
  String get savingsShareMessage =>
      'How much of your savings you share with the household, and what you plan to add each month. Everyone in it sees these.';

  @override
  String get amountYouShare => 'Amount you share';

  @override
  String get planToAddMonthly => 'You plan to add each month';

  @override
  String get enterAnAmount => 'Enter an amount.';

  @override
  String youHaveInGoal(String amount) {
    return 'You have $amount in this goal.';
  }

  @override
  String freeShareIs(String amount) {
    return 'Your free share is $amount. Share more first with \"Set how much you share\".';
  }

  @override
  String get takeOut => 'Take out';

  @override
  String savedOfTarget(String saved, String target) {
    return '$saved of $target saved';
  }

  @override
  String fromYouFreeShare(String mine, String free) {
    return 'From you: $mine · Your free share: $free';
  }

  @override
  String get amountToTakeOut => 'Amount to take out';

  @override
  String get amountToAdd => 'Amount to add';

  @override
  String emailLinkSent(String email) {
    return 'We sent a link to $email. Your email changes once you open it.';
  }

  @override
  String get emailTakenByOther => 'That email already has a Vesta account.';

  @override
  String get notAdded => 'Not added';

  @override
  String get changeNumberSupport => 'To change your number, contact support.';

  @override
  String get userId => 'User ID';

  @override
  String get userIdCopied => 'User ID copied';

  @override
  String get copy => 'Copy';

  @override
  String get userIdFixed =>
      'Your user ID is given to you and can\'t be changed.';

  @override
  String get deleteVestaAccount => 'Delete Vesta account';

  @override
  String get profilePicture => 'Profile picture';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get takeAPhoto => 'Take a photo';

  @override
  String imageUploadFailed(String error) {
    return 'Failed to upload image: $error';
  }

  @override
  String get passwordWrong => 'That password isn\'t right.';

  @override
  String get tooManyTries => 'Too many tries. Wait a little, then try again.';

  @override
  String somethingWentWrongCode(String code) {
    return 'Something went wrong ($code).';
  }

  @override
  String get confirmItsYou => 'Confirm it\'s you';

  @override
  String get enterPasswordToContinue =>
      'Enter your Vesta password to continue.';

  @override
  String get fingerprintReason => 'Authenticate to turn on fingerprint unlock';

  @override
  String get fingerprintFailed => 'Couldn\'t confirm your fingerprint';

  @override
  String get changeOrResetPassword => 'Change or reset your password';

  @override
  String get fingerprintUnlock => 'Fingerprint unlock';

  @override
  String get notAvailableOnPhone => 'Not available on this phone';

  @override
  String get unlockWithBiometrics =>
      'Unlock Vesta with your fingerprint or face';

  @override
  String get unlockQuickly => 'Unlock quickly instead of typing your password';

  @override
  String get dataConsent => 'Data consent';

  @override
  String get dataConsentSubtitle => 'What we read from your bank accounts';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get passwordRule =>
      'Use 6 or more characters with an uppercase letter, a lowercase letter, and a number.';

  @override
  String get enterCurrentPassword => 'Enter your current password.';

  @override
  String get newPasswordsDontMatch => 'The new passwords don\'t match.';

  @override
  String get pickDifferentPassword => 'Pick a password you are not using now.';

  @override
  String get passwordUpdated => 'Password updated';

  @override
  String get currentPasswordWrong => 'Your current password isn\'t right.';

  @override
  String get passwordTooWeak => 'That password is too weak.';

  @override
  String resetLinkSent(String email) {
    return 'We sent a reset link to $email.';
  }

  @override
  String linkSendFailed(String code) {
    return 'Couldn\'t send the link ($code).';
  }

  @override
  String get changePassword => 'Change password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get passwordHint =>
      'At least 6 characters, with an uppercase letter, a lowercase letter, and a number.';

  @override
  String get updatePassword => 'Update password';

  @override
  String get forgotMyPassword => 'Forgot my password';

  @override
  String get twoFactor => 'Two-factor authentication';

  @override
  String get twoFactorSoon => 'Coming soon: a code by SMS when you sign in';

  @override
  String get planFree => 'Free';

  @override
  String get planFeatCore => 'Budgeting, Spendings, and Savings';

  @override
  String get planFeat2Banks => 'Up to 2 linked bank accounts';

  @override
  String get planFeatHealth => 'Monthly financial health score';

  @override
  String get planFeatAllFree => 'Everything in Free';

  @override
  String get planFeatUnlimitedBanks => 'Unlimited bank accounts';

  @override
  String get planFeatShared1 =>
      'Shared finances with 1 household and up to 3 shared goals';

  @override
  String get planFeatReminders => 'Smart reminders and alerts';

  @override
  String get planFeatAllPlus => 'Everything in Plus';

  @override
  String get planFeatShared3 =>
      'Up to 3 households with unlimited shared goals';

  @override
  String get planFeatInsights => 'Advanced insights and exports';

  @override
  String get planFeatPriority => 'Priority customer service';

  @override
  String get paidPlansSoon => 'Paid plans are coming soon';

  @override
  String get paidPlansSoonBody =>
      'You\'ll be able to subscribe here once they launch. Until then, everything in Vesta is free.';

  @override
  String get noSubscription => 'You don\'t have a subscription';

  @override
  String get onFreePlan =>
      'You\'re on the Free plan. Pick a plan to unlock more.';

  @override
  String get aMonth => 'a month';

  @override
  String getPlan(String plan) {
    return 'Get $plan';
  }

  @override
  String get howReferralsWork => 'How referrals work';

  @override
  String referralsHowBody(String reward, String welcome) {
    return 'Share your code. When a friend enters it while signing up, you get $reward points and they get $welcome. 1,000 points get you a free month of Plus, and 1,500 a free month of Premium.';
  }

  @override
  String get gotIt => 'Got it';

  @override
  String get enoughPremium => 'Enough for a free month of Premium';

  @override
  String enoughPlusMore(String points) {
    return 'Enough for a free month of Plus · $points more for Premium';
  }

  @override
  String moreForPlus(String points) {
    return '$points more for a free month of Plus';
  }

  @override
  String get yourPoints => 'Your points';

  @override
  String pointsShort(String points) {
    return '$points pts';
  }

  @override
  String get howItWorks => 'How it works';

  @override
  String get usePoints => 'Use points';

  @override
  String get yourReferralCode => 'Your referral code';

  @override
  String get copyCode => 'Copy code';

  @override
  String get codeCopied => 'Code copied';

  @override
  String get copyLink => 'Copy link';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get share => 'Share';

  @override
  String referralShareText(String code, String link) {
    return 'I use Vesta to plan my money. Join with my code $code: $link';
  }

  @override
  String get peopleInvited => 'People you\'ve invited';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String get noOneInvitedYet =>
      'No one yet. Share your code, and the friends who join show up here.';

  @override
  String get friend => 'Friend';

  @override
  String joinedOn(String date) {
    return 'Joined $date';
  }

  @override
  String get reasonNotEnough => 'I don\'t use it enough';

  @override
  String get reasonPrivacy => 'I have privacy concerns';

  @override
  String get reasonMissingFeatures => 'It\'s missing features I need';

  @override
  String get reasonSwitching => 'I\'m switching to another app';

  @override
  String get reasonExpensive => 'It\'s too expensive';

  @override
  String get reasonTechnical => 'I\'m having technical issues';

  @override
  String get pickReason => 'Pick at least one reason.';

  @override
  String get deleteVestaAccountTitle => 'Delete your Vesta account?';

  @override
  String get deleteVestaAccountMessage =>
      'Everything in it is removed for good. This cannot be undone.';

  @override
  String vestaAccountDeleteFailed(String error) {
    return 'Couldn\'t delete the account: $error';
  }

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get whyDelete => 'Why do you want to delete your account?';

  @override
  String get tellUsMore => 'Tell us more (optional)';

  @override
  String get deleteWarning =>
      'If you delete your account, all of your information will be gone: your budgets, transactions, savings goals, accounts, and shared finances.';

  @override
  String get iconSecFood => 'Food & drink';

  @override
  String get iconSecHome => 'Home & bills';

  @override
  String get iconSecTransport => 'Transport & travel';

  @override
  String get iconSecLifestyle => 'Lifestyle';

  @override
  String get iconSecPeople => 'People & other';

  @override
  String get chooseAnIcon => 'Choose an icon';
}
