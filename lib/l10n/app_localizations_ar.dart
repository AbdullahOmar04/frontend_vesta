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
}
