// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'نظام إدارة العقارات';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get signIn => 'دخول';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get leads => 'العملاء المحتملون';

  @override
  String get properties => 'العقارات';

  @override
  String get clients => 'العملاء';

  @override
  String get tasks => 'المهام';

  @override
  String get deals => 'الصفقات';

  @override
  String get reports => 'التقارير';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'الإنجليزية';

  @override
  String get salesWorkspace => 'مساحة عمل المبيعات';

  @override
  String get searchCrm => 'البحث في النظام';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get crmUser => 'مستخدم النظام';

  @override
  String get workspace => 'مساحة العمل';

  @override
  String get crmOverview => 'نظرة عامة على النظام';

  @override
  String get dashboardPlaceholderDescription =>
      'ستظهر هنا بيانات المبيعات والعملاء المحتملين والمتابعات ونشاط العقارات.';

  @override
  String get totalLeads => 'إجمالي العملاء المحتملين';

  @override
  String get followUpsDue => 'المتابعات المستحقة';

  @override
  String get openDeals => 'الصفقات المفتوحة';

  @override
  String get availableProperties => 'العقارات المتاحة';

  @override
  String get authScreenPlaceholder => 'شاشة تسجيل دخول مؤقتة';

  @override
  String get openDashboard => 'فتح لوحة التحكم';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get loginSubtitle =>
      'سجل الدخول للمتابعة إلى مساحة عمل إدارة العقارات.';

  @override
  String get emailRequired => 'البريد الإلكتروني مطلوب.';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة.';

  @override
  String get invalidEmail => 'أدخل بريداً إلكترونياً صحيحاً.';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get signingIn => 'جاري تسجيل الدخول...';

  @override
  String get authErrorInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get authErrorConnection =>
      'حدث خطأ في الاتصال. تحقق من اتصالك بالإنترنت.';

  @override
  String get authErrorSignInFailed => 'تعذر تسجيل الدخول. حاول مرة أخرى.';

  @override
  String get authErrorSignOutFailed => 'تعذر تسجيل الخروج. حاول مرة أخرى.';

  @override
  String get authErrorProfileMissing => 'تعذر تحميل ملف المستخدم الخاص بك.';

  @override
  String get authErrorInactiveAccount =>
      'حسابك غير مفعل. يرجى التواصل مع مسؤول النظام.';

  @override
  String get logoutTooltip => 'تسجيل الخروج';

  @override
  String get createLead => 'إضافة عميل محتمل';

  @override
  String get leadDetails => 'تفاصيل العميل المحتمل';

  @override
  String get leadName => 'اسم العميل المحتمل';

  @override
  String get phone => 'الهاتف';

  @override
  String get source => 'المصدر';

  @override
  String get status => 'الحالة';

  @override
  String get priority => 'الأولوية';

  @override
  String get budgetMin => 'الحد الأدنى للميزانية';

  @override
  String get budgetMax => 'الحد الأقصى للميزانية';

  @override
  String get preferredLocation => 'الموقع المفضل';

  @override
  String get preferredPropertyType => 'نوع العقار المفضل';

  @override
  String get assignedTo => 'مسند إلى';

  @override
  String get notes => 'ملاحظات';

  @override
  String get saveLead => 'حفظ العميل المحتمل';

  @override
  String get leadCreated => 'تم إنشاء العميل المحتمل بنجاح.';

  @override
  String get noLeads => 'لا توجد عملاء محتملون بعد.';

  @override
  String get unableToLoadLeads =>
      'تعذر تحميل العملاء المحتملين. حاول مرة أخرى.';

  @override
  String get unableToCreateLead => 'تعذر إنشاء العميل المحتمل. حاول مرة أخرى.';

  @override
  String get requiredField => 'هذا الحقل مطلوب.';

  @override
  String get notAvailable => 'غير متوفر';

  @override
  String get newLead => 'جديد';

  @override
  String get contacted => 'تم التواصل';

  @override
  String get interested => 'مهتم';

  @override
  String get visitScheduled => 'تم تحديد زيارة';

  @override
  String get negotiation => 'تفاوض';

  @override
  String get won => 'تم الفوز';

  @override
  String get lost => 'مفقود';

  @override
  String get low => 'منخفضة';

  @override
  String get medium => 'متوسطة';

  @override
  String get high => 'عالية';

  @override
  String get facebook => 'فيسبوك';

  @override
  String get website => 'الموقع الإلكتروني';

  @override
  String get phoneCall => 'مكالمة هاتفية';

  @override
  String get whatsapp => 'واتساب';

  @override
  String get referral => 'ترشيح';

  @override
  String get walkIn => 'زيارة مباشرة';

  @override
  String get other => 'أخرى';

  @override
  String get leadsSubtitle =>
      'تابع الاستفسارات الجديدة وتواصل مع العملاء المحتملين.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get back => 'رجوع';

  @override
  String get archive => 'أرشفة';

  @override
  String get archiveLead => 'أرشفة العميل المحتمل';

  @override
  String get archiveLeadConfirmation =>
      'سيتم أرشفة هذا العميل المحتمل وإخفاؤه من قائمة العملاء النشطين.';

  @override
  String get leadArchived => 'تمت أرشفة العميل المحتمل بنجاح.';

  @override
  String get unableToArchiveLead =>
      'تعذرت أرشفة العميل المحتمل. حاول مرة أخرى.';

  @override
  String get permissionDenied => 'ليس لديك صلاحية لتنفيذ هذا الإجراء.';

  @override
  String get contactInformation => 'بيانات التواصل';

  @override
  String get leadPreferences => 'تفضيلات العميل المحتمل';

  @override
  String get leadAssignment => 'الإسناد والملاحظات';

  @override
  String get missingCompanyProfile =>
      'تعذر تحميل ملف الشركة. يرجى تسجيل الدخول مرة أخرى.';
}
