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
}
