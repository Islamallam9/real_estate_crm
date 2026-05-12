// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'مسار';

  @override
  String get loginBrandName => 'Masar | مسار';

  @override
  String get websiteTitle => 'مسار | نظام ادارة مبيعات العقارات';

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
  String get loggedOutSuccessfully => 'تم تسجيل الخروج بنجاح.';

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
  String get tasksSubtitle =>
      'نظم المتابعات ومهام الفريق حسب تاريخ الاستحقاق والحالة والأولوية.';

  @override
  String get createTask => 'إنشاء مهمة';

  @override
  String get editTask => 'تعديل المهمة';

  @override
  String get updateTask => 'تحديث المهمة';

  @override
  String get searchReports => 'ابحث في التقارير';

  @override
  String get taskCreatedSuccessfully => 'تم إنشاء المهمة بنجاح.';

  @override
  String get taskUpdatedSuccessfully => 'تم تحديث المهمة بنجاح.';

  @override
  String get taskCompletedSuccessfully => 'تم وضع علامة مكتملة على المهمة.';

  @override
  String get taskCancelledSuccessfully => 'تم إلغاء المهمة بنجاح.';

  @override
  String get markTaskCompleted => 'وضع علامة مكتملة';

  @override
  String get cancelTask => 'إلغاء المهمة';

  @override
  String get cancelTaskConfirmation =>
      'سيتم وضع علامة ملغاة على هذه المهمة وستبقى ظاهرة في قوائم المهام.';

  @override
  String get taskNotFound =>
      'لم يتم العثور على المهمة. افتحها من قائمة المهام.';

  @override
  String get taskInformation => 'بيانات المهمة';

  @override
  String get taskTitle => 'عنوان المهمة';

  @override
  String get relatedType => 'نوع السجل المرتبط';

  @override
  String get relatedRecordId => 'معرف السجل المرتبط';

  @override
  String get relatedRecord => 'السجل المرتبط';

  @override
  String get selectRelatedRecord => 'اختر السجل المرتبط';

  @override
  String get relatedRecordRequired => 'اختر سجلا مرتبطا.';

  @override
  String get relatedRecordUnavailable => 'السجل المرتبط غير متوفر';

  @override
  String get noLeadsFound => 'لا توجد عملاء محتملون.';

  @override
  String get noPropertiesFound => 'لا توجد عقارات.';

  @override
  String get scheduleAndPriority => 'الموعد والأولوية';

  @override
  String get selectDueDate => 'اختر تاريخ الاستحقاق';

  @override
  String get dueDate => 'تاريخ الاستحقاق';

  @override
  String get dueDateRequired => 'تاريخ الاستحقاق مطلوب.';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get inProgress => 'قيد التنفيذ';

  @override
  String get completed => 'مكتملة';

  @override
  String get cancelled => 'ملغاة';

  @override
  String get allPriorities => 'كل الأولويات';

  @override
  String get noTasksYet => 'لم يتم إنشاء مهام بعد.';

  @override
  String get noTasksMatchFilters => 'لا توجد مهام تطابق عوامل التصفية الحالية.';

  @override
  String get lead => 'عميل محتمل';

  @override
  String get client => 'عميل';

  @override
  String get property => 'عقار';

  @override
  String get deal => 'صفقة';

  @override
  String get general => 'عام';

  @override
  String get deals => 'الصفقات';

  @override
  String get reports => 'التقارير';

  @override
  String get settings => 'الإعدادات';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get lightMode => 'الوضع الفاتح';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'الإنجليزية';

  @override
  String get salesWorkspace => 'من العميل المحتمل إلى الصفقة، مسار واضح واحد.';

  @override
  String get searchCrm => 'البحث في مسار CRM';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get crmUser => 'مستخدم مسار';

  @override
  String get workspace => 'مساحة العمل';

  @override
  String get crmOverview => 'نظرة عامة على مسار CRM';

  @override
  String get dashboardPlaceholderDescription =>
      'ستظهر هنا بيانات المبيعات والعملاء المحتملين والمتابعات ونشاط العقارات.';

  @override
  String get totalLeads => 'إجمالي العملاء المحتملين';

  @override
  String get newLeads => 'العملاء الجدد';

  @override
  String get activeLeads => 'العملاء النشطون / تم التواصل';

  @override
  String get unassignedLeads => 'عملاء غير مسندين';

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
  String get loginSubtitle => 'من العميل المحتمل إلى الصفقة، مسار واضح واحد.';

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
  String get quickAdd => 'إضافة سريعة';

  @override
  String get addLead => 'إضافة عميل محتمل';

  @override
  String get addClient => 'إضافة عميل';

  @override
  String get savedSuccessfully => 'تم الحفظ بنجاح.';

  @override
  String get updatedSuccessfully => 'تم التحديث بنجاح.';

  @override
  String get unableToSave => 'تعذر الحفظ. حاول مرة أخرى.';

  @override
  String get unableToAssignClient => 'تعذر تعيين العميل. حاول مرة أخرى.';

  @override
  String get unableToUpdateTask => 'تعذر تحديث المهمة. حاول مرة أخرى.';

  @override
  String get actionCompletedSuccessfully => 'تم تنفيذ الإجراء بنجاح.';

  @override
  String get actionFailed => 'تعذر تنفيذ الإجراء. حاول مرة أخرى.';

  @override
  String get createClient => 'إضافة عميل';

  @override
  String get editClient => 'تعديل العميل';

  @override
  String get updateClient => 'تحديث العميل';

  @override
  String get clientDetails => 'تفاصيل العميل';

  @override
  String get clientCreatedSuccessfully => 'تم إنشاء العميل بنجاح.';

  @override
  String get clientUpdatedSuccessfully => 'تم تحديث العميل بنجاح.';

  @override
  String get assignClient => 'تعيين العميل';

  @override
  String get clientAssignedSuccessfully => 'تم تعيين العميل بنجاح.';

  @override
  String get noClientsFound => 'لم يتم العثور على عملاء.';

  @override
  String get noAssignedClientsFound => 'لم يتم العثور على عملاء معينين.';

  @override
  String get archiveClient => 'أرشفة العميل';

  @override
  String get archiveClientConfirmation =>
      'سيتم أرشفة هذا العميل وإخفاؤه من قائمة العملاء النشطين.';

  @override
  String get clientArchivedSuccessfully => 'تمت أرشفة العميل بنجاح.';

  @override
  String get clientNotFoundMessage =>
      'العميل غير موجود. افتحه من قائمة العملاء.';

  @override
  String get backToClients => 'العودة إلى العملاء';

  @override
  String get clientPreferences => 'تفضيلات العميل';

  @override
  String get budgetMaxMustBeGreaterThanBudgetMin =>
      'لا يمكن أن يكون الحد الأقصى للميزانية أقل من الحد الأدنى.';

  @override
  String get createProperty => 'إضافة عقار';

  @override
  String get editProperty => 'تعديل العقار';

  @override
  String get updateProperty => 'حفظ التعديلات';

  @override
  String get leadDetails => 'تفاصيل العميل المحتمل';

  @override
  String get leadName => 'اسم العميل المحتمل';

  @override
  String get phone => 'الهاتف';

  @override
  String get source => 'المصدر';

  @override
  String get sourceDetails => 'تفاصيل المصدر';

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
  String get propertiesSubtitle =>
      'إدارة قوائم العقارات وحالتها في عرض عملي واحد.';

  @override
  String get noProperties => 'لا توجد عقارات بعد.';

  @override
  String get unableToLoadProperties => 'تعذر تحميل العقارات. حاول مرة أخرى.';

  @override
  String get propertyTitle => 'العنوان';

  @override
  String get propertyType => 'نوع العقار';

  @override
  String get listingType => 'نوع الإعلان';

  @override
  String get price => 'السعر';

  @override
  String get area => 'المساحة';

  @override
  String get location => 'الموقع';

  @override
  String get apartment => 'شقة';

  @override
  String get villa => 'فيلا';

  @override
  String get office => 'مكتب';

  @override
  String get shop => 'محل';

  @override
  String get land => 'أرض';

  @override
  String get studio => 'استوديو';

  @override
  String get duplex => 'دوبلكس';

  @override
  String get penthouse => 'بنتهاوس';

  @override
  String get sale => 'بيع';

  @override
  String get rent => 'إيجار';

  @override
  String get available => 'متاح';

  @override
  String get reserved => 'محجوز';

  @override
  String get sold => 'مباع';

  @override
  String get rented => 'مؤجر';

  @override
  String get inactive => 'غير نشط';

  @override
  String get requiredField => 'هذا الحقل مطلوب.';

  @override
  String get enterValidNumber => 'أدخل رقمًا صالحًا.';

  @override
  String get valueMustBePositive => 'يجب أن تكون القيمة أكبر من صفر.';

  @override
  String get valueMustBeNonNegative => 'لا يمكن أن تكون القيمة سالبة.';

  @override
  String get notAvailable => 'غير متوفر';

  @override
  String get description => 'الوصف';

  @override
  String get bedrooms => 'غرف النوم';

  @override
  String get bathrooms => 'الحمامات';

  @override
  String get compound => 'الكمبوند';

  @override
  String get ownerName => 'اسم المالك';

  @override
  String get ownerPhone => 'هاتف المالك';

  @override
  String get propertyBasicInformation => 'المعلومات الأساسية';

  @override
  String get propertyMetrics => 'بيانات العقار';

  @override
  String get propertyLocationSection => 'الموقع';

  @override
  String get propertyOwnerSection => 'بيانات المالك';

  @override
  String get propertyCreatedSuccessfully => 'تم إنشاء العقار بنجاح.';

  @override
  String get propertyUpdatedSuccessfully => 'تم تحديث العقار بنجاح.';

  @override
  String get propertyDetails => 'تفاصيل العقار';

  @override
  String get searchProperties => 'البحث في العقارات';

  @override
  String get clearFilters => 'مسح الفلاتر';

  @override
  String get noMatchingProperties => 'لا توجد عقارات مطابقة للفلاتر الحالية.';

  @override
  String get adjustPropertyFiltersHint =>
      'غيّر نص البحث أو قيم الفلاتر ثم حاول مرة أخرى.';

  @override
  String get allPropertyTypes => 'كل أنواع العقارات';

  @override
  String get allListingTypes => 'كل أنواع الإعلان';

  @override
  String propertiesResultsCount(Object shown, Object total) {
    return '$shown من $total عقار';
  }

  @override
  String get propertyNotFoundMessage =>
      'العقار غير موجود. افتح التفاصيل من قائمة العقارات.';

  @override
  String get backToProperties => 'العودة إلى العقارات';

  @override
  String get createdAt => 'تاريخ الإنشاء';

  @override
  String get updatedAt => 'تاريخ آخر تحديث';

  @override
  String get auditInfo => 'معلومات التدقيق';

  @override
  String get unableToLoadPropertyForEdit =>
      'تعذر تحميل بيانات العقار للتعديل. افتح التعديل من قائمة العقارات.';

  @override
  String get actions => 'الإجراءات';

  @override
  String get newLead => 'جديد';

  @override
  String get newLeadStatus => 'جديد';

  @override
  String get contacted => 'تم التواصل';

  @override
  String get contactedLeadStatus => 'تم التواصل';

  @override
  String get interested => 'مهتم';

  @override
  String get interestedLeadStatus => 'مهتم';

  @override
  String get visitScheduled => 'تم تحديد زيارة';

  @override
  String get visitScheduledLeadStatus => 'تم تحديد زيارة';

  @override
  String get negotiation => 'تفاوض';

  @override
  String get negotiationLeadStatus => 'تفاوض';

  @override
  String get won => 'تم الفوز';

  @override
  String get wonLeadStatus => 'تم البيع';

  @override
  String get lost => 'خاسر';

  @override
  String get lostLeadStatus => 'خاسر';

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
  String get deactivate => 'إيقاف';

  @override
  String get deactivateProperty => 'إيقاف العقار';

  @override
  String get deactivatePropertyConfirmation =>
      'سيتم تعيين هذا العقار كغير نشط.';

  @override
  String get propertyDeactivatedSuccessfully => 'تم إيقاف العقار بنجاح.';

  @override
  String get unableToDeactivateProperty => 'تعذر إيقاف العقار. حاول مرة أخرى.';

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
  String get lastContact => 'آخر تواصل';

  @override
  String get nextFollowUp => 'المتابعة القادمة';

  @override
  String get clearDate => 'مسح التاريخ';

  @override
  String get leadPreferences => 'تفضيلات العميل المحتمل';

  @override
  String get leadAssignment => 'الإسناد والملاحظات';

  @override
  String get missingCompanyProfile =>
      'تعذر تحميل ملف الشركة. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get editLead => 'تعديل العميل المحتمل';

  @override
  String get updateLead => 'تحديث العميل المحتمل';

  @override
  String get leadUpdated => 'تم تحديث العميل المحتمل بنجاح.';

  @override
  String get searchLeads => 'البحث في العملاء المحتملين';

  @override
  String get allStatuses => 'كل الحالات';

  @override
  String get allSources => 'كل المصادر';

  @override
  String get allAgents => 'كل الموظفين';

  @override
  String get assignee => 'المسؤول';

  @override
  String get allAssignees => 'كل المسؤولين';

  @override
  String get changeStatus => 'تغيير الحالة';

  @override
  String get addNote => 'إضافة ملاحظة';

  @override
  String get note => 'ملاحظة';

  @override
  String get notesHistory => 'سجل الملاحظات';

  @override
  String get noNotes => 'لا توجد ملاحظات بعد.';

  @override
  String get saveNote => 'حفظ الملاحظة';

  @override
  String get unableToLoadNotes => 'تعذر تحميل الملاحظات. حاول مرة أخرى.';

  @override
  String get unableToAddNote => 'تعذر إضافة الملاحظة. حاول مرة أخرى.';

  @override
  String get activeUsers => 'المستخدمون النشطون';

  @override
  String get unassigned => 'غير مسند';

  @override
  String get onlyAdminsManagersCanAssign =>
      'يمكن للمسؤولين والمديرين فقط إسناد العملاء المحتملين.';

  @override
  String get cannotAssignAcrossCompanies =>
      'لا يمكن إسناد عميل محتمل خارج شركتك.';

  @override
  String get accessDenied => 'تم رفض الوصول';

  @override
  String get assignedUser => 'المستخدم المسند إليه';

  @override
  String get assignedUserUnavailable => 'المستخدم المسند غير متوفر';

  @override
  String get youDoNotHavePermissionToViewLead =>
      'ليس لديك صلاحية لعرض هذا العميل المحتمل.';

  @override
  String get youDoNotHavePermissionToEditLead =>
      'ليس لديك صلاحية لتعديل هذا العميل المحتمل.';

  @override
  String get timeline => 'الخط الزمني';

  @override
  String get leadCreatedEvent => 'تم إنشاء العميل المحتمل';

  @override
  String get leadAssignedEvent => 'تم إسناد العميل المحتمل';

  @override
  String get leadReassignedEvent => 'تم إعادة إسناد العميل المحتمل';

  @override
  String get statusChangedEvent => 'تم تغيير الحالة';

  @override
  String get noteAddedEvent => 'تمت إضافة ملاحظة';

  @override
  String get archivedEvent => 'تمت أرشفة العميل المحتمل';

  @override
  String get updatedEvent => 'تم تحديث العميل المحتمل';

  @override
  String get changedFrom => 'تم التغيير من';

  @override
  String get changedTo => 'تم التغيير إلى';

  @override
  String get unknownUser => 'مستخدم غير معروف';

  @override
  String leadCreatedBy(Object user) {
    return 'تم إنشاء العميل المحتمل بواسطة $user';
  }

  @override
  String statusChangedToBy(Object status, Object user) {
    return 'تم تغيير الحالة إلى $status بواسطة $user';
  }

  @override
  String noteAddedBy(Object user) {
    return 'تمت إضافة ملاحظة بواسطة $user';
  }

  @override
  String leadReassignedBy(Object user) {
    return 'تمت إعادة إسناد العميل المحتمل بواسطة $user';
  }

  @override
  String leadReassignedFromToBy(Object fromUser, Object toUser, Object actor) {
    return 'تم إعادة إسناد العميل المحتمل من $fromUser إلى $toUser بواسطة $actor';
  }

  @override
  String leadArchivedBy(Object user) {
    return 'تمت أرشفة العميل المحتمل بواسطة $user';
  }

  @override
  String get noLeadsAvailable => 'لا توجد عملاء محتملون متاحون.';

  @override
  String get noNotesAvailable => 'لا توجد ملاحظات متاحة.';

  @override
  String get noTimelineEvents => 'لا توجد أحداث في الخط الزمني بعد.';

  @override
  String fieldChangedBy(Object field, Object user) {
    return 'تم تغيير $field بواسطة $user';
  }

  @override
  String changedFromTo(Object oldValue, Object newValue) {
    return 'تم التغيير من $oldValue إلى $newValue';
  }

  @override
  String get assignedToLabel => 'مسند إلى';

  @override
  String leadAssignedTo(Object name) {
    return 'مسند إلى: $name';
  }

  @override
  String get fullNameUpdated => 'الاسم الكامل';

  @override
  String get phoneUpdated => 'الهاتف';

  @override
  String get emailUpdated => 'البريد الإلكتروني';

  @override
  String get sourceUpdated => 'المصدر';

  @override
  String get statusUpdated => 'الحالة';

  @override
  String get priorityUpdated => 'الأولوية';

  @override
  String get budgetUpdated => 'الميزانية';

  @override
  String get preferredLocationUpdated => 'الموقع المفضل';

  @override
  String get preferredPropertyTypeUpdated => 'نوع العقار المفضل';

  @override
  String get more => 'المزيد';

  @override
  String get filters => 'الفلاتر';

  @override
  String get applyFilters => 'تطبيق الفلاتر';

  @override
  String get updated => 'تم التحديث';

  @override
  String get details => 'التفاصيل';

  @override
  String get viewDetails => 'عرض التفاصيل';

  @override
  String get selectLeadPreview => 'اختر عميلاً محتملاً';

  @override
  String get selectLeadPreviewMessage =>
      'اختر عميلاً من القائمة لمعاينة بيانات التواصل والحالة والإجراءات.';

  @override
  String get somethingWentWrong => 'حدث خطأ ما';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get unableToConnect =>
      'تعذر الاتصال. تحقق من اتصال الإنترنت وحاول مرة أخرى.';

  @override
  String get leadUpdateFailed => 'تعذر تحديث العميل المحتمل. حاول مرة أخرى.';

  @override
  String get noData => 'لا توجد بيانات متاحة.';

  @override
  String get leadCreatedSuccessfully => 'تم إنشاء العميل المحتمل بنجاح.';

  @override
  String get leadUpdatedSuccessfully => 'تم تحديث العميل المحتمل بنجاح.';

  @override
  String get leadArchivedSuccessfully => 'تمت أرشفة العميل المحتمل بنجاح.';

  @override
  String get leadStatusUpdatedSuccessfully =>
      'تم تحديث حالة العميل المحتمل بنجاح.';

  @override
  String get leadAssignedSuccessfully => 'تم إسناد العميل المحتمل بنجاح.';

  @override
  String get noteAddedSuccessfully => 'تمت إضافة الملاحظة بنجاح.';

  @override
  String get overdue => 'متأخرة';

  @override
  String get dueToday => 'مستحقة اليوم';

  @override
  String get upcoming => 'قادمة';

  @override
  String get allDueDates => 'كل تواريخ الاستحقاق';

  @override
  String get dueDateFilter => 'تاريخ الاستحقاق';

  @override
  String get notScheduled => 'غير مجدولة';

  @override
  String get allFollowUps => 'كل المتابعات';

  @override
  String get needsAttention => 'يحتاج اهتمام';

  @override
  String get staleLead => 'عميل خامد';

  @override
  String get markContactedToday => 'تسجيل التواصل اليوم';

  @override
  String get leadMarkedContactedToday =>
      'تم تسجيل التواصل مع العميل المحتمل اليوم.';

  @override
  String get scheduleFollowUp => 'جدولة متابعة';

  @override
  String get duplicateLeadFound =>
      'يوجد عميل محتمل بنفس رقم الهاتف أو البريد الإلكتروني.';

  @override
  String get dashboardGoodMorning => 'صباح الخير';

  @override
  String get dashboardGoodAfternoon => 'مساء الخير';

  @override
  String get dashboardGoodEvening => 'مساء الخير';

  @override
  String get dashboardOverdueFollowUps => 'متابعات متأخرة';

  @override
  String get dashboardUpcomingFollowUps => 'متابعات قادمة';

  @override
  String get dashboardAvailableProperties => 'عقارات متاحة';

  @override
  String get dashboardVisualAnalytics => 'تحليلات العمل';

  @override
  String get dashboardLeadStatusDistribution => 'توزيع حالات العملاء المحتملين';

  @override
  String get dashboardTasksDueBreakdown => 'توزيع مواعيد المهام';

  @override
  String get dashboardPropertyStatusDistribution => 'توزيع حالات العقارات';

  @override
  String get dashboardTodaysFollowUps => 'متابعات اليوم';

  @override
  String get dashboardOverdueTasks => 'مهام متأخرة';

  @override
  String get dashboardUnassignedLeads => 'عملاء محتملون غير مسندين';

  @override
  String get dashboardRecentlyUpdatedLeads => 'آخر العملاء المحتملين تحديثاً';

  @override
  String get dashboardQuickActions => 'إجراءات سريعة';

  @override
  String get dashboardActive => 'نشط';

  @override
  String get dashboardInactive => 'غير نشط';

  @override
  String get dashboardReservedOrClosed => 'محجوزة أو مغلقة';

  @override
  String get dashboardGeneralTask => 'مهمة عامة';

  @override
  String get clientsSubtitle =>
      'احتفظ بملفات العملاء وتفضيلاتهم والتكليفات جاهزة للمتابعة.';

  @override
  String get searchClients => 'ابحث في العملاء';

  @override
  String get searchTasks => 'ابحث في المهام';

  @override
  String get createDeal => 'إنشاء صفقة';

  @override
  String get editDeal => 'تعديل الصفقة';

  @override
  String get updateDeal => 'تحديث الصفقة';

  @override
  String get dealDetails => 'تفاصيل الصفقة';

  @override
  String get dealsSubtitle =>
      'تابع فرص العملاء وقيمة العقار والعمولة وحالة الإغلاق.';

  @override
  String get dealInformation => 'بيانات الصفقة';

  @override
  String get dealValueAndStage => 'القيمة والمرحلة';

  @override
  String get dealSummary => 'ملخص الصفقة';

  @override
  String get noDeals => 'لا توجد صفقات بعد.';

  @override
  String get noDealsAvailable => 'لا توجد صفقات متاحة.';

  @override
  String get noDealsMatchFilters => 'لا توجد صفقات تطابق الفلاتر الحالية.';

  @override
  String get searchDeals => 'ابحث في الصفقات';

  @override
  String get dealStage => 'مرحلة الصفقة';

  @override
  String get newDealStage => 'جديدة';

  @override
  String get qualified => 'مؤهلة';

  @override
  String get proposal => 'عرض';

  @override
  String get expectedValue => 'القيمة المتوقعة';

  @override
  String get commission => 'العمولة';

  @override
  String get closingDate => 'تاريخ الإغلاق';

  @override
  String get lostReason => 'سبب الخسارة';

  @override
  String get assignedAgent => 'الموظف المسؤول';

  @override
  String get updateStage => 'تحديث المرحلة';

  @override
  String get archiveDeal => 'أرشفة الصفقة';

  @override
  String get archiveDealConfirmation =>
      'سيتم أرشفة هذه الصفقة وإخفاؤها من قوائم الصفقات النشطة.';

  @override
  String get dealCreatedSuccessfully => 'تم إنشاء الصفقة بنجاح.';

  @override
  String get dealUpdatedSuccessfully => 'تم تحديث الصفقة بنجاح.';

  @override
  String get dealArchivedSuccessfully => 'تمت أرشفة الصفقة بنجاح.';

  @override
  String get dealStageUpdatedSuccessfully => 'تم تحديث مرحلة الصفقة بنجاح.';

  @override
  String get unableToSaveDeal => 'تعذر حفظ الصفقة. حاول مرة أخرى.';

  @override
  String get lostReasonRequired => 'سبب الخسارة مطلوب.';

  @override
  String get selectClient => 'اختر العميل';

  @override
  String get selectLead => 'اختر العميل المحتمل';

  @override
  String get selectProperty => 'اختر العقار';

  @override
  String get selectAssignedAgent => 'اختر الموظف المسؤول';

  @override
  String get allClosingDates => 'كل تواريخ الإغلاق';

  @override
  String get pastClosing => 'إغلاق متأخر';

  @override
  String get thisWeek => 'هذا الأسبوع';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get backToDeals => 'العودة إلى الصفقات';

  @override
  String get dealNotFoundMessage =>
      'الصفقة غير موجودة. افتحها من قائمة الصفقات.';

  @override
  String get reportsComingSoon => 'التقارير قادمة قريباً.';

  @override
  String get myProfile => 'ملفي الشخصي';

  @override
  String get profileInformation => 'بيانات الملف الشخصي';

  @override
  String get role => 'الدور';

  @override
  String get accountStatus => 'حالة الحساب';

  @override
  String get active => 'نشط';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get edit => 'تعديل';

  @override
  String get preferences => 'التفضيلات';

  @override
  String get appearance => 'المظهر';

  @override
  String get account => 'الحساب';

  @override
  String get aboutApp => 'عن التطبيق';

  @override
  String get admin => 'مسؤول';

  @override
  String get manager => 'مدير';

  @override
  String get salesAgent => 'موظف مبيعات';

  @override
  String get marketing => 'تسويق';

  @override
  String get viewer => 'مشاهد';

  @override
  String get connectionTimeout =>
      'تعذر تحميل البيانات. تحقق من الاتصال وحاول مرة أخرى.';

  @override
  String get unableToLoadReports => 'تعذر تحميل التقارير. حاول مرة أخرى.';

  @override
  String get reportsOverview =>
      'راجع أداء إدارة العملاء باستخدام بيانات العملاء المحتملين والصفقات والمهام والعقارات للفترة المحددة.';

  @override
  String get reportPeriod => 'فترة التقرير';

  @override
  String get selectedPeriod => 'الفترة المحددة';

  @override
  String get allTime => 'كل الفترات';

  @override
  String get today => 'اليوم';

  @override
  String get totalDeals => 'إجمالي الصفقات';

  @override
  String get wonDeals => 'الصفقات الرابحة';

  @override
  String get lostDeals => 'الصفقات الخاسرة';

  @override
  String get expectedValueTotal => 'إجمالي القيمة المتوقعة';

  @override
  String get commissionTotal => 'إجمالي العمولة';

  @override
  String get dealsByStage => 'الصفقات حسب المرحلة';

  @override
  String get dealPipeline => 'مسار الصفقات';

  @override
  String get pipelineValue => 'قيمة المسار';

  @override
  String get recentDeals => 'أحدث الصفقات';

  @override
  String get overdueTasks => 'المهام المتأخرة';

  @override
  String get dueTodayTasks => 'مهام اليوم';

  @override
  String get upcomingTasks => 'المهام القادمة';

  @override
  String get completedTasks => 'المهام المكتملة';

  @override
  String get cancelledTasks => 'المهام الملغاة';

  @override
  String get completionRate => 'معدل الإنجاز';

  @override
  String get overdueRate => 'معدل التأخير';

  @override
  String get leadsReport => 'أداء العملاء المحتملين';

  @override
  String get dealsReport => 'أداء الصفقات';

  @override
  String get tasksReport => 'المهام والمتابعات';

  @override
  String get propertiesReport => 'تقرير العقارات';

  @override
  String get teamReport => 'تقرير الموظفين';

  @override
  String get leadsByStatus => 'العملاء المحتملون حسب الحالة';

  @override
  String get leadsBySource => 'العملاء المحتملون حسب المصدر';

  @override
  String get leadsByPriority => 'العملاء المحتملون حسب الأولوية';

  @override
  String get propertiesByStatus => 'العقارات حسب الحالة';

  @override
  String get propertiesByType => 'العقارات حسب النوع';

  @override
  String get taskStatusDistribution => 'توزيع حالات المهام';

  @override
  String get agentPerformance => 'أداء الموظفين';

  @override
  String get highestPriorityTasks => 'أهم المهام العاجلة';

  @override
  String get inventoryValue => 'قيمة المخزون';

  @override
  String get totalListedValue => 'إجمالي قيمة المعروض';

  @override
  String get averagePrice => 'متوسط السعر';

  @override
  String get wonValue => 'قيمة الصفقات الرابحة';

  @override
  String get lostValue => 'قيمة الصفقات الخاسرة';

  @override
  String get noReportData => 'لا توجد بيانات تقارير للفلاتر المحددة.';

  @override
  String get addDeal => 'إضافة صفقة';

  @override
  String get appVersion => 'إصدار التطبيق';

  @override
  String get version => 'الإصدار';
}
