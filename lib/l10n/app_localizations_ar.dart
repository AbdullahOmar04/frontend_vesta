// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabDashboard => 'لوحة المتابعة';

  @override
  String get tabWallet => 'المحفظة';

  @override
  String get tabProfile => 'حسابي';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get currencyJod => 'د.أ';

  @override
  String get profileTitle => 'حسابي';

  @override
  String get notLoggedIn => 'لم تسجّل الدخول';

  @override
  String get profilePersonalInfo => 'المعلومات الشخصية';

  @override
  String get profileBankAccounts => 'إدارة الحسابات البنكية';

  @override
  String get profileSubscriptions => 'الاشتراكات';

  @override
  String get profileFreePlan => 'الباقة المجانية';

  @override
  String get profileReferrals => 'دعوة الأصدقاء';

  @override
  String profilePoints(String points) {
    return '$points نقطة';
  }

  @override
  String get profilePreferences => 'التفضيلات';

  @override
  String get profileSecurity => 'كلمة المرور والأمان';

  @override
  String get profileTerms => 'الشروط والأحكام';

  @override
  String get logOut => 'تسجيل الخروج';

  @override
  String get logOutTitle => 'تسجيل الخروج من Vesta؟';

  @override
  String get logOutMessage => 'ستحتاج إلى تسجيل الدخول مرة أخرى لرؤية أموالك.';

  @override
  String get prefsTitle => 'التفضيلات';

  @override
  String get prefsDisplay => 'العرض';

  @override
  String get prefsDisplaySubtitle => 'المظهر واللغة والعملة';

  @override
  String get prefsResetDay => 'يوم بداية الميزانية';

  @override
  String prefsResetDaySubtitle(String day) {
    return 'اليوم $day من كل شهر';
  }

  @override
  String get prefsFeatures => 'إدارة الميزات';

  @override
  String get prefsReminders => 'التذكيرات والتنبيهات';

  @override
  String get prefsRemindersSubtitle => 'الدفعات القادمة والميزانيات والأهداف';

  @override
  String get prefsNotifications => 'الإشعارات';

  @override
  String get displayTitle => 'العرض';

  @override
  String get displayAppearance => 'المظهر';

  @override
  String get displayLight => 'فاتح';

  @override
  String get displayDark => 'داكن';

  @override
  String get displayAuto => 'تلقائي';

  @override
  String get displayAutoNote => 'الوضع التلقائي يتبع إعداد هاتفك.';

  @override
  String get displayLanguage => 'اللغة';

  @override
  String get displayCurrency => 'العملة';

  @override
  String get displayCurrencyJod => 'د.أ · دينار أردني';

  @override
  String get displayMoreCurrencies => 'المزيد من العملات قريباً.';

  @override
  String get remindersIntro => 'اختر ما تريد أن يذكّرك به Vesta.';

  @override
  String get remindersUpcoming => 'الدفعات القادمة';

  @override
  String get remindersUpcomingSubtitle => 'قبل موعد أي دفعة مجدولة';

  @override
  String get remindersRemindMe => 'ذكّرني قبل';

  @override
  String remindersDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يوماً',
      few: '$count أيام',
      two: 'يومين',
      one: 'يوم',
    );
    return '$_temp0';
  }

  @override
  String get remindersOverBudget => 'تجاوز الميزانية';

  @override
  String get remindersOverBudgetSubtitle =>
      'عندما يقترب إنفاقك من حدّ الميزانية';

  @override
  String get remindersAlertAt => 'نبّهني عند';

  @override
  String get remindersCategoryLimits => 'حدود الفئات';

  @override
  String get remindersCategoryLimitsSubtitle =>
      'عندما تصل فئة إلى حدّها الشهري';

  @override
  String get remindersSavings => 'أهداف الادخار';

  @override
  String get remindersSavingsSubtitle => 'عندما لا تبلغ هدف هذا الشهر';

  @override
  String get remindersLarge => 'المعاملات الكبيرة';

  @override
  String remindersLargeSubtitle(String amount) {
    return 'عندما تتجاوز معاملة واحدة $amount';
  }

  @override
  String get remindersNotYet =>
      'لا يرسل Vesta هذه التنبيهات بعد. سنحفظ اختياراتك حتى يبدأ بإرسالها.';

  @override
  String get notificationsIntro => 'اختر الإشعارات التي تريد استلامها.';

  @override
  String get notificationsPerTransaction => 'كل معاملة';

  @override
  String get notificationsPerTransactionSubtitle =>
      'في كل مرة يدخل فيها مال أو يخرج';

  @override
  String get notificationsRequired => 'إجراءات مطلوبة';

  @override
  String get notificationsRequiredSubtitle =>
      'أمور تحتاجك، مثل فاتورة بانتظار التأكيد';

  @override
  String get notificationsMotivational => 'تحفيزية';

  @override
  String get notificationsMotivationalSubtitle => 'الإنجازات والتشجيع';

  @override
  String get notificationsPromotional => 'العروض وتحديثات التطبيق';

  @override
  String get notificationsPromotionalSubtitle => 'العروض والميزات الجديدة';

  @override
  String get notificationsSupport => 'خدمة العملاء';

  @override
  String get notificationsSupportSubtitle => 'الردود على طلبات الدعم';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get logIn => 'تسجيل الدخول';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get ok => 'حسناً';

  @override
  String get back => 'رجوع';

  @override
  String get skip => 'تخطي';

  @override
  String get goBack => 'رجوع';

  @override
  String get genericErrorLater => 'حدث خطأ. حاول مرة أخرى لاحقاً.';

  @override
  String get genericErrorAgain => 'حدث خطأ. حاول مرة أخرى.';

  @override
  String get tooManyAttempts => 'محاولات كثيرة. حاول مرة أخرى لاحقاً.';

  @override
  String get enterValidEmail => 'أدخل بريداً إلكترونياً صحيحاً';

  @override
  String errorWith(String error) {
    return 'خطأ: $error';
  }

  @override
  String get welcomeTitle => 'أهلاً بك في Vesta';

  @override
  String get welcomeSubtitle => 'سجّل الدخول أو أنشئ حساباً للمتابعة.';

  @override
  String get unlockReason => 'افتح Vesta';

  @override
  String get welcomeBack => 'أهلاً بعودتك';

  @override
  String welcomeBackName(String name) {
    return 'أهلاً بعودتك، $name';
  }

  @override
  String get unlockSubtitle => 'افتح القفل لرؤية أموالك.';

  @override
  String get unlock => 'فتح القفل';

  @override
  String get logInWithPassword => 'الدخول بكلمة المرور';

  @override
  String get notYou => 'لست أنت؟ استخدم حساباً آخر أو أنشئ حساباً';

  @override
  String get blockedTitle => 'رقم الهاتف محظور مؤقتاً';

  @override
  String get blockedVerifyBody => 'حُظر رقمك مؤقتاً بسبب كثرة محاولات التحقق.';

  @override
  String get blockedOtpBody => 'حُظر رقمك مؤقتاً بسبب كثرة المحاولات الفاشلة.';

  @override
  String get blockedDuration => 'مدة الحظر: 30 دقيقة';

  @override
  String get blockedRegain => 'لاستعادة الوصول:';

  @override
  String get blockedStep1 => '1. انتظر حتى تنتهي مدة الحظر (حتى 30 دقيقة)';

  @override
  String get blockedStep2 => '2. تأكد من أن الرقم معك ويستقبل الرسائل';

  @override
  String get blockedStep3Later => '3. حاول مرة أخرى بعد انتهاء المدة';

  @override
  String get blockedStep3Otp => '3. حاول مرة أخرى بالرمز الصحيح';

  @override
  String get phoneInvalid =>
      'أدخل رقماً أردنياً صحيحاً يبدأ بـ 7 (مثل 79xxxxxxx)';

  @override
  String get phoneVerifyFailed => 'فشل التحقق من الرقم';

  @override
  String phoneVerifyStartError(String error) {
    return 'تعذّر بدء التحقق من الرقم: $error';
  }

  @override
  String get phoneTitle => 'رقم هاتفك';

  @override
  String get phoneSubtitle => 'سنرسل رمز تحقق إلى هذا الرقم.';

  @override
  String get phoneLabel => 'رقم الهاتف';

  @override
  String get sendCode => 'إرسال الرمز';

  @override
  String get fillAllFields => 'يرجى تعبئة جميع الحقول';

  @override
  String get passwordsDontMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get passwordRequirementsNotMet =>
      'تأكد من أن كلمة المرور تستوفي جميع الشروط';

  @override
  String get usernameRules =>
      'اسم المستخدم يقبل الحروف الإنجليزية والأرقام والشرطة السفلية (_) فقط';

  @override
  String get usernameTaken => 'اسم المستخدم محجوز. اختر اسماً آخر.';

  @override
  String get emailRegistered =>
      'البريد الإلكتروني مسجّل مسبقاً. استخدم بريداً آخر أو سجّل الدخول.';

  @override
  String get referralNotFound =>
      'لم نجد رمز الدعوة هذا. تحقق منه أو اتركه فارغاً.';

  @override
  String checkUsernameError(String error) {
    return 'تعذّر التحقق من اسم المستخدم أو البريد: $error';
  }

  @override
  String get createAccountTitle => 'أنشئ حسابك';

  @override
  String get nextVerifyPhone => 'بعد ذلك سنتحقق من رقم هاتفك.';

  @override
  String useTheseToLogIn(String username) {
    return 'ستستخدم هذه البيانات لتسجيل الدخول باسم $username. بعد ذلك سنتحقق من رقم هاتفك.';
  }

  @override
  String get username => 'اسم المستخدم';

  @override
  String get passwordNeeds => 'يجب أن تحتوي كلمة المرور على';

  @override
  String get pwMinLength => '6 أحرف على الأقل';

  @override
  String get pwUppercase => 'حرف إنجليزي كبير واحد على الأقل (A-Z)';

  @override
  String get pwLowercase => 'حرف إنجليزي صغير واحد على الأقل (a-z)';

  @override
  String get pwNumber => 'رقم واحد على الأقل (من 0 إلى 9)';

  @override
  String get repeatPassword => 'تأكيد كلمة المرور';

  @override
  String get referralCode => 'رمز الدعوة';

  @override
  String get referralHint => 'اختياري، مثل MAYA-25K9';

  @override
  String get resetPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get resetPasswordMessage =>
      'أدخل بريدك الإلكتروني وسنرسل لك رابطاً لإعادة تعيين كلمة المرور.';

  @override
  String get sendResetLink => 'إرسال الرابط';

  @override
  String get enterEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get resetEmailSent =>
      'أرسلنا رسالة إعادة تعيين كلمة المرور. تفقّد بريدك.';

  @override
  String get resetEmailFailed => 'تعذّر إرسال الرسالة. حاول مرة أخرى.';

  @override
  String get invalidLogin => 'اسم المستخدم أو كلمة المرور غير صحيحة';

  @override
  String get networkError => 'خطأ في الشبكة. تحقق من اتصالك.';

  @override
  String get accountError => 'مشكلة في الحساب. تواصل مع الدعم.';

  @override
  String get biometricUnavailable => 'الدخول بالبصمة غير متاح أو غير مفعّل';

  @override
  String get biometricFailed => 'فشل التحقق بالبصمة';

  @override
  String get noStoredCredentials =>
      'لا توجد بيانات محفوظة. سجّل الدخول بكلمة المرور أولاً.';

  @override
  String get sessionExpired => 'انتهت الجلسة. سجّل الدخول بكلمة المرور.';

  @override
  String get loginSubtitle => 'سجّل الدخول باسم المستخدم أو البريد الإلكتروني.';

  @override
  String get usernameOrEmail => 'اسم المستخدم أو البريد الإلكتروني';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get logInWithBiometrics => 'الدخول بالبصمة';

  @override
  String get enableBiometricsLater =>
      'فعّل البصمة من الإعدادات بعد تسجيل الدخول';

  @override
  String get noAccount => 'ليس لديك حساب؟ ';

  @override
  String get otpExpired => 'انتهت صلاحية الرمز. اطلب رمزاً جديداً.';

  @override
  String get otpEnter6 => 'أدخل الرمز المكوّن من 6 أرقام';

  @override
  String get numberHasAccount =>
      'هذا الرقم مرتبط بحساب في Vesta. سجّل الدخول بدلاً من ذلك.';

  @override
  String get emailHasAccount =>
      'هذا البريد مرتبط بحساب في Vesta. سجّل الدخول بدلاً من ذلك.';

  @override
  String get usernameTakenRetry => 'اسم المستخدم محجوز. أعد التسجيل باسم آخر.';

  @override
  String get emailTakenRetry =>
      'البريد الإلكتروني مسجّل مسبقاً. سجّل الدخول أو استخدم بريداً آخر.';

  @override
  String get usernameOrEmailTaken =>
      'اسم المستخدم أو البريد محجوز. أعد التسجيل ببيانات أخرى.';

  @override
  String createAccountFailed(String error) {
    return 'تعذّر إنشاء الحساب: $error';
  }

  @override
  String get verificationFailed => 'فشل التحقق';

  @override
  String get resendFailed => 'تعذّرت إعادة إرسال الرمز';

  @override
  String get otpResent => 'أرسلنا رمزاً جديداً';

  @override
  String resendError(String error) {
    return 'تعذّرت إعادة إرسال الرمز: $error';
  }

  @override
  String get enterCode => 'أدخل الرمز';

  @override
  String codeSentTo(String phone) {
    return 'أرسلنا رمزاً إلى $phone للتحقق من رقمك.';
  }

  @override
  String get codeExpiredBelow =>
      'انتهت صلاحية الرمز. اطلب رمزاً جديداً بالأسفل.';

  @override
  String codeExpiresIn(String time) {
    return 'تنتهي صلاحية الرمز خلال $time';
  }

  @override
  String get verifyCreate => 'تحقّق وأنشئ الحساب';

  @override
  String get didntGetIt => 'لم يصلك؟ ';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String resendIn(String seconds) {
    return 'يمكنك إعادة الإرسال بعد $seconds ث';
  }

  @override
  String get usernameCharsShort =>
      'استخدم الحروف الإنجليزية والأرقام والشرطة السفلية فقط';

  @override
  String get usernameTakenShort => 'اسم المستخدم هذا محجوز';

  @override
  String usernameCheckFailed(String error) {
    return 'تعذّر التحقق من اسم المستخدم: $error';
  }

  @override
  String get onbWelcomeTitle => 'لنجمع أموالك في مكان واحد هادئ.';

  @override
  String get onbWelcomeBody =>
      'بضعة أسئلة وتحصل على ميزانية أولى، وحساباتك في مكان واحد، ومدرّب يتابع إنفاقك.';

  @override
  String get chooseUsername => 'اختر اسم مستخدم';

  @override
  String incomeTitle(String name) {
    return 'تشرّفنا يا $name. كم يصل إلى حسابك كل شهر؟';
  }

  @override
  String get incomeBody =>
      'صافي دخلك بعد الضرائب. سنقترح تقسيماً يمكنك تغييره متى شئت.';

  @override
  String get perMonth => 'شهرياً';

  @override
  String get incomePrivate => 'يبقى على هاتفك حتى تنشئ حسابك.';

  @override
  String get suggestedSplit => 'التقسيم المقترح للبداية';

  @override
  String get useAsBudget => 'اعتمده كميزانيتي الأولى';

  @override
  String get bucketNecessities => 'الضروريات';

  @override
  String get bucketNecessitiesExamples => 'الإيجار والبقالة والفواتير';

  @override
  String get bucketLuxuries => 'الكماليات';

  @override
  String get bucketLuxuriesExamples => 'المطاعم والترفيه والتسوق';

  @override
  String get bucketSavings => 'الادخار';

  @override
  String get bucketSavingsExamples => 'الأهداف والدفعات الإضافية';

  @override
  String get focusTitle => 'بماذا تريد أن تبدأ؟';

  @override
  String get focusBody => 'اختر حتى ثلاثة. سيركّز مدرّبك عليها.';

  @override
  String get focusSpend => 'إدارة مصاريفي';

  @override
  String get focusGoals => 'بدء أهداف ادخار';

  @override
  String get focusBills => 'إدارة الفواتير والدفعات المجدولة';

  @override
  String get focusShared => 'إدارة المصاريف المشتركة';

  @override
  String get focusBudget => 'بناء ميزانية شهرية';

  @override
  String get focusClarity => 'فهم وضعي المالي بوضوح';

  @override
  String get banksTitle => 'ما البنوك التي تتعامل معها؟';

  @override
  String get banksBody =>
      'اختر كل ما ينطبق. لن نربط أي حساب؛ هذا يساعدنا فقط على تجهيز Vesta حول حساباتك.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get yes => 'نعم';

  @override
  String get add => 'إضافة';

  @override
  String get remove => 'حذف';

  @override
  String get done => 'تم';

  @override
  String get close => 'إغلاق';

  @override
  String get comingLater => 'هذه الميزة قادمة في تحديث لاحق.';

  @override
  String get greetingMorning => 'صباح الخير،';

  @override
  String get greetingAfternoon => 'مساء الخير،';

  @override
  String get greetingEvening => 'مساء الخير،';

  @override
  String get greetingNight => 'مساء الخير،';

  @override
  String get greetingFallbackName => 'يا صديقي';

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String get totalBalance => 'الرصيد الإجمالي';

  @override
  String amountSpent(String amount) {
    return 'أنفقت $amount';
  }

  @override
  String amountEarned(String amount) {
    return 'دخل $amount';
  }

  @override
  String get accountsLabel => 'الحسابات';

  @override
  String accountCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حساب',
      many: '$count حساباً',
      few: '$count حسابات',
      two: 'حسابان',
      one: 'حساب واحد',
      zero: 'لا حسابات',
    );
    return '$_temp0';
  }

  @override
  String get tileBudgeting => 'الميزانية';

  @override
  String get tileSpendings => 'المصاريف';

  @override
  String get tileSavings => 'المدخرات';

  @override
  String get tileShared => 'المالية المشتركة';

  @override
  String monthBudget(String month) {
    return 'ميزانية $month';
  }

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get noBudgetPlan => 'لا توجد خطة ميزانية لهذا الشهر بعد.';

  @override
  String get planYourBudget => 'خطّط لميزانيتك';

  @override
  String spentOfBudget(String spent, String budget) {
    return '$spent من $budget للإنفاق';
  }

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقي $count يوم',
      many: 'بقي $count يوماً',
      few: 'بقي $count أيام',
      two: 'بقي يومان',
      one: 'بقي يوم',
    );
    return '$_temp0';
  }

  @override
  String get notInPlan => 'خارج الخطة';

  @override
  String get targetReached => 'تم بلوغ الهدف';

  @override
  String amountToGo(String amount) {
    return 'بقي $amount';
  }

  @override
  String amountOver(String amount) {
    return 'تجاوز بـ $amount';
  }

  @override
  String amountLeft(String amount) {
    return 'متبقٍّ $amount';
  }

  @override
  String get comingUp => 'القادمة';

  @override
  String get allBills => 'كل الفواتير';

  @override
  String get nothingDue => 'لا دفعات قريبة.';

  @override
  String get addYourBills => 'أضف فواتيرك';

  @override
  String get goals => 'الأهداف';

  @override
  String get noGoals => 'لا أهداف ادخار بعد.';

  @override
  String get createGoal => 'أنشئ هدفاً';

  @override
  String get goalFallback => 'هدف';

  @override
  String get recent => 'الأحدث';

  @override
  String get noTransactions => 'لا معاملات بعد.';

  @override
  String get addOne => 'أضف معاملة';

  @override
  String get coachLabel => 'مدرّبك';

  @override
  String get coachPlanTitle => 'لنخطّط لهذا الشهر.';

  @override
  String get coachPlanBody =>
      'أدخل دخلك وقسّمه بين الادخار والضروريات والكماليات، وسأخبرك كيف يسير إنفاقك مقارنة بالخطة.';

  @override
  String get coachMostlyOnPace => 'إنفاقك منضبط في معظمه.';

  @override
  String get coachRunningHot => 'إنفاقك أعلى قليلاً من المعتاد.';

  @override
  String get bucketNecessitiesLower => 'الضروريات';

  @override
  String get bucketLuxuriesLower => 'الكماليات';

  @override
  String coachOverWithOther(
    String name,
    String by,
    String left,
    String other,
    String perDay,
    String until,
  ) {
    return 'تجاوزت $name حدّها بـ $by. ما زال لديك $left لـ$other، أي نحو $perDay يومياً حتى $until.';
  }

  @override
  String coachOverUsedUp(String name, String by, String until) {
    return 'تجاوزت $name حدّها بـ $by، ونفدت ميزانية إنفاقك حتى $until.';
  }

  @override
  String get coachAheadTitle => 'إنفاقك يسبق الخطة.';

  @override
  String coachAheadBody(String used, String left, String perDay) {
    return 'استخدمت $used% من ميزانية إنفاقك وما زال $left% من الدورة. إنفاق $perDay يومياً يبقيك على المسار.';
  }

  @override
  String get coachOnPaceTitle => 'إنفاقك على المسار في هذه الدورة.';

  @override
  String coachOnPaceBody(String left, String perDay, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'للـ$days يوم القادمة',
      many: 'للـ$days يوماً القادمة',
      few: 'للأيام الـ$days القادمة',
      two: 'لليومين القادمين',
      one: 'لليوم المتبقي',
    );
    return 'متبقٍّ للإنفاق $left، أي نحو $perDay يومياً $_temp0.';
  }

  @override
  String get coachPlanLink => 'خطّط لميزانيتك ←';

  @override
  String get coachInsightsLink => 'عرض التحليلات ←';

  @override
  String amountThisMonth(String amount) {
    return '$amount هذا الشهر';
  }

  @override
  String get delete => 'حذف';

  @override
  String deleteNameTitle(String name) {
    return 'حذف $name؟';
  }

  @override
  String get deleteAccountMessage =>
      'سيُحذف معه كل معاملات الحساب، ولا يمكن التراجع عن ذلك.';

  @override
  String get accountDeleted => 'حُذف الحساب';

  @override
  String accountDeleteFailed(String error) {
    return 'تعذّر حذف الحساب: $error';
  }

  @override
  String get walletTitle => 'المحفظة';

  @override
  String get addAccount => 'إضافة حساب';

  @override
  String get removeAnAccount => 'حذف حساب';

  @override
  String get noAccountsYet => 'لا حسابات بعد. اضغط + لإضافة حساب.';

  @override
  String get netWorth => 'صافي الثروة';

  @override
  String acrossAccounts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'في $count حساب',
      many: 'في $count حساباً',
      few: 'في $count حسابات',
      two: 'في حسابين',
      one: 'في حساب واحد',
      zero: 'لا حسابات',
    );
    return '$_temp0';
  }

  @override
  String get unknownBank => 'بنك غير معروف';

  @override
  String get unknownType => 'نوع غير معروف';

  @override
  String get typeCurrent => 'حساب جاري';

  @override
  String get typeSavings => 'حساب توفير';

  @override
  String get typeCreditCard => 'بطاقة ائتمان';

  @override
  String get typeLoan => 'قرض';

  @override
  String get typeInvestment => 'حساب استثماري';

  @override
  String get typeCash => 'نقدي';

  @override
  String get enterBalanceNumber => 'أدخل الرصيد كرقم';

  @override
  String get accountAdded => 'أُضيف الحساب';

  @override
  String accountAddFailed(String error) {
    return 'تعذّرت إضافة الحساب: $error';
  }

  @override
  String get addAccountManually => 'إضافة حساب يدوياً';

  @override
  String get bank => 'البنك';

  @override
  String get accountType => 'نوع الحساب';

  @override
  String get accountName => 'اسم الحساب';

  @override
  String get accountNameHint => 'مثل: حساب الراتب';

  @override
  String get last4Digits => 'آخر 4 أرقام';

  @override
  String get optional => 'اختياري';

  @override
  String get amountOwed => 'المبلغ المستحق';

  @override
  String get currentBalance => 'الرصيد الحالي';

  @override
  String get manualAccountsNote =>
      'الحسابات اليدوية لا تتزامن مع البنك؛ ستضيف المعاملات وتحدّث الرصيد بنفسك.';

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String get bucketNecessity => 'ضرورية';

  @override
  String get bucketLuxury => 'كمالية';

  @override
  String get income => 'دخل';

  @override
  String get expense => 'مصروف';

  @override
  String get other => 'أخرى';

  @override
  String get catFoodDrinks => 'طعام ومشروبات';

  @override
  String get catGroceries => 'بقالة';

  @override
  String get catEntertainment => 'ترفيه';

  @override
  String get catOthers => 'أخرى';

  @override
  String get catRent => 'إيجار';

  @override
  String get catShopping => 'تسوق';

  @override
  String get catTransport => 'مواصلات';

  @override
  String get catHealth => 'صحة';

  @override
  String get catBills => 'فواتير وخدمات';

  @override
  String get catSavings => 'ادخار';

  @override
  String get budgetDayHelp =>
      'تبدأ دورة ميزانيتك في هذا اليوم من كل شهر، وغالباً يكون يوم الراتب.';

  @override
  String get dayOfMonth => 'يوم الشهر';

  @override
  String get enterDay => 'أدخل يوماً';

  @override
  String get enterValidNumber => 'أدخل رقماً صحيحاً';

  @override
  String get dayRange => 'يجب أن يكون اليوم بين 1 و31';

  @override
  String currentDay(String day) {
    return 'الحالي: اليوم $day';
  }

  @override
  String get save => 'حفظ';

  @override
  String budgetDayUpdated(String day) {
    return 'أصبح يوم بداية الميزانية $day';
  }

  @override
  String get budgetDayFailed => 'تعذّر تحديث اليوم. حاول مرة أخرى.';

  @override
  String get allAccounts => 'كل الحسابات';

  @override
  String get allCategories => 'كل الفئات';

  @override
  String get uncategorized => 'بلا فئة';

  @override
  String categoryUpdated(String name) {
    return 'تغيّرت الفئة إلى $name';
  }

  @override
  String get category => 'الفئة';

  @override
  String get type => 'النوع';

  @override
  String get merchant => 'التاجر';

  @override
  String get account => 'الحساب';

  @override
  String get source => 'المصدر';

  @override
  String get sourceManual => 'يدوي';

  @override
  String get sourceSms => 'رسالة نصية';

  @override
  String get sourceBank => 'البنك';

  @override
  String get description => 'الوصف';

  @override
  String get addedBy => 'أضافها';

  @override
  String get date => 'التاريخ';

  @override
  String get assignToHousehold => 'إضافة إلى المنزل المشترك';

  @override
  String get transactionDeleted => 'حُذفت المعاملة';

  @override
  String transactionDeleteError(String error) {
    return 'تعذّر حذف المعاملة: $error';
  }

  @override
  String get deleteTransaction => 'حذف المعاملة';

  @override
  String get removeFromHousehold => 'إزالة من المنزل المشترك';

  @override
  String get notInAnyHousehold => 'لست عضواً في أي منزل مشترك.';

  @override
  String get transactionNotFound => 'لم نجد المعاملة';

  @override
  String assignedTo(String name) {
    return 'أُضيفت إلى \"$name\"';
  }

  @override
  String get loadTransactionsFailed => 'تعذّر تحميل المعاملات';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get noTransactionsTitle => 'لا معاملات بعد';

  @override
  String get addFirstTransaction => 'اضغط + لإضافة أول معاملة.';

  @override
  String get refresh => 'تحديث';

  @override
  String get noMatchingTransactions => 'لا معاملات تطابق هذه الفلاتر';

  @override
  String get tryOtherFilters => 'جرّب حساباً أو فئة أو تاريخاً آخر.';

  @override
  String get clearFilters => 'مسح الفلاتر';

  @override
  String get selectMonth => 'اختر الشهر';

  @override
  String get periodAll => 'الكل';

  @override
  String get periodLast7 => 'آخر 7 أيام';

  @override
  String get periodLast30 => 'آخر 30 يوماً';

  @override
  String get month => 'الشهر';

  @override
  String get transactionsTitle => 'المعاملات';

  @override
  String get deleteTransactionTitle => 'حذف هذه المعاملة؟';

  @override
  String deleteTxnReturned(String amount) {
    return 'ستُحذف ويُعاد $amount إلى رصيد الحساب.';
  }

  @override
  String deleteTxnTakenOff(String amount) {
    return 'ستُحذف ويُخصم $amount من رصيد الحساب.';
  }

  @override
  String transactionDeleteFailed(String error) {
    return 'تعذّر حذف المعاملة: $error';
  }

  @override
  String get addTransaction => 'إضافة معاملة';

  @override
  String get removeATransaction => 'حذف معاملة';

  @override
  String get enterValidAmount => 'أدخل مبلغاً صحيحاً.';

  @override
  String get selectAnAccount => 'اختر حساباً.';

  @override
  String get transactionAdded => 'أُضيفت المعاملة.';

  @override
  String get smsNoAmount =>
      'لم نجد مبلغاً في هذه الرسالة. جرّب الإدخال اليدوي.';

  @override
  String get addATransaction => 'إضافة معاملة';

  @override
  String get pasteBankSms => 'الصق رسالة البنك';

  @override
  String get trySample => 'جرّب رسالة نموذجية';

  @override
  String get readMessage => 'قراءة الرسالة';

  @override
  String get smsWillFill => 'سنعبّئ التفاصيل لتراجعها قبل الحفظ.';

  @override
  String get filledFromSms => 'عبّأناها من رسالتك. راجع التفاصيل أدناه.';

  @override
  String get noAccountsAddInWallet =>
      'لا حسابات بعد. أضف حساباً من المحفظة أولاً.';

  @override
  String amountIn(String currency) {
    return 'المبلغ ($currency)';
  }

  @override
  String get merchantFrom => 'التاجر / المرسل';

  @override
  String get noteOptional => 'ملاحظة (اختياري)';

  @override
  String transactionCountRecent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count معاملة · الأحدث أولاً',
      many: '$count معاملة · الأحدث أولاً',
      few: '$count معاملات · الأحدث أولاً',
      two: 'معاملتان · الأحدث أولاً',
      one: 'معاملة واحدة · الأحدث أولاً',
    );
    return '$_temp0';
  }

  @override
  String get spendingsTitle => 'المصاريف';

  @override
  String get categories => 'الفئات';

  @override
  String get latestTransactions => 'آخر المعاملات';

  @override
  String spentInMonthSoFar(String month) {
    return 'المصروف في $month حتى الآن';
  }

  @override
  String percentUsed(String percent) {
    return 'استُخدم $percent%';
  }

  @override
  String ofAmount(String amount) {
    return 'من $amount';
  }

  @override
  String get noBudgetThisCycle => 'لا خطة ميزانية لهذه الدورة بعد';

  @override
  String daysToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقي $count يوم',
      many: 'بقي $count يوماً',
      few: 'بقي $count أيام',
      two: 'بقي يومان',
      one: 'بقي يوم',
    );
    return '$_temp0';
  }

  @override
  String get noCategorizedSpending =>
      'لا مصاريف مصنّفة بعد.\nأضف فئات لمعاملاتك لتظهر هنا.';

  @override
  String loadBudgetError(String error) {
    return 'تعذّر تحميل الميزانية: $error';
  }

  @override
  String get insightsTitle => 'التحليلات';

  @override
  String vsMonth(String amount, String month) {
    return '$amount مقارنة بـ$month';
  }

  @override
  String categoryDown(String name, String amount) {
    return 'انخفضت $name بـ $amount';
  }

  @override
  String categoryUp(String name, String amount) {
    return 'ارتفعت $name بـ $amount';
  }

  @override
  String comparedWithMonth(String month) {
    return 'مقارنة بالفترة نفسها من $month.';
  }

  @override
  String biggestDrop(String month) {
    return 'مقارنة بالفترة نفسها من $month. هذا أكبر انخفاض بين الفئات.';
  }

  @override
  String get byCategory => 'حسب الفئة';

  @override
  String get noSpendingTwoMonths => 'لا مصاريف هذا الشهر ولا الشهر الماضي.';

  @override
  String onePurchase(String date) {
    return 'معظمها من عملية شراء واحدة في $date. تستحق نظرة قبل نهاية الشهر.';
  }

  @override
  String get categoryAdded => 'أُضيفت الفئة';

  @override
  String get deleteCategoryMessage => 'تبقى معاملاتها بمبالغها لكن بلا فئة.';

  @override
  String categoryDeleted(String name) {
    return 'حُذفت فئة \"$name\" وأُزيلت من معاملاتها.';
  }

  @override
  String categoryDeleteError(String error) {
    return 'تعذّر حذف الفئة: $error';
  }

  @override
  String get sortBy => 'ترتيب حسب';

  @override
  String get sortHigh => 'الأعلى إنفاقاً';

  @override
  String get sortLow => 'الأقل إنفاقاً';

  @override
  String get sortName => 'الاسم (أ–ي)';

  @override
  String get sortLimit => 'الأقرب إلى الحد';

  @override
  String get filter => 'تصفية';

  @override
  String filterCount(String count) {
    return 'تصفية · $count';
  }

  @override
  String get sort => 'ترتيب';

  @override
  String get newCategory => 'فئة جديدة';

  @override
  String get removeACategory => 'حذف فئة';

  @override
  String get noCategoriesYet => 'لا فئات بعد. اضغط + لإنشاء فئة.';

  @override
  String get noCategoriesMatch => 'لا فئات تطابق هذه التصفية.';

  @override
  String get clearFilter => 'مسح التصفية';

  @override
  String get noBudgetPlanned => 'لا ميزانية مخططة';

  @override
  String get show => 'عرض';

  @override
  String get onlyWithSpending => 'الفئات التي فيها إنفاق فقط';

  @override
  String get onlyOverLimit => 'الفئات التي تجاوزت حدّها فقط';

  @override
  String get reset => 'إعادة ضبط';

  @override
  String get showResults => 'عرض النتائج';

  @override
  String get giveCategoryName => 'اكتب اسماً للفئة.';

  @override
  String categoryExists(String name) {
    return 'لديك فئة باسم \"$name\" مسبقاً.';
  }

  @override
  String categoryAddFailed(String error) {
    return 'تعذّرت إضافة الفئة: $error';
  }

  @override
  String get addNewCategory => 'إضافة فئة جديدة';

  @override
  String get addCategory => 'إضافة الفئة';

  @override
  String get categoryName => 'اسم الفئة';

  @override
  String get budget => 'الميزانية';

  @override
  String get monthlyLimit => 'حد الإنفاق الشهري';

  @override
  String get noLimit => 'بلا حد';

  @override
  String get necessitiesBudget => 'ميزانية الضروريات';

  @override
  String get luxuriesBudget => 'ميزانية الكماليات';

  @override
  String get notPlanned => 'غير مخطط';

  @override
  String get thisLimit => 'هذا الحد';

  @override
  String percentOfBudget(String percent) {
    return '$percent% من الميزانية';
  }

  @override
  String get budgetingTitle => 'الميزانية';

  @override
  String get noBudgetPlanYet => 'لا خطة ميزانية بعد';

  @override
  String get budgetEmptyBody =>
      'قسّم دخلك بين الادخار والضروريات والكماليات، وتابع كيف تسير كل دورة مقارنة بالخطة.';

  @override
  String get createBudgetPlan => 'إنشاء خطة ميزانية';

  @override
  String get spendingByBucket => 'الإنفاق حسب البند';

  @override
  String get noSpendingSixMonths => 'لا إنفاق في الأشهر الستة الأخيرة بعد';

  @override
  String budgetPlanFor(String month) {
    return 'خطة ميزانية $month';
  }

  @override
  String get editBudgetPlan => 'تعديل خطة الميزانية';

  @override
  String get totalIncome => 'إجمالي الدخل';

  @override
  String get spentSoFar => 'المصروف حتى الآن';

  @override
  String get upcomingPayments => 'الدفعات القادمة';

  @override
  String get addABill => 'إضافة فاتورة';

  @override
  String get removeABill => 'حذف فاتورة';

  @override
  String billDeleteFailed(String error) {
    return 'تعذّر حذف الفاتورة: $error';
  }

  @override
  String get noUpcomingPayments => 'لا دفعات قادمة بعد. اضغط + لإضافة فاتورة.';

  @override
  String seeAllCount(String count) {
    return 'عرض الكل ($count)';
  }

  @override
  String get noDate => 'بلا تاريخ';

  @override
  String nextDate(String date) {
    return 'التالية: $date';
  }

  @override
  String fromAccount(String account) {
    return 'من $account';
  }

  @override
  String paymentsLeft(String count) {
    return 'متبقٍّ $count';
  }

  @override
  String get yourBudgetPlan => 'خطة ميزانيتك';

  @override
  String get totalMonthlyIncome => 'إجمالي الدخل الشهري';

  @override
  String planSaveFailed(String error) {
    return 'تعذّر حفظ الخطة: $error';
  }

  @override
  String get savePlan => 'حفظ الخطة';

  @override
  String get enterAmountToPlan => 'أدخل مبلغاً لتخطيطه.';

  @override
  String overBy(String amount) {
    return 'زيادة بمقدار $amount';
  }

  @override
  String get allPlanned => 'خُطّط المبلغ كله';

  @override
  String get amount => 'المبلغ';

  @override
  String get savingsGoalAdded => 'أُضيف هدف الادخار';

  @override
  String allocateToGoal(String goal) {
    return 'إضافة مبلغ إلى $goal';
  }

  @override
  String availableAmount(String amount) {
    return 'المتاح: $amount';
  }

  @override
  String inThisGoal(String amount) {
    return 'في هذا الهدف: $amount';
  }

  @override
  String stillNeeded(String amount) {
    return 'المتبقي لبلوغ الهدف: $amount';
  }

  @override
  String get amountToAllocate => 'المبلغ المراد إضافته';

  @override
  String get removeFromGoal => 'سحب من الهدف';

  @override
  String get allocate => 'إضافة';

  @override
  String get insufficientBalance => 'الرصيد المتاح غير كافٍ';

  @override
  String get goalFullyFunded => 'هذا الهدف مكتمل بالفعل';

  @override
  String allocatingCapped(String amount) {
    return 'سيُضاف $amount فقط (المبلغ المتبقي للهدف)';
  }

  @override
  String get deleteGoalTitle => 'حذف هذا الهدف؟';

  @override
  String get deleteGoalMessage =>
      'سيُحذف الهدف وما أنجزته فيه، ولا يمكن التراجع عن ذلك.';

  @override
  String get goalDeleted => 'حُذف هدف الادخار';

  @override
  String goalDeleteError(String error) {
    return 'تعذّر حذف الهدف: $error';
  }

  @override
  String removeFromGoalTitle(String goal) {
    return 'سحب من $goal';
  }

  @override
  String get amountToRemove => 'المبلغ المراد سحبه';

  @override
  String get removeAll => 'سحب الكل';

  @override
  String get amountExceedsAllocation => 'المبلغ أكبر مما في الهدف حالياً';

  @override
  String amountAllocated(String amount) {
    return 'أُضيف $amount إلى الهدف';
  }

  @override
  String amountRemovedFromGoal(String amount) {
    return 'سُحب $amount من الهدف';
  }

  @override
  String get noSavingsGoalsYet => 'لا أهداف ادخار بعد';

  @override
  String get savingsEmptyBody => 'أنشئ هدفاً وانقل إليه من مدخراتك أولاً بأول.';

  @override
  String get createSavingsGoal => 'إنشاء هدف ادخار';

  @override
  String get savingGoals => 'أهداف الادخار';

  @override
  String get newGoal => 'هدف جديد';

  @override
  String get removeAGoal => 'حذف هدف';

  @override
  String get totalSaved => 'إجمالي المدخرات';

  @override
  String get allocatedToGoals => 'المخصّص للأهداف';

  @override
  String get leftToAllocate => 'المتبقي للتخصيص';

  @override
  String get completed => 'مكتمل';

  @override
  String amountOfAmount(String current, String target) {
    return '$current من $target';
  }

  @override
  String perMonthByDate(String amount, String date) {
    return '$amount شهرياً · بحلول $date';
  }

  @override
  String perMonthFor(String amount, String duration) {
    return '$amount شهرياً · $duration';
  }

  @override
  String monthsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شهر',
      many: '$count شهراً',
      few: '$count أشهر',
      two: 'شهران',
      one: 'شهر واحد',
      zero: '0 شهر',
    );
    return '$_temp0';
  }

  @override
  String yearsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سنة',
      many: '$count سنة',
      few: '$count سنوات',
      two: 'سنتان',
      one: 'سنة واحدة',
      zero: '0 سنة',
    );
    return '$_temp0';
  }

  @override
  String yearsAndMonths(String years, String months) {
    return '$years و$months';
  }

  @override
  String get giveGoalName => 'اكتب اسماً للهدف.';

  @override
  String get enterSaveAmount => 'أدخل المبلغ الذي تريد ادخاره.';

  @override
  String get enterMonthsOrDate => 'أدخل عدد الأشهر أو اختر تاريخاً مستهدفاً.';

  @override
  String goalAddFailed(String error) {
    return 'تعذّرت إضافة الهدف: $error';
  }

  @override
  String get newSavingsGoal => 'هدف ادخار جديد';

  @override
  String get addGoal => 'إضافة الهدف';

  @override
  String get goalName => 'اسم الهدف';

  @override
  String get totalTargetAmount => 'المبلغ المستهدف';

  @override
  String get targetPerMonth => 'المبلغ الشهري';

  @override
  String get months => 'الأشهر';

  @override
  String get targetDate => 'التاريخ المستهدف';

  @override
  String get deleteBillTitle => 'حذف هذه الفاتورة؟';

  @override
  String willBeRemoved(String name) {
    return 'ستُحذف \"$name\".';
  }

  @override
  String billUpdateFailed(String error) {
    return 'تعذّر تحديث الفاتورة: $error';
  }

  @override
  String billSaveFailed(String error) {
    return 'تعذّر حفظ الفاتورة: $error';
  }

  @override
  String get billsTitle => 'الفواتير والاشتراكات';

  @override
  String get stillDueThisMonth => 'المتبقي هذا الشهر';

  @override
  String get perMo => 'شهرياً';

  @override
  String get noBillsYet => 'لا فواتير بعد';

  @override
  String get billsEmptyBody =>
      'أضف الإيجار والهاتف والاشتراكات وكل ما تدفعه شهرياً. وتظهر هنا أيضاً الأوامر الثابتة من بنكك.';

  @override
  String get bills => 'الفواتير';

  @override
  String get billsFootnote =>
      'فعّل المفتاح لتعليم الفاتورة كدفع تلقائي. أما الأوامر الثابتة فتُضبط من بنكك.';

  @override
  String get paid => 'مدفوعة';

  @override
  String wasDue(String date) {
    return 'كانت مستحقة في $date';
  }

  @override
  String get noDateSet => 'بلا تاريخ';

  @override
  String get dueToday => 'مستحقة اليوم';

  @override
  String get dueTomorrow => 'مستحقة غداً';

  @override
  String dueInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مستحقة بعد $count يوم',
      many: 'مستحقة بعد $count يوماً',
      few: 'مستحقة بعد $count أيام',
      two: 'مستحقة بعد يومين',
      one: 'مستحقة بعد يوم',
      zero: 'مستحقة اليوم',
    );
    return '$_temp0';
  }

  @override
  String get incoming => 'واردة';

  @override
  String get autopayLower => 'دفع تلقائي';

  @override
  String get editBill => 'تعديل الفاتورة';

  @override
  String get name => 'الاسم';

  @override
  String get billNameHint => 'الإيجار، الهاتف، Netflix...';

  @override
  String get dueEveryMonthOn => 'تُستحق شهرياً في';

  @override
  String dayN(int day) {
    return 'اليوم $day';
  }

  @override
  String get shorterMonthsNote =>
      'في الأشهر الأقصر تُستحق في آخر يوم من الشهر.';

  @override
  String get paidFrom => 'تُدفع من';

  @override
  String get notSet => 'غير محدد';

  @override
  String get subscription => 'اشتراك';

  @override
  String get subscriptionSubtitle => 'تُحسب ضمن اشتراكاتك الشهرية';

  @override
  String get autopay => 'دفع تلقائي';

  @override
  String get autopaySubtitle => 'تُخصم تلقائياً';

  @override
  String get addBill => 'إضافة الفاتورة';

  @override
  String get deleteBill => 'حذف الفاتورة';

  @override
  String get billFallback => 'فاتورة';

  @override
  String get scheduledPayment => 'دفعة مجدولة';

  @override
  String accountFallback(String id) {
    return 'حساب $id';
  }

  @override
  String hhInviteShare(String name, String link) {
    return 'انضم إلى منزلي المشترك \"$name\" على Vesta! اضغط هنا: $link';
  }

  @override
  String get hhInviteSubject => 'دعوة للانضمام إلى منزلي المشترك';

  @override
  String get aHousehold => 'منزل مشترك';

  @override
  String inviteCreateError(String error) {
    return 'تعذّر إنشاء الدعوة: $error';
  }

  @override
  String get member => 'عضو';

  @override
  String get manage => 'إدارة';

  @override
  String get household => 'المنزل المشترك';

  @override
  String get noLongerInHousehold => 'لم تعد عضواً في هذا المنزل المشترك';

  @override
  String get noLongerInHouseholdBody => 'إما أنه حُذف أو أن مالكه أزالك منه.';

  @override
  String get backToShared => 'العودة إلى المالية المشتركة';

  @override
  String nameAdmin(String name) {
    return '$name (المشرف)';
  }

  @override
  String nameYou(String name) {
    return '$name (أنت)';
  }

  @override
  String get noHouseholdBudget => 'لا ميزانية للمنزل المشترك بعد';

  @override
  String get good => 'جيد';

  @override
  String get overTag => 'تجاوز';

  @override
  String get overall => 'الإجمالي';

  @override
  String get atRisk => 'في خطر';

  @override
  String get financialHealth => 'الصحة المالية';

  @override
  String get noSharedSpendingSixMonths =>
      'لا مصاريف مشتركة في الأشهر الستة الأخيرة بعد';

  @override
  String get householdBudgetPlan => 'خطة ميزانية المنزل المشترك';

  @override
  String get totalMonthlyBudget => 'إجمالي الميزانية الشهرية';

  @override
  String get totalBudget => 'إجمالي الميزانية';

  @override
  String get noBudgetTapPencil =>
      'لم تُحدَّد ميزانية بعد. اضغط على القلم لتخطيطها.';

  @override
  String overThisCycleSplit(String amount) {
    return 'تجاوزت الميزانية بـ $amount في هذه الدورة. اضغط على القلم لتقسيمها إلى بنود.';
  }

  @override
  String leftThisCycleSplit(String amount) {
    return 'متبقٍّ $amount في هذه الدورة. اضغط على القلم لتقسيم الميزانية إلى بنود.';
  }

  @override
  String householdBudgetLoadError(String error) {
    return 'تعذّر تحميل ميزانية المنزل المشترك: $error';
  }

  @override
  String get noSharedCategorized =>
      'لا مصاريف مصنّفة بعد.\nأضف فئات للمعاملات المشتركة لتظهر هنا.';

  @override
  String transactionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count معاملة',
      many: '$count معاملة',
      few: '$count معاملات',
      two: 'معاملتان',
      one: 'معاملة واحدة',
      zero: 'لا معاملات',
    );
    return '$_temp0';
  }

  @override
  String get noSharedTransactions =>
      'لا معاملات مشتركة بعد.\nأضف معاملة من صفحة تفاصيلها.';

  @override
  String get noHouseholdsYet => 'لا منازل مشتركة بعد';

  @override
  String get householdsEmptyBody =>
      'أنشئ منزلاً مشتركاً لتدير ميزانية مع من تعيش معهم.';

  @override
  String get createHousehold => 'إنشاء منزل مشترك';

  @override
  String get sharedHouseholds => 'المنازل المشتركة';

  @override
  String get newHousehold => 'منزل مشترك جديد';

  @override
  String get leaveOrDeleteHousehold => 'مغادرة منزل مشترك أو حذفه';

  @override
  String get thisHousehold => 'هذا المنزل المشترك';

  @override
  String get unnamedHousehold => 'منزل بلا اسم';

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عضو',
      many: '$count عضواً',
      few: '$count أعضاء',
      two: 'عضوان',
      one: 'عضو واحد',
      zero: 'لا أعضاء',
    );
    return '$_temp0';
  }

  @override
  String get noBudgetOpenToSet => 'لا ميزانية بعد. افتحه لتحديدها.';

  @override
  String get noBudgetSetYet => 'لم تُحدَّد ميزانية بعد';

  @override
  String get logInToSeeHouseholds => 'سجّل الدخول لرؤية منازلك المشتركة.';

  @override
  String get userDataNotFound => 'لم نجد بيانات المستخدم.';

  @override
  String get joiningHousehold => 'جارٍ الانضمام إلى المنزل المشترك...';

  @override
  String get inviteDeclined => 'رُفضت الدعوة';

  @override
  String inviteAnswerFailed(String error) {
    return 'تعذّر الرد على الدعوة: $error';
  }

  @override
  String invitedYouToJoin(String inviter, String household) {
    return 'دعاك $inviter للانضمام إلى $household.';
  }

  @override
  String get someone => 'شخص ما';

  @override
  String get decline => 'رفض';

  @override
  String get accept => 'قبول';

  @override
  String get deleteHouseholdMessage =>
      'سيُحذف المنزل المشترك وميزانيته لجميع الأعضاء، ولا يمكن التراجع عن ذلك.';

  @override
  String householdDeleteFailed(String error) {
    return 'تعذّر حذف المنزل المشترك: $error';
  }

  @override
  String leaveNameTitle(String name) {
    return 'مغادرة $name؟';
  }

  @override
  String get leaveHouseholdMessage =>
      'لن ترى ميزانيته ومعاملاته بعد الآن، ويمكن لمالكه دعوتك مجدداً.';

  @override
  String get leave => 'مغادرة';

  @override
  String householdLeaveFailed(String error) {
    return 'تعذّرت مغادرة المنزل المشترك: $error';
  }

  @override
  String removeNameTitle(String name) {
    return 'إزالة $name؟';
  }

  @override
  String get removeMemberMessage =>
      'سيفقد الوصول إلى هذا المنزل المشترك، ويمكنك دعوته مجدداً لاحقاً.';

  @override
  String get removeMember => 'إزالة';

  @override
  String memberRemoveFailed(String name, String error) {
    return 'تعذّرت إزالة $name: $error';
  }

  @override
  String get logInToInvite => 'سجّل الدخول مجدداً لتتمكن من الدعوة.';

  @override
  String get enterUsernameOrEmail => 'أدخل اسم مستخدم أو بريداً إلكترونياً.';

  @override
  String noUserGoesBy(String query) {
    return 'لا يوجد مستخدم في Vesta باسم \"$query\".';
  }

  @override
  String get thatsYou => 'هذا أنت.';

  @override
  String get alreadyInHousehold =>
      'هذا الشخص عضو في هذا المنزل المشترك بالفعل.';

  @override
  String get giveHouseholdName => 'اكتب اسماً للمنزل المشترك.';

  @override
  String householdCreateFailed(String error) {
    return 'تعذّر إنشاء المنزل المشترك: $error';
  }

  @override
  String get create => 'إنشاء';

  @override
  String get householdName => 'اسم المنزل المشترك';

  @override
  String saveFailed(String error) {
    return 'تعذّر الحفظ: $error';
  }

  @override
  String inviteSentTo(String name) {
    return 'أُرسلت الدعوة إلى $name، ويمكنه قبولها من المالية المشتركة.';
  }

  @override
  String inviteSendFailed(String error) {
    return 'تعذّر إرسال الدعوة: $error';
  }

  @override
  String get editHousehold => 'تعديل المنزل المشترك';

  @override
  String get members => 'الأعضاء';

  @override
  String get youParen => '(أنت)';

  @override
  String get admin => 'المشرف';

  @override
  String get invite => 'دعوة';

  @override
  String get shareInviteLink => 'مشاركة رابط الدعوة';

  @override
  String get youAreAdmin =>
      'أنت المشرف لأنك أنشأت هذا المنزل المشترك. وحده المشرف يمكنه إضافة الأعضاء أو إزالتهم.';

  @override
  String onlyAdminNamed(String name) {
    return 'وحده المشرف ($name) يمكنه إضافة الأعضاء أو إزالتهم.';
  }

  @override
  String get onlyAdmin => 'وحده المشرف يمكنه إضافة الأعضاء أو إزالتهم.';

  @override
  String get deleteHousehold => 'حذف المنزل المشترك';

  @override
  String willBeRemovedForEveryone(String name) {
    return 'ستُحذف \"$name\" لدى الجميع.';
  }

  @override
  String get addSharedBill => 'إضافة فاتورة مشتركة';

  @override
  String get noSharedBills =>
      'لا فواتير مشتركة بعد. أضف الإيجار أو الخدمات أو الاشتراكات التي تتقاسمونها.';

  @override
  String get whenToday => 'اليوم';

  @override
  String get whenTomorrow => 'غداً';

  @override
  String whenInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بعد $count يوم',
      many: 'بعد $count يوماً',
      few: 'بعد $count أيام',
      two: 'بعد يومين',
      one: 'بعد يوم',
      zero: 'اليوم',
    );
    return '$_temp0';
  }

  @override
  String billDueLine(String date, String when) {
    return 'تُستحق $date · $when · شهرياً';
  }

  @override
  String get giveBillName => 'اكتب اسماً للفاتورة.';

  @override
  String get enterTheAmount => 'أدخل المبلغ.';

  @override
  String get pickDueDay => 'اختر يوم استحقاق من 1 إلى 31.';

  @override
  String sharesDontAddUp(String total, String amount) {
    return 'مجموع الحصص $total وليس $amount.';
  }

  @override
  String get newSharedBill => 'فاتورة مشتركة جديدة';

  @override
  String get egRent => 'مثل: الإيجار';

  @override
  String get dueDay => 'يوم الاستحقاق';

  @override
  String get splitEvenly => 'تقسيم بالتساوي';

  @override
  String amountEach(String amount) {
    return '$amount لكل عضو';
  }

  @override
  String get setEachPays => 'أو حدّد ما يدفعه كل عضو';

  @override
  String somethingWentWrong(String error) {
    return 'حدث خطأ: $error';
  }

  @override
  String get sharedGoalAdded => 'أُضيف الهدف المشترك';

  @override
  String get deleteSharedGoalMessage =>
      'سيُحذف لدى الجميع، وتعود مساهمات الأعضاء إلى حصصهم الحرة.';

  @override
  String get sharedByMembers => 'حصص الأعضاء';

  @override
  String get allocatedShared => 'المخصّص / المشارَك';

  @override
  String get setHowMuchYouShare => 'حدّد ما تشاركه';

  @override
  String get setMonthlyPlanHint =>
      'حدّد ما تنوي إضافته كل شهر لمتابعة ادخار المنزل المشترك الشهري.';

  @override
  String monthSavingsGoal(String month, String amount) {
    return 'هدف ادخار $month: $amount';
  }

  @override
  String get reached => 'تحقّق';

  @override
  String get notYet => 'ليس بعد';

  @override
  String savedThisMonth(String amount) {
    return 'ادّخرتم $amount هذا الشهر.';
  }

  @override
  String savedSoFarToGo(String saved, String toGo, String days) {
    return 'ادّخرتم $saved حتى الآن، وبقي $toGo والمتبقي من الشهر $days.';
  }

  @override
  String plansPerMonth(String amount) {
    return 'يخطط لـ $amount شهرياً';
  }

  @override
  String get noMonthlyPlan => 'لا خطة شهرية بعد';

  @override
  String amountFree(String amount) {
    return 'متاح $amount';
  }

  @override
  String get newSharedGoal => 'هدف مشترك جديد';

  @override
  String get noSharedGoals =>
      'لا أهداف مشتركة بعد. أضف هدفاً لتدّخروا له معاً.';

  @override
  String byDate(String date) {
    return 'بحلول $date';
  }

  @override
  String shareAtLeast(String amount) {
    return 'وضعت $amount في الأهداف، فشارك هذا المبلغ على الأقل.';
  }

  @override
  String get yourSavingsShare => 'حصتك من الادخار';

  @override
  String get savingsShareMessage =>
      'كم تشارك من مدخراتك مع المنزل المشترك، وما تنوي إضافته كل شهر. يرى جميع الأعضاء هذه الأرقام.';

  @override
  String get amountYouShare => 'المبلغ الذي تشاركه';

  @override
  String get planToAddMonthly => 'ما تنوي إضافته شهرياً';

  @override
  String get enterAnAmount => 'أدخل مبلغاً.';

  @override
  String youHaveInGoal(String amount) {
    return 'لديك $amount في هذا الهدف.';
  }

  @override
  String freeShareIs(String amount) {
    return 'حصتك الحرة $amount. شارك المزيد أولاً من \"حدّد ما تشاركه\".';
  }

  @override
  String get takeOut => 'سحب';

  @override
  String savedOfTarget(String saved, String target) {
    return 'ادُّخر $saved من $target';
  }

  @override
  String fromYouFreeShare(String mine, String free) {
    return 'منك: $mine · حصتك الحرة: $free';
  }

  @override
  String get amountToTakeOut => 'المبلغ المراد سحبه';

  @override
  String get amountToAdd => 'المبلغ المراد إضافته';

  @override
  String emailLinkSent(String email) {
    return 'أرسلنا رابطاً إلى $email. سيتغيّر بريدك بعد فتحه.';
  }

  @override
  String get emailTakenByOther => 'هذا البريد مرتبط بحساب آخر في Vesta.';

  @override
  String get notAdded => 'غير مضاف';

  @override
  String get changeNumberSupport => 'لتغيير رقمك، تواصل مع الدعم.';

  @override
  String get userId => 'معرّف المستخدم';

  @override
  String get userIdCopied => 'نُسخ معرّف المستخدم';

  @override
  String get copy => 'نسخ';

  @override
  String get userIdFixed => 'يُمنح لك معرّف المستخدم ولا يمكن تغييره.';

  @override
  String get deleteVestaAccount => 'حذف حساب Vesta';

  @override
  String get profilePicture => 'الصورة الشخصية';

  @override
  String get chooseFromGallery => 'اختيار من المعرض';

  @override
  String get takeAPhoto => 'التقاط صورة';

  @override
  String imageUploadFailed(String error) {
    return 'تعذّر رفع الصورة: $error';
  }

  @override
  String get passwordWrong => 'كلمة المرور غير صحيحة.';

  @override
  String get tooManyTries => 'محاولات كثيرة. انتظر قليلاً ثم حاول مجدداً.';

  @override
  String somethingWentWrongCode(String code) {
    return 'حدث خطأ ($code).';
  }

  @override
  String get confirmItsYou => 'تأكيد هويتك';

  @override
  String get enterPasswordToContinue => 'أدخل كلمة مرور Vesta للمتابعة.';

  @override
  String get fingerprintReason => 'تحقّق من هويتك لتفعيل الفتح بالبصمة';

  @override
  String get fingerprintFailed => 'تعذّر التحقق من بصمتك';

  @override
  String get changeOrResetPassword => 'غيّر كلمة المرور أو أعد تعيينها';

  @override
  String get fingerprintUnlock => 'الفتح بالبصمة';

  @override
  String get notAvailableOnPhone => 'غير متاح على هذا الهاتف';

  @override
  String get unlockWithBiometrics => 'افتح Vesta ببصمة الإصبع أو الوجه';

  @override
  String get unlockQuickly => 'افتح بسرعة بدل كتابة كلمة المرور';

  @override
  String get dataConsent => 'الموافقة على البيانات';

  @override
  String get dataConsentSubtitle => 'ما نقرؤه من حساباتك البنكية';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get passwordRule =>
      'استخدم 6 أحرف أو أكثر، منها حرف إنجليزي كبير وحرف صغير ورقم.';

  @override
  String get enterCurrentPassword => 'أدخل كلمة المرور الحالية.';

  @override
  String get newPasswordsDontMatch => 'كلمتا المرور الجديدتان غير متطابقتين.';

  @override
  String get pickDifferentPassword => 'اختر كلمة مرور مختلفة عن الحالية.';

  @override
  String get passwordUpdated => 'تم تحديث كلمة المرور';

  @override
  String get currentPasswordWrong => 'كلمة المرور الحالية غير صحيحة.';

  @override
  String get passwordTooWeak => 'كلمة المرور هذه ضعيفة جداً.';

  @override
  String resetLinkSent(String email) {
    return 'أرسلنا رابط إعادة التعيين إلى $email.';
  }

  @override
  String linkSendFailed(String code) {
    return 'تعذّر إرسال الرابط ($code).';
  }

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get passwordHint =>
      '6 أحرف على الأقل، منها حرف إنجليزي كبير وحرف صغير ورقم.';

  @override
  String get updatePassword => 'تحديث كلمة المرور';

  @override
  String get forgotMyPassword => 'نسيت كلمة المرور';

  @override
  String get twoFactor => 'التحقق بخطوتين';

  @override
  String get twoFactorSoon => 'قريباً: رمز برسالة نصية عند تسجيل الدخول';

  @override
  String get planFree => 'المجانية';

  @override
  String get planFeatCore => 'الميزانية والمصاريف والمدخرات';

  @override
  String get planFeat2Banks => 'حتى حسابين بنكيين مربوطين';

  @override
  String get planFeatHealth => 'تقييم شهري لصحتك المالية';

  @override
  String get planFeatAllFree => 'كل ما في الباقة المجانية';

  @override
  String get planFeatUnlimitedBanks => 'حسابات بنكية بلا حدود';

  @override
  String get planFeatShared1 => 'مالية مشتركة لمنزل واحد وحتى 3 أهداف مشتركة';

  @override
  String get planFeatReminders => 'تذكيرات وتنبيهات ذكية';

  @override
  String get planFeatAllPlus => 'كل ما في باقة Plus';

  @override
  String get planFeatShared3 => 'حتى 3 منازل مشتركة بأهداف مشتركة بلا حدود';

  @override
  String get planFeatInsights => 'تحليلات متقدمة وتصدير البيانات';

  @override
  String get planFeatPriority => 'أولوية في خدمة العملاء';

  @override
  String get paidPlansSoon => 'الباقات المدفوعة قادمة قريباً';

  @override
  String get paidPlansSoonBody =>
      'ستتمكن من الاشتراك من هنا عند إطلاقها. حتى ذلك الحين، كل ما في Vesta مجاني.';

  @override
  String get noSubscription => 'ليس لديك اشتراك';

  @override
  String get onFreePlan =>
      'أنت على الباقة المجانية. اختر باقة لتحصل على المزيد.';

  @override
  String get aMonth => 'شهرياً';

  @override
  String getPlan(String plan) {
    return 'اشترك في $plan';
  }

  @override
  String get howReferralsWork => 'كيف تعمل الدعوات';

  @override
  String referralsHowBody(String reward, String welcome) {
    return 'شارك رمزك. عندما يُدخله صديقك أثناء التسجيل تحصل على $reward نقطة ويحصل هو على $welcome. 1,000 نقطة تمنحك شهراً مجانياً من Plus، و1,500 نقطة شهراً مجانياً من Premium.';
  }

  @override
  String get gotIt => 'فهمت';

  @override
  String get enoughPremium => 'تكفي لشهر مجاني من Premium';

  @override
  String enoughPlusMore(String points) {
    return 'تكفي لشهر مجاني من Plus · $points نقطة أخرى لـ Premium';
  }

  @override
  String moreForPlus(String points) {
    return '$points نقطة أخرى لشهر مجاني من Plus';
  }

  @override
  String get yourPoints => 'نقاطك';

  @override
  String pointsShort(String points) {
    return '$points نقطة';
  }

  @override
  String get howItWorks => 'كيف تعمل';

  @override
  String get usePoints => 'استخدام النقاط';

  @override
  String get yourReferralCode => 'رمز دعوتك';

  @override
  String get copyCode => 'نسخ الرمز';

  @override
  String get codeCopied => 'نُسخ الرمز';

  @override
  String get copyLink => 'نسخ الرابط';

  @override
  String get linkCopied => 'نُسخ الرابط';

  @override
  String get share => 'مشاركة';

  @override
  String referralShareText(String code, String link) {
    return 'أستخدم Vesta لتخطيط أموالي. انضم برمزي $code: $link';
  }

  @override
  String get peopleInvited => 'الأشخاص الذين دعوتهم';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شخص',
      many: '$count شخصاً',
      few: '$count أشخاص',
      two: 'شخصان',
      one: 'شخص واحد',
      zero: 'لا أحد',
    );
    return '$_temp0';
  }

  @override
  String get noOneInvitedYet =>
      'لا أحد بعد. شارك رمزك، وسيظهر هنا الأصدقاء الذين ينضمون.';

  @override
  String get friend => 'صديق';

  @override
  String joinedOn(String date) {
    return 'انضم في $date';
  }

  @override
  String get reasonNotEnough => 'لا أستخدمه بما يكفي';

  @override
  String get reasonPrivacy => 'لدي مخاوف تتعلق بالخصوصية';

  @override
  String get reasonMissingFeatures => 'تنقصه ميزات أحتاجها';

  @override
  String get reasonSwitching => 'سأنتقل إلى تطبيق آخر';

  @override
  String get reasonExpensive => 'مكلف جداً';

  @override
  String get reasonTechnical => 'أواجه مشاكل تقنية';

  @override
  String get pickReason => 'اختر سبباً واحداً على الأقل.';

  @override
  String get deleteVestaAccountTitle => 'حذف حسابك في Vesta؟';

  @override
  String get deleteVestaAccountMessage =>
      'سيُحذف كل ما فيه نهائياً، ولا يمكن التراجع عن ذلك.';

  @override
  String vestaAccountDeleteFailed(String error) {
    return 'تعذّر حذف الحساب: $error';
  }

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get whyDelete => 'لماذا تريد حذف حسابك؟';

  @override
  String get tellUsMore => 'أخبرنا بالمزيد (اختياري)';

  @override
  String get deleteWarning =>
      'إذا حذفت حسابك فستُحذف جميع معلوماتك: ميزانياتك ومعاملاتك وأهداف ادخارك وحساباتك ومالياتك المشتركة.';

  @override
  String get iconSecFood => 'الطعام والشراب';

  @override
  String get iconSecHome => 'المنزل والفواتير';

  @override
  String get iconSecTransport => 'المواصلات والسفر';

  @override
  String get iconSecLifestyle => 'أسلوب الحياة';

  @override
  String get iconSecPeople => 'أشخاص وغير ذلك';

  @override
  String get chooseAnIcon => 'اختر أيقونة';

  @override
  String get pasteBankSmsAnyLanguage =>
      'الصق رسالة البنك، بالعربية أو الإنجليزية';

  @override
  String get smsPrivacyNote =>
      'يقرأ Vesta الرسالة على هاتفك، ولا يستعين بـGemini من Google إلا عند الحاجة. راجع التفاصيل قبل الحفظ؛ نحتفظ بالتفاصيل فقط، ولا نحتفظ بالرسالة أبداً.';

  @override
  String smsFilledConvert(String from, String to) {
    return 'عبّأناها من رسالتك. المبلغ بعملة $from، فحوّله إلى $to قبل الحفظ.';
  }

  @override
  String get smsCouldntRead =>
      'تعذّرت قراءة الرسالة. تحقق من اتصالك، أو جرّب الإدخال اليدوي.';

  @override
  String get smsMaybeDeclined =>
      'قد تكون هذه دفعة مرفوضة أو فاشلة. إن تمّت فعلاً، أضفها يدوياً.';

  @override
  String get smsOneTimeCode => 'تبدو هذه رمز تحقق لمرة واحدة، لا دفعة.';

  @override
  String get smsNotAPayment =>
      'هذه الرسالة ليست دفعة ولا تحويلاً. جرّب الإدخال اليدوي.';
}
