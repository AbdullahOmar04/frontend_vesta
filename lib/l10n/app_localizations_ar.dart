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
}
