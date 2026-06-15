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
  String get dashboard => 'لوحة المتابعة';

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
  String get agentPerformanceSummary =>
      'قارن بين حجم العمل ونشاط الصفقات وإنجاز المهام ومخاطر التأخير لكل مسؤول.';

  @override
  String get agent => 'المسؤول';

  @override
  String get performanceScore => 'التقييم';

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
  String get agentActivityResults => 'نشاط ونتائج الموظفين';

  @override
  String get agentActivityResultsSummary =>
      'راجع حجم العمل، الصفقات الرابحة، إنجاز المهام، والمتأخرات لكل موظف.';

  @override
  String get workload => 'حجم العمل';

  @override
  String get results => 'النتائج';

  @override
  String get followUps => 'المتابعات';

  @override
  String get wonDeals => 'الصفقات الرابحة';

  @override
  String get wonDealsThisMonth => 'الصفقات الرابحة هذا الشهر';

  @override
  String get taskCompletion => 'إنجاز المهام';

  @override
  String get overdueTasks => 'المهام المتأخرة';

  @override
  String get noPropertiesFound => 'لا توجد عقارات.';

  @override
  String get scheduleAndPriority => 'الموعد والأولوية';

  @override
  String get selectDueDate => 'اختر تاريخ الاستحقاق';

  @override
  String get dueDate => 'تاريخ الاستحقاق';

  @override
  String get dashboardRecentActivity => 'آخر النشاط';

  @override
  String get dashboardRecentActivitySubtitle =>
      'آخر تغييرات CRM المسجلة لهذه الشركة.';

  @override
  String get dashboardNoRecentActivity => 'لا يوجد نشاط حديث بعد.';

  @override
  String get dashboardUnableToLoadRecentActivity => 'تعذر تحميل آخر النشاط.';

  @override
  String get teamRecentActivity => 'آخر نشاط للفريق';

  @override
  String get teamRecentActivitySubtitle => 'آخر تغييرات CRM المسجلة لفريقك.';

  @override
  String get noRecentTeamActivity => 'لا يوجد نشاط حديث للفريق حتى الآن.';

  @override
  String dashboardAuditActionLabel(Object module, Object action) {
    return '$module · $action';
  }

  @override
  String get dashboardAuditCreated => 'إنشاء';

  @override
  String get dashboardAuditUpdated => 'تحديث';

  @override
  String get dashboardAuditArchived => 'أرشفة';

  @override
  String get dashboardAuditDeactivated => 'إيقاف';

  @override
  String get dashboardAuditAssigned => 'إسناد';

  @override
  String get dashboardAuditStatusChanged => 'تغيير الحالة';

  @override
  String get dashboardAuditStageChanged => 'تغيير المرحلة';

  @override
  String get dashboardAuditCompleted => 'إكمال';

  @override
  String get dashboardAuditCancelled => 'إلغاء';

  @override
  String get dashboardAuditImageAdded => 'إضافة صورة';

  @override
  String get dashboardAuditImageRemoved => 'إزالة صورة';

  @override
  String get dashboardAuditRestored => 'استعادة';

  @override
  String get dashboardAuditExportGenerated => 'إنشاء تصدير';

  @override
  String get dashboardAuditLead => 'عميل محتمل';

  @override
  String get dashboardAuditClient => 'عميل';

  @override
  String get dashboardAuditProperty => 'عقار';

  @override
  String get dashboardAuditTask => 'مهمة';

  @override
  String get dashboardAuditDeal => 'صفقة';

  @override
  String get dashboardActivityLeadUpdated => 'تم تحديث عميل محتمل';

  @override
  String get dashboardActivityClientUpdated => 'تم تحديث عميل';

  @override
  String get dashboardActivityPropertyUpdated => 'تم تحديث عقار';

  @override
  String get dashboardActivityTaskUpdated => 'تم تحديث مهمة';

  @override
  String get dashboardActivityTaskCompleted => 'تم إكمال مهمة';

  @override
  String get dashboardActivityDealUpdated => 'تم تحديث صفقة';

  @override
  String get dashboardActivityDealWon => 'صفقة رابحة';

  @override
  String get dashboardActivityDealLost => 'صفقة خاسرة';

  @override
  String get dashboardJustNow => 'الآن';

  @override
  String dashboardMinutesAgo(int count) {
    return 'منذ $count دقيقة';
  }

  @override
  String dashboardHoursAgo(int count) {
    return 'منذ $count ساعة';
  }

  @override
  String get dashboardYesterday => 'أمس';

  @override
  String byUser(String name) {
    return 'بواسطة $name';
  }

  @override
  String get unknownUser => 'مستخدم غير معروف';

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
  String get salesWorkspace => 'رحلة العميل إلى الصفقة';

  @override
  String get searchCrm => 'البحث في مسار CRM';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get crmUser => 'مستخدم مسار';

  @override
  String get workspace => 'بيئة العمل';

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
  String get loginSupportTitle => 'تحتاج مساعدة للبدء؟';

  @override
  String get loginSupportSubtitle =>
      'تواصل مع دعم مسار لإنشاء حساب شركتك أو الحصول على دعوة.';

  @override
  String get loginSupportWhatsAppMessage =>
      'مرحبًا دعم مسار، أحتاج مساعدة في إنشاء حساب شركتي أو الدخول إليه.';

  @override
  String get loginSupportEmailSubject => 'طلب دخول إلى مسار CRM';

  @override
  String get loginSupportEmailBody =>
      'مرحبًا دعم مسار،\n\nأحتاج مساعدة في إنشاء حساب شركتي أو الدخول إليه.\n\nشكرًا لكم.';

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
  String get authErrorAccountNotLinked => 'هذا الحساب غير مرتبط بشركة نشطة.';

  @override
  String get authErrorCompanyInactive =>
      'هذه الشركة غير نشطة. يرجى التواصل مع دعم المنصة.';

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
  String get archived => 'مؤرشف';

  @override
  String get restore => 'استعادة';

  @override
  String get restoreRecord => 'استعادة السجل';

  @override
  String get restoreRecordConfirmation => 'سيعود هذا السجل إلى القوائم النشطة.';

  @override
  String get archiveReason => 'سبب الأرشفة';

  @override
  String get noArchivedRecords => 'لا توجد سجلات مؤرشفة';

  @override
  String get archivedRecordsHiddenFromActiveLists =>
      'تبقى السجلات المؤرشفة مخفية من القوائم النشطة.';

  @override
  String get recordRestoredSuccessfully => 'تمت استعادة السجل بنجاح.';

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
  String get propertyImages => 'صور العقار';

  @override
  String get propertyImagesHint =>
      'ارفع صورًا واضحة للعقار. سيتم استخدام أول صورة كصورة الغلاف.';

  @override
  String get addPropertyImages => 'إضافة صور';

  @override
  String get noPropertyImagesYet => 'لا توجد صور للعقار حتى الآن.';

  @override
  String get removeImage => 'حذف الصورة';

  @override
  String get newImage => 'جديد';

  @override
  String get propertyImageInvalidType => 'يُسمح بملفات الصور فقط.';

  @override
  String get propertyImageTooLarge => 'يجب ألا يتجاوز حجم كل صورة 5 ميجابايت.';

  @override
  String get unableToPickPropertyImages =>
      'تعذر اختيار صور العقار. حاول مرة أخرى.';

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
  String get recordMustBeAssignedBeforeSaving =>
      'يجب إسناد هذا السجل قبل الحفظ.';

  @override
  String get canOnlyAssignRecordsToYourTeam =>
      'يمكنك إسناد السجلات لمستخدمي فريقك فقط.';

  @override
  String get selectedAssigneeInactive => 'المستخدم المحدد غير نشط.';

  @override
  String get selectedAssigneeNotEligible =>
      'المستخدم المحدد غير مؤهل لهذا السجل.';

  @override
  String get permissionToViewAnotherTeamRecordsDenied =>
      'ليس لديك صلاحية لعرض سجلات فريق آخر.';

  @override
  String get sessionOrCompanyProfileMissing =>
      'بيانات الجلسة أو الشركة غير مكتملة. يرجى تسجيل الدخول مرة أخرى.';

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
  String get contactedTodayFollowUpStillOverdue =>
      'تم التواصل اليوم والمتابعة ما زالت متأخرة';

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
  String get dashboardVsLastMonth => 'مقارنة بالشهر الماضي';

  @override
  String get dashboardOfCurrentTotal => 'من الإجمالي الحالي';

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
  String get dashboardAppointmentsTitle => 'متابعة المواعيد';

  @override
  String get nextAppointment => 'الموعد التالي';

  @override
  String get noUpcomingAppointments => 'لا توجد مواعيد قادمة';

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
  String get dashboardKpiActiveLeads => 'العملاء المحتملون النشطون';

  @override
  String get dashboardKpiHotOpportunities => 'فرص مهمة';

  @override
  String get dashboardKpiDueTodayFollowUps => 'متابعات اليوم';

  @override
  String get dashboardKpiOverdueActions => 'مهام متأخرة';

  @override
  String get dashboardKpiAppointmentsToday => 'مواعيد اليوم';

  @override
  String get dashboardKpiDealsPipeline => 'خط الصفقات';

  @override
  String get dashboardKpiExpectedPipeline => 'قيمة الصفقات';

  @override
  String get dashboardKpiActiveListings => 'عقارات متاحة';

  @override
  String get dashboardPeriodToday => 'اليوم';

  @override
  String get dashboardPeriodThisMonth => 'هذا الشهر';

  @override
  String get dashboardPeriodCurrentScope => 'حسب صلاحيات دورك';

  @override
  String get dashboardNotEnoughData => 'لا توجد بيانات كافية بعد.';

  @override
  String get dashboardPerformanceTitle => 'أداء المبيعات';

  @override
  String get dashboardPerformanceOverview => 'نظرة على الأداء';

  @override
  String get dashboardLeadsTrend => 'اتجاه العملاء المحتملين';

  @override
  String get dashboardFollowUpsCompletedMissed => 'المتابعات المنجزة والمتأخرة';

  @override
  String get dashboardAppointmentsFlow => 'حالة مواعيد اليوم';

  @override
  String get dashboardLeadSources => 'مصادر العملاء المحتملين';

  @override
  String get dashboardLast7Days => 'آخر ٧ أيام';

  @override
  String get dashboardTodayRailTitle => 'اليوم';

  @override
  String get dashboardDueFollowUps => 'متابعات مستحقة';

  @override
  String get dashboardOverdueReminders => 'تنبيهات متأخرة';

  @override
  String get dashboardNoUrgentActions => 'لا توجد إجراءات عاجلة الآن.';

  @override
  String get dashboardPipelineSnapshot => 'خط المبيعات';

  @override
  String get dashboardPipelineHasNoValue =>
      'تظهر قيمة المسار عند تسجيل قيم الصفقات.';

  @override
  String get dashboardStuckDeals => 'صفقات متوقفة';

  @override
  String get dashboardDealRisks => 'صفقات تحتاج متابعة';

  @override
  String get dashboardClosingThisMonth => 'إغلاق هذا الشهر';

  @override
  String get dashboardWonLost => 'رابحة / خاسرة';

  @override
  String get dashboardDealsByStage => 'الصفقات حسب المرحلة';

  @override
  String get dashboardTeamPerformance => 'أداء الفريق';

  @override
  String get dashboardPersonalPerformance => 'أدائي';

  @override
  String get dashboardTopActiveAgent => 'الأكثر نشاطًا';

  @override
  String get dashboardOverloadedAssignee => 'يحتاج توزيع عبء';

  @override
  String get dashboardNoTeamSignal => 'لا توجد مؤشرات ضغط على الفريق الآن.';

  @override
  String get dashboardPerformanceLimitedForRole => 'عرض محدود لهذا الدور.';

  @override
  String get dashboardOverviewTab => 'نظرة عامة';

  @override
  String get dashboardWorkQueue => 'قائمة العمل';

  @override
  String get dashboardPerformanceTab => 'الأداء';

  @override
  String get dashboardOpportunitiesTab => 'الفرص';

  @override
  String get dashboardQuickActionsUnavailable =>
      'لا توجد إجراءات سريعة متاحة لهذا الدور.';

  @override
  String get dashboardImportantOpportunities => 'أهم الفرص المفتوحة';

  @override
  String get dashboardNoOpportunities => 'لا توجد فرص مهمة بعد.';

  @override
  String get dashboardDailyInsight => 'رؤية ذكية';

  @override
  String dashboardAppointmentsForDate(Object date) {
    return 'مواعيد $date';
  }

  @override
  String get dashboardNoAppointmentsForDay => 'لا توجد مواعيد لهذا اليوم';

  @override
  String get dashboardUrgentActions => 'إجراءات عاجلة';

  @override
  String get dashboardUrgentFollowUps => 'متابعات عاجلة';

  @override
  String get dashboardNoUrgentFollowUps => 'لا توجد متابعات عاجلة';

  @override
  String get dashboardQuickAction => 'إجراء سريع';

  @override
  String get dashboardTeamUser => 'المستشار';

  @override
  String get dashboardTeamAppointments => 'المواعيد';

  @override
  String get dashboardTeamDeals => 'الصفقات';

  @override
  String get dashboardTeamPipeline => 'قيمة الصفقات المفتوحة';

  @override
  String get dashboardNoValue => 'بدون قيمة';

  @override
  String get dashboardAddLead => 'إضافة عميل محتمل';

  @override
  String get dashboardAddClient => 'إضافة عميل';

  @override
  String get dashboardAddProperty => 'إضافة عقار';

  @override
  String get dashboardAddAppointment => 'إضافة موعد';

  @override
  String get dashboardSeriesLeads => 'العملاء المحتملون';

  @override
  String get dashboardSeriesAppointments => 'المواعيد';

  @override
  String get dashboardSeriesDeals => 'الصفقات';

  @override
  String get dashboardSeriesPipelineValue => 'قيمة الصفقات';

  @override
  String dashboardDailyInsightStaleLeads(Object count) {
    return 'هناك $count فرص نشطة بدون حركة حديثة منذ أكثر من ٥ أيام. ابدأ بالفرص الأعلى قيمة.';
  }

  @override
  String dashboardDailyInsightNoNextFollowUp(Object count) {
    return 'هناك $count فرص نشطة بدون موعد متابعة قادم. كل فرصة مفتوحة تحتاج خطوة واضحة.';
  }

  @override
  String dashboardDailyInsightContactedTodayStillOverdue(Object count) {
    return 'تم التواصل اليوم مع $count فرص، لكن المتابعة المتأخرة لم تُجدول من جديد. حدّد موعد المتابعة القادم قبل نهاية اليوم.';
  }

  @override
  String dashboardDailyInsightConversionUp(Object percent) {
    return 'معدل التحويل الحالي أعلى من الشهر السابق بنسبة $percent٪.';
  }

  @override
  String get dashboardDailyInsightCalm =>
      'لا توجد إجراءات حرجة الآن. تابع مؤشرات الأداء واستعد للفرصة القادمة.';

  @override
  String get dashboardDailyInsightNotEnoughData =>
      'لا توجد بيانات كافية بعد لعرض رؤية يومية دقيقة.';

  @override
  String get dashboardWelcomeInsightActive =>
      'ابدأ اليوم من الفرص المهمة والمتابعات المستحقة، ثم راجع مواعيد الفريق من شريط اليوم.';

  @override
  String get dashboardWelcomeInsightCalm =>
      'لا توجد مؤشرات عاجلة الآن. راقب الأداء واستعد للفرص القادمة.';

  @override
  String get dashboardTodayShort => 'اليوم';

  @override
  String dashboardDaysAgo(Object count) {
    return 'منذ $count يوم';
  }

  @override
  String get salesCommandCenterTitle => 'مركز المتابعة اليومية';

  @override
  String get salesCommandCenterSubtitle =>
      'أهم الفرص والمتابعات التي تحتاج حركة اليوم.';

  @override
  String get salesCommandEmptyTitle => 'لا توجد إجراءات عاجلة الآن.';

  @override
  String get salesCommandEmptyMessage =>
      'لا توجد إجراءات عاجلة الآن. المتابعة تحت السيطرة.';

  @override
  String get salesCommandLimitedMessage =>
      'ستظهر هنا الأعمال المتاحة حسب صلاحياتك عند وجود بيانات كافية.';

  @override
  String get salesCommandUpdatedNow => 'تم التحديث الآن';

  @override
  String get salesCommandMetricDueToday => 'مستحق اليوم';

  @override
  String get salesCommandMetricOverdue => 'متأخر';

  @override
  String get salesCommandMetricHot => 'فرص مهمة';

  @override
  String get salesCommandMetricRisk => 'تحتاج تدخل';

  @override
  String get dashboardCommandLegendTooltip =>
      'الأحمر = متأخر أو عالي المخاطر. الذهبي = مستحق اليوم أو قريب. الأزرق = فرصة مهمة. الأخضر = نتيجة إيجابية أو مكتمل.';

  @override
  String get dashboardSuggestedNextAction => 'الإجراء المقترح';

  @override
  String get salesCommandTodayPrioritiesTitle => 'أولويات اليوم';

  @override
  String get salesCommandTodayPrioritiesSubtitle =>
      'أهم الإجراءات المختلطة بين العملاء والمهام والصفقات والمواعيد.';

  @override
  String get salesCommandHotOpportunitiesTitle => 'فرص مهمة';

  @override
  String get salesCommandHotOpportunitiesSubtitle =>
      'عملاء وصفقات تظهر عليها إشارات تستحق متابعة قريبة.';

  @override
  String get salesCommandAtRiskTitle => 'تحتاج تدخل';

  @override
  String get salesCommandAtRiskSubtitle =>
      'متابعات فائتة أو عملاء بلا حركة أو صفقات متوقفة.';

  @override
  String get salesCommandTeamPressureTitle => 'ضغط الفريق';

  @override
  String get salesCommandTeamPressureSubtitle =>
      'عبء العمل المتأخر وفجوات المسؤولية ضمن نطاقك.';

  @override
  String get salesCommandNoTodayPriorities => 'لا توجد أولوية مستحقة الآن.';

  @override
  String get salesCommandNoHotOpportunities =>
      'لا توجد فرصة قوية ظاهرة ضمن البيانات الحالية.';

  @override
  String get salesCommandNoAtRisk => 'لا يوجد عنصر ظاهر يحتاج تدخل الآن.';

  @override
  String get salesCommandNoTeamPressure =>
      'لا يظهر ضغط زائد أو فجوة مسؤولية حالياً.';

  @override
  String get salesCommandWhyThisAppears => 'سبب الظهور';

  @override
  String get salesCommandOpenAction => 'عرض';

  @override
  String get salesCommandDueToday => 'مستحق اليوم';

  @override
  String salesCommandOverdueByDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'متأخر $count أيام',
      one: 'متأخر يوم واحد',
      zero: 'متأخر',
    );
    return '$_temp0';
  }

  @override
  String salesCommandAgeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بلا حركة منذ $count أيام',
      one: 'بلا حركة منذ يوم',
    );
    return '$_temp0';
  }

  @override
  String salesCommandDueAt(Object date) {
    return 'مستحق $date';
  }

  @override
  String get salesCommandModuleLead => 'عميل محتمل';

  @override
  String get salesCommandModuleTask => 'مهمة';

  @override
  String get salesCommandModuleDeal => 'صفقة';

  @override
  String get salesCommandModuleAppointment => 'موعد';

  @override
  String get salesCommandModuleClient => 'عميل';

  @override
  String get salesCommandModuleUser => 'مستخدم';

  @override
  String get salesCommandModuleTeam => 'فريق';

  @override
  String get salesCommandWhyOverdueFollowUp =>
      'موعد المتابعة فات والعميل المحتمل ما زال مفتوحاً.';

  @override
  String get salesCommandWhyDueTodayFollowUp =>
      'هذا العميل لديه متابعة مستحقة اليوم.';

  @override
  String get salesCommandWhyOverdueTask => 'المهمة ما زالت مفتوحة بعد موعدها.';

  @override
  String get salesCommandWhyDueTodayTask =>
      'المهمة مستحقة اليوم ولم تُنجز بعد.';

  @override
  String salesCommandWhyStaleLead(int count) {
    return 'لا يوجد تواصل أو تحديث حديث منذ $count يوم.';
  }

  @override
  String get salesCommandWhyHotLead =>
      'الأولوية أو الحالة تشير إلى فرصة تستحق متابعة قريبة.';

  @override
  String get salesCommandWhyUnassignedLead =>
      'عميل مهم بدون مسؤول متابعة حتى الآن.';

  @override
  String get salesCommandWhyAppointmentMissed =>
      'وقت الموعد انتهى وما زال يحتاج معالجة.';

  @override
  String get salesCommandWhyAppointmentDueNow =>
      'الموعد مستحق الآن أو يفترض أنه بدأ بالفعل.';

  @override
  String get salesCommandWhyAppointmentUpcoming =>
      'موعد اليوم ظاهر للتنبيه فقط بدون أن يطغى على الأولويات.';

  @override
  String get salesCommandWhyAppointmentNeedsFeedback =>
      'الموعد انتهى ولم يتم تسجيل نتيجته.';

  @override
  String get salesCommandWhyDealAtRisk =>
      'الصفقة متوقفة أو اقترب موعد إغلاقها وتحتاج خطوة واضحة.';

  @override
  String get salesCommandWhyDealHotOpportunity =>
      'هذه الصفقة لديها قيمة أو تقدّم واضح في المرحلة. ثبّت الالتزام القادم أو حدّث المرحلة أو أنشئ مهمة متابعة حتى يبقى مسار الفرصة مضبوطًا.';

  @override
  String get salesCommandWhyDealClosingDue =>
      'تاريخ الإغلاق المتوقع مستحق أو متأخر. أكّد قرار العميل أو حدّث مرحلة الصفقة أو أنشئ مهمة الإغلاق الآن.';

  @override
  String get salesCommandWhyDealStale =>
      'هذه الصفقة لم تتحرك مؤخرًا. اتفق على الالتزام القادم وسجّله حتى يعكس خط البيع الفرص الحقيقية فقط.';

  @override
  String get salesCommandWhyAppointmentMissedRecovery =>
      'الموعد فائت. عالجه بإعادة الجدولة أو إكماله مع تسجيل النتيجة أو إلغائه بسبب واضح.';

  @override
  String get salesCommandWhyAppointmentDueNowSmart =>
      'الموعد مستحق الآن. افتحه، ولا تكمله إلا بعد حدوث المقابلة، ثم سجّل النتيجة.';

  @override
  String get salesCommandWhyAppointmentUpcomingSmart =>
      'هذا الموعد قادم اليوم. أبقه ظاهرًا، لكن لا تتعامل معه كإجراء عاجل إلا عند حلول توقيته أو الحاجة للتحضير.';

  @override
  String get salesCommandWhyAppointmentNeedsOutcomeSmart =>
      'تم إكمال الموعد بدون تسجيل نتيجة. أضف النتيجة حتى تكون الخطوة التالية مبنية على إثبات واضح.';

  @override
  String salesCommandWhyOverloadedAssignee(Object name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عناصر متأخرة',
      one: 'عنصر واحد متأخر',
    );
    return '$name لديه $_temp0.';
  }

  @override
  String salesCommandMoreItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'توجد $count إجراءات أخرى داخل الوحدات',
      one: 'يوجد إجراء آخر داخل الوحدات',
    );
    return '$_temp0';
  }

  @override
  String get salesCommandReasonOverdueFollowUp =>
      'تأخرت المتابعة ويحتاج العميل إجراء الآن';

  @override
  String get salesCommandReasonDueTodayFollowUp =>
      'موعد المتابعة اليوم ولا يفضل تأجيله';

  @override
  String get salesCommandReasonOverdueTask => 'مهمة متأخرة تؤثر على المتابعة';

  @override
  String get salesCommandReasonDueTodayTask => 'مهمة مستحقة اليوم';

  @override
  String get salesCommandReasonStaleLead => 'لا توجد حركة حديثة على هذه الفرصة';

  @override
  String get salesCommandReasonHotLead => 'فرصة نشطة وتستحق أولوية';

  @override
  String get salesCommandReasonUnassignedLead => 'عميل مهم غير مسند';

  @override
  String get salesCommandReasonAppointmentMissed => 'موعد فائت';

  @override
  String get salesCommandReasonAppointmentDueNow => 'موعد مستحق الآن';

  @override
  String get salesCommandReasonAppointmentUpcoming => 'موعد قريب';

  @override
  String get salesCommandReasonAppointmentNeedsFeedback => 'يحتاج نتيجة الموعد';

  @override
  String get salesCommandReasonDealAtRisk => 'الصفقة متوقفة وتحتاج تدخل';

  @override
  String salesCommandReasonOverloadedAssignee(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مهام متأخرة',
      one: 'مهمة متأخرة واحدة',
    );
    return '$_temp0';
  }

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
  String get assignedAgent => 'المسند إليه';

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
  String get selectLostReason => 'اختر سبب الخسارة';

  @override
  String get lostReasonControlledRequired => 'اختر سبب خسارة صحيحًا.';

  @override
  String get dealWonRequiresClient => 'يجب ربط الصفقة الناجحة بعميل.';

  @override
  String get dealWonRequiresProperty => 'يجب ربط الصفقة الناجحة بعقار.';

  @override
  String get dealWonRequiresExpectedValue =>
      'يجب أن تحتوي الصفقة الناجحة على قيمة متوقعة أكبر من صفر.';

  @override
  String get dealLostReasonBudgetMismatch => 'عدم توافق الميزانية';

  @override
  String get dealLostReasonLocationMismatch => 'عدم توافق الموقع';

  @override
  String get dealLostReasonBoughtElsewhere => 'اشترى من جهة أخرى';

  @override
  String get dealLostReasonNotReady => 'العميل غير جاهز حاليًا';

  @override
  String get dealLostReasonNoResponse => 'لا يوجد رد من العميل';

  @override
  String get dealLostReasonWrongNumber => 'رقم غير صحيح';

  @override
  String get dealLostReasonLostToCompetitor => 'خسارة لصالح منافس';

  @override
  String get dealLostReasonDuplicate => 'فرصة مكررة';

  @override
  String get dealLostReasonOther => 'سبب آخر';

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
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get uploadProfileImage => 'رفع صورة الملف الشخصي';

  @override
  String get removeProfileImage => 'إزالة صورة الملف الشخصي';

  @override
  String get profileUpdatedSuccessfully => 'تم تحديث الملف الشخصي بنجاح.';

  @override
  String get unableToPickProfileImage =>
      'تعذر اختيار صورة الملف الشخصي. حاول مرة أخرى.';

  @override
  String get fullNameRequired => 'الاسم الكامل مطلوب.';

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
  String get platformDashboard => 'لوحة إدارة المنصة';

  @override
  String get platformDashboardSubtitle =>
      'إدارة وصول الشركات وحالتها وإعداداتها ومستخدميها عبر منصة مسار.';

  @override
  String get platformAdmin => 'مسؤول المنصة';

  @override
  String get platformOverview => 'نظرة عامة';

  @override
  String get platformCompanies => 'الشركات';

  @override
  String get totalCompanies => 'إجمالي الشركات';

  @override
  String get activeCompanies => 'الشركات النشطة';

  @override
  String get inactiveCompanies => 'الشركات غير النشطة';

  @override
  String get trialCompanies => 'الشركات التجريبية';

  @override
  String get recentlyCreatedCompanies => 'أُنشئت حديثاً';

  @override
  String get searchCompanies => 'البحث في الشركات';

  @override
  String get allCompanies => 'كل الشركات';

  @override
  String get noCompaniesFound => 'لم يتم العثور على شركات';

  @override
  String get noCompaniesFoundMessage => 'عدّل البحث أو فلتر الحالة.';

  @override
  String get createCompany => 'إنشاء شركة';

  @override
  String get createCompanySuccess => 'تم إنشاء الشركة بنجاح.';

  @override
  String get addUserSuccess => 'تمت إضافة المستخدم بنجاح.';

  @override
  String get companyName => 'اسم الشركة';

  @override
  String get companyDisplayName => 'الاسم المعروض';

  @override
  String get companyIdSlug => 'معرف الشركة';

  @override
  String get firstAdminFullName => 'اسم أول مسؤول';

  @override
  String get firstAdminEmail => 'بريد أول مسؤول';

  @override
  String get firstAdminPhone => 'هاتف أول مسؤول';

  @override
  String get temporaryPassword => 'كلمة مرور مؤقتة';

  @override
  String get defaultLocale => 'اللغة الافتراضية';

  @override
  String get timezone => 'المنطقة الزمنية';

  @override
  String get companyDetails => 'تفاصيل الشركة';

  @override
  String get companySettings => 'إعدادات الشركة';

  @override
  String get dataHealth => 'صحة البيانات';

  @override
  String get runDataHealthCheck => 'تشغيل فحص صحة البيانات';

  @override
  String get dataHealthNotRun => 'لا يوجد تقرير صحة بيانات بعد';

  @override
  String get dataHealthNotRunMessage =>
      'شغّل فحصًا خاصًا بالشركة لاكتشاف لقطات الإسناد الناقصة والمستخدمين غير المؤهلين.';

  @override
  String get dataHealthClean => 'لم يتم العثور على مشاكل إسناد';

  @override
  String get dataHealthCleanMessage =>
      'السجلات التي تم فحصها متوافقة مع سياسة الإسناد الحالية.';

  @override
  String get dataHealthAffectedRecords => 'السجلات المتأثرة';

  @override
  String get missingSnapshots => 'لقطات ناقصة';

  @override
  String get invalidAssignees => 'مسندون غير صالحين';

  @override
  String get inactiveAssignees => 'مسندون غير نشطين';

  @override
  String get staleTeamSnapshots => 'لقطات فريق قديمة';

  @override
  String get missingAssignee => 'مسند غير موجود';

  @override
  String get safeBackfillAvailable => 'إصلاح آمن';

  @override
  String get manualReview => 'مراجعة يدوية';

  @override
  String get editCompanySettings => 'تعديل إعدادات الشركة';

  @override
  String get saveSettings => 'حفظ الإعدادات';

  @override
  String get settingsSaved => 'تم حفظ الإعدادات بنجاح.';

  @override
  String get companyLimits => 'حدود الشركة';

  @override
  String get companyFeatures => 'ميزات الشركة';

  @override
  String get featureEnabled => 'مفعّلة';

  @override
  String get featureDisabled => 'معطّلة';

  @override
  String get enableFeature => 'تفعيل الميزة';

  @override
  String get disableFeature => 'تعطيل الميزة';

  @override
  String get locale => 'اللغة';

  @override
  String get userLimit => 'حد المستخدمين';

  @override
  String get usersUsed => 'المستخدمون الحاليون';

  @override
  String get userLimitReached =>
      'تم الوصول إلى حد المستخدمين. ارفع الحد قبل إضافة مستخدمين آخرين.';

  @override
  String get storageLimitMb => 'حد التخزين (MB)';

  @override
  String get trial => 'تجريبية';

  @override
  String get auditLogs => 'سجل النشاط';

  @override
  String get previewDashboard => 'معاينة لوحة الشركة';

  @override
  String get readOnlyPreview => 'معاينة فقط';

  @override
  String get companyDashboardPreview => 'معاينة لوحة الشركة';

  @override
  String get platformAccessDenied => 'تم رفض الوصول إلى المنصة.';

  @override
  String get companyUsers => 'مستخدمو الشركة';

  @override
  String get addUser => 'إضافة مستخدم';

  @override
  String get platformSupportAddUser => 'إضافة مستخدم للدعم';

  @override
  String get platformCurrentCompany => 'الشركة الحالية';

  @override
  String get platformDashboardHeroSubtitle =>
      'نظرة شاملة على أداء المنصة وإدارة الشركات والمستخدمين.';

  @override
  String get platformSearchHint => 'بحث في المنصة...';

  @override
  String get platformCompanySelector => 'اختيار الشركة';

  @override
  String get platformSelectedCompany => 'الشركة المحددة';

  @override
  String get platformCompanyFeatures => 'الميزات المفعلة';

  @override
  String get platformStorageUsage => 'استخدام التخزين';

  @override
  String get platformRecentActivity => 'النشاط الأخير';

  @override
  String get platformWorkspaceSummary => 'ملخص بيئة العمل';

  @override
  String get platformViewAllLogs => 'عرض جميع السجلات';

  @override
  String get platformViewAllCompanies => 'عرض جميع الشركات';

  @override
  String get platformNoRecentActivity => 'لا يوجد نشاط حديث بعد';

  @override
  String get platformTotalUsers => 'إجمالي المستخدمين';

  @override
  String get platformAdminsManagers => 'المسؤولون / المديرون';

  @override
  String get platformActiveUsers => 'المستخدمون النشطون';

  @override
  String platformOwnerGreeting(Object name) {
    return 'مساء الخير، $name';
  }

  @override
  String get activateCompany => 'تفعيل الشركة';

  @override
  String get deactivateCompany => 'تعطيل الشركة';

  @override
  String get activateUser => 'تفعيل المستخدم';

  @override
  String get deactivateUser => 'تعطيل المستخدم';

  @override
  String get activateUserConfirmation =>
      'سيتم السماح لهذا المستخدم بالدخول إلى بيئة عمل الشركة مرة أخرى.';

  @override
  String get deactivateUserConfirmation =>
      'سيفقد هذا المستخدم إمكانية الدخول إلى بيئة عمل هذه الشركة. ستظل السجلات الحالية كما هي.';

  @override
  String get noCompanies => 'لا توجد شركات بعد';

  @override
  String get noCompaniesMessage =>
      'أنشئ أول شركة تجريبية بعد تجهيز بيانات التهيئة.';

  @override
  String get noCompanySelected => 'لم يتم تحديد شركة';

  @override
  String get noCompanySelectedMessage =>
      'اختر شركة لعرض المستخدمين والبيانات الأساسية.';

  @override
  String get noCompanyUsers => 'لا يوجد مستخدمون للشركة بعد';

  @override
  String get noCompanyUsersMessage =>
      'أضف أول المستخدمين من خلال دالة Cloud Function الآمنة.';

  @override
  String get connectionTimeout =>
      'تعذر تحميل البيانات. تحقق من الاتصال وحاول مرة أخرى.';

  @override
  String get unableToLoadReports => 'تعذر تحميل التقارير. حاول مرة أخرى.';

  @override
  String get reportsOverview => 'نظرة عامة';

  @override
  String get exportCenter => 'التصدير';

  @override
  String get exportCenterSubtitle =>
      'أنشئ ملفات Excel منظمة بعلامة مسار من بيانات إدارة العملاء المسموح لك بالوصول إليها.';

  @override
  String get exportsFollowRolePermissions => 'كل تصدير يلتزم بصلاحيات دورك.';

  @override
  String get generateExport => 'إنشاء ملف Excel';

  @override
  String get exportReportType => 'نوع التقرير';

  @override
  String get exportGenerateSection => 'إنشاء الملف';

  @override
  String get excel => 'Excel';

  @override
  String get exportLanguage => 'لغة التقرير';

  @override
  String get exportStatusFilter => 'الحالة أو المرحلة';

  @override
  String get allStatuses => 'كل الحالات';

  @override
  String get includeArchivedRecords => 'تضمين السجلات المؤرشفة';

  @override
  String get exportColumns => 'أعمدة الملف';

  @override
  String get recommendedColumns => 'الأعمدة المقترحة';

  @override
  String get advancedColumns => 'اختيار أعمدة متقدم';

  @override
  String get selectedAssignee => 'الموظف المحدد';

  @override
  String get exportReady => 'التصدير جاهز';

  @override
  String get downloadFile => 'تنزيل الملف';

  @override
  String get records => 'سجل';

  @override
  String get exportGeneratedSuccessfully => 'تم إنشاء ملف Excel بنجاح.';

  @override
  String get exportDownloadFailed =>
      'تعذر حفظ ملف Excel على هذا الجهاز. حاول مرة أخرى.';

  @override
  String get androidUpdateTitle => 'تحديث مطلوب';

  @override
  String get androidUpdateBody =>
      'هذا الإصدار من تطبيق أندرويد لم يعد مدعومًا. حدّث مسار CRM للاستمرار في استخدام التطبيق بأمان.';

  @override
  String get androidUpdateButton => 'تحديث التطبيق';

  @override
  String get androidUpdateCurrentVersion => 'الإصدار الحالي';

  @override
  String get androidUpdateLatestVersion => 'آخر إصدار';

  @override
  String get androidUpdateRemainingTime => 'الوقت المتبقي للتحديث';

  @override
  String get androidUpdateExpired =>
      'انتهت مهلة التحديث. يرجى تثبيت أحدث ملف APK.';

  @override
  String get androidUpdateOpenFailed =>
      'تعذر فتح رابط التحديث. يرجى التواصل مع الدعم.';

  @override
  String get androidUpdateChecking => 'جاري التحقق من إصدار التطبيق';

  @override
  String get androidUpdateDownloading => 'جاري تنزيل التحديث';

  @override
  String get androidUpdateDownloadStarting => 'جاري بدء تنزيل التحديث بشكل آمن';

  @override
  String get androidUpdateDownloadFailed =>
      'تعذر تنزيل التحديث. تحقق من الاتصال وحاول مرة أخرى.';

  @override
  String get androidUpdateInvalidPackage =>
      'ملف التحديث الذي تم تنزيله ليس ملف APK صالحًا. تحقق من رابط الإصدار أو تواصل مع الدعم.';

  @override
  String get androidUpdateInstalling => 'جاري فتح مثبت أندرويد';

  @override
  String get androidUpdateReadyToInstall => 'اكتمل التنزيل. مثبت أندرويد جاهز.';

  @override
  String get androidUpdateInstallButton => 'تثبيت التحديث';

  @override
  String get androidUpdateInstallPermissionRequired =>
      'اسمح لتطبيق مسار CRM بتثبيت التحديثات، ثم ارجع واضغط تثبيت التحديث مرة أخرى.';

  @override
  String get checkForUpdates => 'التحقق من التحديثات';

  @override
  String get checkForUpdatesSubtitle =>
      'تحقق هل يعمل هذا الجهاز على أحدث إصدار من مسار CRM.';

  @override
  String get checkingForUpdates => 'جاري التحقق من التحديثات';

  @override
  String get appUpdateAvailableTitle => 'يتوفر تحديث جديد';

  @override
  String get appUpdateAvailableBody =>
      'يتوفر إصدار أحدث من مسار CRM. حدّث الآن للحصول على آخر الإصلاحات والتحسينات.';

  @override
  String get appUpdateRequiredManualBody =>
      'هذا الإصدار لم يعد مدعومًا. حدّث مسار CRM للاستمرار بأمان.';

  @override
  String get appUpdateUpToDate => 'أنت تستخدم أحدث إصدار.';

  @override
  String get appUpdateUnableToCheck =>
      'تعذر التحقق من التحديثات. حاول مرة أخرى.';

  @override
  String get appUpdateLater => 'لاحقًا';

  @override
  String get appUpdateReminderTitle => 'يتوفر تحديث لمسار CRM';

  @override
  String get appUpdateReminderBody =>
      'يتوفر إصدار أحدث من مسار CRM. حدّث الآن للحفاظ على مساحة عملك آمنة ومستقرة.';

  @override
  String get appUpdateOpenUpdater => 'التحديث الآن';

  @override
  String get exportNotAvailableForRole => 'هذا التصدير غير متاح لدورك.';

  @override
  String get teamPerformanceExport => 'أداء الفريق';

  @override
  String get pipelineReportExport => 'تقرير مسار الصفقات';

  @override
  String get followUpReportExport => 'تقرير المتابعات';

  @override
  String get auditSummaryExport => 'ملخص سجل النشاط';

  @override
  String get companyWideExportScope => 'على مستوى الشركة';

  @override
  String get myTeamExportScope => 'فريقي';

  @override
  String get myRecordsExportScope => 'سجلاتي';

  @override
  String get restrictedExportScope => 'محدود';

  @override
  String get lastMonth => 'الشهر الماضي';

  @override
  String get customRange => 'نطاق مخصص';

  @override
  String get product => 'المنتج';

  @override
  String get reportName => 'اسم التقرير';

  @override
  String get scope => 'النطاق';

  @override
  String get dateRange => 'نطاق التاريخ';

  @override
  String get generatedBy => 'تم الإنشاء بواسطة';

  @override
  String get generatedAt => 'وقت الإنشاء';

  @override
  String get recordCount => 'عدد السجلات';

  @override
  String get filtersSummary => 'ملخص الفلاتر';

  @override
  String get field => 'الحقل';

  @override
  String get value => 'القيمة';

  @override
  String get reportSummary => 'ملخص التقرير';

  @override
  String get dataSheet => 'بيانات التقرير';

  @override
  String get exportColumnLeadName => 'اسم العميل المحتمل';

  @override
  String get exportColumnClientName => 'اسم العميل';

  @override
  String get exportColumnDealTitle => 'عنوان الصفقة';

  @override
  String get exportColumnPropertyTitle => 'عنوان العقار';

  @override
  String get budget => 'الميزانية';

  @override
  String get stage => 'المرحلة';

  @override
  String get expectedCloseDate => 'تاريخ الإغلاق المتوقع';

  @override
  String get title => 'العنوان';

  @override
  String get scheduledAt => 'موعد الجدولة';

  @override
  String get type => 'النوع';

  @override
  String get imageCount => 'عدد الصور';

  @override
  String get dealCount => 'عدد الصفقات';

  @override
  String get totalValue => 'إجمالي القيمة';

  @override
  String get averageDealValue => 'متوسط قيمة الصفقة';

  @override
  String get leadsAssigned => 'العملاء المحتملون المسندون';

  @override
  String get convertedLeads => 'العملاء المحتملون المحولون';

  @override
  String get tasksDue => 'المهام المستحقة';

  @override
  String get tasksOverdue => 'المهام المتأخرة';

  @override
  String get appointmentsUpcoming => 'المواعيد القادمة';

  @override
  String get team => 'الفريق';

  @override
  String get action => 'الإجراء';

  @override
  String get recordTitle => 'عنوان السجل';

  @override
  String get actor => 'المنفذ';

  @override
  String get reportPeriod => 'فترة التقرير';

  @override
  String get selectedPeriod => 'الفترة المحددة';

  @override
  String get today => 'اليوم';

  @override
  String get totalDeals => 'إجمالي الصفقات';

  @override
  String get lostDeals => 'الصفقات الخاسرة';

  @override
  String get expectedValueTotal => 'إجمالي القيمة المتوقعة';

  @override
  String get loadedExpectedValueTotal => 'القيمة المتوقعة للسجلات المحملة';

  @override
  String get commissionTotal => 'إجمالي العمولة';

  @override
  String get loadedCommissionTotal => 'عمولة السجلات المحملة';

  @override
  String get dealsByStage => 'الصفقات حسب المرحلة';

  @override
  String get dealPipeline => 'مسار الصفقات';

  @override
  String get pipelineValue => 'قيمة المسار';

  @override
  String get recentDeals => 'أحدث الصفقات';

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
  String get loadedListedValue => 'قيمة العقارات المحملة';

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

  @override
  String get featureUnavailable => 'الميزة غير متاحة';

  @override
  String get featureUnavailableMessage =>
      'تم تعطيل هذه الميزة لهذه الشركة. تواصل مع مالك المنصة لتفعيلها.';

  @override
  String get moduleDisabled => 'القسم معطل';

  @override
  String authRetryCountdown(int seconds) {
    return 'حاول مرة أخرى بعد $seconds ثانية.';
  }

  @override
  String get passwordResetEmailSent =>
      'تم إرسال رابط إعادة تعيين كلمة المرور. تحقق من بريدك الإلكتروني.';

  @override
  String get passwordResetEmailFailed =>
      'تعذر إرسال رابط إعادة تعيين كلمة المرور. حاول مرة أخرى.';

  @override
  String get save => 'حفظ';

  @override
  String get close => 'إغلاق';

  @override
  String get changeEmail => 'تغيير البريد الإلكتروني';

  @override
  String get platformOwnerEmailUpdated =>
      'تم تحديث بريد مالك المنصة الإلكتروني.';

  @override
  String get reauthenticationRequired =>
      'يرجى تسجيل الدخول مرة أخرى ثم تغيير البريد الإلكتروني. يتطلب Firebase تسجيل دخول حديثاً لهذا الإجراء.';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get passwordChangedSuccessfully => 'تم تغيير كلمة المرور بنجاح.';

  @override
  String get passwordChangeFailed => 'تعذر تغيير كلمة المرور. حاول مرة أخرى.';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get currentPasswordRequired => 'كلمة المرور الحالية مطلوبة.';

  @override
  String get currentPasswordIncorrect => 'كلمة المرور الحالية غير صحيحة.';

  @override
  String get recentLoginRequired =>
      'يرجى تسجيل الدخول مرة أخرى قبل تغيير كلمة المرور.';

  @override
  String get newPasswordRequired => 'كلمة المرور الجديدة مطلوبة.';

  @override
  String get newPasswordTooShort =>
      'يجب ألا تقل كلمة المرور الجديدة عن 8 أحرف.';

  @override
  String get passwordMustIncludeLowercase =>
      'يجب أن تحتوي كلمة المرور على حرف إنجليزي صغير واحد على الأقل.';

  @override
  String get passwordMustIncludeUppercase =>
      'يجب أن تحتوي كلمة المرور على حرف إنجليزي كبير واحد على الأقل.';

  @override
  String get passwordMustIncludeNumber =>
      'يجب أن تحتوي كلمة المرور على رقم واحد على الأقل.';

  @override
  String get generateResetLink => 'إنشاء رابط إعادة تعيين';

  @override
  String get resetLinkGenerated => 'تم إنشاء رابط إعادة التعيين.';

  @override
  String get copyResetLink => 'نسخ رابط التعيين';

  @override
  String get resetLinkCopied => 'تم نسخ رابط التعيين.';

  @override
  String get sendThisLinkManuallyToTheUser =>
      'أرسل هذا الرابط للمستخدم يدويًا.';

  @override
  String get platformEmailChanged => 'تم تحديث بريد المستخدم الإلكتروني.';

  @override
  String get platformPasswordChanged =>
      'تم تغيير كلمة مرور المستخدم من المنصة.';

  @override
  String get notAllowedToChangePassword =>
      'غير مسموح لك بتغيير كلمة المرور هذه.';

  @override
  String get lastLogin => 'آخر تسجيل دخول';

  @override
  String get lastLoginDetails => 'تفاصيل آخر تسجيل دخول';

  @override
  String get ipAddress => 'عنوان IP';

  @override
  String get device => 'الجهاز';

  @override
  String get browser => 'المتصفح';

  @override
  String get platform => 'المنصة';

  @override
  String get loginActivity => 'نشاط تسجيل الدخول';

  @override
  String get recentLoginActivity => 'أحدث نشاط تسجيل دخول';

  @override
  String get noLoginActivityYet => 'لا يوجد نشاط تسجيل دخول بعد.';

  @override
  String get security => 'الأمان';

  @override
  String get userSecurity => 'أمان المستخدم';

  @override
  String get teamManagement => 'إدارة الفرق';

  @override
  String get teamManagementSubtitle =>
      'أنشئ فرقًا يقودها المديرون ونظّم مستخدمي المبيعات والتسويق داخل الشركة.';

  @override
  String get teams => 'الفرق';

  @override
  String get myTeam => 'فريقي';

  @override
  String get myTeamSubtitle => 'اعرض فريقك المعيّن وأعضاءه النشطين.';

  @override
  String get createTeam => 'إنشاء فريق';

  @override
  String get editTeam => 'تعديل الفريق';

  @override
  String get teamDetails => 'تفاصيل الفريق';

  @override
  String get teamName => 'اسم الفريق';

  @override
  String get teamDescription => 'وصف الفريق';

  @override
  String get teamManager => 'مدير الفريق';

  @override
  String get teamMembers => 'أعضاء الفريق';

  @override
  String get teamMembersShort => 'أعضاء الفريق';

  @override
  String get addMembers => 'إضافة أعضاء';

  @override
  String get manageMembers => 'إدارة الأعضاء';

  @override
  String get removeMember => 'إزالة عضو';

  @override
  String get moveToTeam => 'نقل إلى فريق';

  @override
  String get unassignedUsers => 'مستخدمون بدون فريق';

  @override
  String get usersWithoutTeam => 'مستخدمون بدون فريق';

  @override
  String get activeTeams => 'الفرق النشطة';

  @override
  String get inactiveTeams => 'الفرق غير النشطة';

  @override
  String get members => 'الأعضاء';

  @override
  String teamMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أعضاء',
      two: 'عضوان',
      one: 'عضو واحد',
      zero: 'لا يوجد أعضاء',
    );
    return '$_temp0';
  }

  @override
  String get managersWithTeams => 'مديرون لديهم فرق';

  @override
  String get noTeamsYet => 'لا توجد فرق بعد';

  @override
  String get noTeamsYetMessage => 'أنشئ أول فريق وعيّن مديرًا نشطًا له.';

  @override
  String get noTeamMembersYet => 'لا يوجد أعضاء في الفريق بعد';

  @override
  String get noTeamMembersYetMessage =>
      'أضف مستخدمي المبيعات أو التسويق إلى هذا الفريق.';

  @override
  String get noTeamAssigned => 'لم يتم تعيين فريق';

  @override
  String get noTeamAssignedMessage => 'اطلب من المسؤول تعيينك مديرًا لفريق.';

  @override
  String get assignManager => 'تعيين مدير';

  @override
  String get changeManager => 'تغيير المدير';

  @override
  String get deactivateTeam => 'تعطيل الفريق';

  @override
  String get activateTeam => 'تفعيل الفريق';

  @override
  String get teamSavedSuccessfully => 'تم حفظ الفريق بنجاح.';

  @override
  String get teamUpdateFailed => 'فشل تحديث الفريق.';

  @override
  String get teamPermissionDenied => 'ليس لديك صلاحية لإدارة أعضاء الفريق.';

  @override
  String get teamSessionExpired =>
      'انتهت جلستك. سجّل الدخول مرة أخرى ثم أعد المحاولة.';

  @override
  String get teamUserInactive =>
      'هذا المستخدم غير نشط. فعّل المستخدم قبل تعيينه في فريق.';

  @override
  String get teamInactive => 'هذا الفريق غير نشط. فعّل الفريق أولًا.';

  @override
  String get teamMemberIneligible =>
      'يمكن إضافة موظفي المبيعات والتسويق فقط كأعضاء في الفريق.';

  @override
  String get teamManagerUnavailable =>
      'يجب أن يكون مدير الفريق مستخدمًا نشطًا بدور مدير.';

  @override
  String get teamManagerAlreadyHasTeam =>
      'هذا المدير مسؤول بالفعل عن فريق نشط.';

  @override
  String get teamUserNotFound =>
      'المستخدم المحدد لم يعد موجودًا. حدّث الصفحة وحاول مرة أخرى.';

  @override
  String get teamNotFound =>
      'الفريق المحدد لم يعد موجودًا. حدّث الصفحة وحاول مرة أخرى.';

  @override
  String get teamCompanyInactive => 'الشركة المحددة غير نشطة.';

  @override
  String get teamCompanyMismatch =>
      'يجب أن يكون المستخدم والفريق داخل نفس الشركة.';

  @override
  String get teamConnectionInterrupted =>
      'انقطع الاتصال. تحقق من الإنترنت ثم حاول مرة أخرى.';

  @override
  String get teamRecordChanged =>
      'تغيرت بيانات الفريق. حدّث الصفحة وحاول مرة أخرى.';

  @override
  String get teamInvalidInput =>
      'راجع الفريق والمستخدم المحددين ثم حاول مرة أخرى.';

  @override
  String get userAddedToTeam => 'تمت إضافة المستخدم إلى الفريق.';

  @override
  String get userRemovedFromTeam => 'تمت إزالة المستخدم من الفريق.';

  @override
  String get searchTeams => 'البحث في الفرق';

  @override
  String get noManagersAvailable => 'لا يوجد مديرون متاحون';

  @override
  String get noManagersAvailableMessage =>
      'أضف مستخدمًا نشطًا بدور مدير قبل إنشاء فريق.';

  @override
  String get noUnassignedUsers => 'لا يوجد مستخدمون مؤهلون';

  @override
  String get noUnassignedUsersMessage =>
      'مستخدمو المبيعات والتسويق معيّنون بالفعل أو غير متاحين.';

  @override
  String get backfillSnapshots => 'إصلاح اللقطات';

  @override
  String get dataHealthRepairSuccess => 'تم إصلاح اللقطات بنجاح.';

  @override
  String get companyDataHealthMessage =>
      'أدوات مسؤول الشركة لإصلاح الإسناد غير الصحيح ولقطات الفريق القديمة.';

  @override
  String get reassignRecord => 'إعادة إسناد السجل';

  @override
  String get notifyManager => 'إشعار المدير';

  @override
  String get noManagerForDataHealthIssue =>
      'لا يوجد مدير مسؤول متاح لهذه المشكلة.';

  @override
  String get managerNotificationSent => 'تم إشعار المدير بنجاح.';

  @override
  String get notificationsComingSoon => 'الإشعارات غير متاحة حالياً.';

  @override
  String get noEligibleAssignees => 'لا يوجد مستخدمون مؤهلون';

  @override
  String get noEligibleAssigneesMessage =>
      'لا يوجد مستخدمون نشطون ومؤهلون لهذا النوع من السجلات.';

  @override
  String get dataHealthReassignSuccess => 'تمت إعادة إسناد السجل بنجاح.';

  @override
  String get companyAdminActionRequired => 'يتطلب إجراء من مسؤول الشركة.';

  @override
  String get notificationCenter => 'مركز الإشعارات';

  @override
  String notificationCenterSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إشعارات غير مقروءة',
      one: 'إشعار واحد غير مقروء',
      zero: 'لا توجد إشعارات غير مقروءة',
    );
    return '$_temp0';
  }

  @override
  String get all => 'الكل';

  @override
  String get unread => 'غير مقروء';

  @override
  String get attention => 'الانتباه';

  @override
  String get system => 'النظام';

  @override
  String get open => 'فتح';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get markRead => 'تحديد كمقروء';

  @override
  String get markAllRead => 'تحديد الكل كمقروء';

  @override
  String get attentionNeeded => 'يحتاج إلى انتباه';

  @override
  String get noNotificationsYet => 'لا توجد إشعارات حتى الآن';

  @override
  String get noNotificationsYetMessage =>
      'ستظهر هنا تحديثات الإسناد والتنبيهات المهمة.';

  @override
  String get notificationDataRepairNeededTitle =>
      'تحتاج بيانات الإشعارات إلى إصلاح';

  @override
  String get notificationDataRepairNeededMessage =>
      'بعض الإشعارات تحتاج إلى إصلاح بياناتها. ستظهر الإشعارات الجديدة بعد النشاط التالي.';

  @override
  String get notificationStreamError => 'تعذر تحميل الإشعارات. حاول مرة أخرى.';

  @override
  String get noUrgentReminders => 'لا توجد تنبيهات عاجلة';

  @override
  String get noUrgentRemindersMessage =>
      'ستظهر هنا الأعمال المستحقة والمتأخرة عند الحاجة للمتابعة.';

  @override
  String get notificationLeadAssignedTitle => 'تم تعيين عميل محتمل جديد لك';

  @override
  String get notificationLeadReassignedTitle => 'تم إعادة تعيين عميل محتمل لك';

  @override
  String get notificationLeadRemovedFromYouTitle =>
      'تمت إزالة العميل المحتمل من قائمتك';

  @override
  String get notificationTaskAssignedTitle => 'تم تعيين مهمة جديدة لك';

  @override
  String get notificationTaskReassignedTitle => 'تم إعادة تعيين مهمة لك';

  @override
  String get notificationTaskRemovedFromYouTitle => 'تمت إزالة المهمة من عملك';

  @override
  String get notificationClientAssignedTitle => 'تم تعيين عميل جديد لك';

  @override
  String get notificationClientReassignedTitle => 'تم إعادة تعيين عميل لك';

  @override
  String get notificationClientRemovedFromYouTitle =>
      'تمت إزالة العميل من قائمتك';

  @override
  String get notificationDealAssignedTitle => 'تم تعيين صفقة جديدة لك';

  @override
  String get notificationDealReassignedTitle => 'تم إعادة تعيين صفقة لك';

  @override
  String get notificationDealRemovedFromYouTitle =>
      'تمت إزالة الصفقة من قائمتك';

  @override
  String get notificationLeadImportantStatusChangedTitle =>
      'تغيرت حالة عميل محتمل مهمة';

  @override
  String get notificationDealStageChangedTitle => 'تغيرت مرحلة الصفقة';

  @override
  String get notificationDealImportantStatusChangedTitle =>
      'تغيرت حالة صفقة مهمة';

  @override
  String get notificationDealWonTitle => 'تم كسب الصفقة';

  @override
  String get notificationDealLostTitle => 'تم خسارة الصفقة';

  @override
  String get notificationTaskStatusChangedTitle => 'تغيرت حالة المهمة';

  @override
  String get notificationTeamMemberAssignedTitle => 'إسناد ضمن الفريق';

  @override
  String get notificationTeamMemberReassignedTitle => 'إعادة إسناد ضمن الفريق';

  @override
  String get notificationTeamMemberRemovedTitle => 'إزالة إسناد ضمن الفريق';

  @override
  String get notificationTeamLeadStatusChangedTitle =>
      'تغيرت حالة عميل محتمل في فريقك';

  @override
  String get notificationTeamDealStageChangedTitle =>
      'تغيرت مرحلة صفقة في فريقك';

  @override
  String get notificationTeamTaskStatusChangedTitle =>
      'تغيرت حالة مهمة في فريقك';

  @override
  String get notificationGenericStatusChangedTitle => 'تغيرت الحالة';

  @override
  String get notificationFollowUpDueTodayTitle => 'متابعة مستحقة اليوم';

  @override
  String get notificationFollowUpOverdueTitle => 'متابعة متأخرة';

  @override
  String get notificationTaskDueTodayTitle => 'مهمة مستحقة اليوم';

  @override
  String get notificationTaskOverdueTitle => 'مهمة متأخرة';

  @override
  String get notificationSystemInfoTitle => 'إشعار من النظام';

  @override
  String get notificationDataHealthIssueTitle =>
      'صحة البيانات تحتاج إلى انتباه';

  @override
  String notificationDataHealthIssueBody(Object record, Object issue) {
    return '$record يحتاج إلى مراجعة: $issue.';
  }

  @override
  String get notificationGenericTitle => 'إشعار من نظام CRM';

  @override
  String get notificationUnassignedLeadTitle =>
      'عميل محتمل غير مسند يحتاج إلى متابعة';

  @override
  String get notificationRecordFallback => 'السجل';

  @override
  String get notificationSystemModule => 'النظام';

  @override
  String notificationRecordBody(Object record) {
    return '$record يحتاج إلى انتباهك.';
  }

  @override
  String notificationRecordByActorBody(Object record, Object actor) {
    return 'تم تحديث $record بواسطة $actor.';
  }

  @override
  String notificationRecordNoLongerAssignedBody(Object record) {
    return 'لم يعد $record مسندًا إليك.';
  }

  @override
  String notificationGenericBody(Object record) {
    return 'افتح $record لمراجعة آخر تحديث.';
  }

  @override
  String notificationReminderAssignedBody(Object record, Object assignee) {
    return '$record مسند إلى $assignee.';
  }

  @override
  String notificationUnassignedLeadBody(Object record) {
    return '$record لا يزال غير مسند.';
  }

  @override
  String notificationStatusChangedBody(Object record, Object status) {
    return 'تغير $record إلى $status.';
  }

  @override
  String notificationStatusChangedByActorBody(
    Object record,
    Object status,
    Object actor,
  ) {
    return 'تغير $record إلى $status بواسطة $actor.';
  }

  @override
  String notificationTeamMemberAssignedBody(Object record, Object member) {
    return 'تم إسناد $record إلى $member.';
  }

  @override
  String notificationTeamMemberAssignedByActorBody(
    Object record,
    Object member,
    Object actor,
  ) {
    return 'قام $actor بإسناد $record إلى $member.';
  }

  @override
  String notificationTeamMemberReassignedBody(
    Object record,
    Object oldMember,
    Object newMember,
  ) {
    return 'تم نقل $record من $oldMember إلى $newMember.';
  }

  @override
  String notificationTeamMemberReassignedByActorBody(
    Object record,
    Object oldMember,
    Object newMember,
    Object actor,
  ) {
    return 'قام $actor بنقل $record من $oldMember إلى $newMember.';
  }

  @override
  String notificationTeamMemberRemovedBody(Object record, Object member) {
    return 'تمت إزالة $member من $record.';
  }

  @override
  String notificationTeamMemberRemovedByActorBody(
    Object record,
    Object member,
    Object actor,
  ) {
    return 'قام $actor بإزالة $member من $record.';
  }

  @override
  String get notificationRouteUnavailable =>
      'هذا العنصر لم يعد متاحًا أو لا تملك صلاحية الوصول إليه.';

  @override
  String get notificationPermissionPromptTitle => 'تفعيل الإشعارات';

  @override
  String get notificationPermissionPromptBody =>
      'اسمح لمسار CRM بإرسال التكليفات والمواعيد والمتابعات العاجلة حتى خارج التطبيق.';

  @override
  String get notificationPermissionEnableAction => 'تفعيل';

  @override
  String get notificationPermissionUnavailableBody =>
      'الإشعارات غير مفعّلة بعد. اسمح بها من المتصفح أو الجهاز ثم حاول مرة أخرى.';

  @override
  String get notificationPermissionSyncFailedBody =>
      'تم السماح بالإشعارات، لكن تعذر حفظ رمز الجهاز. تحقق من الاتصال وحاول مرة أخرى.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get notificationsUnavailableInPlatform =>
      'إشعارات مبيعات الشركات غير متاحة في وضع المنصة.';

  @override
  String get appointments => 'المواعيد';

  @override
  String get appointmentsSubtitle =>
      'نظم المعاينات والاجتماعات والمكالمات ومتابعات الصفقات في جدول واحد مضبوط.';

  @override
  String get newAppointment => 'موعد جديد';

  @override
  String get editAppointment => 'تعديل الموعد';

  @override
  String get appointmentDetails => 'تفاصيل الموعد';

  @override
  String get appointmentTitle => 'عنوان الموعد';

  @override
  String get appointmentType => 'نوع الموعد';

  @override
  String get appointmentSchedule => 'الجدولة';

  @override
  String get appointmentNotes => 'الملاحظات والنتيجة';

  @override
  String get outcomeNotes => 'ملاحظات النتيجة';

  @override
  String get appointmentTime => 'الوقت';

  @override
  String get duration => 'المدة';

  @override
  String durationMinutes(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String get selectAppointmentDate => 'اختر التاريخ';

  @override
  String get selectStartTime => 'اختر وقت البداية';

  @override
  String get saveAppointment => 'حفظ الموعد';

  @override
  String get updateAppointment => 'تحديث الموعد';

  @override
  String get appointmentDateRequired => 'اختر تاريخ الموعد ووقت البداية.';

  @override
  String get appointmentDurationRequired =>
      'يجب أن تكون مدة الموعد أكبر من صفر.';

  @override
  String get appointmentAssigneeRequired => 'اختر المستخدم المسؤول قبل الحفظ.';

  @override
  String get appointmentEndAfterStartRequired =>
      'يجب أن يكون وقت نهاية الموعد بعد وقت البداية.';

  @override
  String get appointmentSaved => 'تم حفظ الموعد.';

  @override
  String get appointmentUpdated => 'تم تحديث الموعد.';

  @override
  String get appointmentCancelled => 'تم إلغاء الموعد.';

  @override
  String get appointmentCompleted => 'تم إكمال الموعد.';

  @override
  String get appointmentMissed => 'تم تسجيل الموعد كفائت.';

  @override
  String get appointmentRescheduled => 'تمت إعادة جدولة الموعد.';

  @override
  String get appointmentNotFound => 'لم يتم العثور على الموعد.';

  @override
  String get appointmentAttention => 'تنبيهات المواعيد';

  @override
  String get appointmentCalendarTodayView => 'اليوم';

  @override
  String get appointmentCalendarMonthView => 'الشهر';

  @override
  String get appointmentCalendarWeekView => 'الأسبوع';

  @override
  String get appointmentCalendarDayView => 'يوم محدد';

  @override
  String get todayAgenda => 'جدول اليوم';

  @override
  String get appointmentAgenda => 'جدول المواعيد';

  @override
  String get noAppointmentsToday => 'لا توجد مواعيد اليوم';

  @override
  String get noAppointmentsForSelectedDay => 'لا توجد مواعيد في هذا اليوم';

  @override
  String get openLinkedRecord => 'فتح السجل المرتبط';

  @override
  String get currentAppointmentTime => 'الوقت الحالي';

  @override
  String get appointmentOutcome => 'نتيجة الموعد';

  @override
  String get cancellationReason => 'سبب الإلغاء';

  @override
  String get cancellationReasonRequired => 'اكتب سبب الإلغاء.';

  @override
  String get todaysAppointments => 'مواعيد اليوم';

  @override
  String get upcomingAppointments => 'المواعيد القادمة';

  @override
  String get missedAppointments => 'المواعيد الفائتة';

  @override
  String get noMissedAppointments => 'لا توجد مواعيد فائتة.';

  @override
  String get completedAppointments => 'المواعيد المكتملة';

  @override
  String get cancelledAppointments => 'المواعيد الملغاة';

  @override
  String get rescheduledAppointments => 'المواعيد المعاد جدولتها';

  @override
  String get searchAppointments => 'بحث في المواعيد';

  @override
  String get filterByDate => 'تصفية حسب التاريخ';

  @override
  String get filterByStatus => 'تصفية حسب الحالة';

  @override
  String get filterByType => 'تصفية حسب النوع';

  @override
  String get allAppointments => 'كل المواعيد';

  @override
  String get allAppointmentTypes => 'كل الأنواع';

  @override
  String get noAppointmentsYet => 'لا توجد مواعيد بعد';

  @override
  String get createFirstAppointment => 'أنشئ أول موعد';

  @override
  String get noAppointmentsMatchFilters => 'لا توجد مواعيد تطابق عوامل التصفية';

  @override
  String get completeAppointment => 'إكمال الموعد';

  @override
  String get cancelAppointment => 'إلغاء الموعد';

  @override
  String get markMissed => 'تسجيل كفائت';

  @override
  String get reschedule => 'إعادة جدولة';

  @override
  String get cancelAppointmentConfirmation =>
      'هل تريد إلغاء هذا الموعد؟ سيبقى السجل محفوظًا في التاريخ.';

  @override
  String get completeAppointmentConfirmation => 'أنهِ هذا الموعد وسجّل نتيجته.';

  @override
  String get markMissedConfirmation => 'هل تريد تسجيل هذا الموعد كموعد فائت؟';

  @override
  String get appointmentOutcomeSuccessfulMeeting => 'اجتماع ناجح';

  @override
  String get appointmentOutcomeNoAnswer => 'لا يوجد رد';

  @override
  String get appointmentOutcomeClientPostponed => 'العميل أجّل الموعد';

  @override
  String get appointmentOutcomeClientNotInterested => 'العميل غير مهتم';

  @override
  String get appointmentOutcomeFollowUpNeeded => 'تحتاج متابعة';

  @override
  String get appointmentOutcomeDealOpportunity => 'فرصة صفقة';

  @override
  String get appointmentOutcomeOther => 'أخرى';

  @override
  String get appointmentFutureTimeRequired => 'اختر وقت موعد في المستقبل.';

  @override
  String get recordAppointmentOutcome => 'تسجيل نتيجة الموعد';

  @override
  String get appointmentCompletedOutcomePromptMessage =>
      'تم إكمال الموعد. سجّل النتيجة الآن، أو أضفها لاحقًا إذا كنت تحتاج إلى تأكيد التفاصيل.';

  @override
  String get addAppointmentOutcomeLater => 'لاحقًا';

  @override
  String get appointmentOutcomePendingDecision => 'في انتظار قرار';

  @override
  String get appointmentOutcomeHintSuccessfulMeeting =>
      'الاجتماع نجح. سجّل الالتزام التالي بوضوح.';

  @override
  String get appointmentOutcomeHintNoAnswer =>
      'لم يتم الرد. أعد التواصل أو أعد الجدولة للحفاظ على فرصة التحويل.';

  @override
  String get appointmentOutcomeHintClientPostponed =>
      'العميل أجّل الموعد. اتفق على موعد جديد وسجّل المتابعة التالية.';

  @override
  String get appointmentOutcomeHintClientNotInterested =>
      'العميل غير مهتم. سجّل السبب أو حدّد متابعة لاحقة إذا ما زالت هناك فرصة.';

  @override
  String get appointmentOutcomeHintFollowUpNeeded =>
      'هناك متابعة مطلوبة. حدّد الخطوة التالية حتى تبقى الفرصة تحت المتابعة.';

  @override
  String get appointmentOutcomeHintDealOpportunity =>
      'يمكن تحويل هذا إلى صفقة. أنشئ الصفقة أو حدّثها بعد حفظ النتيجة.';

  @override
  String get appointmentOutcomeHintPendingDecision =>
      'العميل يحتاج موعدًا واضحًا لاتخاذ القرار. حدّد متابعة واجعل الخطوة التالية واضحة.';

  @override
  String get appointmentOutcomeHintOther =>
      'سجّل النتيجة الفعلية بوضوح حتى تبقى الخطوة التالية دقيقة.';

  @override
  String get appointmentTypeCall => 'مكالمة';

  @override
  String get appointmentTypeMeeting => 'اجتماع';

  @override
  String get appointmentTypePropertyViewing => 'معاينة عقار';

  @override
  String get appointmentTypeSiteVisit => 'زيارة موقع';

  @override
  String get appointmentTypeContractMeeting => 'اجتماع عقد';

  @override
  String get appointmentTypeReservationMeeting => 'اجتماع حجز';

  @override
  String get appointmentTypeFollowUp => 'متابعة';

  @override
  String get appointmentTypeOther => 'أخرى';

  @override
  String get appointmentStatusScheduled => 'مجدول';

  @override
  String get appointmentStatusCompleted => 'مكتمل';

  @override
  String get appointmentStatusCancelled => 'ملغى';

  @override
  String get appointmentStatusMissed => 'فائت';

  @override
  String get appointmentStatusRescheduled => 'معاد جدولته';

  @override
  String get notificationAppointmentAssignedTitle => 'تم إسناد موعد جديد';

  @override
  String get notificationAppointmentReassignedTitle =>
      'تمت إعادة إسناد موعد إليك';

  @override
  String get notificationAppointmentRemovedFromYouTitle =>
      'تمت إزالة موعد من جدولك';

  @override
  String get notificationAppointmentRescheduledTitle => 'تمت إعادة جدولة موعد';

  @override
  String get notificationAppointmentCancelledTitle => 'تم إلغاء موعد';

  @override
  String get notificationAppointmentCompletedTitle => 'تم إكمال موعد';

  @override
  String get notificationAppointmentMissedTitle => 'موعد فائت';

  @override
  String get notificationAppointmentTodayAttentionTitle => 'موعد اليوم';

  @override
  String get notificationAppointmentDueNowTitle => 'الموعد مستحق الآن';

  @override
  String get notificationAppointmentDueSoonTitle => 'موعد خلال 10 دقائق';

  @override
  String get notificationAppointmentMissedAttentionTitle => 'موعد فائت';

  @override
  String get notificationAppointmentUpcomingSoonTitle => 'موعد قريب';

  @override
  String get notificationTeamAppointmentAssignedTitle =>
      'تم إسناد موعد داخل الفريق';

  @override
  String get notificationTeamAppointmentReassignedTitle =>
      'تمت إعادة إسناد موعد داخل الفريق';

  @override
  String get notificationTeamAppointmentDueNowTitle =>
      'موعد مستحق الآن في الفريق';

  @override
  String get notificationTeamAppointmentDueSoonTitle =>
      'موعد فريق خلال 10 دقائق';

  @override
  String get notificationTeamAppointmentRescheduledTitle =>
      'تمت إعادة جدولة موعد في الفريق';

  @override
  String get notificationTeamAppointmentCancelledTitle =>
      'تم إلغاء موعد في الفريق';

  @override
  String get notificationTeamAppointmentCompletedTitle =>
      'تم إكمال موعد في الفريق';

  @override
  String get notificationTeamAppointmentMissedTitle => 'موعد فائت في الفريق';

  @override
  String get invitations => 'الدعوات';

  @override
  String get createInvitation => 'إنشاء دعوة';

  @override
  String get invitationCode => 'رمز الدعوة';

  @override
  String get invitationLink => 'رابط الدعوة';

  @override
  String get copyCode => 'نسخ الرمز';

  @override
  String get copyLink => 'نسخ الرابط';

  @override
  String get revokeInvitation => 'إلغاء الدعوة';

  @override
  String get invitationActive => 'دعوة نشطة';

  @override
  String get invitationUsed => 'دعوة مستخدمة';

  @override
  String get invitationExpired => 'دعوة منتهية';

  @override
  String get invitationRevoked => 'دعوة ملغاة';

  @override
  String get expiresAt => 'تنتهي في';

  @override
  String get plan => 'الخطة';

  @override
  String get planId => 'معرف الخطة';

  @override
  String get features => 'الميزات';

  @override
  String get allowedAdminEmail => 'بريد المسؤول المسموح';

  @override
  String get manualSupportSetup => 'إعداد يدوي للدعم';

  @override
  String get invitationOnboarding => 'التسجيل بالدعوة';

  @override
  String get companyAdminInvitation => 'دعوة مسؤول الشركة';

  @override
  String get invitationOnboardingNote =>
      'يتيح التسجيل بالدعوة لمسؤول الشركة إنشاء بيئة عمل شركته بنفسه. يظل الإعداد اليدوي متاحاً لحالات الدعم.';

  @override
  String get noInvitationsYet => 'لا توجد دعوات بعد';

  @override
  String get noInvitationsYetMessage =>
      'أنشئ رمز دعوة لمسؤول الشركة المشتركة التالية.';

  @override
  String get invitationCreated =>
      'تم إنشاء الدعوة. انسخ الرمز أو الرابط الآن؛ يظهر الرمز الكامل مرة واحدة فقط.';

  @override
  String get invitationCodeCopied => 'تم نسخ رمز الدعوة.';

  @override
  String get invitationLinkCopied => 'تم نسخ رابط الدعوة.';

  @override
  String get expiresInDays => 'تنتهي بعد أيام';

  @override
  String get registerYourCompany => 'سجّل شركتك';

  @override
  String get enterInvitationCode => 'أدخل رمز الدعوة';

  @override
  String get validateInvitation => 'تحقق من الدعوة';

  @override
  String get invitationValid => 'الدعوة صالحة';

  @override
  String get invitationInvalid => 'الدعوة غير صالحة';

  @override
  String get adminAccount => 'حساب المسؤول';

  @override
  String get reviewAndCreate => 'مراجعة وإنشاء';

  @override
  String get createWorkspace => 'إنشاء بيئة العمل';

  @override
  String get companyEmail => 'بريد الشركة';

  @override
  String get companyPhone => 'هاتف الشركة';

  @override
  String get cityLocation => 'المدينة/الموقع';

  @override
  String get preferredLanguage => 'اللغة المفضلة';

  @override
  String get adminFullName => 'اسم المسؤول الكامل';

  @override
  String get adminEmail => 'بريد المسؤول';

  @override
  String get adminPhone => 'هاتف المسؤول';

  @override
  String get companyRegistrationCompleted => 'اكتمل تسجيل الشركة.';

  @override
  String get invitationAlreadyUsed => 'الدعوة مستخدمة بالفعل';

  @override
  String get companyIdAlreadyExists => 'معرف الشركة موجود بالفعل';

  @override
  String get companyIdInvalid =>
      'يجب أن يستخدم معرف الشركة حروفاً إنجليزية صغيرة وأرقاماً وشرطات أو شرطات سفلية.';

  @override
  String get next => 'التالي';

  @override
  String get onboardingTitle =>
      'من العميل المحتمل إلى الصفقة، أدِر منظومة مبيعاتك العقارية من مكان واحد.';

  @override
  String get onboardingSubtitle =>
      'يربط مسار الفرق والعملاء المحتملين والعقارات والمواعيد والإشعارات والتقارير داخل بيئة عمل الشركة آمنة.';

  @override
  String get onboardingOperationsTitle => 'بيئة تشغيل CRM عملية';

  @override
  String get onboardingOperationsMessage =>
      'أدر العملاء المحتملين والعملاء والعقارات والمهام والصفقات والمواعيد بصلاحيات دقيقة حسب الدور.';

  @override
  String get onboardingInvitationTitle => 'تأسيس الشركة برمز دعوة';

  @override
  String get onboardingInvitationMessage =>
      'استخدم رمز الدعوة لإنشاء بيئة عمل الشركة والبدء كأول مسؤول للشركة.';

  @override
  String get onboardingAnalyticsTitle => 'لوحات وتقارير مباشرة';

  @override
  String get onboardingAnalyticsMessage =>
      'تابع أداء الفرق والعمل المستحق والمواعيد ونشاط المبيعات من لوحات احترافية.';

  @override
  String get signInExistingAccount => 'تسجيل الدخول لحساب موجود';

  @override
  String get createAdminWorkspace => 'إنشاء بيئة عمل الشركة';

  @override
  String get companyIdGeneratedAutomatically =>
      'يتم إنشاء معرف الشركة تلقائياً';

  @override
  String get companyIdGeneratedMessage => 'سيتم إنشاؤه من اسم الشركة.';

  @override
  String get invalidPhone => 'أدخل رقم هاتف صحيحاً.';

  @override
  String get invalidUrl => 'أدخل رابط موقع صحيح يبدأ بـ http:// أو https://.';

  @override
  String get invalidName => 'أدخل اسماً صحيحاً.';

  @override
  String get userManagement => 'إدارة المستخدمين';

  @override
  String get userManagementSubtitle =>
      'أنشئ المديرين وموظفي المبيعات والتسويق والمشاهدين لهذه الشركة.';

  @override
  String get createUser => 'إنشاء مستخدم';

  @override
  String get searchUsers => 'البحث في المستخدمين';

  @override
  String get companyUsersEmptyMessage =>
      'أنشئ أول مستخدم أو مدير في الشركة من هذه الصفحة.';

  @override
  String get userCreatedResetLinkTitle => 'تم إنشاء المستخدم';

  @override
  String get userCreatedSuccessfully => 'تم إنشاء المستخدم بنجاح';

  @override
  String get sendSetupLinkToUser =>
      'أرسل هذا الرابط للمستخدم ليقوم بتعيين كلمة المرور.';

  @override
  String get copySetupLink => 'نسخ الرابط';

  @override
  String get openSetupLink => 'فتح الرابط';

  @override
  String get linkCopied => 'تم نسخ الرابط.';

  @override
  String get generateSetupLink => 'إنشاء رابط تعيين كلمة المرور';

  @override
  String get done => 'تم';

  @override
  String get userCreatedNoResetLinkMessage =>
      'تم إنشاء المستخدم، لكن لم يتم إرجاع رابط تعيين كلمة المرور.';

  @override
  String get companyUserAlreadyExists => 'هذا المستخدم موجود بالفعل في الشركة.';

  @override
  String get registrationInvitationInvalid => 'هذه الدعوة لم تعد صالحة.';

  @override
  String get registrationInvitationExpired => 'انتهت صلاحية هذه الدعوة.';

  @override
  String get registrationInvitationUsed => 'تم استخدام هذه الدعوة بالفعل.';

  @override
  String get registrationInvitationRevoked => 'تم إلغاء هذه الدعوة.';

  @override
  String get registrationInvitationLimitReached =>
      'وصلت هذه الدعوة إلى حد الاستخدام.';

  @override
  String get adminEmailAlreadyExists => 'جرّب بريدًا آخر للمسؤول.';

  @override
  String get companyNameAlreadyRegistered =>
      'اسم الشركة مستخدم بالفعل. جرّب اسماً آخر.';

  @override
  String get weakPassword =>
      'يجب أن تكون كلمة المرور 8 أحرف على الأقل وأن تحتوي على حرف كبير وحرف صغير ورقم.';

  @override
  String get emailPasswordAuthDisabled =>
      'تسجيل الدخول بالبريد وكلمة المرور غير مفعّل. تواصل مع مالك المنصة.';

  @override
  String get unableToCreateAdminUser =>
      'تعذر إنشاء مستخدم المسؤول. راجع البيانات وحاول مرة أخرى.';

  @override
  String get unableToCreateWorkspace =>
      'تعذر إنشاء بيئة العمل. راجع البيانات وحاول مرة أخرى.';

  @override
  String get unableToCompleteRegistration =>
      'تعذر إكمال التسجيل. حاول مرة أخرى لاحقاً.';

  @override
  String get registrationConflict =>
      'التسجيل قيد التنفيذ بالفعل أو تم إنشاء بيئة العمل للتو. حاول مرة أخرى.';

  @override
  String get createYourAdminPassword => 'أنشئ كلمة مرور المسؤول';

  @override
  String get adminPasswordHelp =>
      'سيتم استخدام كلمة المرور هذه لتسجيل الدخول كمسؤول للشركة.';

  @override
  String get companyAdminPassword => 'كلمة مرور مسؤول الشركة';

  @override
  String get confirmCompanyAdminPassword => 'تأكيد كلمة مرور مسؤول الشركة';

  @override
  String get notificationsDisabledForCompany =>
      'تم تعطيل الإشعارات لهذه الشركة.';

  @override
  String get featureNotEnabledForWorkspace =>
      'هذه الميزة غير مفعّلة لبيئة عملك.';

  @override
  String get errorOccurred => 'حدث خطأ';

  @override
  String get skip => 'تخطي';

  @override
  String get setTemporaryPassword => 'تعيين كلمة مرور مؤقتة';

  @override
  String get confirmTemporaryPassword => 'تأكيد كلمة المرور المؤقتة';

  @override
  String get temporaryPasswordHelp =>
      'اختياري. يمكن للمستخدم تسجيل الدخول بكلمة المرور المؤقتة ويجب عليه تغييرها من الإعدادات بعد أول دخول.';

  @override
  String get temporaryPasswordCreatedMessage =>
      'تم إنشاء المستخدم بكلمة مرور مؤقتة. أرسل كلمة المرور المؤقتة بشكل آمن واطلب من المستخدم تغييرها بعد أول دخول.';

  @override
  String get mustChangePassword => 'يجب تغيير كلمة المرور';

  @override
  String get temporaryPasswordChangeRequiredTitle => 'أنشئ كلمة مرور جديدة';

  @override
  String get temporaryPasswordChangeRequiredMessage =>
      'أنت تستخدم كلمة مرور مؤقتة. أنشئ كلمة مرور جديدة قبل المتابعة إلى مسار CRM.';

  @override
  String get updatePasswordAndContinue => 'تحديث كلمة المرور والمتابعة';

  @override
  String get supportCenter => 'مركز الدعم';

  @override
  String get supportCenterSubtitle =>
      'أرسل طلبات الدعم أو ملاحظات المنتج من داخل بيئة العمل.';

  @override
  String get contactSupport => 'التواصل مع الدعم';

  @override
  String get contactSupportSubtitle =>
      'أنشئ طلب دعم مع إرفاق الصفحة والإصدار وسياق بيئة العمل تلقائياً.';

  @override
  String get sendFeedback => 'إرسال ملاحظة';

  @override
  String get sendFeedbackSubtitle =>
      'شارك ملاحظة سريعة عن المنتج بدون فتح طلب دعم كامل.';

  @override
  String get myRequests => 'طلباتي';

  @override
  String get supportTitle => 'العنوان';

  @override
  String get supportMessage => 'الرسالة';

  @override
  String get supportCategory => 'الفئة';

  @override
  String get supportPriority => 'الأولوية';

  @override
  String get feedbackRating => 'التقييم';

  @override
  String get feedbackCategory => 'فئة الملاحظة';

  @override
  String get feedbackMessage => 'نص الملاحظة';

  @override
  String get submitSupportRequest => 'إرسال الطلب';

  @override
  String get submitFeedback => 'إرسال الملاحظة';

  @override
  String get supportTicketCreated => 'تم إرسال طلب الدعم.';

  @override
  String get feedbackSubmitted => 'تم إرسال الملاحظة.';

  @override
  String get supportNoRequestsTitle => 'لا توجد طلبات بعد';

  @override
  String get supportNoRequestsMessage =>
      'ستظهر طلبات الدعم والملاحظات المرسلة هنا.';

  @override
  String get supportCategoryAccountLogin => 'الحساب وتسجيل الدخول';

  @override
  String get supportCategoryUsersPermissions => 'المستخدمون والصلاحيات';

  @override
  String get supportCategoryBillingSubscription => 'الفوترة والاشتراك';

  @override
  String get supportCategoryBug => 'خلل';

  @override
  String get feedbackCategorySuggestion => 'اقتراح';

  @override
  String get feedbackCategoryUiImprovement => 'تحسين الواجهة';

  @override
  String get feedbackCategoryMissingFeature => 'ميزة ناقصة';

  @override
  String get feedbackCategoryConfusingBehavior => 'سلوك غير واضح';

  @override
  String get feedbackCategoryPerformance => 'الأداء';

  @override
  String get feedbackCategoryGeneralFeedback => 'ملاحظة عامة';

  @override
  String get supportPriorityLow => 'منخفضة';

  @override
  String get supportPriorityNormal => 'عادية';

  @override
  String get supportPriorityUrgent => 'عاجلة';

  @override
  String get supportStatusOpen => 'مفتوح';

  @override
  String get supportStatusInReview => 'قيد المراجعة';

  @override
  String get supportStatusWaitingForUser => 'بانتظار المستخدم';

  @override
  String get supportStatusResolved => 'تم الحل';

  @override
  String get supportStatusClosed => 'مغلق';

  @override
  String get platformSupportInbox => 'صندوق الدعم';

  @override
  String get supportOpenTickets => 'طلبات مفتوحة';

  @override
  String get supportUrgentTickets => 'طلبات عاجلة';

  @override
  String get supportFeedbackCount => 'الملاحظات';

  @override
  String get supportResolvedThisMonth => 'تم حلها هذا الشهر';

  @override
  String get searchSupportRequests => 'البحث في الدعم';

  @override
  String get requestType => 'النوع';

  @override
  String get allTypes => 'كل الأنواع';

  @override
  String get requestTypeSupport => 'دعم';

  @override
  String get requestTypeFeedback => 'ملاحظة';

  @override
  String get allCategories => 'كل الفئات';

  @override
  String get supportDetails => 'تفاصيل الطلب';

  @override
  String get updateStatus => 'تحديث الحالة';

  @override
  String get supportStatusUpdated => 'تم تحديث الحالة.';

  @override
  String get company => 'الشركة';

  @override
  String get user => 'المستخدم';

  @override
  String get currentRoute => 'المسار الحالي';

  @override
  String get deviceInfo => 'معلومات الجهاز';

  @override
  String get platformNotifications => 'إشعارات المنصة';

  @override
  String get platformNotificationsSubtitle =>
      'تابع إجراءات المالك المهمة وأحداث الاشتراك عبر مسار CRM.';

  @override
  String get noPlatformNotifications => 'لا توجد إشعارات منصة حتى الآن';

  @override
  String get noPlatformNotificationsMessage =>
      'ستظهر هنا إجراءات المنصة المهمة وأحداث الاشتراك.';

  @override
  String get markUnread => 'تحديد كغير مقروء';

  @override
  String get platformNotificationStorageLabel => 'التخزين';

  @override
  String get platformNotificationSeverityInfo => 'معلومة';

  @override
  String get platformNotificationSeveritySuccess => 'نجاح';

  @override
  String get platformNotificationSeverityWarning => 'تحذير';

  @override
  String get platformNotificationSeverityUrgent => 'عاجل';

  @override
  String daysAgo(int count) {
    return 'منذ $count يوم';
  }

  @override
  String get platformNotificationCompanyRegistered => 'تم تسجيل شركة';

  @override
  String get platformNotificationCompanyCreated => 'تم إنشاء شركة';

  @override
  String get platformNotificationCompanyStatusChanged => 'تغيرت حالة الشركة';

  @override
  String get platformNotificationCompanySettingsChanged =>
      'تغيرت إعدادات الشركة';

  @override
  String get platformNotificationCompanyFeatureChanged => 'تغيرت ميزات الشركة';

  @override
  String get platformNotificationCompanyLimitChanged => 'تغيرت حدود الشركة';

  @override
  String get platformNotificationCompanyUserCreated => 'تم إنشاء مستخدم للشركة';

  @override
  String get platformNotificationCompanyUserStatusChanged =>
      'تغيرت حالة مستخدم الشركة';

  @override
  String get platformNotificationDealWon => 'تم كسب صفقة';

  @override
  String get platformNotificationDealLost => 'تم فقد صفقة';

  @override
  String get platformNotificationCompanyUserPasswordReset =>
      'إجراء كلمة مرور لمستخدم الشركة';

  @override
  String get platformNotificationInvitationCreated => 'تم إنشاء دعوة';

  @override
  String get platformNotificationInvitationAccepted => 'تم قبول دعوة';

  @override
  String get platformNotificationInvitationRevoked => 'تم إلغاء دعوة';

  @override
  String get platformNotificationSupportTicketCreated => 'تم إنشاء تذكرة دعم';

  @override
  String get platformNotificationFeedbackSubmitted => 'تم إرسال ملاحظات';

  @override
  String get platformNotificationSupportTicketStatusChanged =>
      'تغيرت حالة الدعم';

  @override
  String get platformNotificationStorageUsageRefreshed =>
      'تم تحديث استخدام التخزين';

  @override
  String get platformNotificationStorageNearLimit => 'التخزين قريب من الحد';

  @override
  String get platformNotificationFunctionFailed => 'فشلت وظيفة منصة';

  @override
  String get platformNotificationUnknown => 'حدث منصة';

  @override
  String platformNotificationCompanyActorMessage(Object company, Object actor) {
    return 'تم تحديث $company بواسطة $actor.';
  }

  @override
  String platformNotificationCompanyMessage(Object company) {
    return 'يوجد حدث منصة جديد في $company.';
  }

  @override
  String platformNotificationActorMessage(Object actor) {
    return 'أنشأ $actor حدث منصة.';
  }

  @override
  String get platformNotificationGenericMessage =>
      'يوجد حدث منصة يحتاج إلى انتباهك.';

  @override
  String get storageUsageUnavailable => 'الاستخدام غير متاح';

  @override
  String get storageNotTrackedYet => 'لم يتم تتبع استخدام التخزين بعد.';

  @override
  String get storageLastUpdated => 'آخر تحديث';

  @override
  String get refreshStorageUsage => 'تحديث الاستخدام';

  @override
  String get storageUsageUpdated => 'تم تحديث استخدام التخزين.';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get message => 'الرسالة';

  @override
  String get module => 'الوحدة';

  @override
  String get severity => 'الخطورة';

  @override
  String get resolved => 'تم الحل';

  @override
  String get unresolved => 'غير محلول';

  @override
  String get platformMonitoring => 'المراقبة';

  @override
  String get platformMonitoringSubtitle =>
      'تتبع الأخطاء الجسيمة ومشكلات الصلاحيات المتكررة وحوادث الشركات داخل مسار CRM.';

  @override
  String get activeIncidents => 'الحوادث النشطة';

  @override
  String get fatalErrors => 'الأخطاء القاتلة';

  @override
  String get errorsToday => 'أخطاء اليوم';

  @override
  String get affectedCompanies => 'الشركات المتأثرة';

  @override
  String get allSeverities => 'كل مستويات الخطورة';

  @override
  String get allErrorSources => 'كل المصادر';

  @override
  String get allModules => 'كل الوحدات';

  @override
  String get allTime => 'كل الفترات';

  @override
  String get last24Hours => 'آخر 24 ساعة';

  @override
  String get last7Days => 'آخر 7 أيام';

  @override
  String get last30Days => 'آخر 30 يومًا';

  @override
  String get resolvedAndUnresolved => 'محلول وغير محلول';

  @override
  String get unresolvedOnly => 'غير المحلولة فقط';

  @override
  String get resolvedOnly => 'المحلولة فقط';

  @override
  String get noPlatformErrors => 'لا توجد حوادث مراقبة';

  @override
  String get noPlatformErrorsMessage =>
      'ستظهر هنا أخطاء التطبيق والقواعد والتخزين والدوال الجسيمة بعد الإبلاغ عنها.';

  @override
  String get occurrenceCount => 'مرات التكرار';

  @override
  String get firstSeenAt => 'أول ظهور';

  @override
  String get lastSeenAt => 'آخر ظهور';

  @override
  String get errorCode => 'رمز الخطأ';

  @override
  String get stackHash => 'بصمة المكدس';

  @override
  String get shortStack => 'المكدس المختصر';

  @override
  String get metadata => 'بيانات إضافية';

  @override
  String get ownerNotified => 'تم تنبيه المالك';

  @override
  String get markResolved => 'تحديد كمحلول';

  @override
  String get resolvedBy => 'تم الحل بواسطة';

  @override
  String get resolvedAt => 'وقت الحل';

  @override
  String get errorDetails => 'تفاصيل الخطأ';

  @override
  String get buildNumber => 'رقم البناء';

  @override
  String get errorSeverityInfo => 'معلومة';

  @override
  String get errorSeverityWarning => 'تحذير';

  @override
  String get errorSeverityError => 'خطأ';

  @override
  String get errorSeverityFatal => 'قاتل';

  @override
  String get errorSourceFlutterWeb => 'Flutter Web';

  @override
  String get errorSourceFlutterMobile => 'Flutter Mobile';

  @override
  String get errorSourceCloudFunction => 'Cloud Function';

  @override
  String get errorSourceFirestoreRule => 'قاعدة Firestore';

  @override
  String get errorSourceStorage => 'Storage';

  @override
  String get errorSourceUnknown => 'غير معروف';

  @override
  String get platformMonitoringResolvedMessage =>
      'تم تحديد حادث المراقبة كمحلول.';

  @override
  String get enableTrial => 'تفعيل الفترة التجريبية';

  @override
  String get enableTrialSubtitle =>
      'تظل الشركة نشطة خلال الفترة التجريبية المحددة، ثم يتوقف الوصول حتى يتم التجديد من الدعم.';

  @override
  String get trialPeriodDays => 'مدة التجربة';

  @override
  String get trialEndsAt => 'تنتهي التجربة';

  @override
  String get trialEnded => 'انتهت التجربة';

  @override
  String get trialEndedAccessMessage =>
      'انتهت الفترة التجريبية. تواصل مع الدعم أو اشترك لمتابعة استخدام مسار CRM.';

  @override
  String get trialReminderTitle => 'تنبيه الفترة التجريبية';

  @override
  String get trialRemaining => 'الوقت المتبقي للتجربة';

  @override
  String get trialFirstReminderMessage =>
      'تم تجاوز أول مرحلة من الفترة التجريبية. جهّز الاشتراك قبل توقف الوصول.';

  @override
  String get trialSecondReminderMessage =>
      'الفترة التجريبية تقترب من الانتهاء. اشترك أو تواصل مع الدعم للاستمرار دون انقطاع.';

  @override
  String get trialFinalReminderMessage =>
      'الفترة التجريبية على وشك الانتهاء. اشترك أو تواصل مع الدعم الآن لتجنب توقف الوصول.';

  @override
  String get exportCompanyData => 'تصدير بيانات الشركة';

  @override
  String get companyDataExported => 'تم تصدير بيانات الشركة.';

  @override
  String get developedAndDesignedBy =>
      'تم التطوير والتصميم بواسطة: Islam A. © 2026';

  @override
  String get clearNotification => 'مسح';

  @override
  String get collapseAttentionNeeded => 'طي';

  @override
  String get expandAttentionNeeded => 'عرض';

  @override
  String get paymentFollowUp => 'متابعة المدفوعات';

  @override
  String get paymentStatus => 'حالة الدفع';

  @override
  String get paid => 'مدفوع';

  @override
  String get dueSoon => 'مستحق قريبًا';

  @override
  String get gracePeriod => 'فترة سماح';

  @override
  String get suspended => 'موقوف';

  @override
  String get markAsPaid => 'تسجيل كمدفوع';

  @override
  String get extendDueDate => 'تمديد تاريخ الاستحقاق';

  @override
  String get nextPaymentDue => 'تاريخ الاستحقاق القادم';

  @override
  String get lastPayment => 'آخر دفعة';

  @override
  String get paymentHistory => 'سجل المدفوعات';

  @override
  String get paymentNotes => 'ملاحظات الدفع';

  @override
  String get paymentCurrency => 'العملة';

  @override
  String get paymentCycle => 'دورة الدفع';

  @override
  String get monthly => 'شهري';

  @override
  String get quarterly => 'ربع سنوي';

  @override
  String get semiAnnual => 'نصف سنوي';

  @override
  String get yearly => 'سنوي';

  @override
  String get custom => 'مخصص';

  @override
  String get amount => 'المبلغ';

  @override
  String get daysRemaining => 'الأيام المتبقية';

  @override
  String get paidCompanies => 'شركات مدفوعة';

  @override
  String get expectedThisMonth => 'المتوقع هذا الشهر';

  @override
  String get moveToGracePeriod => 'نقل إلى فترة سماح';

  @override
  String get suspendCompany => 'إيقاف الشركة';

  @override
  String get reactivateCompany => 'إعادة تفعيل الشركة';

  @override
  String get gracePeriodEndsAt => 'نهاية فترة السماح';

  @override
  String get suspendedReason => 'سبب الإيقاف';

  @override
  String get markedPaid => 'تم التسجيل كمدفوع';

  @override
  String get extended => 'تم التمديد';

  @override
  String get reactivated => 'تمت إعادة التفعيل';

  @override
  String get noteAdded => 'تمت إضافة ملاحظة';

  @override
  String get noPaymentHistory =>
      'ستظهر إجراءات الدفع هنا بعد أن يحدّث مالك المنصة هذه الشركة.';

  @override
  String get futureDateRequired => 'أدخل تاريخًا مستقبليًا.';

  @override
  String get paymentAccessBlockedMessage =>
      'تم إيقاف وصول الشركة بسبب حالة الدفع. يرجى التواصل مع الدعم أو مالك المنصة لإعادة التفعيل.';

  @override
  String get paymentDueSoonMessage =>
      'يوجد دفعة مستحقة قريبًا على الشركة. يرجى التواصل مع الدعم أو مالك المنصة لتجنب انقطاع الوصول.';

  @override
  String get paymentOverdueMessage =>
      'يوجد دفعة متأخرة على الشركة. يرجى التواصل مع الدعم أو مالك المنصة لتحديث حالة الدفع.';

  @override
  String get paymentGraceMessage =>
      'الشركة في فترة سماح للدفع. يرجى التواصل مع الدعم أو مالك المنصة قبل إيقاف الوصول.';

  @override
  String daysRemainingCount(int count) {
    return 'متبقي $count يوم';
  }

  @override
  String overdueDaysCount(int count) {
    return 'متأخر $count يوم';
  }

  @override
  String get swipeToSeeMore => 'اسحب لعرض المزيد';

  @override
  String get dashboardActionNoAnswer => 'لم يرد';

  @override
  String get dashboardActionInterested => 'تمييز كفرصة مهمة';

  @override
  String get dashboardActionNotInterested => 'تحديد كغير مهتم';

  @override
  String get dashboardActionMarkTaskCompleted => 'إنهاء المهمة';

  @override
  String get dashboardActionSaved => 'تم حفظ الإجراء.';

  @override
  String get dashboardActionFailed => 'تعذر تنفيذ الإجراء. حاول مرة أخرى.';

  @override
  String get dashboardCallPhone => 'اتصال';

  @override
  String get dashboardOpenWhatsApp => 'فتح واتساب';

  @override
  String get dashboardLeadNoteContacted =>
      'نتيجة المتابعة: تم التواصل من لوحة المتابعة.';

  @override
  String get dashboardLeadNoteNoAnswer =>
      'نتيجة المتابعة: لم يرد من لوحة المتابعة. تم تحديد متابعة للغد.';

  @override
  String get dashboardLeadNoteInterested =>
      'نتيجة المتابعة: العميل مهتم من لوحة المتابعة.';

  @override
  String get dashboardLeadNoteNotInterested =>
      'نتيجة المتابعة: العميل غير مهتم من لوحة المتابعة.';

  @override
  String dashboardLeadNoteFollowUpScheduled(Object date) {
    return 'تم تحديد متابعة يوم $date من لوحة المتابعة.';
  }

  @override
  String get connectedJourneyTitle => 'رحلة السجل';

  @override
  String get connectedJourneySubtitle =>
      'تسلسل المتابعات والمهام والمواعيد والصفقات والنشاط المرتبط بهذا السجل.';

  @override
  String get journeyRecommendedNextAction => 'الإجراء المقترح الآن';

  @override
  String get journeyNoActivity => 'لا توجد أنشطة مرتبطة حتى الآن.';

  @override
  String get journeyOpenRecord => 'فتح السجل';

  @override
  String get journeyReason => 'السبب';

  @override
  String get journeyItemRecordCreated => 'تم إنشاء السجل';

  @override
  String get journeyItemAuditCreated => 'تم تسجيل نشاط جديد';

  @override
  String get journeyItemAuditUpdated => 'تم تحديث نشاط';

  @override
  String get journeyActionEverythingCalm => 'لا يوجد إجراء عاجل';

  @override
  String get journeyActionEverythingCalmDescription =>
      'هذا السجل لا يحتوي على تنبيهات عاجلة في الرحلة حاليًا.';

  @override
  String get journeyActionOverdueFollowUp => 'المتابعة متأخرة';

  @override
  String get journeyActionOverdueFollowUpDescription =>
      'تواصل مع هذا السجل اليوم أو أنشئ مهمة للحفاظ على زخم المتابعة.';

  @override
  String get journeyActionNoContact => 'يحتاج نقطة تواصل جديدة';

  @override
  String get journeyActionNoContactDescription =>
      'لا يوجد تواصل حديث. خطط لمكالمة أو مهمة أو موعد.';

  @override
  String get journeyActionScheduleVisit => 'حدد الموعد التالي';

  @override
  String get journeyActionScheduleVisitDescription =>
      'السجل جاهز لخطوة واضحة مثل اجتماع أو معاينة عقار.';

  @override
  String get journeyActionCompleteProfile => 'استكمال البيانات الناقصة';

  @override
  String get journeyActionCompleteProfileDescription =>
      'أضف التفضيلات الناقصة حتى تصبح المطابقة والمتابعة أدق.';

  @override
  String get journeyActionStuckDeal => 'الصفقة تحتاج مراجعة';

  @override
  String get journeyActionStuckDealDescription =>
      'هذه الصفقة لم تتحرك مؤخرًا. راجع المرحلة والالتزام التالي.';

  @override
  String get journeyActionClosingDue => 'تاريخ الإغلاق يحتاج متابعة';

  @override
  String get journeyActionClosingDueDescription =>
      'تاريخ الإغلاق المتوقع انتهى. أنشئ مهمة أو حدّث خطة الصفقة.';

  @override
  String get activityHistory => 'سجل العمليات';

  @override
  String get visibleAuditLogs => 'العمليات الظاهرة';

  @override
  String get todayActivityCount => 'نشاط اليوم';

  @override
  String get exportActivity => 'نشاط التصدير';

  @override
  String get importantActivity => 'نشاط مهم';

  @override
  String get auditLogPermissionMessage =>
      'سجل النشاط متاح للمسؤول والمدير فقط.';

  @override
  String get auditLogsLoadFailed =>
      'تعذر تحميل سجل النشاط. تحقق من الفهارس أو الصلاحيات ثم حاول مرة أخرى.';

  @override
  String get noAuditLogsFound => 'لا توجد عمليات مسجلة';

  @override
  String get noAuditLogsFoundMessage =>
      'لا توجد عمليات تطابق نطاق التصفية الحالي.';

  @override
  String get allActions => 'كل الإجراءات';

  @override
  String get allUsers => 'كل المستخدمين';

  @override
  String get searchAuditLogs => 'بحث في سجل النشاط';

  @override
  String get auditDetails => 'تفاصيل العملية';

  @override
  String get detailsSummary => 'ملخص التفاصيل';

  @override
  String get openRelatedRecord => 'فتح السجل المرتبط';

  @override
  String get technicalDetails => 'التفاصيل التقنية';

  @override
  String get exportType => 'نوع التصدير';

  @override
  String get exportScope => 'نطاق التصدير';

  @override
  String get fileFormat => 'صيغة الملف';

  @override
  String get exportedRows => 'عدد الصفوف المصدّرة';

  @override
  String get exportedColumns => 'الأعمدة المصدّرة';

  @override
  String get filterSummary => 'ملخص التصفية';

  @override
  String get supervisorNotification => 'تنبيه المسؤول';

  @override
  String get auditLogsExport => 'تصدير سجل النشاط';

  @override
  String get reportsExport => 'تصدير التقارير';

  @override
  String get platformCompanyExport => 'تصدير شركة من المنصة';

  @override
  String get exportTrackingFailed =>
      'تم إنشاء ملف التصدير، لكن تعذر تسجيل عملية التصدير. حاول مرة أخرى.';

  @override
  String get time => 'الوقت';

  @override
  String get openFile => 'فتح الملف';

  @override
  String get openDownloads => 'فتح التنزيلات';

  @override
  String get exportSavedTo => 'تم الحفظ في';

  @override
  String get exportOpenFileFailed => 'تعذر فتح الملف على هذا الجهاز.';

  @override
  String get exportOpenDownloadsFailed =>
      'تعذر فتح مجلد التنزيلات على هذا الجهاز.';

  @override
  String get multipleReports => 'تقارير متعددة';

  @override
  String get multipleReportsColumnsHint =>
      'عند تصدير أكثر من تقرير، يتم استخدام الأعمدة المقترحة لكل تقرير محدد.';

  @override
  String get androidReleaseManagement => 'إدارة إصدار أندرويد';

  @override
  String get androidReleaseManagementSubtitle =>
      'تحكم في تحديثات APK الإجبارية لمستخدمي أندرويد بدون تعديل Firestore يدويًا.';

  @override
  String get releaseReady => 'الإصدار جاهز';

  @override
  String get minimumSupportedBuild => 'أقل رقم بناء مدعوم';

  @override
  String get latestBuild => 'أحدث رقم بناء';

  @override
  String get updateUrl => 'رابط التحديث';

  @override
  String get suggestedUpdateUrl => 'رابط التحديث المقترح';

  @override
  String get useSuggestedUpdateUrl => 'استخدام الرابط المقترح';

  @override
  String get saveReleasePolicy => 'حفظ سياسة الإصدار';

  @override
  String get androidReleasePolicySaved => 'تم حفظ سياسة إصدار أندرويد.';

  @override
  String get androidReleasePolicyHint =>
      'اترك جاهزية الإصدار مغلقة حتى ترفع ملف APK وتختبر الرابط.';

  @override
  String get enabled => 'مفعّل';

  @override
  String get connectionLostSnackbar =>
      'لا يوجد اتصال بالإنترنت. قد لا تكتمل بعض العمليات حتى يعود الاتصال.';

  @override
  String get connectionRestoredSnackbar => 'عاد الاتصال بالإنترنت.';

  @override
  String get androidVersionAdoption => 'انتشار إصدارات أندرويد';

  @override
  String get androidVersionAdoptionSubtitle =>
      'المستخدمون النشطون حسب إصدار التطبيق المثبّت، بناءً على آخر أجهزة مسجلة.';

  @override
  String get activeDevices => 'الأجهزة النشطة';

  @override
  String get latestSeen => 'آخر ظهور';

  @override
  String get noAndroidVersionData => 'لا توجد بيانات إصدارات أندرويد حتى الآن.';

  @override
  String get releaseCenter => 'مركز الإصدارات';

  @override
  String get releaseOverview => 'نظرة عامة على الإصدارات';

  @override
  String get releases => 'الإصدارات';

  @override
  String get versionAdoption => 'اعتماد الإصدارات';

  @override
  String get devices => 'الأجهزة';

  @override
  String get versionHistory => 'سجل الإصدارات';

  @override
  String get health => 'الصحة';

  @override
  String get latestWebVersion => 'أحدث إصدار ويب';

  @override
  String get latestAndroidVersion => 'أحدث إصدار أندرويد';

  @override
  String get latestActiveWeb => 'أحدث إصدار ويب نشط';

  @override
  String get latestActiveAndroid => 'أحدث إصدار أندرويد نشط';

  @override
  String get latestReleasedWeb => 'أحدث إصدار ويب منشور';

  @override
  String get latestReleasedAndroid => 'أحدث إصدار أندرويد منشور';

  @override
  String get webUsersDevices => 'مستخدمو وأجهزة الويب';

  @override
  String get androidUsersDevices => 'مستخدمو وأجهزة أندرويد';

  @override
  String get oldBuilds => 'الإصدارات القديمة';

  @override
  String get belowMinimumBuild => 'أقل من الحد الأدنى للإصدار';

  @override
  String get pushHealth => 'حالة الإشعارات';

  @override
  String get currentAdoptionHistoryHint =>
      'الاعتماد الحالي يعرض الأجهزة النشطة فقط. سجل الإصدارات يعرض الإصدارات السابقة.';

  @override
  String get noAdoptionDataYet => 'لا توجد بيانات اعتماد إصدارات بعد';

  @override
  String get noReleaseRecordsYet => 'لا توجد سجلات إصدارات بعد';

  @override
  String get noDeviceDataYet => 'لا توجد بيانات أجهزة بعد';

  @override
  String get noVersionHistoryYet => 'لا يوجد سجل إصدارات بعد';

  @override
  String get noHealthDataYet => 'لا توجد بيانات صحة بعد';

  @override
  String get web => 'ويب';

  @override
  String get androidPlatform => 'أندرويد';

  @override
  String get latest => 'الأحدث';

  @override
  String get oldBuild => 'إصدار قديم';

  @override
  String get connected => 'متصل';

  @override
  String get blocked => 'محظور';

  @override
  String get missing => 'مفقود';

  @override
  String get failed => 'فشل';

  @override
  String get invalid => 'غير صالح';

  @override
  String get lastUpdated => 'آخر تحديث';

  @override
  String get unknown => 'غير معروف';

  @override
  String get notReported => 'غير متوفر';

  @override
  String get invalidOrFailed => 'غير صالح أو فشل';

  @override
  String get deviceBrowser => 'الجهاز/المتصفح';

  @override
  String get createdBy => 'أنشأه';

  @override
  String get createAction => 'إنشاء';

  @override
  String get releaseCenterAllCompaniesHint => 'يعرض مركز الإصدارات كل الشركات.';

  @override
  String get releaseCenterSelectedCompanyHint =>
      'مركز الإصدارات مفلتر على الشركة المحددة.';

  @override
  String get releaseRecordsStartAfterRegistryEnabled =>
      'لا توجد سجلات إصدارات بعد. تبدأ سجلات الإصدارات بعد تفعيل سجل الإصدارات أو بعد إنشاء سجل من سياسة أندرويد الحالية.';

  @override
  String get createReleaseRecordFromAndroidPolicy =>
      'إنشاء سجل إصدار من سياسة أندرويد الحالية';

  @override
  String get createReleaseRecordFromAndroidPolicyConfirm =>
      'سيتم إنشاء سجل إصدار من سياسة تحديث أندرويد الإجباري الحالية. لن يتم تغيير السياسة أو تنفيذ أي نشر.';

  @override
  String get releaseRecordCreated => 'تم إنشاء سجل الإصدار.';

  @override
  String get versionHistoryStartsAfterBuildChange =>
      'يبدأ سجل الإصدارات عندما يتغير رقم بناء جهاز بعد v2.31.0+102.';

  @override
  String get draft => 'مسودة';

  @override
  String get released => 'تم الإصدار';

  @override
  String get disabled => 'معطل';

  @override
  String get rolledBack => 'تم التراجع';

  @override
  String get notNow => 'ليس الآن';

  @override
  String get dismiss => 'إخفاء';

  @override
  String get notificationPermissionEnabledTitle => 'تم تفعيل الإشعارات';

  @override
  String get notificationPermissionEnabledBody =>
      'هذا الجهاز متصل وسيستقبل تنبيهات مسار CRM المهمة.';

  @override
  String get notificationPermissionNotConnectedTitle =>
      'إشعارات الجهاز غير متصلة';

  @override
  String get notificationPermissionBlockedTitle => 'الإشعارات محظورة';

  @override
  String get notificationPermissionBlockedBody =>
      'فعّل الإشعارات من إعدادات المتصفح أو الجهاز عندما تريد استقبال التنبيهات.';

  @override
  String get notificationPermissionConfigurationIssueTitle =>
      'إعداد الإشعارات يحتاج ضبطًا';

  @override
  String get notificationPermissionConfigurationIssueBody =>
      'مفتاح Web Push غير موجود في هذا البناء. أعد بناء التطبيق باستخدام مفتاح Firebase VAPID لتفعيل إشعارات المتصفح.';

  @override
  String get platformActivityDeferredMessage =>
      'افتح النشاط لتحميل مستخدمي الشركة المحددة وسجل الدخول لهذه الجلسة فقط.';

  @override
  String get platformWorkspaceSummaryDeferredMessage =>
      'افتح مساحة العمل لتحميل أعداد مستخدمي الشركة المحددة لهذه الجلسة فقط.';

  @override
  String get releaseOverviewGuidance =>
      'استخدم هذه الصفحة لمراجعة أحدث إصدارات الويب وأندرويد، والأجهزة القديمة، وجاهزية تحديث أندرويد، وصحة الإشعارات قبل نشر إصدار جديد.';

  @override
  String get releaseOverviewMixedScopeHint =>
      'أحدث الإصدارات وسياسة أندرويد على مستوى المنصة؛ أما أعداد الأجهزة والسجل فتتبع فلتر الشركة المحددة.';

  @override
  String get releaseRegistryGuidance =>
      'يعرض هذا السجل الإصدارات المحضرة والمنشورة على مستوى المنصة. استخدمه لتأكيد ما تم تسجيله كإصدار، وليس لتغيير سياسة التحديث الإجباري لأندرويد.';

  @override
  String get releaseRegistryAndroidPolicyNote =>
      'تتم إدارة تفاصيل سياسة أندرويد من إدارة إصدار أندرويد.';

  @override
  String get releaseAdoptionDevicesGuidance =>
      'استخدم هذا التبويب لمعرفة الأجهزة والمستخدمين النشطين فعليًا حسب الإصدار. الاعتماد يعرض الاستخدام المثبت، وليس سجل الإصدارات.';

  @override
  String get releaseAndroidPolicyGuidance =>
      'استخدم هذا التبويب لإدارة جاهزية التحديث الإجباري لأندرويد. لا تجعل الإصدار جاهزًا إلا بعد رفع ملف APK واختبار رابط التحميل.';

  @override
  String get releaseHistoryGuidance =>
      'استخدم هذا التبويب لمراجعة تغييرات إصدارات الأجهزة وأحداث الإصدار السابقة عند استكشاف المشكلات.';

  @override
  String get releaseHistoryProfileLimitNote =>
      'قد تحتوي الأحداث القديمة على مرجع مستخدم تقني فقط؛ يظهر المرجع المختصر لأغراض استكشاف المشكلات فقط.';

  @override
  String get releaseSectionPlatformWideNote =>
      'هذا القسم على مستوى المنصة ولا يتأثر بالشركة المحددة.';

  @override
  String get notificationAdoptionSeparateNote =>
      'جاهزية الإشعارات منفصلة عن اعتماد الإصدارات.';

  @override
  String get androidPolicyBuildComparisonNote =>
      'قرارات تحديث أندرويد تعتمد على رقم البناء، وليس نص الإصدار المعروض.';

  @override
  String get suggestedApkUrlNotProof =>
      'الرابط المقترح يساعد على التسمية فقط. ارفع ملف APK واختبر رابط التحميل قبل جعل الإصدار جاهزًا.';

  @override
  String get androidPolicyNotReadyAction =>
      'الإصدار غير جاهز. ارفع رابط APK واختبره قبل تفعيل حالة الجاهزية.';

  @override
  String get androidPolicyReadyAction =>
      'الإصدار محدد كجاهز. سيقارن عملاء أندرويد متطلبات التحديث حسب رقم البناء.';

  @override
  String get notificationReadyDevices => 'أجهزة جاهزة للإشعارات';

  @override
  String notificationReadyDevicesRatio(int ready, int total) {
    return '$ready / $total';
  }

  @override
  String notificationReadyDevicesSummary(int ready, int total) {
    return '$ready من $total أجهزة نشطة يمكنها استقبال الإشعارات.';
  }

  @override
  String get notificationBlockedDevices => 'أجهزة حظرت الإشعارات';

  @override
  String get notificationMissingDevices => 'أجهزة بلا رمز إشعارات';

  @override
  String get notificationInvalidFailedDevices =>
      'أجهزة إشعارات غير صالحة أو فشلت';

  @override
  String get devicesBelowLatestBuild => 'أجهزة أقل من أحدث بناء';

  @override
  String devicesBelowLatestBuildSummary(int users, int devices) {
    return '$users مستخدمين على $devices أجهزة أقل من أحدث بناء.';
  }

  @override
  String get requiresReview => 'يتطلب مراجعة';

  @override
  String get unresolvedUser => 'مستخدم غير محدد';

  @override
  String get userProfileUnavailable => 'بيانات المستخدم غير متاحة';

  @override
  String get releaseEventTechnicalReferenceOnly =>
      'هذا الحدث يحتوي على مرجع تقني فقط للمستخدم.';

  @override
  String get technicalReference => 'مرجع تقني';

  @override
  String get dashboardPerformanceDailyActivityNote =>
      'يعرض النشاط اليومي، لذلك تظهر الأيام التي لا تحتوي على سجلات جديدة كقيمة 0.';

  @override
  String get dashboardPerformanceTotalTrend => 'الإجمالي';

  @override
  String get dashboardPerformanceDailyTrend => 'اليومي';

  @override
  String get dashboardPerformanceTotalTrendNote =>
      'يعرض الإجمالي المتراكم خلال الفترة المحددة، لذلك لا يهبط الخط إلى 0 في الأيام الهادئة.';

  @override
  String get salesCommandWhyLeadNeedsContact =>
      'هذا العميل المحتمل لم يتم التعامل معه بعد. ابدأ بمكالمة أو واتساب الآن، ثم سجّل النتيجة حتى تبقى الفرصة واضحة في المسار.';

  @override
  String get salesCommandWhyLeadMissingNextStep =>
      'تم التواصل مع العميل من قبل، لكن لا يوجد إجراء قادم واضح. حدّد المتابعة التالية حتى لا تختفي الفرصة من خط البيع.';

  @override
  String get salesCommandWhyLeadNeedsAppointment =>
      'العميل يظهر اهتمامًا. حرّك المحادثة للأمام بحجز معاينة أو موعد بدل تركها مفتوحة.';

  @override
  String get salesCommandWhyLeadNeedsDeal =>
      'العميل وصل لمرحلة التفاوض. أنشئ الصفقة الآن حتى يتم تتبع القيمة والمرحلة والالتزام القادم.';

  @override
  String get salesCommandReasonLeadNeedsContact => 'تواصل الآن';

  @override
  String get salesCommandReasonLeadMissingNextStep => 'ينقصه إجراء قادم';

  @override
  String get salesCommandReasonLeadNeedsAppointment => 'حدد معاينة';

  @override
  String get salesCommandReasonLeadNeedsDeal => 'أنشئ صفقة';

  @override
  String get leadNbaContactTitle => 'ابدأ بتواصل حقيقي مع العميل';

  @override
  String get leadNbaContactBody =>
      'هذا العميل ما زال جديدًا. اتصل به أو أرسل واتساب أولًا، ثم سجّل التواصل حتى تفهم لوحة المتابعة أنه تم التعامل معه.';

  @override
  String get leadNbaFollowUpOverdueTitle => 'المتابعة متأخرة';

  @override
  String get leadNbaFollowUpOverdueBody =>
      'هذا العميل كان ينتظر متابعة والتاريخ مر بالفعل. تواصل معه الآن، ثم حدّد الخطوة التالية.';

  @override
  String get leadNbaFollowUpTodayTitle => 'المتابعة مستحقة اليوم';

  @override
  String get leadNbaFollowUpTodayBody =>
      'هذا هو الوقت المناسب للمتابعة. افتح المحادثة اليوم للحفاظ على زخم الفرصة.';

  @override
  String get leadNbaMissingNextStepTitle =>
      'حدّد الخطوة التالية للحفاظ على زخم الفرصة';

  @override
  String get leadNbaMissingNextStepBody =>
      'تم التواصل مع العميل من قبل، لكن لا يوجد تاريخ متابعة قادم. أضف إجراءً واضحًا حتى يرجعه التطبيق في الوقت الصحيح.';

  @override
  String get leadNbaScheduleAppointmentTitle => 'حوّل الاهتمام إلى معاينة';

  @override
  String get leadNbaScheduleAppointmentBody =>
      'العميل مهتم. الخطوة الذكية الآن هي حجز معاينة أو موعد بدل ترك المحادثة مفتوحة.';

  @override
  String get leadNbaCreateAppointmentTitle => 'تابع الزيارة المجدولة';

  @override
  String get leadNbaCreateAppointmentBody =>
      'العميل دخل مرحلة الزيارة بالفعل. اترك الموعد المجدول يقود الخطوة التالية، ثم سجّل نتيجة الزيارة حتى تظل الفرصة واضحة.';

  @override
  String get leadNbaCreateDealTitle => 'حوّل التفاوض إلى صفقة واضحة';

  @override
  String get leadNbaCreateDealBody =>
      'العميل وصل لمرحلة التفاوض. أنشئ الصفقة الآن حتى تتم إدارة القيمة والمرحلة وخطوات الإغلاق بشكل صحيح.';

  @override
  String get leadNbaCreateDealSalesTitle => 'ثبّت خطوة التفاوض القادمة';

  @override
  String get leadNbaCreateDealSalesBody =>
      'العميل في مرحلة تفاوض. لا تترك المحادثة مفتوحة: اتفق على المتابعة القادمة أو خطوة الحجز أو موعد قرار واضح، ثم سجّلها حتى تظل الفرصة نشطة.';

  @override
  String get leadNbaStaleTitle => 'أعد تنشيط هذا العميل الهادئ';

  @override
  String get leadNbaStaleBody =>
      'لا توجد حركة مهمة منذ فترة. تابعه الآن أو قرر هل يجب إغلاقه كعميل مفقود.';

  @override
  String get leadNbaFutureFollowUpTitle => 'الخطوة القادمة مجدولة بالفعل';

  @override
  String get leadNbaFutureFollowUpBody =>
      'هذا العميل لديه متابعة مستقبلية، لذلك من الأفضل أن يظل هادئًا حتى يأتي وقته. لا يوجد إجراء عاجل الآن.';

  @override
  String get leadNbaPrimaryActionContact => 'تسجيل التواصل';

  @override
  String get leadNbaPrimaryActionScheduleFollowUp => 'تحديد متابعة';

  @override
  String get leadNbaPrimaryActionCreateAppointment => 'إنشاء موعد';

  @override
  String get leadNbaPrimaryActionCreateDeal => 'إنشاء صفقة';

  @override
  String get leadNbaContactedTodayTitle => 'تم التعامل معه اليوم';

  @override
  String get leadNbaContactedTodayBody =>
      'تم التواصل مع هذا العميل اليوم، لذلك لا يجب أن يظل كإجراء عاجل الآن. حدّد متابعة إذا كان يحتاج تواصلًا آخر.';

  @override
  String get matchingPropertiesTitle => 'عقارات متاحة مناسبة';

  @override
  String get matchingPropertiesLeadSubtitle =>
      'اقتراحات بناءً على الموقع المطلوب ونوع العقار والميزانية لهذا العميل المحتمل. استخدمها كإشارة بيع، وليست تطابقًا مضمونًا.';

  @override
  String get matchingPropertiesClientSubtitle =>
      'اقتراحات بناءً على الموقع المطلوب ونوع العقار والميزانية لهذا العميل. استخدمها كإشارة بيع، وليست تطابقًا مضمونًا.';

  @override
  String get matchingPropertiesAddPreferences =>
      'أضف الموقع المطلوب أو نوع العقار أو الميزانية لعرض اقتراحات عقارية مفيدة.';

  @override
  String get matchingPropertiesNoMatches =>
      'لا توجد عقارات متاحة متطابقة بقوة مع هذه التفضيلات حاليًا.';

  @override
  String get matchingPropertiesLoadFailed => 'تعذر تحميل العقارات المناسبة.';

  @override
  String get propertyMatchSameCompound => 'نفس الكمبوند';

  @override
  String get propertyMatchSameLocation => 'نفس الموقع';

  @override
  String get propertyMatchSameType => 'نفس النوع';

  @override
  String get propertyMatchWithinBudget => 'ضمن الميزانية';

  @override
  String get propertyMatchCloseToBudget => 'قريبة من الميزانية';

  @override
  String get propertyMatchAvailableNow => 'متاحة الآن';

  @override
  String get viewProperty => 'عرض العقار';

  @override
  String get matchingDemandTitle => 'عملاء مناسبون لهذا العقار';

  @override
  String get matchingDemandSubtitle =>
      'عملاء حاليون أو محتملون تتوافق تفضيلاتهم مع هذا العقار المتاح. استخدمها لتحديد من يستحق التواصل أولًا.';

  @override
  String get matchingDemandNoMatches =>
      'لا يوجد عملاء حاليون أو محتملون متوافقون بقوة مع هذا العقار حاليًا.';

  @override
  String get matchingDemandLoadFailed =>
      'تعذر تحميل العملاء المناسبين لهذا العقار.';

  @override
  String get matchingDemandUnavailableProperty =>
      'تظهر المطابقات فقط للعقارات المتاحة.';

  @override
  String get matchingDemandNoAccess =>
      'لا توجد صلاحية لعرض العملاء الحاليين أو المحتملين لهذا الدور.';

  @override
  String get matchingDemandLead => 'عميل محتمل';

  @override
  String get matchingDemandClient => 'عميل';

  @override
  String get dashboardDailySalesFocusTitle => 'أولويات اليوم';

  @override
  String get dashboardDailySalesFocusSubtitle => 'أهم ما يحتاج متابعة الآن.';

  @override
  String get dashboardDailySalesFocusManagerSubtitle =>
      'مخاطر الفريق التي تحتاج متابعة اليوم.';

  @override
  String get dashboardDailySalesFocusAdminSubtitle =>
      'مخاطر مبيعات على مستوى الشركة.';

  @override
  String get dashboardDailySalesFocusMarketingSubtitle =>
      'إجراءات العملاء المحتملين المهمة اليوم.';

  @override
  String get dashboardDailySalesFocusViewerSubtitle =>
      'أولويات للقراءة فقط من سجلاتك.';

  @override
  String get dashboardDailySalesFocusEmpty => 'لا توجد أولوية حرجة الآن.';

  @override
  String dashboardDailySalesFocusCount(Object count) {
    return '$count عناصر';
  }

  @override
  String get dashboardDailySalesFocusMatchingHint =>
      'راجع العقارات المطابقة ثم تواصل.';

  @override
  String get dashboardDailySalesFocusLeadHint => 'حدد الخطوة التالية.';

  @override
  String get dashboardDailySalesFocusAppointmentHint =>
      'سجّل النتيجة أو أعد الجدولة.';

  @override
  String get dashboardDailySalesFocusDealHint => 'حدد خطوة الإغلاق التالية.';

  @override
  String get dashboardDailySalesFocusTaskHint => 'أنهِ المهمة أو حدّث حالتها.';

  @override
  String get dashboardDailySalesFocusGenericHint => 'افتح السجل واحسم العائق.';

  @override
  String leadAssignedBy(Object toUser, Object actor) {
    return 'تم إسناد العميل المحتمل إلى $toUser بواسطة $actor';
  }

  @override
  String auditAssignedToUser(Object user) {
    return 'تم إسناده إلى $user';
  }

  @override
  String auditReassignedFromTo(Object fromUser, Object toUser) {
    return 'تم نقله من $fromUser إلى $toUser';
  }

  @override
  String auditUnassignedFrom(Object user) {
    return 'تمت إزالة الإسناد من $user';
  }
}
