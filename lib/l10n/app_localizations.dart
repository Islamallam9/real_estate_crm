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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Masar'**
  String get appName;

  /// No description provided for @loginBrandName.
  ///
  /// In en, this message translates to:
  /// **'Masar | مسار'**
  String get loginBrandName;

  /// No description provided for @websiteTitle.
  ///
  /// In en, this message translates to:
  /// **'Masar | CRM'**
  String get websiteTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

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

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @loggedOutSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully.'**
  String get loggedOutSuccessfully;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @leads.
  ///
  /// In en, this message translates to:
  /// **'Leads'**
  String get leads;

  /// No description provided for @properties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get properties;

  /// No description provided for @clients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clients;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @tasksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan follow-ups and internal task work by due date, status, and priority.'**
  String get tasksSubtitle;

  /// No description provided for @createTask.
  ///
  /// In en, this message translates to:
  /// **'Create task'**
  String get createTask;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTask;

  /// No description provided for @updateTask.
  ///
  /// In en, this message translates to:
  /// **'Update task'**
  String get updateTask;

  /// No description provided for @agentPerformanceSummary.
  ///
  /// In en, this message translates to:
  /// **'Compare agent workload, deal activity, task completion, and overdue risk.'**
  String get agentPerformanceSummary;

  /// No description provided for @agent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get agent;

  /// No description provided for @performanceScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get performanceScore;

  /// No description provided for @searchReports.
  ///
  /// In en, this message translates to:
  /// **'Search reports'**
  String get searchReports;

  /// No description provided for @taskCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Task created successfully.'**
  String get taskCreatedSuccessfully;

  /// No description provided for @taskUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Task updated successfully.'**
  String get taskUpdatedSuccessfully;

  /// No description provided for @taskCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Task marked completed.'**
  String get taskCompletedSuccessfully;

  /// No description provided for @taskCancelledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Task cancelled successfully.'**
  String get taskCancelledSuccessfully;

  /// No description provided for @markTaskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark completed'**
  String get markTaskCompleted;

  /// No description provided for @cancelTask.
  ///
  /// In en, this message translates to:
  /// **'Cancel task'**
  String get cancelTask;

  /// No description provided for @cancelTaskConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This task will be marked as cancelled and remain visible in task lists.'**
  String get cancelTaskConfirmation;

  /// No description provided for @taskNotFound.
  ///
  /// In en, this message translates to:
  /// **'Task not found. Open it from the tasks list.'**
  String get taskNotFound;

  /// No description provided for @taskInformation.
  ///
  /// In en, this message translates to:
  /// **'Task information'**
  String get taskInformation;

  /// No description provided for @taskTitle.
  ///
  /// In en, this message translates to:
  /// **'Task title'**
  String get taskTitle;

  /// No description provided for @relatedType.
  ///
  /// In en, this message translates to:
  /// **'Related type'**
  String get relatedType;

  /// No description provided for @relatedRecordId.
  ///
  /// In en, this message translates to:
  /// **'Related record ID'**
  String get relatedRecordId;

  /// No description provided for @relatedRecord.
  ///
  /// In en, this message translates to:
  /// **'Related record'**
  String get relatedRecord;

  /// No description provided for @selectRelatedRecord.
  ///
  /// In en, this message translates to:
  /// **'Select related record'**
  String get selectRelatedRecord;

  /// No description provided for @relatedRecordRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a related record.'**
  String get relatedRecordRequired;

  /// No description provided for @relatedRecordUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Related record unavailable'**
  String get relatedRecordUnavailable;

  /// No description provided for @noLeadsFound.
  ///
  /// In en, this message translates to:
  /// **'No leads found.'**
  String get noLeadsFound;

  /// No description provided for @agentActivityResults.
  ///
  /// In en, this message translates to:
  /// **'Agent activity and results'**
  String get agentActivityResults;

  /// No description provided for @agentActivityResultsSummary.
  ///
  /// In en, this message translates to:
  /// **'Review workload, won deals, completed tasks, and overdue follow-ups by agent.'**
  String get agentActivityResultsSummary;

  /// No description provided for @workload.
  ///
  /// In en, this message translates to:
  /// **'Workload'**
  String get workload;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @followUps.
  ///
  /// In en, this message translates to:
  /// **'Follow-ups'**
  String get followUps;

  /// No description provided for @wonDeals.
  ///
  /// In en, this message translates to:
  /// **'Won deals'**
  String get wonDeals;

  /// No description provided for @wonDealsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Won deals this month'**
  String get wonDealsThisMonth;

  /// No description provided for @taskCompletion.
  ///
  /// In en, this message translates to:
  /// **'Task completion'**
  String get taskCompletion;

  /// No description provided for @overdueTasks.
  ///
  /// In en, this message translates to:
  /// **'Overdue tasks'**
  String get overdueTasks;

  /// No description provided for @noPropertiesFound.
  ///
  /// In en, this message translates to:
  /// **'No properties found.'**
  String get noPropertiesFound;

  /// No description provided for @scheduleAndPriority.
  ///
  /// In en, this message translates to:
  /// **'Schedule and priority'**
  String get scheduleAndPriority;

  /// No description provided for @selectDueDate.
  ///
  /// In en, this message translates to:
  /// **'Select due date'**
  String get selectDueDate;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @dashboardRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get dashboardRecentActivity;

  /// No description provided for @dashboardRecentActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Latest logged CRM changes for this company.'**
  String get dashboardRecentActivitySubtitle;

  /// No description provided for @dashboardNoRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity yet.'**
  String get dashboardNoRecentActivity;

  /// No description provided for @dashboardUnableToLoadRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Unable to load recent activity.'**
  String get dashboardUnableToLoadRecentActivity;

  /// No description provided for @teamRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Team Recent Activity'**
  String get teamRecentActivity;

  /// No description provided for @teamRecentActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Latest logged CRM changes for your team.'**
  String get teamRecentActivitySubtitle;

  /// No description provided for @noRecentTeamActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent team activity yet.'**
  String get noRecentTeamActivity;

  /// No description provided for @dashboardAuditActionLabel.
  ///
  /// In en, this message translates to:
  /// **'{module} · {action}'**
  String dashboardAuditActionLabel(Object module, Object action);

  /// No description provided for @dashboardAuditCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get dashboardAuditCreated;

  /// No description provided for @dashboardAuditUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get dashboardAuditUpdated;

  /// No description provided for @dashboardAuditArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get dashboardAuditArchived;

  /// No description provided for @dashboardAuditDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get dashboardAuditDeactivated;

  /// No description provided for @dashboardAuditAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get dashboardAuditAssigned;

  /// No description provided for @dashboardAuditStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Status changed'**
  String get dashboardAuditStatusChanged;

  /// No description provided for @dashboardAuditStageChanged.
  ///
  /// In en, this message translates to:
  /// **'Stage changed'**
  String get dashboardAuditStageChanged;

  /// No description provided for @dashboardAuditCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get dashboardAuditCompleted;

  /// No description provided for @dashboardAuditCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get dashboardAuditCancelled;

  /// No description provided for @dashboardAuditImageAdded.
  ///
  /// In en, this message translates to:
  /// **'Image added'**
  String get dashboardAuditImageAdded;

  /// No description provided for @dashboardAuditImageRemoved.
  ///
  /// In en, this message translates to:
  /// **'Image removed'**
  String get dashboardAuditImageRemoved;

  /// No description provided for @dashboardAuditRestored.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get dashboardAuditRestored;

  /// No description provided for @dashboardAuditExportGenerated.
  ///
  /// In en, this message translates to:
  /// **'Export generated'**
  String get dashboardAuditExportGenerated;

  /// No description provided for @dashboardAuditLead.
  ///
  /// In en, this message translates to:
  /// **'Lead'**
  String get dashboardAuditLead;

  /// No description provided for @dashboardAuditClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get dashboardAuditClient;

  /// No description provided for @dashboardAuditProperty.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get dashboardAuditProperty;

  /// No description provided for @dashboardAuditTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get dashboardAuditTask;

  /// No description provided for @dashboardAuditDeal.
  ///
  /// In en, this message translates to:
  /// **'Deal'**
  String get dashboardAuditDeal;

  /// No description provided for @dashboardActivityLeadUpdated.
  ///
  /// In en, this message translates to:
  /// **'Lead updated'**
  String get dashboardActivityLeadUpdated;

  /// No description provided for @dashboardActivityClientUpdated.
  ///
  /// In en, this message translates to:
  /// **'Client updated'**
  String get dashboardActivityClientUpdated;

  /// No description provided for @dashboardActivityPropertyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Property updated'**
  String get dashboardActivityPropertyUpdated;

  /// No description provided for @dashboardActivityTaskUpdated.
  ///
  /// In en, this message translates to:
  /// **'Task updated'**
  String get dashboardActivityTaskUpdated;

  /// No description provided for @dashboardActivityTaskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Task completed'**
  String get dashboardActivityTaskCompleted;

  /// No description provided for @dashboardActivityDealUpdated.
  ///
  /// In en, this message translates to:
  /// **'Deal updated'**
  String get dashboardActivityDealUpdated;

  /// No description provided for @dashboardActivityDealWon.
  ///
  /// In en, this message translates to:
  /// **'Deal won'**
  String get dashboardActivityDealWon;

  /// No description provided for @dashboardActivityDealLost.
  ///
  /// In en, this message translates to:
  /// **'Deal lost'**
  String get dashboardActivityDealLost;

  /// No description provided for @dashboardJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get dashboardJustNow;

  /// No description provided for @dashboardMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String dashboardMinutesAgo(int count);

  /// No description provided for @dashboardHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hr ago'**
  String dashboardHoursAgo(int count);

  /// No description provided for @dashboardYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dashboardYesterday;

  /// No description provided for @byUser.
  ///
  /// In en, this message translates to:
  /// **'By {name}'**
  String byUser(String name);

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get unknownUser;

  /// No description provided for @dueDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Due date is required.'**
  String get dueDateRequired;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @allPriorities.
  ///
  /// In en, this message translates to:
  /// **'All priorities'**
  String get allPriorities;

  /// No description provided for @noTasksYet.
  ///
  /// In en, this message translates to:
  /// **'No tasks have been created yet.'**
  String get noTasksYet;

  /// No description provided for @noTasksMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No tasks match the current filters.'**
  String get noTasksMatchFilters;

  /// No description provided for @lead.
  ///
  /// In en, this message translates to:
  /// **'Lead'**
  String get lead;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @property.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get property;

  /// No description provided for @deal.
  ///
  /// In en, this message translates to:
  /// **'Deal'**
  String get deal;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @deals.
  ///
  /// In en, this message translates to:
  /// **'Deals'**
  String get deals;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @salesWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Lead-to-deal journey'**
  String get salesWorkspace;

  /// No description provided for @searchCrm.
  ///
  /// In en, this message translates to:
  /// **'Search Masar CRM'**
  String get searchCrm;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @crmUser.
  ///
  /// In en, this message translates to:
  /// **'Masar user'**
  String get crmUser;

  /// No description provided for @workspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get workspace;

  /// No description provided for @crmOverview.
  ///
  /// In en, this message translates to:
  /// **'Masar CRM overview'**
  String get crmOverview;

  /// No description provided for @dashboardPlaceholderDescription.
  ///
  /// In en, this message translates to:
  /// **'Key sales, leads, follow-ups, and property activity will appear here.'**
  String get dashboardPlaceholderDescription;

  /// No description provided for @totalLeads.
  ///
  /// In en, this message translates to:
  /// **'Total leads'**
  String get totalLeads;

  /// No description provided for @newLeads.
  ///
  /// In en, this message translates to:
  /// **'New leads'**
  String get newLeads;

  /// No description provided for @activeLeads.
  ///
  /// In en, this message translates to:
  /// **'Contacted / active leads'**
  String get activeLeads;

  /// No description provided for @unassignedLeads.
  ///
  /// In en, this message translates to:
  /// **'Unassigned leads'**
  String get unassignedLeads;

  /// No description provided for @followUpsDue.
  ///
  /// In en, this message translates to:
  /// **'Follow-ups due'**
  String get followUpsDue;

  /// No description provided for @openDeals.
  ///
  /// In en, this message translates to:
  /// **'Open deals'**
  String get openDeals;

  /// No description provided for @availableProperties.
  ///
  /// In en, this message translates to:
  /// **'Available properties'**
  String get availableProperties;

  /// No description provided for @authScreenPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Authentication screen placeholder'**
  String get authScreenPlaceholder;

  /// No description provided for @openDashboard.
  ///
  /// In en, this message translates to:
  /// **'Open dashboard'**
  String get openDashboard;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From lead to deal, one clear path.'**
  String get loginSubtitle;

  /// No description provided for @loginSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Need help getting started?'**
  String get loginSupportTitle;

  /// No description provided for @loginSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Masar support to create your company account or get an invitation.'**
  String get loginSupportSubtitle;

  /// No description provided for @loginSupportWhatsAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello Masar Support, I need help creating or accessing my company account.'**
  String get loginSupportWhatsAppMessage;

  /// No description provided for @loginSupportEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'Masar CRM access request'**
  String get loginSupportEmailSubject;

  /// No description provided for @loginSupportEmailBody.
  ///
  /// In en, this message translates to:
  /// **'Hello Masar Support,\n\nI need help creating or accessing my company account.\n\nThank you.'**
  String get loginSupportEmailBody;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required.'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get passwordRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Check your internet connection.'**
  String get authErrorConnection;

  /// No description provided for @authErrorSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign in. Please try again.'**
  String get authErrorSignInFailed;

  /// No description provided for @authErrorSignOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign out. Please try again.'**
  String get authErrorSignOutFailed;

  /// No description provided for @authErrorProfileMissing.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your user profile.'**
  String get authErrorProfileMissing;

  /// No description provided for @authErrorInactiveAccount.
  ///
  /// In en, this message translates to:
  /// **'Your account is inactive. Please contact an administrator.'**
  String get authErrorInactiveAccount;

  /// No description provided for @authErrorAccountNotLinked.
  ///
  /// In en, this message translates to:
  /// **'This account is not linked to an active company.'**
  String get authErrorAccountNotLinked;

  /// No description provided for @authErrorCompanyInactive.
  ///
  /// In en, this message translates to:
  /// **'This company is inactive. Please contact platform support.'**
  String get authErrorCompanyInactive;

  /// No description provided for @logoutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutTooltip;

  /// No description provided for @createLead.
  ///
  /// In en, this message translates to:
  /// **'Create lead'**
  String get createLead;

  /// No description provided for @quickAdd.
  ///
  /// In en, this message translates to:
  /// **'Quick add'**
  String get quickAdd;

  /// No description provided for @addLead.
  ///
  /// In en, this message translates to:
  /// **'Add lead'**
  String get addLead;

  /// No description provided for @addClient.
  ///
  /// In en, this message translates to:
  /// **'Add client'**
  String get addClient;

  /// No description provided for @savedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully.'**
  String get savedSuccessfully;

  /// No description provided for @updatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Updated successfully.'**
  String get updatedSuccessfully;

  /// No description provided for @unableToSave.
  ///
  /// In en, this message translates to:
  /// **'Unable to save. Please try again.'**
  String get unableToSave;

  /// No description provided for @unableToAssignClient.
  ///
  /// In en, this message translates to:
  /// **'Unable to assign client. Please try again.'**
  String get unableToAssignClient;

  /// No description provided for @unableToUpdateTask.
  ///
  /// In en, this message translates to:
  /// **'Unable to update task. Please try again.'**
  String get unableToUpdateTask;

  /// No description provided for @actionCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Action completed successfully.'**
  String get actionCompletedSuccessfully;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed. Please try again.'**
  String get actionFailed;

  /// No description provided for @createClient.
  ///
  /// In en, this message translates to:
  /// **'Create client'**
  String get createClient;

  /// No description provided for @editClient.
  ///
  /// In en, this message translates to:
  /// **'Edit client'**
  String get editClient;

  /// No description provided for @updateClient.
  ///
  /// In en, this message translates to:
  /// **'Update client'**
  String get updateClient;

  /// No description provided for @clientDetails.
  ///
  /// In en, this message translates to:
  /// **'Client details'**
  String get clientDetails;

  /// No description provided for @clientCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Client created successfully.'**
  String get clientCreatedSuccessfully;

  /// No description provided for @clientUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Client updated successfully.'**
  String get clientUpdatedSuccessfully;

  /// No description provided for @assignClient.
  ///
  /// In en, this message translates to:
  /// **'Assign client'**
  String get assignClient;

  /// No description provided for @clientAssignedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Client assigned successfully.'**
  String get clientAssignedSuccessfully;

  /// No description provided for @noClientsFound.
  ///
  /// In en, this message translates to:
  /// **'No clients found.'**
  String get noClientsFound;

  /// No description provided for @noAssignedClientsFound.
  ///
  /// In en, this message translates to:
  /// **'No assigned clients found.'**
  String get noAssignedClientsFound;

  /// No description provided for @archiveClient.
  ///
  /// In en, this message translates to:
  /// **'Archive client'**
  String get archiveClient;

  /// No description provided for @archiveClientConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This client will be archived and hidden from the active clients list.'**
  String get archiveClientConfirmation;

  /// No description provided for @clientArchivedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Client archived successfully.'**
  String get clientArchivedSuccessfully;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @restoreRecord.
  ///
  /// In en, this message translates to:
  /// **'Restore record'**
  String get restoreRecord;

  /// No description provided for @restoreRecordConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This record will return to active lists.'**
  String get restoreRecordConfirmation;

  /// No description provided for @archiveReason.
  ///
  /// In en, this message translates to:
  /// **'Archive reason'**
  String get archiveReason;

  /// No description provided for @noArchivedRecords.
  ///
  /// In en, this message translates to:
  /// **'No archived records'**
  String get noArchivedRecords;

  /// No description provided for @archivedRecordsHiddenFromActiveLists.
  ///
  /// In en, this message translates to:
  /// **'Archived records stay hidden from active lists.'**
  String get archivedRecordsHiddenFromActiveLists;

  /// No description provided for @recordRestoredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Record restored successfully.'**
  String get recordRestoredSuccessfully;

  /// No description provided for @clientNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Client not found. Open it from the clients list.'**
  String get clientNotFoundMessage;

  /// No description provided for @backToClients.
  ///
  /// In en, this message translates to:
  /// **'Back to clients'**
  String get backToClients;

  /// No description provided for @clientPreferences.
  ///
  /// In en, this message translates to:
  /// **'Client preferences'**
  String get clientPreferences;

  /// No description provided for @budgetMaxMustBeGreaterThanBudgetMin.
  ///
  /// In en, this message translates to:
  /// **'Maximum budget cannot be less than minimum budget.'**
  String get budgetMaxMustBeGreaterThanBudgetMin;

  /// No description provided for @createProperty.
  ///
  /// In en, this message translates to:
  /// **'Create property'**
  String get createProperty;

  /// No description provided for @editProperty.
  ///
  /// In en, this message translates to:
  /// **'Edit property'**
  String get editProperty;

  /// No description provided for @updateProperty.
  ///
  /// In en, this message translates to:
  /// **'Update property'**
  String get updateProperty;

  /// No description provided for @leadDetails.
  ///
  /// In en, this message translates to:
  /// **'Lead details'**
  String get leadDetails;

  /// No description provided for @leadName.
  ///
  /// In en, this message translates to:
  /// **'Lead name'**
  String get leadName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @sourceDetails.
  ///
  /// In en, this message translates to:
  /// **'Source details'**
  String get sourceDetails;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @budgetMin.
  ///
  /// In en, this message translates to:
  /// **'Minimum budget'**
  String get budgetMin;

  /// No description provided for @budgetMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum budget'**
  String get budgetMax;

  /// No description provided for @preferredLocation.
  ///
  /// In en, this message translates to:
  /// **'Preferred location'**
  String get preferredLocation;

  /// No description provided for @preferredPropertyType.
  ///
  /// In en, this message translates to:
  /// **'Preferred property type'**
  String get preferredPropertyType;

  /// No description provided for @assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get assignedTo;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @saveLead.
  ///
  /// In en, this message translates to:
  /// **'Save lead'**
  String get saveLead;

  /// No description provided for @leadCreated.
  ///
  /// In en, this message translates to:
  /// **'Lead created successfully.'**
  String get leadCreated;

  /// No description provided for @noLeads.
  ///
  /// In en, this message translates to:
  /// **'No leads yet.'**
  String get noLeads;

  /// No description provided for @unableToLoadLeads.
  ///
  /// In en, this message translates to:
  /// **'Unable to load leads. Please try again.'**
  String get unableToLoadLeads;

  /// No description provided for @unableToCreateLead.
  ///
  /// In en, this message translates to:
  /// **'Unable to create lead. Please try again.'**
  String get unableToCreateLead;

  /// No description provided for @propertiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage company listings and availability in one practical view.'**
  String get propertiesSubtitle;

  /// No description provided for @noProperties.
  ///
  /// In en, this message translates to:
  /// **'No properties yet.'**
  String get noProperties;

  /// No description provided for @unableToLoadProperties.
  ///
  /// In en, this message translates to:
  /// **'Unable to load properties. Please try again.'**
  String get unableToLoadProperties;

  /// No description provided for @propertyTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get propertyTitle;

  /// No description provided for @propertyType.
  ///
  /// In en, this message translates to:
  /// **'Property type'**
  String get propertyType;

  /// No description provided for @listingType.
  ///
  /// In en, this message translates to:
  /// **'Listing type'**
  String get listingType;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @apartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment'**
  String get apartment;

  /// No description provided for @villa.
  ///
  /// In en, this message translates to:
  /// **'Villa'**
  String get villa;

  /// No description provided for @office.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get office;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @land.
  ///
  /// In en, this message translates to:
  /// **'Land'**
  String get land;

  /// No description provided for @studio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get studio;

  /// No description provided for @duplex.
  ///
  /// In en, this message translates to:
  /// **'Duplex'**
  String get duplex;

  /// No description provided for @penthouse.
  ///
  /// In en, this message translates to:
  /// **'Penthouse'**
  String get penthouse;

  /// No description provided for @sale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get sale;

  /// No description provided for @rent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get rent;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @reserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get reserved;

  /// No description provided for @sold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get sold;

  /// No description provided for @rented.
  ///
  /// In en, this message translates to:
  /// **'Rented'**
  String get rented;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredField;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number.'**
  String get enterValidNumber;

  /// No description provided for @valueMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Value must be greater than zero.'**
  String get valueMustBePositive;

  /// No description provided for @valueMustBeNonNegative.
  ///
  /// In en, this message translates to:
  /// **'Value cannot be negative.'**
  String get valueMustBeNonNegative;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @bedrooms.
  ///
  /// In en, this message translates to:
  /// **'Bedrooms'**
  String get bedrooms;

  /// No description provided for @bathrooms.
  ///
  /// In en, this message translates to:
  /// **'Bathrooms'**
  String get bathrooms;

  /// No description provided for @compound.
  ///
  /// In en, this message translates to:
  /// **'Compound'**
  String get compound;

  /// No description provided for @ownerName.
  ///
  /// In en, this message translates to:
  /// **'Owner name'**
  String get ownerName;

  /// No description provided for @ownerPhone.
  ///
  /// In en, this message translates to:
  /// **'Owner phone'**
  String get ownerPhone;

  /// No description provided for @propertyBasicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic information'**
  String get propertyBasicInformation;

  /// No description provided for @propertyMetrics.
  ///
  /// In en, this message translates to:
  /// **'Property metrics'**
  String get propertyMetrics;

  /// No description provided for @propertyLocationSection.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get propertyLocationSection;

  /// No description provided for @propertyOwnerSection.
  ///
  /// In en, this message translates to:
  /// **'Owner information'**
  String get propertyOwnerSection;

  /// No description provided for @propertyImages.
  ///
  /// In en, this message translates to:
  /// **'Property images'**
  String get propertyImages;

  /// No description provided for @propertyImagesHint.
  ///
  /// In en, this message translates to:
  /// **'Upload clear property photos. The first image is used as the cover.'**
  String get propertyImagesHint;

  /// No description provided for @addPropertyImages.
  ///
  /// In en, this message translates to:
  /// **'Add images'**
  String get addPropertyImages;

  /// No description provided for @noPropertyImagesYet.
  ///
  /// In en, this message translates to:
  /// **'No property images yet.'**
  String get noPropertyImagesYet;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get removeImage;

  /// No description provided for @newImage.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newImage;

  /// No description provided for @propertyImageInvalidType.
  ///
  /// In en, this message translates to:
  /// **'Only image files are allowed.'**
  String get propertyImageInvalidType;

  /// No description provided for @propertyImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Each property image must be 5 MB or smaller.'**
  String get propertyImageTooLarge;

  /// No description provided for @unableToPickPropertyImages.
  ///
  /// In en, this message translates to:
  /// **'Unable to select property images. Please try again.'**
  String get unableToPickPropertyImages;

  /// No description provided for @propertyCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Property created successfully.'**
  String get propertyCreatedSuccessfully;

  /// No description provided for @propertyUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Property updated successfully.'**
  String get propertyUpdatedSuccessfully;

  /// No description provided for @propertyDetails.
  ///
  /// In en, this message translates to:
  /// **'Property details'**
  String get propertyDetails;

  /// No description provided for @searchProperties.
  ///
  /// In en, this message translates to:
  /// **'Search properties'**
  String get searchProperties;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @noMatchingProperties.
  ///
  /// In en, this message translates to:
  /// **'No properties match your filters.'**
  String get noMatchingProperties;

  /// No description provided for @adjustPropertyFiltersHint.
  ///
  /// In en, this message translates to:
  /// **'Try changing search text or filter values.'**
  String get adjustPropertyFiltersHint;

  /// No description provided for @allPropertyTypes.
  ///
  /// In en, this message translates to:
  /// **'All property types'**
  String get allPropertyTypes;

  /// No description provided for @allListingTypes.
  ///
  /// In en, this message translates to:
  /// **'All listing types'**
  String get allListingTypes;

  /// No description provided for @propertiesResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total} properties'**
  String propertiesResultsCount(Object shown, Object total);

  /// No description provided for @propertyNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Property not found. Open it from the properties list.'**
  String get propertyNotFoundMessage;

  /// No description provided for @backToProperties.
  ///
  /// In en, this message translates to:
  /// **'Back to properties'**
  String get backToProperties;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get createdAt;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated at'**
  String get updatedAt;

  /// No description provided for @auditInfo.
  ///
  /// In en, this message translates to:
  /// **'Audit info'**
  String get auditInfo;

  /// No description provided for @unableToLoadPropertyForEdit.
  ///
  /// In en, this message translates to:
  /// **'Unable to load property for editing. Open it from the properties list.'**
  String get unableToLoadPropertyForEdit;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @newLead.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLead;

  /// No description provided for @newLeadStatus.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLeadStatus;

  /// No description provided for @contacted.
  ///
  /// In en, this message translates to:
  /// **'Contacted'**
  String get contacted;

  /// No description provided for @contactedLeadStatus.
  ///
  /// In en, this message translates to:
  /// **'Contacted'**
  String get contactedLeadStatus;

  /// No description provided for @interested.
  ///
  /// In en, this message translates to:
  /// **'Interested'**
  String get interested;

  /// No description provided for @interestedLeadStatus.
  ///
  /// In en, this message translates to:
  /// **'Interested'**
  String get interestedLeadStatus;

  /// No description provided for @visitScheduled.
  ///
  /// In en, this message translates to:
  /// **'Visit scheduled'**
  String get visitScheduled;

  /// No description provided for @visitScheduledLeadStatus.
  ///
  /// In en, this message translates to:
  /// **'Visit scheduled'**
  String get visitScheduledLeadStatus;

  /// No description provided for @negotiation.
  ///
  /// In en, this message translates to:
  /// **'Negotiation'**
  String get negotiation;

  /// No description provided for @negotiationLeadStatus.
  ///
  /// In en, this message translates to:
  /// **'Negotiation'**
  String get negotiationLeadStatus;

  /// No description provided for @won.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get won;

  /// No description provided for @wonLeadStatus.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get wonLeadStatus;

  /// No description provided for @lost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get lost;

  /// No description provided for @lostLeadStatus.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get lostLeadStatus;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @facebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get facebook;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @phoneCall.
  ///
  /// In en, this message translates to:
  /// **'Phone call'**
  String get phoneCall;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @referral.
  ///
  /// In en, this message translates to:
  /// **'Referral'**
  String get referral;

  /// No description provided for @walkIn.
  ///
  /// In en, this message translates to:
  /// **'Walk-in'**
  String get walkIn;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @leadsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track new inquiries and follow up with prospects.'**
  String get leadsSubtitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @archiveLead.
  ///
  /// In en, this message translates to:
  /// **'Archive lead'**
  String get archiveLead;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @deactivateProperty.
  ///
  /// In en, this message translates to:
  /// **'Deactivate property'**
  String get deactivateProperty;

  /// No description provided for @deactivatePropertyConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This property will be marked as inactive.'**
  String get deactivatePropertyConfirmation;

  /// No description provided for @propertyDeactivatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Property deactivated successfully.'**
  String get propertyDeactivatedSuccessfully;

  /// No description provided for @unableToDeactivateProperty.
  ///
  /// In en, this message translates to:
  /// **'Unable to deactivate property. Please try again.'**
  String get unableToDeactivateProperty;

  /// No description provided for @archiveLeadConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This lead will be archived and hidden from the active leads list.'**
  String get archiveLeadConfirmation;

  /// No description provided for @leadArchived.
  ///
  /// In en, this message translates to:
  /// **'Lead archived successfully.'**
  String get leadArchived;

  /// No description provided for @unableToArchiveLead.
  ///
  /// In en, this message translates to:
  /// **'Unable to archive lead. Please try again.'**
  String get unableToArchiveLead;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to perform this action.'**
  String get permissionDenied;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact information'**
  String get contactInformation;

  /// No description provided for @lastContact.
  ///
  /// In en, this message translates to:
  /// **'Last contact'**
  String get lastContact;

  /// No description provided for @nextFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Next follow-up'**
  String get nextFollowUp;

  /// No description provided for @clearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get clearDate;

  /// No description provided for @leadPreferences.
  ///
  /// In en, this message translates to:
  /// **'Lead preferences'**
  String get leadPreferences;

  /// No description provided for @leadAssignment.
  ///
  /// In en, this message translates to:
  /// **'Assignment and notes'**
  String get leadAssignment;

  /// No description provided for @missingCompanyProfile.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your company profile. Please sign in again.'**
  String get missingCompanyProfile;

  /// No description provided for @editLead.
  ///
  /// In en, this message translates to:
  /// **'Edit lead'**
  String get editLead;

  /// No description provided for @updateLead.
  ///
  /// In en, this message translates to:
  /// **'Update lead'**
  String get updateLead;

  /// No description provided for @leadUpdated.
  ///
  /// In en, this message translates to:
  /// **'Lead updated successfully.'**
  String get leadUpdated;

  /// No description provided for @searchLeads.
  ///
  /// In en, this message translates to:
  /// **'Search leads'**
  String get searchLeads;

  /// No description provided for @allSources.
  ///
  /// In en, this message translates to:
  /// **'All sources'**
  String get allSources;

  /// No description provided for @allAgents.
  ///
  /// In en, this message translates to:
  /// **'All agents'**
  String get allAgents;

  /// No description provided for @assignee.
  ///
  /// In en, this message translates to:
  /// **'Assignee'**
  String get assignee;

  /// No description provided for @allAssignees.
  ///
  /// In en, this message translates to:
  /// **'All assignees'**
  String get allAssignees;

  /// No description provided for @changeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get changeStatus;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNote;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @notesHistory.
  ///
  /// In en, this message translates to:
  /// **'Notes history'**
  String get notesHistory;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get noNotes;

  /// No description provided for @saveNote.
  ///
  /// In en, this message translates to:
  /// **'Save note'**
  String get saveNote;

  /// No description provided for @unableToLoadNotes.
  ///
  /// In en, this message translates to:
  /// **'Unable to load notes. Please try again.'**
  String get unableToLoadNotes;

  /// No description provided for @unableToAddNote.
  ///
  /// In en, this message translates to:
  /// **'Unable to add note. Please try again.'**
  String get unableToAddNote;

  /// No description provided for @activeUsers.
  ///
  /// In en, this message translates to:
  /// **'Active users'**
  String get activeUsers;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @onlyAdminsManagersCanAssign.
  ///
  /// In en, this message translates to:
  /// **'Only admins and managers can assign leads.'**
  String get onlyAdminsManagersCanAssign;

  /// No description provided for @recordMustBeAssignedBeforeSaving.
  ///
  /// In en, this message translates to:
  /// **'This record must be assigned before saving.'**
  String get recordMustBeAssignedBeforeSaving;

  /// No description provided for @canOnlyAssignRecordsToYourTeam.
  ///
  /// In en, this message translates to:
  /// **'You can only assign records to users in your team.'**
  String get canOnlyAssignRecordsToYourTeam;

  /// No description provided for @selectedAssigneeInactive.
  ///
  /// In en, this message translates to:
  /// **'The selected assignee is inactive.'**
  String get selectedAssigneeInactive;

  /// No description provided for @selectedAssigneeNotEligible.
  ///
  /// In en, this message translates to:
  /// **'The selected assignee is not eligible for this record.'**
  String get selectedAssigneeNotEligible;

  /// No description provided for @permissionToViewAnotherTeamRecordsDenied.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view records from another team.'**
  String get permissionToViewAnotherTeamRecordsDenied;

  /// No description provided for @sessionOrCompanyProfileMissing.
  ///
  /// In en, this message translates to:
  /// **'Your session or company profile is missing. Please sign in again.'**
  String get sessionOrCompanyProfileMissing;

  /// No description provided for @cannotAssignAcrossCompanies.
  ///
  /// In en, this message translates to:
  /// **'Cannot assign a lead outside your company.'**
  String get cannotAssignAcrossCompanies;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get accessDenied;

  /// No description provided for @assignedUser.
  ///
  /// In en, this message translates to:
  /// **'Assigned user'**
  String get assignedUser;

  /// No description provided for @assignedUserUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Assigned user unavailable'**
  String get assignedUserUnavailable;

  /// No description provided for @youDoNotHavePermissionToViewLead.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view this lead.'**
  String get youDoNotHavePermissionToViewLead;

  /// No description provided for @youDoNotHavePermissionToEditLead.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to edit this lead.'**
  String get youDoNotHavePermissionToEditLead;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @leadCreatedEvent.
  ///
  /// In en, this message translates to:
  /// **'Lead created'**
  String get leadCreatedEvent;

  /// No description provided for @leadAssignedEvent.
  ///
  /// In en, this message translates to:
  /// **'Lead assigned'**
  String get leadAssignedEvent;

  /// No description provided for @leadReassignedEvent.
  ///
  /// In en, this message translates to:
  /// **'Lead reassigned'**
  String get leadReassignedEvent;

  /// No description provided for @statusChangedEvent.
  ///
  /// In en, this message translates to:
  /// **'Status changed'**
  String get statusChangedEvent;

  /// No description provided for @noteAddedEvent.
  ///
  /// In en, this message translates to:
  /// **'Note added'**
  String get noteAddedEvent;

  /// No description provided for @archivedEvent.
  ///
  /// In en, this message translates to:
  /// **'Lead archived'**
  String get archivedEvent;

  /// No description provided for @updatedEvent.
  ///
  /// In en, this message translates to:
  /// **'Lead updated'**
  String get updatedEvent;

  /// No description provided for @changedFrom.
  ///
  /// In en, this message translates to:
  /// **'Changed from'**
  String get changedFrom;

  /// No description provided for @changedTo.
  ///
  /// In en, this message translates to:
  /// **'Changed to'**
  String get changedTo;

  /// No description provided for @leadCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Lead created by {user}'**
  String leadCreatedBy(Object user);

  /// No description provided for @statusChangedToBy.
  ///
  /// In en, this message translates to:
  /// **'Status changed to {status} by {user}'**
  String statusChangedToBy(Object status, Object user);

  /// No description provided for @noteAddedBy.
  ///
  /// In en, this message translates to:
  /// **'Note added by {user}'**
  String noteAddedBy(Object user);

  /// No description provided for @leadReassignedBy.
  ///
  /// In en, this message translates to:
  /// **'Lead reassigned by {user}'**
  String leadReassignedBy(Object user);

  /// No description provided for @leadReassignedFromToBy.
  ///
  /// In en, this message translates to:
  /// **'Lead reassigned from {fromUser} to {toUser} by {actor}'**
  String leadReassignedFromToBy(Object fromUser, Object toUser, Object actor);

  /// No description provided for @leadArchivedBy.
  ///
  /// In en, this message translates to:
  /// **'Lead archived by {user}'**
  String leadArchivedBy(Object user);

  /// No description provided for @noLeadsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No leads available.'**
  String get noLeadsAvailable;

  /// No description provided for @noNotesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No notes available.'**
  String get noNotesAvailable;

  /// No description provided for @noTimelineEvents.
  ///
  /// In en, this message translates to:
  /// **'No timeline events yet.'**
  String get noTimelineEvents;

  /// No description provided for @fieldChangedBy.
  ///
  /// In en, this message translates to:
  /// **'{field} changed by {user}'**
  String fieldChangedBy(Object field, Object user);

  /// No description provided for @changedFromTo.
  ///
  /// In en, this message translates to:
  /// **'Changed from {oldValue} to {newValue}'**
  String changedFromTo(Object oldValue, Object newValue);

  /// No description provided for @assignedToLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get assignedToLabel;

  /// No description provided for @leadAssignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to: {name}'**
  String leadAssignedTo(Object name);

  /// No description provided for @fullNameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameUpdated;

  /// No description provided for @phoneUpdated.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneUpdated;

  /// No description provided for @emailUpdated.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailUpdated;

  /// No description provided for @sourceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get sourceUpdated;

  /// No description provided for @statusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusUpdated;

  /// No description provided for @priorityUpdated.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorityUpdated;

  /// No description provided for @budgetUpdated.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetUpdated;

  /// No description provided for @preferredLocationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Preferred location'**
  String get preferredLocationUpdated;

  /// No description provided for @preferredPropertyTypeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Preferred property type'**
  String get preferredPropertyTypeUpdated;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get applyFilters;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @selectLeadPreview.
  ///
  /// In en, this message translates to:
  /// **'Select a lead'**
  String get selectLeadPreview;

  /// No description provided for @selectLeadPreviewMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose a lead from the list to preview contact, status, and next actions.'**
  String get selectLeadPreviewMessage;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @unableToConnect.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect. Check your internet connection and try again.'**
  String get unableToConnect;

  /// No description provided for @leadUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to update lead. Please try again.'**
  String get leadUpdateFailed;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available.'**
  String get noData;

  /// No description provided for @leadCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Lead created successfully.'**
  String get leadCreatedSuccessfully;

  /// No description provided for @leadUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Lead updated successfully.'**
  String get leadUpdatedSuccessfully;

  /// No description provided for @leadArchivedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Lead archived successfully.'**
  String get leadArchivedSuccessfully;

  /// No description provided for @leadStatusUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Lead status updated successfully.'**
  String get leadStatusUpdatedSuccessfully;

  /// No description provided for @leadAssignedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Lead assigned successfully.'**
  String get leadAssignedSuccessfully;

  /// No description provided for @noteAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Note added successfully.'**
  String get noteAddedSuccessfully;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @allDueDates.
  ///
  /// In en, this message translates to:
  /// **'All due dates'**
  String get allDueDates;

  /// No description provided for @dueDateFilter.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDateFilter;

  /// No description provided for @notScheduled.
  ///
  /// In en, this message translates to:
  /// **'Not scheduled'**
  String get notScheduled;

  /// No description provided for @allFollowUps.
  ///
  /// In en, this message translates to:
  /// **'All follow-ups'**
  String get allFollowUps;

  /// No description provided for @needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get needsAttention;

  /// No description provided for @staleLead.
  ///
  /// In en, this message translates to:
  /// **'Stale lead'**
  String get staleLead;

  /// No description provided for @contactedTodayFollowUpStillOverdue.
  ///
  /// In en, this message translates to:
  /// **'Contacted today, follow-up still overdue'**
  String get contactedTodayFollowUpStillOverdue;

  /// No description provided for @markContactedToday.
  ///
  /// In en, this message translates to:
  /// **'Mark contacted today'**
  String get markContactedToday;

  /// No description provided for @leadMarkedContactedToday.
  ///
  /// In en, this message translates to:
  /// **'Lead marked as contacted today.'**
  String get leadMarkedContactedToday;

  /// No description provided for @scheduleFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Schedule follow-up'**
  String get scheduleFollowUp;

  /// No description provided for @duplicateLeadFound.
  ///
  /// In en, this message translates to:
  /// **'A lead with this phone or email already exists.'**
  String get duplicateLeadFound;

  /// No description provided for @dashboardGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get dashboardGoodMorning;

  /// No description provided for @dashboardGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get dashboardGoodAfternoon;

  /// No description provided for @dashboardGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get dashboardGoodEvening;

  /// No description provided for @dashboardOverdueFollowUps.
  ///
  /// In en, this message translates to:
  /// **'Overdue follow-ups'**
  String get dashboardOverdueFollowUps;

  /// No description provided for @dashboardUpcomingFollowUps.
  ///
  /// In en, this message translates to:
  /// **'Upcoming follow-ups'**
  String get dashboardUpcomingFollowUps;

  /// No description provided for @dashboardAvailableProperties.
  ///
  /// In en, this message translates to:
  /// **'Available properties'**
  String get dashboardAvailableProperties;

  /// No description provided for @dashboardVsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'vs last month'**
  String get dashboardVsLastMonth;

  /// No description provided for @dashboardOfCurrentTotal.
  ///
  /// In en, this message translates to:
  /// **'of current total'**
  String get dashboardOfCurrentTotal;

  /// No description provided for @dashboardVisualAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Workspace analytics'**
  String get dashboardVisualAnalytics;

  /// No description provided for @dashboardLeadStatusDistribution.
  ///
  /// In en, this message translates to:
  /// **'Lead status distribution'**
  String get dashboardLeadStatusDistribution;

  /// No description provided for @dashboardTasksDueBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Tasks due breakdown'**
  String get dashboardTasksDueBreakdown;

  /// No description provided for @dashboardPropertyStatusDistribution.
  ///
  /// In en, this message translates to:
  /// **'Property status distribution'**
  String get dashboardPropertyStatusDistribution;

  /// No description provided for @dashboardTodaysFollowUps.
  ///
  /// In en, this message translates to:
  /// **'Today’s follow-ups'**
  String get dashboardTodaysFollowUps;

  /// No description provided for @dashboardOverdueTasks.
  ///
  /// In en, this message translates to:
  /// **'Overdue tasks'**
  String get dashboardOverdueTasks;

  /// No description provided for @dashboardAppointmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment control'**
  String get dashboardAppointmentsTitle;

  /// No description provided for @nextAppointment.
  ///
  /// In en, this message translates to:
  /// **'Next appointment'**
  String get nextAppointment;

  /// No description provided for @noUpcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'No upcoming appointments'**
  String get noUpcomingAppointments;

  /// No description provided for @dashboardUnassignedLeads.
  ///
  /// In en, this message translates to:
  /// **'Unassigned leads'**
  String get dashboardUnassignedLeads;

  /// No description provided for @dashboardRecentlyUpdatedLeads.
  ///
  /// In en, this message translates to:
  /// **'Recently updated leads'**
  String get dashboardRecentlyUpdatedLeads;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get dashboardActive;

  /// No description provided for @dashboardInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get dashboardInactive;

  /// No description provided for @dashboardReservedOrClosed.
  ///
  /// In en, this message translates to:
  /// **'Reserved or closed'**
  String get dashboardReservedOrClosed;

  /// No description provided for @dashboardGeneralTask.
  ///
  /// In en, this message translates to:
  /// **'General task'**
  String get dashboardGeneralTask;

  /// No description provided for @dashboardKpiActiveLeads.
  ///
  /// In en, this message translates to:
  /// **'Active leads'**
  String get dashboardKpiActiveLeads;

  /// No description provided for @dashboardKpiHotOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Hot Opportunities'**
  String get dashboardKpiHotOpportunities;

  /// No description provided for @dashboardKpiDueTodayFollowUps.
  ///
  /// In en, this message translates to:
  /// **'Follow-ups today'**
  String get dashboardKpiDueTodayFollowUps;

  /// No description provided for @dashboardKpiOverdueActions.
  ///
  /// In en, this message translates to:
  /// **'Overdue actions'**
  String get dashboardKpiOverdueActions;

  /// No description provided for @dashboardKpiAppointmentsToday.
  ///
  /// In en, this message translates to:
  /// **'Appointments today'**
  String get dashboardKpiAppointmentsToday;

  /// No description provided for @dashboardKpiDealsPipeline.
  ///
  /// In en, this message translates to:
  /// **'Deals in pipeline'**
  String get dashboardKpiDealsPipeline;

  /// No description provided for @dashboardKpiExpectedPipeline.
  ///
  /// In en, this message translates to:
  /// **'Pipeline Value'**
  String get dashboardKpiExpectedPipeline;

  /// No description provided for @dashboardKpiActiveListings.
  ///
  /// In en, this message translates to:
  /// **'Available Properties'**
  String get dashboardKpiActiveListings;

  /// No description provided for @dashboardPeriodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashboardPeriodToday;

  /// No description provided for @dashboardPeriodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get dashboardPeriodThisMonth;

  /// No description provided for @dashboardPeriodCurrentScope.
  ///
  /// In en, this message translates to:
  /// **'Current role scope'**
  String get dashboardPeriodCurrentScope;

  /// No description provided for @dashboardNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data yet.'**
  String get dashboardNotEnoughData;

  /// No description provided for @dashboardPerformanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales performance'**
  String get dashboardPerformanceTitle;

  /// No description provided for @dashboardPerformanceOverview.
  ///
  /// In en, this message translates to:
  /// **'Performance Overview'**
  String get dashboardPerformanceOverview;

  /// No description provided for @dashboardLeadsTrend.
  ///
  /// In en, this message translates to:
  /// **'Leads trend'**
  String get dashboardLeadsTrend;

  /// No description provided for @dashboardFollowUpsCompletedMissed.
  ///
  /// In en, this message translates to:
  /// **'Follow-ups completed vs missed'**
  String get dashboardFollowUpsCompletedMissed;

  /// No description provided for @dashboardAppointmentsFlow.
  ///
  /// In en, this message translates to:
  /// **'Appointments booked and outcomes'**
  String get dashboardAppointmentsFlow;

  /// No description provided for @dashboardLeadSources.
  ///
  /// In en, this message translates to:
  /// **'Lead sources'**
  String get dashboardLeadSources;

  /// No description provided for @dashboardLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get dashboardLast7Days;

  /// No description provided for @dashboardTodayRailTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashboardTodayRailTitle;

  /// No description provided for @dashboardDueFollowUps.
  ///
  /// In en, this message translates to:
  /// **'Due follow-ups'**
  String get dashboardDueFollowUps;

  /// No description provided for @dashboardOverdueReminders.
  ///
  /// In en, this message translates to:
  /// **'Overdue reminders'**
  String get dashboardOverdueReminders;

  /// No description provided for @dashboardNoUrgentActions.
  ///
  /// In en, this message translates to:
  /// **'No urgent actions right now.'**
  String get dashboardNoUrgentActions;

  /// No description provided for @dashboardPipelineSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Sales pipeline'**
  String get dashboardPipelineSnapshot;

  /// No description provided for @dashboardPipelineHasNoValue.
  ///
  /// In en, this message translates to:
  /// **'Pipeline value will appear when deal values exist.'**
  String get dashboardPipelineHasNoValue;

  /// No description provided for @dashboardStuckDeals.
  ///
  /// In en, this message translates to:
  /// **'Stuck deals'**
  String get dashboardStuckDeals;

  /// No description provided for @dashboardDealRisks.
  ///
  /// In en, this message translates to:
  /// **'Deal risks'**
  String get dashboardDealRisks;

  /// No description provided for @dashboardClosingThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Closing this month'**
  String get dashboardClosingThisMonth;

  /// No description provided for @dashboardWonLost.
  ///
  /// In en, this message translates to:
  /// **'Won / lost'**
  String get dashboardWonLost;

  /// No description provided for @dashboardDealsByStage.
  ///
  /// In en, this message translates to:
  /// **'Deals by stage'**
  String get dashboardDealsByStage;

  /// No description provided for @dashboardTeamPerformance.
  ///
  /// In en, this message translates to:
  /// **'Team performance'**
  String get dashboardTeamPerformance;

  /// No description provided for @dashboardPersonalPerformance.
  ///
  /// In en, this message translates to:
  /// **'My performance'**
  String get dashboardPersonalPerformance;

  /// No description provided for @dashboardTopActiveAgent.
  ///
  /// In en, this message translates to:
  /// **'Top active agent'**
  String get dashboardTopActiveAgent;

  /// No description provided for @dashboardOverloadedAssignee.
  ///
  /// In en, this message translates to:
  /// **'Needs load review'**
  String get dashboardOverloadedAssignee;

  /// No description provided for @dashboardNoTeamSignal.
  ///
  /// In en, this message translates to:
  /// **'No team pressure signal right now.'**
  String get dashboardNoTeamSignal;

  /// No description provided for @dashboardPerformanceLimitedForRole.
  ///
  /// In en, this message translates to:
  /// **'Limited view for this role.'**
  String get dashboardPerformanceLimitedForRole;

  /// No description provided for @dashboardOverviewTab.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get dashboardOverviewTab;

  /// No description provided for @dashboardWorkQueue.
  ///
  /// In en, this message translates to:
  /// **'Work queue'**
  String get dashboardWorkQueue;

  /// No description provided for @dashboardPerformanceTab.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get dashboardPerformanceTab;

  /// No description provided for @dashboardOpportunitiesTab.
  ///
  /// In en, this message translates to:
  /// **'Opportunities'**
  String get dashboardOpportunitiesTab;

  /// No description provided for @dashboardQuickActionsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No quick actions are available for this role.'**
  String get dashboardQuickActionsUnavailable;

  /// No description provided for @dashboardImportantOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Important open opportunities'**
  String get dashboardImportantOpportunities;

  /// No description provided for @dashboardNoOpportunities.
  ///
  /// In en, this message translates to:
  /// **'No important opportunities yet.'**
  String get dashboardNoOpportunities;

  /// No description provided for @dashboardDailyInsight.
  ///
  /// In en, this message translates to:
  /// **'Daily insight'**
  String get dashboardDailyInsight;

  /// No description provided for @dashboardAppointmentsForDate.
  ///
  /// In en, this message translates to:
  /// **'Appointments {date}'**
  String dashboardAppointmentsForDate(Object date);

  /// No description provided for @dashboardNoAppointmentsForDay.
  ///
  /// In en, this message translates to:
  /// **'No appointments for this day.'**
  String get dashboardNoAppointmentsForDay;

  /// No description provided for @dashboardUrgentActions.
  ///
  /// In en, this message translates to:
  /// **'Urgent actions'**
  String get dashboardUrgentActions;

  /// No description provided for @dashboardUrgentFollowUps.
  ///
  /// In en, this message translates to:
  /// **'Urgent follow-ups'**
  String get dashboardUrgentFollowUps;

  /// No description provided for @dashboardNoUrgentFollowUps.
  ///
  /// In en, this message translates to:
  /// **'No urgent follow-ups.'**
  String get dashboardNoUrgentFollowUps;

  /// No description provided for @dashboardQuickAction.
  ///
  /// In en, this message translates to:
  /// **'Quick action'**
  String get dashboardQuickAction;

  /// No description provided for @dashboardTeamUser.
  ///
  /// In en, this message translates to:
  /// **'Consultant'**
  String get dashboardTeamUser;

  /// No description provided for @dashboardTeamAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appts'**
  String get dashboardTeamAppointments;

  /// No description provided for @dashboardTeamDeals.
  ///
  /// In en, this message translates to:
  /// **'Deals'**
  String get dashboardTeamDeals;

  /// No description provided for @dashboardTeamPipeline.
  ///
  /// In en, this message translates to:
  /// **'Open pipeline value'**
  String get dashboardTeamPipeline;

  /// No description provided for @dashboardNoValue.
  ///
  /// In en, this message translates to:
  /// **'No value'**
  String get dashboardNoValue;

  /// No description provided for @dashboardAddLead.
  ///
  /// In en, this message translates to:
  /// **'Add lead'**
  String get dashboardAddLead;

  /// No description provided for @dashboardAddClient.
  ///
  /// In en, this message translates to:
  /// **'Add client'**
  String get dashboardAddClient;

  /// No description provided for @dashboardAddProperty.
  ///
  /// In en, this message translates to:
  /// **'Add property'**
  String get dashboardAddProperty;

  /// No description provided for @dashboardAddAppointment.
  ///
  /// In en, this message translates to:
  /// **'Add appointment'**
  String get dashboardAddAppointment;

  /// No description provided for @dashboardSeriesLeads.
  ///
  /// In en, this message translates to:
  /// **'Leads'**
  String get dashboardSeriesLeads;

  /// No description provided for @dashboardSeriesAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get dashboardSeriesAppointments;

  /// No description provided for @dashboardSeriesDeals.
  ///
  /// In en, this message translates to:
  /// **'Deals'**
  String get dashboardSeriesDeals;

  /// No description provided for @dashboardSeriesPipelineValue.
  ///
  /// In en, this message translates to:
  /// **'Pipeline value'**
  String get dashboardSeriesPipelineValue;

  /// No description provided for @dashboardDailyInsightStaleLeads.
  ///
  /// In en, this message translates to:
  /// **'You have {count} active leads with no recent movement for more than 5 days. Start with the highest-value opportunities.'**
  String dashboardDailyInsightStaleLeads(Object count);

  /// No description provided for @dashboardDailyInsightNoNextFollowUp.
  ///
  /// In en, this message translates to:
  /// **'You have {count} active leads with no next follow-up scheduled. Every open lead needs a clear next step.'**
  String dashboardDailyInsightNoNextFollowUp(Object count);

  /// No description provided for @dashboardDailyInsightContactedTodayStillOverdue.
  ///
  /// In en, this message translates to:
  /// **'You contacted {count} leads today, but their overdue follow-up was not rescheduled. Set the next follow-up date before closing the day.'**
  String dashboardDailyInsightContactedTodayStillOverdue(Object count);

  /// No description provided for @dashboardDailyInsightConversionUp.
  ///
  /// In en, this message translates to:
  /// **'Current conversion is {percent}% higher than the previous month.'**
  String dashboardDailyInsightConversionUp(Object percent);

  /// No description provided for @dashboardDailyInsightCalm.
  ///
  /// In en, this message translates to:
  /// **'No urgent actions right now. Follow-up is under control.'**
  String get dashboardDailyInsightCalm;

  /// No description provided for @dashboardDailyInsightNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data yet for an accurate daily insight.'**
  String get dashboardDailyInsightNotEnoughData;

  /// No description provided for @dashboardWelcomeInsightActive.
  ///
  /// In en, this message translates to:
  /// **'Start with hot opportunities and due follow-ups, then review the team schedule from the Today rail.'**
  String get dashboardWelcomeInsightActive;

  /// No description provided for @dashboardWelcomeInsightCalm.
  ///
  /// In en, this message translates to:
  /// **'No urgent signals right now. Watch performance and prepare for the next opportunities.'**
  String get dashboardWelcomeInsightCalm;

  /// No description provided for @dashboardTodayShort.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashboardTodayShort;

  /// No description provided for @dashboardDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String dashboardDaysAgo(Object count);

  /// No description provided for @salesCommandCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Sales Command Center'**
  String get salesCommandCenterTitle;

  /// No description provided for @salesCommandCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A live, role-scoped view of the work that can move the pipeline today.'**
  String get salesCommandCenterSubtitle;

  /// No description provided for @salesCommandEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No urgent actions right now.'**
  String get salesCommandEmptyTitle;

  /// No description provided for @salesCommandEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No urgent actions right now. Your pipeline is under control.'**
  String get salesCommandEmptyMessage;

  /// No description provided for @salesCommandLimitedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your role has limited dashboard actions. Available work remains visible in its modules.'**
  String get salesCommandLimitedMessage;

  /// No description provided for @salesCommandUpdatedNow.
  ///
  /// In en, this message translates to:
  /// **'Updated now'**
  String get salesCommandUpdatedNow;

  /// No description provided for @salesCommandMetricDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get salesCommandMetricDueToday;

  /// No description provided for @salesCommandMetricOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get salesCommandMetricOverdue;

  /// No description provided for @salesCommandMetricHot.
  ///
  /// In en, this message translates to:
  /// **'Hot'**
  String get salesCommandMetricHot;

  /// No description provided for @salesCommandMetricRisk.
  ///
  /// In en, this message translates to:
  /// **'At risk'**
  String get salesCommandMetricRisk;

  /// No description provided for @dashboardCommandLegendTooltip.
  ///
  /// In en, this message translates to:
  /// **'Red = overdue/risk. Gold = due today/action soon. Blue = hot/important opportunity. Green = positive/completed.'**
  String get dashboardCommandLegendTooltip;

  /// No description provided for @dashboardSuggestedNextAction.
  ///
  /// In en, this message translates to:
  /// **'Suggested next action'**
  String get dashboardSuggestedNextAction;

  /// No description provided for @salesCommandTodayPrioritiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Today’s priorities'**
  String get salesCommandTodayPrioritiesTitle;

  /// No description provided for @salesCommandTodayPrioritiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The strongest cross-module actions for the current workday.'**
  String get salesCommandTodayPrioritiesSubtitle;

  /// No description provided for @salesCommandHotOpportunitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Hot opportunities'**
  String get salesCommandHotOpportunitiesTitle;

  /// No description provided for @salesCommandHotOpportunitiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Leads and deals with signals worth acting on soon.'**
  String get salesCommandHotOpportunitiesSubtitle;

  /// No description provided for @salesCommandAtRiskTitle.
  ///
  /// In en, this message translates to:
  /// **'At risk'**
  String get salesCommandAtRiskTitle;

  /// No description provided for @salesCommandAtRiskSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Missed, stale, or stuck work that needs intervention.'**
  String get salesCommandAtRiskSubtitle;

  /// No description provided for @salesCommandTeamPressureTitle.
  ///
  /// In en, this message translates to:
  /// **'Team pressure'**
  String get salesCommandTeamPressureTitle;

  /// No description provided for @salesCommandTeamPressureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Overdue workload and ownership gaps for the visible scope.'**
  String get salesCommandTeamPressureSubtitle;

  /// No description provided for @salesCommandNoTodayPriorities.
  ///
  /// In en, this message translates to:
  /// **'No priority action is due right now.'**
  String get salesCommandNoTodayPriorities;

  /// No description provided for @salesCommandNoHotOpportunities.
  ///
  /// In en, this message translates to:
  /// **'No strong opportunity signal in the loaded scope.'**
  String get salesCommandNoHotOpportunities;

  /// No description provided for @salesCommandNoAtRisk.
  ///
  /// In en, this message translates to:
  /// **'No visible at-risk item needs intervention.'**
  String get salesCommandNoAtRisk;

  /// No description provided for @salesCommandNoTeamPressure.
  ///
  /// In en, this message translates to:
  /// **'No overloaded assignee or ownership gap is visible.'**
  String get salesCommandNoTeamPressure;

  /// No description provided for @salesCommandWhyThisAppears.
  ///
  /// In en, this message translates to:
  /// **'Why this appears'**
  String get salesCommandWhyThisAppears;

  /// No description provided for @salesCommandOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get salesCommandOpenAction;

  /// No description provided for @salesCommandDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get salesCommandDueToday;

  /// No description provided for @salesCommandOverdueByDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Overdue} =1{1 day overdue} other{{count} days overdue}}'**
  String salesCommandOverdueByDays(int count);

  /// No description provided for @salesCommandAgeDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day without movement} other{{count} days without movement}}'**
  String salesCommandAgeDays(int count);

  /// No description provided for @salesCommandDueAt.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String salesCommandDueAt(Object date);

  /// No description provided for @salesCommandModuleLead.
  ///
  /// In en, this message translates to:
  /// **'Lead'**
  String get salesCommandModuleLead;

  /// No description provided for @salesCommandModuleTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get salesCommandModuleTask;

  /// No description provided for @salesCommandModuleDeal.
  ///
  /// In en, this message translates to:
  /// **'Deal'**
  String get salesCommandModuleDeal;

  /// No description provided for @salesCommandModuleAppointment.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get salesCommandModuleAppointment;

  /// No description provided for @salesCommandModuleClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get salesCommandModuleClient;

  /// No description provided for @salesCommandModuleUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get salesCommandModuleUser;

  /// No description provided for @salesCommandModuleTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get salesCommandModuleTeam;

  /// No description provided for @salesCommandWhyOverdueFollowUp.
  ///
  /// In en, this message translates to:
  /// **'The follow-up date has passed while the lead is still open.'**
  String get salesCommandWhyOverdueFollowUp;

  /// No description provided for @salesCommandWhyDueTodayFollowUp.
  ///
  /// In en, this message translates to:
  /// **'This lead has a follow-up scheduled for today.'**
  String get salesCommandWhyDueTodayFollowUp;

  /// No description provided for @salesCommandWhyOverdueTask.
  ///
  /// In en, this message translates to:
  /// **'The task is still open after its due date.'**
  String get salesCommandWhyOverdueTask;

  /// No description provided for @salesCommandWhyDueTodayTask.
  ///
  /// In en, this message translates to:
  /// **'This task is due today and still open.'**
  String get salesCommandWhyDueTodayTask;

  /// No description provided for @salesCommandWhyStaleLead.
  ///
  /// In en, this message translates to:
  /// **'No recent contact or update for {count} days.'**
  String salesCommandWhyStaleLead(int count);

  /// No description provided for @salesCommandWhyHotLead.
  ///
  /// In en, this message translates to:
  /// **'Priority, stage, or recent activity suggests a real opportunity.'**
  String get salesCommandWhyHotLead;

  /// No description provided for @salesCommandWhyUnassignedLead.
  ///
  /// In en, this message translates to:
  /// **'Important lead has no responsible owner yet.'**
  String get salesCommandWhyUnassignedLead;

  /// No description provided for @salesCommandWhyAppointmentMissed.
  ///
  /// In en, this message translates to:
  /// **'The appointment time has passed and still needs handling.'**
  String get salesCommandWhyAppointmentMissed;

  /// No description provided for @salesCommandWhyAppointmentDueNow.
  ///
  /// In en, this message translates to:
  /// **'The appointment is happening now or should already be in progress.'**
  String get salesCommandWhyAppointmentDueNow;

  /// No description provided for @salesCommandWhyAppointmentUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Scheduled today, so it should stay visible without dominating the list.'**
  String get salesCommandWhyAppointmentUpcoming;

  /// No description provided for @salesCommandWhyAppointmentNeedsFeedback.
  ///
  /// In en, this message translates to:
  /// **'The appointment ended but no outcome was captured.'**
  String get salesCommandWhyAppointmentNeedsFeedback;

  /// No description provided for @salesCommandWhyDealAtRisk.
  ///
  /// In en, this message translates to:
  /// **'The closing date or activity age suggests this deal needs attention.'**
  String get salesCommandWhyDealAtRisk;

  /// No description provided for @salesCommandWhyOverloadedAssignee.
  ///
  /// In en, this message translates to:
  /// **'{name} has {count, plural, =1{1 overdue item} other{{count} overdue items}}.'**
  String salesCommandWhyOverloadedAssignee(Object name, int count);

  /// No description provided for @salesCommandMoreItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more action in the modules} other{{count} more actions in the modules}}'**
  String salesCommandMoreItems(int count);

  /// No description provided for @salesCommandReasonOverdueFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Overdue follow-up'**
  String get salesCommandReasonOverdueFollowUp;

  /// No description provided for @salesCommandReasonDueTodayFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Follow-up due today'**
  String get salesCommandReasonDueTodayFollowUp;

  /// No description provided for @salesCommandReasonOverdueTask.
  ///
  /// In en, this message translates to:
  /// **'Task overdue'**
  String get salesCommandReasonOverdueTask;

  /// No description provided for @salesCommandReasonDueTodayTask.
  ///
  /// In en, this message translates to:
  /// **'Task due today'**
  String get salesCommandReasonDueTodayTask;

  /// No description provided for @salesCommandReasonStaleLead.
  ///
  /// In en, this message translates to:
  /// **'No recent contact'**
  String get salesCommandReasonStaleLead;

  /// No description provided for @salesCommandReasonHotLead.
  ///
  /// In en, this message translates to:
  /// **'Hot lead'**
  String get salesCommandReasonHotLead;

  /// No description provided for @salesCommandReasonUnassignedLead.
  ///
  /// In en, this message translates to:
  /// **'Unassigned important lead'**
  String get salesCommandReasonUnassignedLead;

  /// No description provided for @salesCommandReasonAppointmentMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed appointment'**
  String get salesCommandReasonAppointmentMissed;

  /// No description provided for @salesCommandReasonAppointmentDueNow.
  ///
  /// In en, this message translates to:
  /// **'Appointment due now'**
  String get salesCommandReasonAppointmentDueNow;

  /// No description provided for @salesCommandReasonAppointmentUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming appointment'**
  String get salesCommandReasonAppointmentUpcoming;

  /// No description provided for @salesCommandReasonAppointmentNeedsFeedback.
  ///
  /// In en, this message translates to:
  /// **'Needs outcome'**
  String get salesCommandReasonAppointmentNeedsFeedback;

  /// No description provided for @salesCommandReasonDealAtRisk.
  ///
  /// In en, this message translates to:
  /// **'Deal at risk'**
  String get salesCommandReasonDealAtRisk;

  /// No description provided for @salesCommandReasonOverloadedAssignee.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 overdue task} other{{count} overdue tasks}}'**
  String salesCommandReasonOverloadedAssignee(int count);

  /// No description provided for @clientsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep client profiles, preferences, and assignments ready for follow-up.'**
  String get clientsSubtitle;

  /// No description provided for @searchClients.
  ///
  /// In en, this message translates to:
  /// **'Search clients'**
  String get searchClients;

  /// No description provided for @searchTasks.
  ///
  /// In en, this message translates to:
  /// **'Search tasks'**
  String get searchTasks;

  /// No description provided for @createDeal.
  ///
  /// In en, this message translates to:
  /// **'Create deal'**
  String get createDeal;

  /// No description provided for @editDeal.
  ///
  /// In en, this message translates to:
  /// **'Edit deal'**
  String get editDeal;

  /// No description provided for @updateDeal.
  ///
  /// In en, this message translates to:
  /// **'Update deal'**
  String get updateDeal;

  /// No description provided for @dealDetails.
  ///
  /// In en, this message translates to:
  /// **'Deal details'**
  String get dealDetails;

  /// No description provided for @dealsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track client opportunities, property value, commission, and closing progress.'**
  String get dealsSubtitle;

  /// No description provided for @dealInformation.
  ///
  /// In en, this message translates to:
  /// **'Deal information'**
  String get dealInformation;

  /// No description provided for @dealValueAndStage.
  ///
  /// In en, this message translates to:
  /// **'Value and stage'**
  String get dealValueAndStage;

  /// No description provided for @dealSummary.
  ///
  /// In en, this message translates to:
  /// **'Deal summary'**
  String get dealSummary;

  /// No description provided for @noDeals.
  ///
  /// In en, this message translates to:
  /// **'No deals yet.'**
  String get noDeals;

  /// No description provided for @noDealsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No deals available.'**
  String get noDealsAvailable;

  /// No description provided for @noDealsMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No deals match the current filters.'**
  String get noDealsMatchFilters;

  /// No description provided for @searchDeals.
  ///
  /// In en, this message translates to:
  /// **'Search deals'**
  String get searchDeals;

  /// No description provided for @dealStage.
  ///
  /// In en, this message translates to:
  /// **'Deal stage'**
  String get dealStage;

  /// No description provided for @newDealStage.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newDealStage;

  /// No description provided for @qualified.
  ///
  /// In en, this message translates to:
  /// **'Qualified'**
  String get qualified;

  /// No description provided for @proposal.
  ///
  /// In en, this message translates to:
  /// **'Proposal'**
  String get proposal;

  /// No description provided for @expectedValue.
  ///
  /// In en, this message translates to:
  /// **'Expected value'**
  String get expectedValue;

  /// No description provided for @commission.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get commission;

  /// No description provided for @closingDate.
  ///
  /// In en, this message translates to:
  /// **'Closing date'**
  String get closingDate;

  /// No description provided for @lostReason.
  ///
  /// In en, this message translates to:
  /// **'Lost reason'**
  String get lostReason;

  /// No description provided for @assignedAgent.
  ///
  /// In en, this message translates to:
  /// **'Assigned agent'**
  String get assignedAgent;

  /// No description provided for @updateStage.
  ///
  /// In en, this message translates to:
  /// **'Update stage'**
  String get updateStage;

  /// No description provided for @archiveDeal.
  ///
  /// In en, this message translates to:
  /// **'Archive deal'**
  String get archiveDeal;

  /// No description provided for @archiveDealConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This deal will be archived and hidden from active deal lists.'**
  String get archiveDealConfirmation;

  /// No description provided for @dealCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Deal created successfully.'**
  String get dealCreatedSuccessfully;

  /// No description provided for @dealUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Deal updated successfully.'**
  String get dealUpdatedSuccessfully;

  /// No description provided for @dealArchivedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Deal archived successfully.'**
  String get dealArchivedSuccessfully;

  /// No description provided for @dealStageUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Deal stage updated successfully.'**
  String get dealStageUpdatedSuccessfully;

  /// No description provided for @unableToSaveDeal.
  ///
  /// In en, this message translates to:
  /// **'Unable to save deal. Please try again.'**
  String get unableToSaveDeal;

  /// No description provided for @lostReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Lost reason is required.'**
  String get lostReasonRequired;

  /// No description provided for @selectClient.
  ///
  /// In en, this message translates to:
  /// **'Select client'**
  String get selectClient;

  /// No description provided for @selectLead.
  ///
  /// In en, this message translates to:
  /// **'Select lead'**
  String get selectLead;

  /// No description provided for @selectProperty.
  ///
  /// In en, this message translates to:
  /// **'Select property'**
  String get selectProperty;

  /// No description provided for @selectAssignedAgent.
  ///
  /// In en, this message translates to:
  /// **'Select assigned agent'**
  String get selectAssignedAgent;

  /// No description provided for @allClosingDates.
  ///
  /// In en, this message translates to:
  /// **'All closing dates'**
  String get allClosingDates;

  /// No description provided for @pastClosing.
  ///
  /// In en, this message translates to:
  /// **'Past closing'**
  String get pastClosing;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @backToDeals.
  ///
  /// In en, this message translates to:
  /// **'Back to deals'**
  String get backToDeals;

  /// No description provided for @dealNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Deal not found. Open it from the deals list.'**
  String get dealNotFoundMessage;

  /// No description provided for @reportsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Reports are coming soon.'**
  String get reportsComingSoon;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfile;

  /// No description provided for @profileInformation.
  ///
  /// In en, this message translates to:
  /// **'Profile information'**
  String get profileInformation;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @uploadProfileImage.
  ///
  /// In en, this message translates to:
  /// **'Upload profile image'**
  String get uploadProfileImage;

  /// No description provided for @removeProfileImage.
  ///
  /// In en, this message translates to:
  /// **'Remove profile image'**
  String get removeProfileImage;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully.'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @unableToPickProfileImage.
  ///
  /// In en, this message translates to:
  /// **'Unable to select profile image. Please try again.'**
  String get unableToPickProfileImage;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required.'**
  String get fullNameRequired;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @accountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account status'**
  String get accountStatus;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About app'**
  String get aboutApp;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @manager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get manager;

  /// No description provided for @salesAgent.
  ///
  /// In en, this message translates to:
  /// **'Sales agent'**
  String get salesAgent;

  /// No description provided for @marketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get marketing;

  /// No description provided for @viewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get viewer;

  /// No description provided for @platformDashboard.
  ///
  /// In en, this message translates to:
  /// **'Platform dashboard'**
  String get platformDashboard;

  /// No description provided for @platformDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage company access, health, settings, and users across the Masar platform.'**
  String get platformDashboardSubtitle;

  /// No description provided for @platformAdmin.
  ///
  /// In en, this message translates to:
  /// **'Platform admin'**
  String get platformAdmin;

  /// No description provided for @platformOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get platformOverview;

  /// No description provided for @platformCompanies.
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get platformCompanies;

  /// No description provided for @totalCompanies.
  ///
  /// In en, this message translates to:
  /// **'Total companies'**
  String get totalCompanies;

  /// No description provided for @activeCompanies.
  ///
  /// In en, this message translates to:
  /// **'Active companies'**
  String get activeCompanies;

  /// No description provided for @inactiveCompanies.
  ///
  /// In en, this message translates to:
  /// **'Inactive companies'**
  String get inactiveCompanies;

  /// No description provided for @trialCompanies.
  ///
  /// In en, this message translates to:
  /// **'Trial companies'**
  String get trialCompanies;

  /// No description provided for @recentlyCreatedCompanies.
  ///
  /// In en, this message translates to:
  /// **'Recently created'**
  String get recentlyCreatedCompanies;

  /// No description provided for @searchCompanies.
  ///
  /// In en, this message translates to:
  /// **'Search companies'**
  String get searchCompanies;

  /// No description provided for @allCompanies.
  ///
  /// In en, this message translates to:
  /// **'All companies'**
  String get allCompanies;

  /// No description provided for @noCompaniesFound.
  ///
  /// In en, this message translates to:
  /// **'No companies found'**
  String get noCompaniesFound;

  /// No description provided for @noCompaniesFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Adjust the search or status filter.'**
  String get noCompaniesFoundMessage;

  /// No description provided for @createCompany.
  ///
  /// In en, this message translates to:
  /// **'Create company'**
  String get createCompany;

  /// No description provided for @createCompanySuccess.
  ///
  /// In en, this message translates to:
  /// **'Company created successfully.'**
  String get createCompanySuccess;

  /// No description provided for @addUserSuccess.
  ///
  /// In en, this message translates to:
  /// **'User added successfully.'**
  String get addUserSuccess;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get companyName;

  /// No description provided for @companyDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get companyDisplayName;

  /// No description provided for @companyIdSlug.
  ///
  /// In en, this message translates to:
  /// **'Company ID'**
  String get companyIdSlug;

  /// No description provided for @firstAdminFullName.
  ///
  /// In en, this message translates to:
  /// **'First admin full name'**
  String get firstAdminFullName;

  /// No description provided for @firstAdminEmail.
  ///
  /// In en, this message translates to:
  /// **'First admin email'**
  String get firstAdminEmail;

  /// No description provided for @firstAdminPhone.
  ///
  /// In en, this message translates to:
  /// **'First admin phone'**
  String get firstAdminPhone;

  /// No description provided for @temporaryPassword.
  ///
  /// In en, this message translates to:
  /// **'Temporary password'**
  String get temporaryPassword;

  /// No description provided for @defaultLocale.
  ///
  /// In en, this message translates to:
  /// **'Default locale'**
  String get defaultLocale;

  /// No description provided for @timezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get timezone;

  /// No description provided for @companyDetails.
  ///
  /// In en, this message translates to:
  /// **'Company details'**
  String get companyDetails;

  /// No description provided for @companySettings.
  ///
  /// In en, this message translates to:
  /// **'Company settings'**
  String get companySettings;

  /// No description provided for @dataHealth.
  ///
  /// In en, this message translates to:
  /// **'Data health'**
  String get dataHealth;

  /// No description provided for @runDataHealthCheck.
  ///
  /// In en, this message translates to:
  /// **'Run data health check'**
  String get runDataHealthCheck;

  /// No description provided for @dataHealthNotRun.
  ///
  /// In en, this message translates to:
  /// **'No data health report yet'**
  String get dataHealthNotRun;

  /// No description provided for @dataHealthNotRunMessage.
  ///
  /// In en, this message translates to:
  /// **'Run a company-scoped check to find missing assignment snapshots and invalid assignees.'**
  String get dataHealthNotRunMessage;

  /// No description provided for @dataHealthClean.
  ///
  /// In en, this message translates to:
  /// **'No assignment issues found'**
  String get dataHealthClean;

  /// No description provided for @dataHealthCleanMessage.
  ///
  /// In en, this message translates to:
  /// **'The scanned records are consistent with the current assignee policy.'**
  String get dataHealthCleanMessage;

  /// No description provided for @dataHealthAffectedRecords.
  ///
  /// In en, this message translates to:
  /// **'Affected records'**
  String get dataHealthAffectedRecords;

  /// No description provided for @missingSnapshots.
  ///
  /// In en, this message translates to:
  /// **'Missing snapshots'**
  String get missingSnapshots;

  /// No description provided for @invalidAssignees.
  ///
  /// In en, this message translates to:
  /// **'Invalid assignees'**
  String get invalidAssignees;

  /// No description provided for @inactiveAssignees.
  ///
  /// In en, this message translates to:
  /// **'Inactive assignees'**
  String get inactiveAssignees;

  /// No description provided for @staleTeamSnapshots.
  ///
  /// In en, this message translates to:
  /// **'Stale team snapshots'**
  String get staleTeamSnapshots;

  /// No description provided for @missingAssignee.
  ///
  /// In en, this message translates to:
  /// **'Missing assignee'**
  String get missingAssignee;

  /// No description provided for @safeBackfillAvailable.
  ///
  /// In en, this message translates to:
  /// **'Safe backfill'**
  String get safeBackfillAvailable;

  /// No description provided for @manualReview.
  ///
  /// In en, this message translates to:
  /// **'Manual review'**
  String get manualReview;

  /// No description provided for @editCompanySettings.
  ///
  /// In en, this message translates to:
  /// **'Edit company settings'**
  String get editCompanySettings;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get saveSettings;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully.'**
  String get settingsSaved;

  /// No description provided for @companyLimits.
  ///
  /// In en, this message translates to:
  /// **'Company limits'**
  String get companyLimits;

  /// No description provided for @companyFeatures.
  ///
  /// In en, this message translates to:
  /// **'Company features'**
  String get companyFeatures;

  /// No description provided for @featureEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get featureEnabled;

  /// No description provided for @featureDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get featureDisabled;

  /// No description provided for @enableFeature.
  ///
  /// In en, this message translates to:
  /// **'Enable feature'**
  String get enableFeature;

  /// No description provided for @disableFeature.
  ///
  /// In en, this message translates to:
  /// **'Disable feature'**
  String get disableFeature;

  /// No description provided for @locale.
  ///
  /// In en, this message translates to:
  /// **'Locale'**
  String get locale;

  /// No description provided for @userLimit.
  ///
  /// In en, this message translates to:
  /// **'User limit'**
  String get userLimit;

  /// No description provided for @usersUsed.
  ///
  /// In en, this message translates to:
  /// **'Users used'**
  String get usersUsed;

  /// No description provided for @userLimitReached.
  ///
  /// In en, this message translates to:
  /// **'User limit reached. Increase the limit before adding more users.'**
  String get userLimitReached;

  /// No description provided for @storageLimitMb.
  ///
  /// In en, this message translates to:
  /// **'Storage limit (MB)'**
  String get storageLimitMb;

  /// No description provided for @trial.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get trial;

  /// No description provided for @auditLogs.
  ///
  /// In en, this message translates to:
  /// **'Audit Logs'**
  String get auditLogs;

  /// No description provided for @previewDashboard.
  ///
  /// In en, this message translates to:
  /// **'Preview dashboard'**
  String get previewDashboard;

  /// No description provided for @readOnlyPreview.
  ///
  /// In en, this message translates to:
  /// **'Read-only preview'**
  String get readOnlyPreview;

  /// No description provided for @companyDashboardPreview.
  ///
  /// In en, this message translates to:
  /// **'Company dashboard preview'**
  String get companyDashboardPreview;

  /// No description provided for @platformAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Platform access denied.'**
  String get platformAccessDenied;

  /// No description provided for @companyUsers.
  ///
  /// In en, this message translates to:
  /// **'Company users'**
  String get companyUsers;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add user'**
  String get addUser;

  /// No description provided for @platformSupportAddUser.
  ///
  /// In en, this message translates to:
  /// **'Support add user'**
  String get platformSupportAddUser;

  /// No description provided for @platformCurrentCompany.
  ///
  /// In en, this message translates to:
  /// **'Current company'**
  String get platformCurrentCompany;

  /// No description provided for @platformDashboardHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete overview of platform performance, companies, and users.'**
  String get platformDashboardHeroSubtitle;

  /// No description provided for @platformSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search platform...'**
  String get platformSearchHint;

  /// No description provided for @platformCompanySelector.
  ///
  /// In en, this message translates to:
  /// **'Company selector'**
  String get platformCompanySelector;

  /// No description provided for @platformSelectedCompany.
  ///
  /// In en, this message translates to:
  /// **'Selected company'**
  String get platformSelectedCompany;

  /// No description provided for @platformCompanyFeatures.
  ///
  /// In en, this message translates to:
  /// **'Enabled features'**
  String get platformCompanyFeatures;

  /// No description provided for @platformStorageUsage.
  ///
  /// In en, this message translates to:
  /// **'Storage usage'**
  String get platformStorageUsage;

  /// No description provided for @platformRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get platformRecentActivity;

  /// No description provided for @platformWorkspaceSummary.
  ///
  /// In en, this message translates to:
  /// **'Workspace summary'**
  String get platformWorkspaceSummary;

  /// No description provided for @platformViewAllLogs.
  ///
  /// In en, this message translates to:
  /// **'View all logs'**
  String get platformViewAllLogs;

  /// No description provided for @platformViewAllCompanies.
  ///
  /// In en, this message translates to:
  /// **'View all companies'**
  String get platformViewAllCompanies;

  /// No description provided for @platformNoRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity yet'**
  String get platformNoRecentActivity;

  /// No description provided for @platformTotalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total users'**
  String get platformTotalUsers;

  /// No description provided for @platformAdminsManagers.
  ///
  /// In en, this message translates to:
  /// **'Admins / Managers'**
  String get platformAdminsManagers;

  /// No description provided for @platformActiveUsers.
  ///
  /// In en, this message translates to:
  /// **'Active users'**
  String get platformActiveUsers;

  /// No description provided for @platformOwnerGreeting.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}'**
  String platformOwnerGreeting(Object name);

  /// No description provided for @activateCompany.
  ///
  /// In en, this message translates to:
  /// **'Activate company'**
  String get activateCompany;

  /// No description provided for @deactivateCompany.
  ///
  /// In en, this message translates to:
  /// **'Deactivate company'**
  String get deactivateCompany;

  /// No description provided for @activateUser.
  ///
  /// In en, this message translates to:
  /// **'Activate user'**
  String get activateUser;

  /// No description provided for @deactivateUser.
  ///
  /// In en, this message translates to:
  /// **'Deactivate user'**
  String get deactivateUser;

  /// No description provided for @activateUserConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This user will be allowed to access the company workspace again.'**
  String get activateUserConfirmation;

  /// No description provided for @deactivateUserConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This user will lose access to this company workspace. Existing records remain unchanged.'**
  String get deactivateUserConfirmation;

  /// No description provided for @noCompanies.
  ///
  /// In en, this message translates to:
  /// **'No companies yet'**
  String get noCompanies;

  /// No description provided for @noCompaniesMessage.
  ///
  /// In en, this message translates to:
  /// **'Create the first trial company when the platform seed is ready.'**
  String get noCompaniesMessage;

  /// No description provided for @noCompanySelected.
  ///
  /// In en, this message translates to:
  /// **'No company selected'**
  String get noCompanySelected;

  /// No description provided for @noCompanySelectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Select a company to view users and metadata.'**
  String get noCompanySelectedMessage;

  /// No description provided for @noCompanyUsers.
  ///
  /// In en, this message translates to:
  /// **'No company users yet'**
  String get noCompanyUsers;

  /// No description provided for @noCompanyUsersMessage.
  ///
  /// In en, this message translates to:
  /// **'Add the first users through the secure Cloud Function.'**
  String get noCompanyUsersMessage;

  /// No description provided for @connectionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Unable to load data. Check your connection and try again.'**
  String get connectionTimeout;

  /// No description provided for @unableToLoadReports.
  ///
  /// In en, this message translates to:
  /// **'Unable to load reports. Please try again.'**
  String get unableToLoadReports;

  /// No description provided for @reportsOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get reportsOverview;

  /// No description provided for @exportCenter.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportCenter;

  /// No description provided for @exportCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate clean, branded Excel workbooks from the CRM data you are allowed to access.'**
  String get exportCenterSubtitle;

  /// No description provided for @exportsFollowRolePermissions.
  ///
  /// In en, this message translates to:
  /// **'Exports follow your role permissions.'**
  String get exportsFollowRolePermissions;

  /// No description provided for @generateExport.
  ///
  /// In en, this message translates to:
  /// **'Generate Excel'**
  String get generateExport;

  /// No description provided for @exportReportType.
  ///
  /// In en, this message translates to:
  /// **'Report type'**
  String get exportReportType;

  /// No description provided for @exportGenerateSection.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get exportGenerateSection;

  /// No description provided for @excel.
  ///
  /// In en, this message translates to:
  /// **'Excel'**
  String get excel;

  /// No description provided for @exportLanguage.
  ///
  /// In en, this message translates to:
  /// **'Report language'**
  String get exportLanguage;

  /// No description provided for @exportStatusFilter.
  ///
  /// In en, this message translates to:
  /// **'Status / stage'**
  String get exportStatusFilter;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get allStatuses;

  /// No description provided for @includeArchivedRecords.
  ///
  /// In en, this message translates to:
  /// **'Include archived records'**
  String get includeArchivedRecords;

  /// No description provided for @exportColumns.
  ///
  /// In en, this message translates to:
  /// **'Export columns'**
  String get exportColumns;

  /// No description provided for @recommendedColumns.
  ///
  /// In en, this message translates to:
  /// **'Recommended columns'**
  String get recommendedColumns;

  /// No description provided for @advancedColumns.
  ///
  /// In en, this message translates to:
  /// **'Advanced column selection'**
  String get advancedColumns;

  /// No description provided for @selectedAssignee.
  ///
  /// In en, this message translates to:
  /// **'Selected assignee'**
  String get selectedAssignee;

  /// No description provided for @exportReady.
  ///
  /// In en, this message translates to:
  /// **'Export ready'**
  String get exportReady;

  /// No description provided for @downloadFile.
  ///
  /// In en, this message translates to:
  /// **'Download file'**
  String get downloadFile;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'records'**
  String get records;

  /// No description provided for @exportGeneratedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Excel file generated successfully.'**
  String get exportGeneratedSuccessfully;

  /// No description provided for @exportDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the Excel file on this device. Please try again.'**
  String get exportDownloadFailed;

  /// No description provided for @androidUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get androidUpdateTitle;

  /// No description provided for @androidUpdateBody.
  ///
  /// In en, this message translates to:
  /// **'This Android version is no longer supported. Update Masar CRM to continue using the app safely.'**
  String get androidUpdateBody;

  /// No description provided for @androidUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update app'**
  String get androidUpdateButton;

  /// No description provided for @androidUpdateCurrentVersion.
  ///
  /// In en, this message translates to:
  /// **'Current version'**
  String get androidUpdateCurrentVersion;

  /// No description provided for @androidUpdateLatestVersion.
  ///
  /// In en, this message translates to:
  /// **'Latest version'**
  String get androidUpdateLatestVersion;

  /// No description provided for @androidUpdateRemainingTime.
  ///
  /// In en, this message translates to:
  /// **'Remaining update period'**
  String get androidUpdateRemainingTime;

  /// No description provided for @androidUpdateExpired.
  ///
  /// In en, this message translates to:
  /// **'The update period has ended. Please install the latest APK.'**
  String get androidUpdateExpired;

  /// No description provided for @androidUpdateOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the update link. Please contact support.'**
  String get androidUpdateOpenFailed;

  /// No description provided for @androidUpdateChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking app version'**
  String get androidUpdateChecking;

  /// No description provided for @androidUpdateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading update'**
  String get androidUpdateDownloading;

  /// No description provided for @androidUpdateDownloadStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting secure update download'**
  String get androidUpdateDownloadStarting;

  /// No description provided for @androidUpdateDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not download the update. Check your connection and try again.'**
  String get androidUpdateDownloadFailed;

  /// No description provided for @androidUpdateInvalidPackage.
  ///
  /// In en, this message translates to:
  /// **'The downloaded update file is not a valid APK. Check the release link or contact support.'**
  String get androidUpdateInvalidPackage;

  /// No description provided for @androidUpdateInstalling.
  ///
  /// In en, this message translates to:
  /// **'Opening Android installer'**
  String get androidUpdateInstalling;

  /// No description provided for @androidUpdateReadyToInstall.
  ///
  /// In en, this message translates to:
  /// **'Download complete. Android installer is ready.'**
  String get androidUpdateReadyToInstall;

  /// No description provided for @androidUpdateInstallButton.
  ///
  /// In en, this message translates to:
  /// **'Install update'**
  String get androidUpdateInstallButton;

  /// No description provided for @androidUpdateInstallPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Allow Masar CRM to install updates, then return and tap Install update again.'**
  String get androidUpdateInstallPermissionRequired;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @checkForUpdatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check whether this device is running the latest Masar CRM version.'**
  String get checkForUpdatesSubtitle;

  /// No description provided for @checkingForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates'**
  String get checkingForUpdates;

  /// No description provided for @appUpdateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get appUpdateAvailableTitle;

  /// No description provided for @appUpdateAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'A newer Masar CRM version is available. Update now to get the latest fixes and improvements.'**
  String get appUpdateAvailableBody;

  /// No description provided for @appUpdateRequiredManualBody.
  ///
  /// In en, this message translates to:
  /// **'This version is no longer supported. Update Masar CRM to continue safely.'**
  String get appUpdateRequiredManualBody;

  /// No description provided for @appUpdateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You’re up to date.'**
  String get appUpdateUpToDate;

  /// No description provided for @appUpdateUnableToCheck.
  ///
  /// In en, this message translates to:
  /// **'Unable to check for updates. Please try again.'**
  String get appUpdateUnableToCheck;

  /// No description provided for @appUpdateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get appUpdateLater;

  /// No description provided for @appUpdateReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Masar CRM update available'**
  String get appUpdateReminderTitle;

  /// No description provided for @appUpdateReminderBody.
  ///
  /// In en, this message translates to:
  /// **'A newer Masar CRM version is available. Update now to keep your workspace secure and stable.'**
  String get appUpdateReminderBody;

  /// No description provided for @appUpdateOpenUpdater.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get appUpdateOpenUpdater;

  /// No description provided for @exportNotAvailableForRole.
  ///
  /// In en, this message translates to:
  /// **'This export is not available for your role.'**
  String get exportNotAvailableForRole;

  /// No description provided for @teamPerformanceExport.
  ///
  /// In en, this message translates to:
  /// **'Team performance'**
  String get teamPerformanceExport;

  /// No description provided for @pipelineReportExport.
  ///
  /// In en, this message translates to:
  /// **'Sales pipeline report'**
  String get pipelineReportExport;

  /// No description provided for @followUpReportExport.
  ///
  /// In en, this message translates to:
  /// **'Follow-up report'**
  String get followUpReportExport;

  /// No description provided for @auditSummaryExport.
  ///
  /// In en, this message translates to:
  /// **'Activity audit summary'**
  String get auditSummaryExport;

  /// No description provided for @companyWideExportScope.
  ///
  /// In en, this message translates to:
  /// **'Company-wide'**
  String get companyWideExportScope;

  /// No description provided for @myTeamExportScope.
  ///
  /// In en, this message translates to:
  /// **'My team'**
  String get myTeamExportScope;

  /// No description provided for @myRecordsExportScope.
  ///
  /// In en, this message translates to:
  /// **'My records'**
  String get myRecordsExportScope;

  /// No description provided for @restrictedExportScope.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get restrictedExportScope;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get lastMonth;

  /// No description provided for @customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get customRange;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @reportName.
  ///
  /// In en, this message translates to:
  /// **'Report name'**
  String get reportName;

  /// No description provided for @scope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get scope;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateRange;

  /// No description provided for @generatedBy.
  ///
  /// In en, this message translates to:
  /// **'Generated by'**
  String get generatedBy;

  /// No description provided for @generatedAt.
  ///
  /// In en, this message translates to:
  /// **'Generated at'**
  String get generatedAt;

  /// No description provided for @recordCount.
  ///
  /// In en, this message translates to:
  /// **'Record count'**
  String get recordCount;

  /// No description provided for @filtersSummary.
  ///
  /// In en, this message translates to:
  /// **'Filters summary'**
  String get filtersSummary;

  /// No description provided for @field.
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get field;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @reportSummary.
  ///
  /// In en, this message translates to:
  /// **'Report Summary'**
  String get reportSummary;

  /// No description provided for @dataSheet.
  ///
  /// In en, this message translates to:
  /// **'Report data'**
  String get dataSheet;

  /// No description provided for @exportColumnLeadName.
  ///
  /// In en, this message translates to:
  /// **'Lead name'**
  String get exportColumnLeadName;

  /// No description provided for @exportColumnClientName.
  ///
  /// In en, this message translates to:
  /// **'Client name'**
  String get exportColumnClientName;

  /// No description provided for @exportColumnDealTitle.
  ///
  /// In en, this message translates to:
  /// **'Deal title'**
  String get exportColumnDealTitle;

  /// No description provided for @exportColumnPropertyTitle.
  ///
  /// In en, this message translates to:
  /// **'Property title'**
  String get exportColumnPropertyTitle;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @stage.
  ///
  /// In en, this message translates to:
  /// **'Stage'**
  String get stage;

  /// No description provided for @expectedCloseDate.
  ///
  /// In en, this message translates to:
  /// **'Expected close date'**
  String get expectedCloseDate;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @scheduledAt.
  ///
  /// In en, this message translates to:
  /// **'Scheduled at'**
  String get scheduledAt;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @imageCount.
  ///
  /// In en, this message translates to:
  /// **'Image count'**
  String get imageCount;

  /// No description provided for @dealCount.
  ///
  /// In en, this message translates to:
  /// **'Deal count'**
  String get dealCount;

  /// No description provided for @totalValue.
  ///
  /// In en, this message translates to:
  /// **'Total value'**
  String get totalValue;

  /// No description provided for @averageDealValue.
  ///
  /// In en, this message translates to:
  /// **'Average deal value'**
  String get averageDealValue;

  /// No description provided for @leadsAssigned.
  ///
  /// In en, this message translates to:
  /// **'Leads assigned'**
  String get leadsAssigned;

  /// No description provided for @convertedLeads.
  ///
  /// In en, this message translates to:
  /// **'Converted leads'**
  String get convertedLeads;

  /// No description provided for @tasksDue.
  ///
  /// In en, this message translates to:
  /// **'Tasks due'**
  String get tasksDue;

  /// No description provided for @tasksOverdue.
  ///
  /// In en, this message translates to:
  /// **'Tasks overdue'**
  String get tasksOverdue;

  /// No description provided for @appointmentsUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming appointments'**
  String get appointmentsUpcoming;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @recordTitle.
  ///
  /// In en, this message translates to:
  /// **'Record title'**
  String get recordTitle;

  /// No description provided for @actor.
  ///
  /// In en, this message translates to:
  /// **'Actor'**
  String get actor;

  /// No description provided for @reportPeriod.
  ///
  /// In en, this message translates to:
  /// **'Report period'**
  String get reportPeriod;

  /// No description provided for @selectedPeriod.
  ///
  /// In en, this message translates to:
  /// **'Selected period'**
  String get selectedPeriod;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @totalDeals.
  ///
  /// In en, this message translates to:
  /// **'Total deals'**
  String get totalDeals;

  /// No description provided for @lostDeals.
  ///
  /// In en, this message translates to:
  /// **'Lost deals'**
  String get lostDeals;

  /// No description provided for @expectedValueTotal.
  ///
  /// In en, this message translates to:
  /// **'Expected value total'**
  String get expectedValueTotal;

  /// No description provided for @loadedExpectedValueTotal.
  ///
  /// In en, this message translates to:
  /// **'Loaded expected value'**
  String get loadedExpectedValueTotal;

  /// No description provided for @commissionTotal.
  ///
  /// In en, this message translates to:
  /// **'Commission total'**
  String get commissionTotal;

  /// No description provided for @loadedCommissionTotal.
  ///
  /// In en, this message translates to:
  /// **'Loaded commission'**
  String get loadedCommissionTotal;

  /// No description provided for @dealsByStage.
  ///
  /// In en, this message translates to:
  /// **'Deals by stage'**
  String get dealsByStage;

  /// No description provided for @dealPipeline.
  ///
  /// In en, this message translates to:
  /// **'Deal pipeline'**
  String get dealPipeline;

  /// No description provided for @pipelineValue.
  ///
  /// In en, this message translates to:
  /// **'Pipeline value'**
  String get pipelineValue;

  /// No description provided for @recentDeals.
  ///
  /// In en, this message translates to:
  /// **'Recent deals'**
  String get recentDeals;

  /// No description provided for @dueTodayTasks.
  ///
  /// In en, this message translates to:
  /// **'Due today tasks'**
  String get dueTodayTasks;

  /// No description provided for @upcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'Upcoming tasks'**
  String get upcomingTasks;

  /// No description provided for @completedTasks.
  ///
  /// In en, this message translates to:
  /// **'Completed tasks'**
  String get completedTasks;

  /// No description provided for @cancelledTasks.
  ///
  /// In en, this message translates to:
  /// **'Cancelled tasks'**
  String get cancelledTasks;

  /// No description provided for @completionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion rate'**
  String get completionRate;

  /// No description provided for @overdueRate.
  ///
  /// In en, this message translates to:
  /// **'Overdue rate'**
  String get overdueRate;

  /// No description provided for @leadsReport.
  ///
  /// In en, this message translates to:
  /// **'Leads performance'**
  String get leadsReport;

  /// No description provided for @dealsReport.
  ///
  /// In en, this message translates to:
  /// **'Deals performance'**
  String get dealsReport;

  /// No description provided for @tasksReport.
  ///
  /// In en, this message translates to:
  /// **'Tasks and follow-ups'**
  String get tasksReport;

  /// No description provided for @propertiesReport.
  ///
  /// In en, this message translates to:
  /// **'Properties report'**
  String get propertiesReport;

  /// No description provided for @teamReport.
  ///
  /// In en, this message translates to:
  /// **'Agent report'**
  String get teamReport;

  /// No description provided for @leadsByStatus.
  ///
  /// In en, this message translates to:
  /// **'Leads by status'**
  String get leadsByStatus;

  /// No description provided for @leadsBySource.
  ///
  /// In en, this message translates to:
  /// **'Leads by source'**
  String get leadsBySource;

  /// No description provided for @leadsByPriority.
  ///
  /// In en, this message translates to:
  /// **'Leads by priority'**
  String get leadsByPriority;

  /// No description provided for @propertiesByStatus.
  ///
  /// In en, this message translates to:
  /// **'Properties by status'**
  String get propertiesByStatus;

  /// No description provided for @propertiesByType.
  ///
  /// In en, this message translates to:
  /// **'Properties by type'**
  String get propertiesByType;

  /// No description provided for @taskStatusDistribution.
  ///
  /// In en, this message translates to:
  /// **'Task status distribution'**
  String get taskStatusDistribution;

  /// No description provided for @agentPerformance.
  ///
  /// In en, this message translates to:
  /// **'Agent performance'**
  String get agentPerformance;

  /// No description provided for @highestPriorityTasks.
  ///
  /// In en, this message translates to:
  /// **'Highest priority tasks'**
  String get highestPriorityTasks;

  /// No description provided for @inventoryValue.
  ///
  /// In en, this message translates to:
  /// **'Inventory value'**
  String get inventoryValue;

  /// No description provided for @totalListedValue.
  ///
  /// In en, this message translates to:
  /// **'Total listed value'**
  String get totalListedValue;

  /// No description provided for @loadedListedValue.
  ///
  /// In en, this message translates to:
  /// **'Loaded listed value'**
  String get loadedListedValue;

  /// No description provided for @averagePrice.
  ///
  /// In en, this message translates to:
  /// **'Average price'**
  String get averagePrice;

  /// No description provided for @wonValue.
  ///
  /// In en, this message translates to:
  /// **'Won value'**
  String get wonValue;

  /// No description provided for @lostValue.
  ///
  /// In en, this message translates to:
  /// **'Lost value'**
  String get lostValue;

  /// No description provided for @noReportData.
  ///
  /// In en, this message translates to:
  /// **'No report data for the selected filters.'**
  String get noReportData;

  /// No description provided for @addDeal.
  ///
  /// In en, this message translates to:
  /// **'Add deal'**
  String get addDeal;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersion;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @featureUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Feature unavailable'**
  String get featureUnavailable;

  /// No description provided for @featureUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'This feature is disabled for this company. Contact the platform owner to enable it.'**
  String get featureUnavailableMessage;

  /// No description provided for @moduleDisabled.
  ///
  /// In en, this message translates to:
  /// **'Module disabled'**
  String get moduleDisabled;

  /// No description provided for @authRetryCountdown.
  ///
  /// In en, this message translates to:
  /// **'Try again in {seconds} seconds.'**
  String authRetryCountdown(int seconds);

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Check your inbox.'**
  String get passwordResetEmailSent;

  /// No description provided for @passwordResetEmailFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to send password reset email. Please try again.'**
  String get passwordResetEmailFailed;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get changeEmail;

  /// No description provided for @platformOwnerEmailUpdated.
  ///
  /// In en, this message translates to:
  /// **'Platform owner email updated.'**
  String get platformOwnerEmailUpdated;

  /// No description provided for @reauthenticationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again, then change the email. Firebase requires a recent login for this action.'**
  String get reauthenticationRequired;

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

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully.'**
  String get passwordChangedSuccessfully;

  /// No description provided for @passwordChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Password change failed. Please try again.'**
  String get passwordChangeFailed;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @currentPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Current password is required.'**
  String get currentPasswordRequired;

  /// No description provided for @currentPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect.'**
  String get currentPasswordIncorrect;

  /// No description provided for @recentLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again before changing your password.'**
  String get recentLoginRequired;

  /// No description provided for @newPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'New password is required.'**
  String get newPasswordRequired;

  /// No description provided for @newPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'New password must be at least 8 characters.'**
  String get newPasswordTooShort;

  /// No description provided for @passwordMustIncludeLowercase.
  ///
  /// In en, this message translates to:
  /// **'Password must include at least one lowercase letter.'**
  String get passwordMustIncludeLowercase;

  /// No description provided for @passwordMustIncludeUppercase.
  ///
  /// In en, this message translates to:
  /// **'Password must include at least one uppercase letter.'**
  String get passwordMustIncludeUppercase;

  /// No description provided for @passwordMustIncludeNumber.
  ///
  /// In en, this message translates to:
  /// **'Password must include at least one number.'**
  String get passwordMustIncludeNumber;

  /// No description provided for @generateResetLink.
  ///
  /// In en, this message translates to:
  /// **'Generate reset link'**
  String get generateResetLink;

  /// No description provided for @resetLinkGenerated.
  ///
  /// In en, this message translates to:
  /// **'Reset link generated.'**
  String get resetLinkGenerated;

  /// No description provided for @copyResetLink.
  ///
  /// In en, this message translates to:
  /// **'Copy reset link'**
  String get copyResetLink;

  /// No description provided for @resetLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Reset link copied.'**
  String get resetLinkCopied;

  /// No description provided for @sendThisLinkManuallyToTheUser.
  ///
  /// In en, this message translates to:
  /// **'Send this link manually to the user.'**
  String get sendThisLinkManuallyToTheUser;

  /// No description provided for @platformEmailChanged.
  ///
  /// In en, this message translates to:
  /// **'User email updated.'**
  String get platformEmailChanged;

  /// No description provided for @platformPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Platform password changed.'**
  String get platformPasswordChanged;

  /// No description provided for @notAllowedToChangePassword.
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to change this password.'**
  String get notAllowedToChangePassword;

  /// No description provided for @lastLogin.
  ///
  /// In en, this message translates to:
  /// **'Last login'**
  String get lastLogin;

  /// No description provided for @lastLoginDetails.
  ///
  /// In en, this message translates to:
  /// **'Last login details'**
  String get lastLoginDetails;

  /// No description provided for @ipAddress.
  ///
  /// In en, this message translates to:
  /// **'IP address'**
  String get ipAddress;

  /// No description provided for @device.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get device;

  /// No description provided for @browser.
  ///
  /// In en, this message translates to:
  /// **'Browser'**
  String get browser;

  /// No description provided for @platform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platform;

  /// No description provided for @loginActivity.
  ///
  /// In en, this message translates to:
  /// **'Login activity'**
  String get loginActivity;

  /// No description provided for @recentLoginActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent login activity'**
  String get recentLoginActivity;

  /// No description provided for @noLoginActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No login activity yet.'**
  String get noLoginActivityYet;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @userSecurity.
  ///
  /// In en, this message translates to:
  /// **'User security'**
  String get userSecurity;

  /// No description provided for @teamManagement.
  ///
  /// In en, this message translates to:
  /// **'Team Management'**
  String get teamManagement;

  /// No description provided for @teamManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create manager-owned teams and keep sales and marketing users organized by company.'**
  String get teamManagementSubtitle;

  /// No description provided for @teams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get teams;

  /// No description provided for @myTeam.
  ///
  /// In en, this message translates to:
  /// **'My Team'**
  String get myTeam;

  /// No description provided for @myTeamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View your assigned team and active team members.'**
  String get myTeamSubtitle;

  /// No description provided for @createTeam.
  ///
  /// In en, this message translates to:
  /// **'Create Team'**
  String get createTeam;

  /// No description provided for @editTeam.
  ///
  /// In en, this message translates to:
  /// **'Edit Team'**
  String get editTeam;

  /// No description provided for @teamDetails.
  ///
  /// In en, this message translates to:
  /// **'Team Details'**
  String get teamDetails;

  /// No description provided for @teamName.
  ///
  /// In en, this message translates to:
  /// **'Team Name'**
  String get teamName;

  /// No description provided for @teamDescription.
  ///
  /// In en, this message translates to:
  /// **'Team Description'**
  String get teamDescription;

  /// No description provided for @teamManager.
  ///
  /// In en, this message translates to:
  /// **'Team Manager'**
  String get teamManager;

  /// No description provided for @teamMembers.
  ///
  /// In en, this message translates to:
  /// **'Team Members'**
  String get teamMembers;

  /// No description provided for @teamMembersShort.
  ///
  /// In en, this message translates to:
  /// **'Team members'**
  String get teamMembersShort;

  /// No description provided for @addMembers.
  ///
  /// In en, this message translates to:
  /// **'Add Members'**
  String get addMembers;

  /// No description provided for @manageMembers.
  ///
  /// In en, this message translates to:
  /// **'Manage members'**
  String get manageMembers;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get removeMember;

  /// No description provided for @moveToTeam.
  ///
  /// In en, this message translates to:
  /// **'Move to Team'**
  String get moveToTeam;

  /// No description provided for @unassignedUsers.
  ///
  /// In en, this message translates to:
  /// **'Unassigned Users'**
  String get unassignedUsers;

  /// No description provided for @usersWithoutTeam.
  ///
  /// In en, this message translates to:
  /// **'Users Without Team'**
  String get usersWithoutTeam;

  /// No description provided for @activeTeams.
  ///
  /// In en, this message translates to:
  /// **'Active Teams'**
  String get activeTeams;

  /// No description provided for @inactiveTeams.
  ///
  /// In en, this message translates to:
  /// **'Inactive Teams'**
  String get inactiveTeams;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @teamMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No members} =1{1 member} other{{count} members}}'**
  String teamMembersCount(int count);

  /// No description provided for @managersWithTeams.
  ///
  /// In en, this message translates to:
  /// **'Managers with teams'**
  String get managersWithTeams;

  /// No description provided for @noTeamsYet.
  ///
  /// In en, this message translates to:
  /// **'No teams yet'**
  String get noTeamsYet;

  /// No description provided for @noTeamsYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Create the first team and assign an active manager.'**
  String get noTeamsYetMessage;

  /// No description provided for @noTeamMembersYet.
  ///
  /// In en, this message translates to:
  /// **'No team members yet'**
  String get noTeamMembersYet;

  /// No description provided for @noTeamMembersYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Add sales or marketing users to this team.'**
  String get noTeamMembersYetMessage;

  /// No description provided for @noTeamAssigned.
  ///
  /// In en, this message translates to:
  /// **'No team assigned'**
  String get noTeamAssigned;

  /// No description provided for @noTeamAssignedMessage.
  ///
  /// In en, this message translates to:
  /// **'Ask an admin to assign you as a team manager.'**
  String get noTeamAssignedMessage;

  /// No description provided for @assignManager.
  ///
  /// In en, this message translates to:
  /// **'Assign Manager'**
  String get assignManager;

  /// No description provided for @changeManager.
  ///
  /// In en, this message translates to:
  /// **'Change Manager'**
  String get changeManager;

  /// No description provided for @deactivateTeam.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Team'**
  String get deactivateTeam;

  /// No description provided for @activateTeam.
  ///
  /// In en, this message translates to:
  /// **'Activate Team'**
  String get activateTeam;

  /// No description provided for @teamSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Team saved successfully.'**
  String get teamSavedSuccessfully;

  /// No description provided for @teamUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Team update failed.'**
  String get teamUpdateFailed;

  /// No description provided for @teamPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to manage team members.'**
  String get teamPermissionDenied;

  /// No description provided for @teamSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Sign in again and retry.'**
  String get teamSessionExpired;

  /// No description provided for @teamUserInactive.
  ///
  /// In en, this message translates to:
  /// **'This user is inactive. Activate the user before assigning them.'**
  String get teamUserInactive;

  /// No description provided for @teamInactive.
  ///
  /// In en, this message translates to:
  /// **'This team is inactive. Activate the team first.'**
  String get teamInactive;

  /// No description provided for @teamMemberIneligible.
  ///
  /// In en, this message translates to:
  /// **'Only Sales Agent and Marketing users can be team members.'**
  String get teamMemberIneligible;

  /// No description provided for @teamManagerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Team manager must be an active Manager user.'**
  String get teamManagerUnavailable;

  /// No description provided for @teamManagerAlreadyHasTeam.
  ///
  /// In en, this message translates to:
  /// **'This manager already owns an active team.'**
  String get teamManagerAlreadyHasTeam;

  /// No description provided for @teamUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'The selected user no longer exists. Refresh and try again.'**
  String get teamUserNotFound;

  /// No description provided for @teamNotFound.
  ///
  /// In en, this message translates to:
  /// **'The selected team no longer exists. Refresh and try again.'**
  String get teamNotFound;

  /// No description provided for @teamCompanyInactive.
  ///
  /// In en, this message translates to:
  /// **'The selected company is inactive.'**
  String get teamCompanyInactive;

  /// No description provided for @teamCompanyMismatch.
  ///
  /// In en, this message translates to:
  /// **'User and team must belong to the same company.'**
  String get teamCompanyMismatch;

  /// No description provided for @teamConnectionInterrupted.
  ///
  /// In en, this message translates to:
  /// **'The connection was interrupted. Check your internet and try again.'**
  String get teamConnectionInterrupted;

  /// No description provided for @teamRecordChanged.
  ///
  /// In en, this message translates to:
  /// **'Team data changed. Refresh and try again.'**
  String get teamRecordChanged;

  /// No description provided for @teamInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Check the selected team and user, then try again.'**
  String get teamInvalidInput;

  /// No description provided for @userAddedToTeam.
  ///
  /// In en, this message translates to:
  /// **'User added to team.'**
  String get userAddedToTeam;

  /// No description provided for @userRemovedFromTeam.
  ///
  /// In en, this message translates to:
  /// **'User removed from team.'**
  String get userRemovedFromTeam;

  /// No description provided for @searchTeams.
  ///
  /// In en, this message translates to:
  /// **'Search teams'**
  String get searchTeams;

  /// No description provided for @noManagersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No managers available'**
  String get noManagersAvailable;

  /// No description provided for @noManagersAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Add an active Manager user before creating a team.'**
  String get noManagersAvailableMessage;

  /// No description provided for @noUnassignedUsers.
  ///
  /// In en, this message translates to:
  /// **'No eligible users'**
  String get noUnassignedUsers;

  /// No description provided for @noUnassignedUsersMessage.
  ///
  /// In en, this message translates to:
  /// **'Sales and marketing users are already assigned or unavailable.'**
  String get noUnassignedUsersMessage;

  /// No description provided for @backfillSnapshots.
  ///
  /// In en, this message translates to:
  /// **'Backfill snapshots'**
  String get backfillSnapshots;

  /// No description provided for @dataHealthRepairSuccess.
  ///
  /// In en, this message translates to:
  /// **'Snapshots repaired successfully.'**
  String get dataHealthRepairSuccess;

  /// No description provided for @companyDataHealthMessage.
  ///
  /// In en, this message translates to:
  /// **'Company admin tools for fixing invalid assignment ownership and stale team snapshots.'**
  String get companyDataHealthMessage;

  /// No description provided for @reassignRecord.
  ///
  /// In en, this message translates to:
  /// **'Reassign record'**
  String get reassignRecord;

  /// No description provided for @notifyManager.
  ///
  /// In en, this message translates to:
  /// **'Notify manager'**
  String get notifyManager;

  /// No description provided for @noManagerForDataHealthIssue.
  ///
  /// In en, this message translates to:
  /// **'No responsible manager is available for this issue.'**
  String get noManagerForDataHealthIssue;

  /// No description provided for @managerNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Manager notified successfully.'**
  String get managerNotificationSent;

  /// No description provided for @notificationsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Notifications are not available yet.'**
  String get notificationsComingSoon;

  /// No description provided for @noEligibleAssignees.
  ///
  /// In en, this message translates to:
  /// **'No eligible assignees'**
  String get noEligibleAssignees;

  /// No description provided for @noEligibleAssigneesMessage.
  ///
  /// In en, this message translates to:
  /// **'There are no active eligible users for this record type.'**
  String get noEligibleAssigneesMessage;

  /// No description provided for @dataHealthReassignSuccess.
  ///
  /// In en, this message translates to:
  /// **'Record reassigned successfully.'**
  String get dataHealthReassignSuccess;

  /// No description provided for @companyAdminActionRequired.
  ///
  /// In en, this message translates to:
  /// **'Company admin action required.'**
  String get companyAdminActionRequired;

  /// No description provided for @notificationCenter.
  ///
  /// In en, this message translates to:
  /// **'Notification center'**
  String get notificationCenter;

  /// No description provided for @notificationCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No unread notifications} =1{1 unread notification} other{{count} unread notifications}}'**
  String notificationCenterSubtitle(int count);

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @attention.
  ///
  /// In en, this message translates to:
  /// **'Attention'**
  String get attention;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @markRead.
  ///
  /// In en, this message translates to:
  /// **'Mark read'**
  String get markRead;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @attentionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Attention needed'**
  String get attentionNeeded;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @noNotificationsYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Important assignment updates and system alerts will appear here.'**
  String get noNotificationsYetMessage;

  /// No description provided for @notificationDataRepairNeededTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification data repair needed'**
  String get notificationDataRepairNeededTitle;

  /// No description provided for @notificationDataRepairNeededMessage.
  ///
  /// In en, this message translates to:
  /// **'Some notifications need data repair. New notifications will appear after the next activity.'**
  String get notificationDataRepairNeededMessage;

  /// No description provided for @notificationStreamError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load notifications. Please try again.'**
  String get notificationStreamError;

  /// No description provided for @noUrgentReminders.
  ///
  /// In en, this message translates to:
  /// **'No urgent reminders'**
  String get noUrgentReminders;

  /// No description provided for @noUrgentRemindersMessage.
  ///
  /// In en, this message translates to:
  /// **'Due and overdue work will appear here when it needs attention.'**
  String get noUrgentRemindersMessage;

  /// No description provided for @notificationLeadAssignedTitle.
  ///
  /// In en, this message translates to:
  /// **'New lead assigned to you'**
  String get notificationLeadAssignedTitle;

  /// No description provided for @notificationLeadReassignedTitle.
  ///
  /// In en, this message translates to:
  /// **'Lead reassigned to you'**
  String get notificationLeadReassignedTitle;

  /// No description provided for @notificationLeadRemovedFromYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Lead removed from your pipeline'**
  String get notificationLeadRemovedFromYouTitle;

  /// No description provided for @notificationTaskAssignedTitle.
  ///
  /// In en, this message translates to:
  /// **'New task assigned'**
  String get notificationTaskAssignedTitle;

  /// No description provided for @notificationTaskReassignedTitle.
  ///
  /// In en, this message translates to:
  /// **'Task reassigned to you'**
  String get notificationTaskReassignedTitle;

  /// No description provided for @notificationTaskRemovedFromYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Task removed from your work'**
  String get notificationTaskRemovedFromYouTitle;

  /// No description provided for @notificationClientAssignedTitle.
  ///
  /// In en, this message translates to:
  /// **'New client assigned to you'**
  String get notificationClientAssignedTitle;

  /// No description provided for @notificationClientReassignedTitle.
  ///
  /// In en, this message translates to:
  /// **'Client reassigned to you'**
  String get notificationClientReassignedTitle;

  /// No description provided for @notificationClientRemovedFromYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Client removed from your pipeline'**
  String get notificationClientRemovedFromYouTitle;

  /// No description provided for @notificationDealAssignedTitle.
  ///
  /// In en, this message translates to:
  /// **'New deal assigned to you'**
  String get notificationDealAssignedTitle;

  /// No description provided for @notificationDealReassignedTitle.
  ///
  /// In en, this message translates to:
  /// **'Deal reassigned to you'**
  String get notificationDealReassignedTitle;

  /// No description provided for @notificationDealRemovedFromYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Deal removed from your pipeline'**
  String get notificationDealRemovedFromYouTitle;

  /// No description provided for @notificationLeadImportantStatusChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Important lead status changed'**
  String get notificationLeadImportantStatusChangedTitle;

  /// No description provided for @notificationDealStageChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Deal stage changed'**
  String get notificationDealStageChangedTitle;

  /// No description provided for @notificationDealImportantStatusChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Important deal status changed'**
  String get notificationDealImportantStatusChangedTitle;

  /// No description provided for @notificationDealWonTitle.
  ///
  /// In en, this message translates to:
  /// **'Deal won'**
  String get notificationDealWonTitle;

  /// No description provided for @notificationDealLostTitle.
  ///
  /// In en, this message translates to:
  /// **'Deal lost'**
  String get notificationDealLostTitle;

  /// No description provided for @notificationTaskStatusChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Task status changed'**
  String get notificationTaskStatusChangedTitle;

  /// No description provided for @notificationTeamMemberAssignedTitle.
  ///
  /// In en, this message translates to:
  /// **'Team assignment'**
  String get notificationTeamMemberAssignedTitle;

  /// No description provided for @notificationTeamMemberReassignedTitle.
  ///
  /// In en, this message translates to:
  /// **'Team reassignment'**
  String get notificationTeamMemberReassignedTitle;

  /// No description provided for @notificationTeamMemberRemovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Team assignment removed'**
  String get notificationTeamMemberRemovedTitle;

  /// No description provided for @notificationTeamLeadStatusChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Team lead status changed'**
  String get notificationTeamLeadStatusChangedTitle;

  /// No description provided for @notificationTeamDealStageChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Team deal stage changed'**
  String get notificationTeamDealStageChangedTitle;

  /// No description provided for @notificationTeamTaskStatusChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Team task status changed'**
  String get notificationTeamTaskStatusChangedTitle;

  /// No description provided for @notificationGenericStatusChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Status changed'**
  String get notificationGenericStatusChangedTitle;

  /// No description provided for @notificationFollowUpDueTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Follow-up due today'**
  String get notificationFollowUpDueTodayTitle;

  /// No description provided for @notificationFollowUpOverdueTitle.
  ///
  /// In en, this message translates to:
  /// **'Follow-up overdue'**
  String get notificationFollowUpOverdueTitle;

  /// No description provided for @notificationTaskDueTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Task due today'**
  String get notificationTaskDueTodayTitle;

  /// No description provided for @notificationTaskOverdueTitle.
  ///
  /// In en, this message translates to:
  /// **'Task overdue'**
  String get notificationTaskOverdueTitle;

  /// No description provided for @notificationSystemInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'System notification'**
  String get notificationSystemInfoTitle;

  /// No description provided for @notificationDataHealthIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Data health needs attention'**
  String get notificationDataHealthIssueTitle;

  /// No description provided for @notificationDataHealthIssueBody.
  ///
  /// In en, this message translates to:
  /// **'{record} needs review: {issue}.'**
  String notificationDataHealthIssueBody(Object record, Object issue);

  /// No description provided for @notificationGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'CRM notification'**
  String get notificationGenericTitle;

  /// No description provided for @notificationUnassignedLeadTitle.
  ///
  /// In en, this message translates to:
  /// **'Unassigned lead needs attention'**
  String get notificationUnassignedLeadTitle;

  /// No description provided for @notificationRecordFallback.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get notificationRecordFallback;

  /// No description provided for @notificationSystemModule.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get notificationSystemModule;

  /// No description provided for @notificationRecordBody.
  ///
  /// In en, this message translates to:
  /// **'{record} needs your attention.'**
  String notificationRecordBody(Object record);

  /// No description provided for @notificationRecordByActorBody.
  ///
  /// In en, this message translates to:
  /// **'{record} was updated by {actor}.'**
  String notificationRecordByActorBody(Object record, Object actor);

  /// No description provided for @notificationRecordNoLongerAssignedBody.
  ///
  /// In en, this message translates to:
  /// **'{record} is no longer assigned to you.'**
  String notificationRecordNoLongerAssignedBody(Object record);

  /// No description provided for @notificationGenericBody.
  ///
  /// In en, this message translates to:
  /// **'Open {record} to review the latest update.'**
  String notificationGenericBody(Object record);

  /// No description provided for @notificationReminderAssignedBody.
  ///
  /// In en, this message translates to:
  /// **'{record} is assigned to {assignee}.'**
  String notificationReminderAssignedBody(Object record, Object assignee);

  /// No description provided for @notificationUnassignedLeadBody.
  ///
  /// In en, this message translates to:
  /// **'{record} is still unassigned.'**
  String notificationUnassignedLeadBody(Object record);

  /// No description provided for @notificationStatusChangedBody.
  ///
  /// In en, this message translates to:
  /// **'{record} changed to {status}.'**
  String notificationStatusChangedBody(Object record, Object status);

  /// No description provided for @notificationStatusChangedByActorBody.
  ///
  /// In en, this message translates to:
  /// **'{record} changed to {status} by {actor}.'**
  String notificationStatusChangedByActorBody(
    Object record,
    Object status,
    Object actor,
  );

  /// No description provided for @notificationTeamMemberAssignedBody.
  ///
  /// In en, this message translates to:
  /// **'{member} was assigned to {record}.'**
  String notificationTeamMemberAssignedBody(Object record, Object member);

  /// No description provided for @notificationTeamMemberAssignedByActorBody.
  ///
  /// In en, this message translates to:
  /// **'{actor} assigned {member} to {record}.'**
  String notificationTeamMemberAssignedByActorBody(
    Object record,
    Object member,
    Object actor,
  );

  /// No description provided for @notificationTeamMemberReassignedBody.
  ///
  /// In en, this message translates to:
  /// **'{record} moved from {oldMember} to {newMember}.'**
  String notificationTeamMemberReassignedBody(
    Object record,
    Object oldMember,
    Object newMember,
  );

  /// No description provided for @notificationTeamMemberReassignedByActorBody.
  ///
  /// In en, this message translates to:
  /// **'{actor} moved {record} from {oldMember} to {newMember}.'**
  String notificationTeamMemberReassignedByActorBody(
    Object record,
    Object oldMember,
    Object newMember,
    Object actor,
  );

  /// No description provided for @notificationTeamMemberRemovedBody.
  ///
  /// In en, this message translates to:
  /// **'{member} was removed from {record}.'**
  String notificationTeamMemberRemovedBody(Object record, Object member);

  /// No description provided for @notificationTeamMemberRemovedByActorBody.
  ///
  /// In en, this message translates to:
  /// **'{actor} removed {member} from {record}.'**
  String notificationTeamMemberRemovedByActorBody(
    Object record,
    Object member,
    Object actor,
  );

  /// No description provided for @notificationRouteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This item is no longer available or you do not have access.'**
  String get notificationRouteUnavailable;

  /// No description provided for @notificationPermissionPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get notificationPermissionPromptTitle;

  /// No description provided for @notificationPermissionPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Allow Masar CRM to send important assignments, appointments, and urgent follow-ups even when you are outside the app.'**
  String get notificationPermissionPromptBody;

  /// No description provided for @notificationPermissionEnableAction.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get notificationPermissionEnableAction;

  /// No description provided for @notificationPermissionUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Browser permission is allowed, but this device is not connected yet. Retry to reconnect notifications.'**
  String get notificationPermissionUnavailableBody;

  /// No description provided for @notificationPermissionSyncFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Notifications were allowed, but the device token could not be saved. Check your connection and try again.'**
  String get notificationPermissionSyncFailedBody;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @notificationsUnavailableInPlatform.
  ///
  /// In en, this message translates to:
  /// **'Tenant sales notifications are not available in platform mode.'**
  String get notificationsUnavailableInPlatform;

  /// No description provided for @appointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointments;

  /// No description provided for @appointmentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan viewings, meetings, calls, and deal follow-ups in one controlled schedule.'**
  String get appointmentsSubtitle;

  /// No description provided for @newAppointment.
  ///
  /// In en, this message translates to:
  /// **'New appointment'**
  String get newAppointment;

  /// No description provided for @editAppointment.
  ///
  /// In en, this message translates to:
  /// **'Edit appointment'**
  String get editAppointment;

  /// No description provided for @appointmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Appointment details'**
  String get appointmentDetails;

  /// No description provided for @appointmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment title'**
  String get appointmentTitle;

  /// No description provided for @appointmentType.
  ///
  /// In en, this message translates to:
  /// **'Appointment type'**
  String get appointmentType;

  /// No description provided for @appointmentSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get appointmentSchedule;

  /// No description provided for @appointmentNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes and outcome'**
  String get appointmentNotes;

  /// No description provided for @outcomeNotes.
  ///
  /// In en, this message translates to:
  /// **'Outcome notes'**
  String get outcomeNotes;

  /// No description provided for @appointmentTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get appointmentTime;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @selectAppointmentDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectAppointmentDate;

  /// No description provided for @selectStartTime.
  ///
  /// In en, this message translates to:
  /// **'Select start time'**
  String get selectStartTime;

  /// No description provided for @saveAppointment.
  ///
  /// In en, this message translates to:
  /// **'Save appointment'**
  String get saveAppointment;

  /// No description provided for @updateAppointment.
  ///
  /// In en, this message translates to:
  /// **'Update appointment'**
  String get updateAppointment;

  /// No description provided for @appointmentDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Select appointment date and start time.'**
  String get appointmentDateRequired;

  /// No description provided for @appointmentDurationRequired.
  ///
  /// In en, this message translates to:
  /// **'Appointment duration must be greater than zero.'**
  String get appointmentDurationRequired;

  /// No description provided for @appointmentAssigneeRequired.
  ///
  /// In en, this message translates to:
  /// **'Select an assigned user before saving.'**
  String get appointmentAssigneeRequired;

  /// No description provided for @appointmentEndAfterStartRequired.
  ///
  /// In en, this message translates to:
  /// **'Appointment end time must be after start time.'**
  String get appointmentEndAfterStartRequired;

  /// No description provided for @appointmentSaved.
  ///
  /// In en, this message translates to:
  /// **'Appointment saved.'**
  String get appointmentSaved;

  /// No description provided for @appointmentUpdated.
  ///
  /// In en, this message translates to:
  /// **'Appointment updated.'**
  String get appointmentUpdated;

  /// No description provided for @appointmentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Appointment cancelled.'**
  String get appointmentCancelled;

  /// No description provided for @appointmentCompleted.
  ///
  /// In en, this message translates to:
  /// **'Appointment completed.'**
  String get appointmentCompleted;

  /// No description provided for @appointmentMissed.
  ///
  /// In en, this message translates to:
  /// **'Appointment marked missed.'**
  String get appointmentMissed;

  /// No description provided for @appointmentRescheduled.
  ///
  /// In en, this message translates to:
  /// **'Appointment rescheduled.'**
  String get appointmentRescheduled;

  /// No description provided for @appointmentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Appointment was not found.'**
  String get appointmentNotFound;

  /// No description provided for @appointmentAttention.
  ///
  /// In en, this message translates to:
  /// **'Appointment attention'**
  String get appointmentAttention;

  /// No description provided for @appointmentCalendarTodayView.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get appointmentCalendarTodayView;

  /// No description provided for @appointmentCalendarMonthView.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get appointmentCalendarMonthView;

  /// No description provided for @appointmentCalendarWeekView.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get appointmentCalendarWeekView;

  /// No description provided for @appointmentCalendarDayView.
  ///
  /// In en, this message translates to:
  /// **'Specific day'**
  String get appointmentCalendarDayView;

  /// No description provided for @todayAgenda.
  ///
  /// In en, this message translates to:
  /// **'Today\'s agenda'**
  String get todayAgenda;

  /// No description provided for @appointmentAgenda.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get appointmentAgenda;

  /// No description provided for @noAppointmentsToday.
  ///
  /// In en, this message translates to:
  /// **'No appointments today'**
  String get noAppointmentsToday;

  /// No description provided for @noAppointmentsForSelectedDay.
  ///
  /// In en, this message translates to:
  /// **'No appointments for this day'**
  String get noAppointmentsForSelectedDay;

  /// No description provided for @openLinkedRecord.
  ///
  /// In en, this message translates to:
  /// **'Open linked record'**
  String get openLinkedRecord;

  /// No description provided for @currentAppointmentTime.
  ///
  /// In en, this message translates to:
  /// **'Current time'**
  String get currentAppointmentTime;

  /// No description provided for @appointmentOutcome.
  ///
  /// In en, this message translates to:
  /// **'Appointment outcome'**
  String get appointmentOutcome;

  /// No description provided for @cancellationReason.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason'**
  String get cancellationReason;

  /// No description provided for @cancellationReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a cancellation reason.'**
  String get cancellationReasonRequired;

  /// No description provided for @todaysAppointments.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todaysAppointments;

  /// No description provided for @upcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingAppointments;

  /// No description provided for @missedAppointments.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missedAppointments;

  /// No description provided for @noMissedAppointments.
  ///
  /// In en, this message translates to:
  /// **'No missed appointments.'**
  String get noMissedAppointments;

  /// No description provided for @completedAppointments.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedAppointments;

  /// No description provided for @cancelledAppointments.
  ///
  /// In en, this message translates to:
  /// **'Cancelled appointments'**
  String get cancelledAppointments;

  /// No description provided for @rescheduledAppointments.
  ///
  /// In en, this message translates to:
  /// **'Rescheduled appointments'**
  String get rescheduledAppointments;

  /// No description provided for @searchAppointments.
  ///
  /// In en, this message translates to:
  /// **'Search appointments'**
  String get searchAppointments;

  /// No description provided for @filterByDate.
  ///
  /// In en, this message translates to:
  /// **'Filter by date'**
  String get filterByDate;

  /// No description provided for @filterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by status'**
  String get filterByStatus;

  /// No description provided for @filterByType.
  ///
  /// In en, this message translates to:
  /// **'Filter by type'**
  String get filterByType;

  /// No description provided for @allAppointments.
  ///
  /// In en, this message translates to:
  /// **'All appointments'**
  String get allAppointments;

  /// No description provided for @allAppointmentTypes.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get allAppointmentTypes;

  /// No description provided for @noAppointmentsYet.
  ///
  /// In en, this message translates to:
  /// **'No appointments yet'**
  String get noAppointmentsYet;

  /// No description provided for @createFirstAppointment.
  ///
  /// In en, this message translates to:
  /// **'Create the first appointment'**
  String get createFirstAppointment;

  /// No description provided for @noAppointmentsMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No appointments match filters'**
  String get noAppointmentsMatchFilters;

  /// No description provided for @completeAppointment.
  ///
  /// In en, this message translates to:
  /// **'Complete appointment'**
  String get completeAppointment;

  /// No description provided for @cancelAppointment.
  ///
  /// In en, this message translates to:
  /// **'Cancel appointment'**
  String get cancelAppointment;

  /// No description provided for @markMissed.
  ///
  /// In en, this message translates to:
  /// **'Mark missed'**
  String get markMissed;

  /// No description provided for @reschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get reschedule;

  /// No description provided for @cancelAppointmentConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Cancel this appointment? The record will stay in history.'**
  String get cancelAppointmentConfirmation;

  /// No description provided for @completeAppointmentConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Complete this appointment and record the outcome.'**
  String get completeAppointmentConfirmation;

  /// No description provided for @markMissedConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Mark this appointment as missed?'**
  String get markMissedConfirmation;

  /// No description provided for @appointmentOutcomeSuccessfulMeeting.
  ///
  /// In en, this message translates to:
  /// **'Successful meeting'**
  String get appointmentOutcomeSuccessfulMeeting;

  /// No description provided for @appointmentOutcomeNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'No answer'**
  String get appointmentOutcomeNoAnswer;

  /// No description provided for @appointmentOutcomeClientPostponed.
  ///
  /// In en, this message translates to:
  /// **'Client postponed'**
  String get appointmentOutcomeClientPostponed;

  /// No description provided for @appointmentOutcomeClientNotInterested.
  ///
  /// In en, this message translates to:
  /// **'Client not interested'**
  String get appointmentOutcomeClientNotInterested;

  /// No description provided for @appointmentOutcomeFollowUpNeeded.
  ///
  /// In en, this message translates to:
  /// **'Follow-up needed'**
  String get appointmentOutcomeFollowUpNeeded;

  /// No description provided for @appointmentOutcomeDealOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Deal opportunity'**
  String get appointmentOutcomeDealOpportunity;

  /// No description provided for @appointmentOutcomeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get appointmentOutcomeOther;

  /// No description provided for @appointmentTypeCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get appointmentTypeCall;

  /// No description provided for @appointmentTypeMeeting.
  ///
  /// In en, this message translates to:
  /// **'Meeting'**
  String get appointmentTypeMeeting;

  /// No description provided for @appointmentTypePropertyViewing.
  ///
  /// In en, this message translates to:
  /// **'Property viewing'**
  String get appointmentTypePropertyViewing;

  /// No description provided for @appointmentTypeSiteVisit.
  ///
  /// In en, this message translates to:
  /// **'Site visit'**
  String get appointmentTypeSiteVisit;

  /// No description provided for @appointmentTypeContractMeeting.
  ///
  /// In en, this message translates to:
  /// **'Contract meeting'**
  String get appointmentTypeContractMeeting;

  /// No description provided for @appointmentTypeReservationMeeting.
  ///
  /// In en, this message translates to:
  /// **'Reservation meeting'**
  String get appointmentTypeReservationMeeting;

  /// No description provided for @appointmentTypeFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Follow-up'**
  String get appointmentTypeFollowUp;

  /// No description provided for @appointmentTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get appointmentTypeOther;

  /// No description provided for @appointmentStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get appointmentStatusScheduled;

  /// No description provided for @appointmentStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get appointmentStatusCompleted;

  /// No description provided for @appointmentStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get appointmentStatusCancelled;

  /// No description provided for @appointmentStatusMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get appointmentStatusMissed;

  /// No description provided for @appointmentStatusRescheduled.
  ///
  /// In en, this message translates to:
  /// **'Rescheduled'**
  String get appointmentStatusRescheduled;

  /// No description provided for @notificationAppointmentAssignedTitle.
  ///
  /// In en, this message translates to:
  /// **'New appointment assigned'**
  String get notificationAppointmentAssignedTitle;

  /// No description provided for @notificationAppointmentReassignedTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment reassigned to you'**
  String get notificationAppointmentReassignedTitle;

  /// No description provided for @notificationAppointmentRemovedFromYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment removed from your schedule'**
  String get notificationAppointmentRemovedFromYouTitle;

  /// No description provided for @notificationAppointmentRescheduledTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment rescheduled'**
  String get notificationAppointmentRescheduledTitle;

  /// No description provided for @notificationAppointmentCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment cancelled'**
  String get notificationAppointmentCancelledTitle;

  /// No description provided for @notificationAppointmentCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment completed'**
  String get notificationAppointmentCompletedTitle;

  /// No description provided for @notificationAppointmentMissedTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment missed'**
  String get notificationAppointmentMissedTitle;

  /// No description provided for @notificationAppointmentTodayAttentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment today'**
  String get notificationAppointmentTodayAttentionTitle;

  /// No description provided for @notificationAppointmentDueNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment due now'**
  String get notificationAppointmentDueNowTitle;

  /// No description provided for @notificationAppointmentDueSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment in 10 minutes'**
  String get notificationAppointmentDueSoonTitle;

  /// No description provided for @notificationAppointmentMissedAttentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Missed appointment'**
  String get notificationAppointmentMissedAttentionTitle;

  /// No description provided for @notificationAppointmentUpcomingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment coming up'**
  String get notificationAppointmentUpcomingSoonTitle;

  /// No description provided for @notificationTeamAppointmentAssignedTitle.
  ///
  /// In en, this message translates to:
  /// **'Team appointment assigned'**
  String get notificationTeamAppointmentAssignedTitle;

  /// No description provided for @notificationTeamAppointmentReassignedTitle.
  ///
  /// In en, this message translates to:
  /// **'Team appointment reassigned'**
  String get notificationTeamAppointmentReassignedTitle;

  /// No description provided for @notificationTeamAppointmentDueNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Team appointment due now'**
  String get notificationTeamAppointmentDueNowTitle;

  /// No description provided for @notificationTeamAppointmentDueSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Team appointment in 10 minutes'**
  String get notificationTeamAppointmentDueSoonTitle;

  /// No description provided for @notificationTeamAppointmentRescheduledTitle.
  ///
  /// In en, this message translates to:
  /// **'Team appointment rescheduled'**
  String get notificationTeamAppointmentRescheduledTitle;

  /// No description provided for @notificationTeamAppointmentCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Team appointment cancelled'**
  String get notificationTeamAppointmentCancelledTitle;

  /// No description provided for @notificationTeamAppointmentCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Team appointment completed'**
  String get notificationTeamAppointmentCompletedTitle;

  /// No description provided for @notificationTeamAppointmentMissedTitle.
  ///
  /// In en, this message translates to:
  /// **'Team appointment missed'**
  String get notificationTeamAppointmentMissedTitle;

  /// No description provided for @invitations.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get invitations;

  /// No description provided for @createInvitation.
  ///
  /// In en, this message translates to:
  /// **'Create invitation'**
  String get createInvitation;

  /// No description provided for @invitationCode.
  ///
  /// In en, this message translates to:
  /// **'Invitation code'**
  String get invitationCode;

  /// No description provided for @invitationLink.
  ///
  /// In en, this message translates to:
  /// **'Invitation link'**
  String get invitationLink;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @revokeInvitation.
  ///
  /// In en, this message translates to:
  /// **'Revoke invitation'**
  String get revokeInvitation;

  /// No description provided for @invitationActive.
  ///
  /// In en, this message translates to:
  /// **'Invitation active'**
  String get invitationActive;

  /// No description provided for @invitationUsed.
  ///
  /// In en, this message translates to:
  /// **'Invitation used'**
  String get invitationUsed;

  /// No description provided for @invitationExpired.
  ///
  /// In en, this message translates to:
  /// **'Invitation expired'**
  String get invitationExpired;

  /// No description provided for @invitationRevoked.
  ///
  /// In en, this message translates to:
  /// **'Invitation revoked'**
  String get invitationRevoked;

  /// No description provided for @expiresAt.
  ///
  /// In en, this message translates to:
  /// **'Expires at'**
  String get expiresAt;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @planId.
  ///
  /// In en, this message translates to:
  /// **'Plan ID'**
  String get planId;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// No description provided for @allowedAdminEmail.
  ///
  /// In en, this message translates to:
  /// **'Allowed admin email'**
  String get allowedAdminEmail;

  /// No description provided for @manualSupportSetup.
  ///
  /// In en, this message translates to:
  /// **'Manual support setup'**
  String get manualSupportSetup;

  /// No description provided for @invitationOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Invitation onboarding'**
  String get invitationOnboarding;

  /// No description provided for @companyAdminInvitation.
  ///
  /// In en, this message translates to:
  /// **'Company admin invitation'**
  String get companyAdminInvitation;

  /// No description provided for @invitationOnboardingNote.
  ///
  /// In en, this message translates to:
  /// **'Invitation onboarding lets a company admin register their own company workspace. Manual setup remains available for support cases.'**
  String get invitationOnboardingNote;

  /// No description provided for @noInvitationsYet.
  ///
  /// In en, this message translates to:
  /// **'No invitations yet'**
  String get noInvitationsYet;

  /// No description provided for @noInvitationsYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Create an invitation code for the next subscribing company admin.'**
  String get noInvitationsYetMessage;

  /// No description provided for @invitationCreated.
  ///
  /// In en, this message translates to:
  /// **'Invitation created. Copy the code or link now; the full code is shown only once.'**
  String get invitationCreated;

  /// No description provided for @invitationCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Invitation code copied.'**
  String get invitationCodeCopied;

  /// No description provided for @invitationLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Invitation link copied.'**
  String get invitationLinkCopied;

  /// No description provided for @expiresInDays.
  ///
  /// In en, this message translates to:
  /// **'Expires in days'**
  String get expiresInDays;

  /// No description provided for @registerYourCompany.
  ///
  /// In en, this message translates to:
  /// **'Register your company'**
  String get registerYourCompany;

  /// No description provided for @enterInvitationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter invitation code'**
  String get enterInvitationCode;

  /// No description provided for @validateInvitation.
  ///
  /// In en, this message translates to:
  /// **'Validate invitation'**
  String get validateInvitation;

  /// No description provided for @invitationValid.
  ///
  /// In en, this message translates to:
  /// **'Invitation valid'**
  String get invitationValid;

  /// No description provided for @invitationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invitation invalid'**
  String get invitationInvalid;

  /// No description provided for @adminAccount.
  ///
  /// In en, this message translates to:
  /// **'Admin account'**
  String get adminAccount;

  /// No description provided for @reviewAndCreate.
  ///
  /// In en, this message translates to:
  /// **'Review and create'**
  String get reviewAndCreate;

  /// No description provided for @createWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Create workspace'**
  String get createWorkspace;

  /// No description provided for @companyEmail.
  ///
  /// In en, this message translates to:
  /// **'Company email'**
  String get companyEmail;

  /// No description provided for @companyPhone.
  ///
  /// In en, this message translates to:
  /// **'Company phone'**
  String get companyPhone;

  /// No description provided for @cityLocation.
  ///
  /// In en, this message translates to:
  /// **'City/location'**
  String get cityLocation;

  /// No description provided for @preferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred language'**
  String get preferredLanguage;

  /// No description provided for @adminFullName.
  ///
  /// In en, this message translates to:
  /// **'Admin full name'**
  String get adminFullName;

  /// No description provided for @adminEmail.
  ///
  /// In en, this message translates to:
  /// **'Admin email'**
  String get adminEmail;

  /// No description provided for @adminPhone.
  ///
  /// In en, this message translates to:
  /// **'Admin phone'**
  String get adminPhone;

  /// No description provided for @companyRegistrationCompleted.
  ///
  /// In en, this message translates to:
  /// **'Company registration completed.'**
  String get companyRegistrationCompleted;

  /// No description provided for @invitationAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'Invitation already used'**
  String get invitationAlreadyUsed;

  /// No description provided for @companyIdAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Company ID already exists'**
  String get companyIdAlreadyExists;

  /// No description provided for @companyIdInvalid.
  ///
  /// In en, this message translates to:
  /// **'Company ID must use lowercase letters, numbers, hyphens, or underscores.'**
  String get companyIdInvalid;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'From lead to deal, run your real estate sales workspace in one place.'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Masar connects teams, leads, properties, appointments, notifications, and reports in a secure company workspace.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingOperationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Operational CRM workspace'**
  String get onboardingOperationsTitle;

  /// No description provided for @onboardingOperationsMessage.
  ///
  /// In en, this message translates to:
  /// **'Manage leads, clients, properties, tasks, deals, and appointments with role-scoped access.'**
  String get onboardingOperationsMessage;

  /// No description provided for @onboardingInvitationTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation-based company setup'**
  String get onboardingInvitationTitle;

  /// No description provided for @onboardingInvitationMessage.
  ///
  /// In en, this message translates to:
  /// **'Use your invitation code to create the company workspace and start as the first company admin.'**
  String get onboardingInvitationMessage;

  /// No description provided for @onboardingAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Live dashboards and reports'**
  String get onboardingAnalyticsTitle;

  /// No description provided for @onboardingAnalyticsMessage.
  ///
  /// In en, this message translates to:
  /// **'Track team performance, due work, appointments, and sales activity from polished dashboards.'**
  String get onboardingAnalyticsMessage;

  /// No description provided for @signInExistingAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to existing account'**
  String get signInExistingAccount;

  /// No description provided for @createAdminWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Create company workspace'**
  String get createAdminWorkspace;

  /// No description provided for @companyIdGeneratedAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Company ID is generated automatically'**
  String get companyIdGeneratedAutomatically;

  /// No description provided for @companyIdGeneratedMessage.
  ///
  /// In en, this message translates to:
  /// **'It will be generated from the company name.'**
  String get companyIdGeneratedMessage;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number.'**
  String get invalidPhone;

  /// No description provided for @invalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid website URL starting with http:// or https://.'**
  String get invalidUrl;

  /// No description provided for @invalidName.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid name.'**
  String get invalidName;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @userManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create managers, sales agents, marketing users, and viewers for this company.'**
  String get userManagementSubtitle;

  /// No description provided for @createUser.
  ///
  /// In en, this message translates to:
  /// **'Create user'**
  String get createUser;

  /// No description provided for @searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search users'**
  String get searchUsers;

  /// No description provided for @companyUsersEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Create the first company user or manager from this page.'**
  String get companyUsersEmptyMessage;

  /// No description provided for @userCreatedResetLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'User created'**
  String get userCreatedResetLinkTitle;

  /// No description provided for @userCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User created successfully'**
  String get userCreatedSuccessfully;

  /// No description provided for @sendSetupLinkToUser.
  ///
  /// In en, this message translates to:
  /// **'Send this setup link to the user so they can set their password.'**
  String get sendSetupLinkToUser;

  /// No description provided for @copySetupLink.
  ///
  /// In en, this message translates to:
  /// **'Copy setup link'**
  String get copySetupLink;

  /// No description provided for @openSetupLink.
  ///
  /// In en, this message translates to:
  /// **'Open setup link'**
  String get openSetupLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied.'**
  String get linkCopied;

  /// No description provided for @generateSetupLink.
  ///
  /// In en, this message translates to:
  /// **'Generate setup link'**
  String get generateSetupLink;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @userCreatedNoResetLinkMessage.
  ///
  /// In en, this message translates to:
  /// **'The user was created, but no password reset link was returned.'**
  String get userCreatedNoResetLinkMessage;

  /// No description provided for @companyUserAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This user already belongs to the company.'**
  String get companyUserAlreadyExists;

  /// No description provided for @registrationInvitationInvalid.
  ///
  /// In en, this message translates to:
  /// **'This invitation is no longer valid.'**
  String get registrationInvitationInvalid;

  /// No description provided for @registrationInvitationExpired.
  ///
  /// In en, this message translates to:
  /// **'This invitation has expired.'**
  String get registrationInvitationExpired;

  /// No description provided for @registrationInvitationUsed.
  ///
  /// In en, this message translates to:
  /// **'This invitation has already been used.'**
  String get registrationInvitationUsed;

  /// No description provided for @registrationInvitationRevoked.
  ///
  /// In en, this message translates to:
  /// **'This invitation has been revoked.'**
  String get registrationInvitationRevoked;

  /// No description provided for @registrationInvitationLimitReached.
  ///
  /// In en, this message translates to:
  /// **'This invitation has reached its usage limit.'**
  String get registrationInvitationLimitReached;

  /// No description provided for @adminEmailAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Please try another admin email.'**
  String get adminEmailAlreadyExists;

  /// No description provided for @companyNameAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This company name is already registered. Try another name.'**
  String get companyNameAlreadyRegistered;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters and include uppercase, lowercase, and a number.'**
  String get weakPassword;

  /// No description provided for @emailPasswordAuthDisabled.
  ///
  /// In en, this message translates to:
  /// **'Email and password sign-in is not enabled. Contact the platform owner.'**
  String get emailPasswordAuthDisabled;

  /// No description provided for @unableToCreateAdminUser.
  ///
  /// In en, this message translates to:
  /// **'Unable to create the admin user. Please check the data and try again.'**
  String get unableToCreateAdminUser;

  /// No description provided for @unableToCreateWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Unable to create the workspace. Please check the data and try again.'**
  String get unableToCreateWorkspace;

  /// No description provided for @unableToCompleteRegistration.
  ///
  /// In en, this message translates to:
  /// **'Unable to complete registration. Please try again later.'**
  String get unableToCompleteRegistration;

  /// No description provided for @registrationConflict.
  ///
  /// In en, this message translates to:
  /// **'Registration is already in progress or the workspace was just created. Please try again.'**
  String get registrationConflict;

  /// No description provided for @createYourAdminPassword.
  ///
  /// In en, this message translates to:
  /// **'Create your admin password'**
  String get createYourAdminPassword;

  /// No description provided for @adminPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'This password will be used to log in as company admin.'**
  String get adminPasswordHelp;

  /// No description provided for @companyAdminPassword.
  ///
  /// In en, this message translates to:
  /// **'Company admin password'**
  String get companyAdminPassword;

  /// No description provided for @confirmCompanyAdminPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm company admin password'**
  String get confirmCompanyAdminPassword;

  /// No description provided for @notificationsDisabledForCompany.
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled for this company.'**
  String get notificationsDisabledForCompany;

  /// No description provided for @featureNotEnabledForWorkspace.
  ///
  /// In en, this message translates to:
  /// **'This feature is not enabled for your workspace.'**
  String get featureNotEnabledForWorkspace;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorOccurred;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @setTemporaryPassword.
  ///
  /// In en, this message translates to:
  /// **'Set temporary password'**
  String get setTemporaryPassword;

  /// No description provided for @confirmTemporaryPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm temporary password'**
  String get confirmTemporaryPassword;

  /// No description provided for @temporaryPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional. The user can sign in with this temporary password and should change it from Settings after first login.'**
  String get temporaryPasswordHelp;

  /// No description provided for @temporaryPasswordCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'The user was created with a temporary password. Share the temporary password securely and ask the user to change it after first login.'**
  String get temporaryPasswordCreatedMessage;

  /// No description provided for @mustChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Must change password'**
  String get mustChangePassword;

  /// No description provided for @temporaryPasswordChangeRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new password'**
  String get temporaryPasswordChangeRequiredTitle;

  /// No description provided for @temporaryPasswordChangeRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'You are using a temporary password. Please create a new password before continuing to Masar CRM.'**
  String get temporaryPasswordChangeRequiredMessage;

  /// No description provided for @updatePasswordAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Update password and continue'**
  String get updatePasswordAndContinue;

  /// No description provided for @supportCenter.
  ///
  /// In en, this message translates to:
  /// **'Support Center'**
  String get supportCenter;

  /// No description provided for @supportCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send support requests or lightweight product feedback from inside your workspace.'**
  String get supportCenterSubtitle;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @contactSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a support request with the page, version, and workspace context attached automatically.'**
  String get contactSupportSubtitle;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @sendFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share a quick product note without opening a full support ticket.'**
  String get sendFeedbackSubtitle;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get supportTitle;

  /// No description provided for @supportMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get supportMessage;

  /// No description provided for @supportCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get supportCategory;

  /// No description provided for @supportPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get supportPriority;

  /// No description provided for @feedbackRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get feedbackRating;

  /// No description provided for @feedbackCategory.
  ///
  /// In en, this message translates to:
  /// **'Feedback category'**
  String get feedbackCategory;

  /// No description provided for @feedbackMessage.
  ///
  /// In en, this message translates to:
  /// **'Feedback message'**
  String get feedbackMessage;

  /// No description provided for @submitSupportRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get submitSupportRequest;

  /// No description provided for @submitFeedback.
  ///
  /// In en, this message translates to:
  /// **'Submit feedback'**
  String get submitFeedback;

  /// No description provided for @supportTicketCreated.
  ///
  /// In en, this message translates to:
  /// **'Support request submitted.'**
  String get supportTicketCreated;

  /// No description provided for @feedbackSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Feedback submitted.'**
  String get feedbackSubmitted;

  /// No description provided for @supportNoRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get supportNoRequestsTitle;

  /// No description provided for @supportNoRequestsMessage.
  ///
  /// In en, this message translates to:
  /// **'Submitted support requests and feedback will appear here.'**
  String get supportNoRequestsMessage;

  /// No description provided for @supportCategoryAccountLogin.
  ///
  /// In en, this message translates to:
  /// **'Account and login'**
  String get supportCategoryAccountLogin;

  /// No description provided for @supportCategoryUsersPermissions.
  ///
  /// In en, this message translates to:
  /// **'Users and permissions'**
  String get supportCategoryUsersPermissions;

  /// No description provided for @supportCategoryBillingSubscription.
  ///
  /// In en, this message translates to:
  /// **'Billing and subscription'**
  String get supportCategoryBillingSubscription;

  /// No description provided for @supportCategoryBug.
  ///
  /// In en, this message translates to:
  /// **'Bug'**
  String get supportCategoryBug;

  /// No description provided for @feedbackCategorySuggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get feedbackCategorySuggestion;

  /// No description provided for @feedbackCategoryUiImprovement.
  ///
  /// In en, this message translates to:
  /// **'UI improvement'**
  String get feedbackCategoryUiImprovement;

  /// No description provided for @feedbackCategoryMissingFeature.
  ///
  /// In en, this message translates to:
  /// **'Missing feature'**
  String get feedbackCategoryMissingFeature;

  /// No description provided for @feedbackCategoryConfusingBehavior.
  ///
  /// In en, this message translates to:
  /// **'Confusing behavior'**
  String get feedbackCategoryConfusingBehavior;

  /// No description provided for @feedbackCategoryPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get feedbackCategoryPerformance;

  /// No description provided for @feedbackCategoryGeneralFeedback.
  ///
  /// In en, this message translates to:
  /// **'General feedback'**
  String get feedbackCategoryGeneralFeedback;

  /// No description provided for @supportPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get supportPriorityLow;

  /// No description provided for @supportPriorityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get supportPriorityNormal;

  /// No description provided for @supportPriorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get supportPriorityUrgent;

  /// No description provided for @supportStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get supportStatusOpen;

  /// No description provided for @supportStatusInReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get supportStatusInReview;

  /// No description provided for @supportStatusWaitingForUser.
  ///
  /// In en, this message translates to:
  /// **'Waiting for user'**
  String get supportStatusWaitingForUser;

  /// No description provided for @supportStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get supportStatusResolved;

  /// No description provided for @supportStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get supportStatusClosed;

  /// No description provided for @platformSupportInbox.
  ///
  /// In en, this message translates to:
  /// **'Support Inbox'**
  String get platformSupportInbox;

  /// No description provided for @supportOpenTickets.
  ///
  /// In en, this message translates to:
  /// **'Open tickets'**
  String get supportOpenTickets;

  /// No description provided for @supportUrgentTickets.
  ///
  /// In en, this message translates to:
  /// **'Urgent tickets'**
  String get supportUrgentTickets;

  /// No description provided for @supportFeedbackCount.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get supportFeedbackCount;

  /// No description provided for @supportResolvedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Resolved this month'**
  String get supportResolvedThisMonth;

  /// No description provided for @searchSupportRequests.
  ///
  /// In en, this message translates to:
  /// **'Search support'**
  String get searchSupportRequests;

  /// No description provided for @requestType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get requestType;

  /// No description provided for @allTypes.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get allTypes;

  /// No description provided for @requestTypeSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get requestTypeSupport;

  /// No description provided for @requestTypeFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get requestTypeFeedback;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @supportDetails.
  ///
  /// In en, this message translates to:
  /// **'Request details'**
  String get supportDetails;

  /// No description provided for @updateStatus.
  ///
  /// In en, this message translates to:
  /// **'Update status'**
  String get updateStatus;

  /// No description provided for @supportStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Status updated.'**
  String get supportStatusUpdated;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @currentRoute.
  ///
  /// In en, this message translates to:
  /// **'Current route'**
  String get currentRoute;

  /// No description provided for @deviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Device info'**
  String get deviceInfo;

  /// No description provided for @platformNotifications.
  ///
  /// In en, this message translates to:
  /// **'Platform Notifications'**
  String get platformNotifications;

  /// No description provided for @platformNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track important owner actions and SaaS events across Masar CRM.'**
  String get platformNotificationsSubtitle;

  /// No description provided for @noPlatformNotifications.
  ///
  /// In en, this message translates to:
  /// **'No platform notifications yet'**
  String get noPlatformNotifications;

  /// No description provided for @noPlatformNotificationsMessage.
  ///
  /// In en, this message translates to:
  /// **'Important platform actions and SaaS events will appear here.'**
  String get noPlatformNotificationsMessage;

  /// No description provided for @markUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark unread'**
  String get markUnread;

  /// No description provided for @platformNotificationStorageLabel.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get platformNotificationStorageLabel;

  /// No description provided for @platformNotificationSeverityInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get platformNotificationSeverityInfo;

  /// No description provided for @platformNotificationSeveritySuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get platformNotificationSeveritySuccess;

  /// No description provided for @platformNotificationSeverityWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get platformNotificationSeverityWarning;

  /// No description provided for @platformNotificationSeverityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get platformNotificationSeverityUrgent;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @platformNotificationCompanyRegistered.
  ///
  /// In en, this message translates to:
  /// **'Company registered'**
  String get platformNotificationCompanyRegistered;

  /// No description provided for @platformNotificationCompanyCreated.
  ///
  /// In en, this message translates to:
  /// **'Company created'**
  String get platformNotificationCompanyCreated;

  /// No description provided for @platformNotificationCompanyStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Company status changed'**
  String get platformNotificationCompanyStatusChanged;

  /// No description provided for @platformNotificationCompanySettingsChanged.
  ///
  /// In en, this message translates to:
  /// **'Company settings changed'**
  String get platformNotificationCompanySettingsChanged;

  /// No description provided for @platformNotificationCompanyFeatureChanged.
  ///
  /// In en, this message translates to:
  /// **'Company features changed'**
  String get platformNotificationCompanyFeatureChanged;

  /// No description provided for @platformNotificationCompanyLimitChanged.
  ///
  /// In en, this message translates to:
  /// **'Company limits changed'**
  String get platformNotificationCompanyLimitChanged;

  /// No description provided for @platformNotificationCompanyUserCreated.
  ///
  /// In en, this message translates to:
  /// **'Company user created'**
  String get platformNotificationCompanyUserCreated;

  /// No description provided for @platformNotificationCompanyUserStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Company user status changed'**
  String get platformNotificationCompanyUserStatusChanged;

  /// No description provided for @platformNotificationDealWon.
  ///
  /// In en, this message translates to:
  /// **'Deal won'**
  String get platformNotificationDealWon;

  /// No description provided for @platformNotificationDealLost.
  ///
  /// In en, this message translates to:
  /// **'Deal lost'**
  String get platformNotificationDealLost;

  /// No description provided for @platformNotificationCompanyUserPasswordReset.
  ///
  /// In en, this message translates to:
  /// **'Company user password action'**
  String get platformNotificationCompanyUserPasswordReset;

  /// No description provided for @platformNotificationInvitationCreated.
  ///
  /// In en, this message translates to:
  /// **'Invitation created'**
  String get platformNotificationInvitationCreated;

  /// No description provided for @platformNotificationInvitationAccepted.
  ///
  /// In en, this message translates to:
  /// **'Invitation accepted'**
  String get platformNotificationInvitationAccepted;

  /// No description provided for @platformNotificationInvitationRevoked.
  ///
  /// In en, this message translates to:
  /// **'Invitation revoked'**
  String get platformNotificationInvitationRevoked;

  /// No description provided for @platformNotificationSupportTicketCreated.
  ///
  /// In en, this message translates to:
  /// **'Support ticket created'**
  String get platformNotificationSupportTicketCreated;

  /// No description provided for @platformNotificationFeedbackSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Feedback submitted'**
  String get platformNotificationFeedbackSubmitted;

  /// No description provided for @platformNotificationSupportTicketStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Support status changed'**
  String get platformNotificationSupportTicketStatusChanged;

  /// No description provided for @platformNotificationStorageUsageRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Storage usage refreshed'**
  String get platformNotificationStorageUsageRefreshed;

  /// No description provided for @platformNotificationStorageNearLimit.
  ///
  /// In en, this message translates to:
  /// **'Storage near limit'**
  String get platformNotificationStorageNearLimit;

  /// No description provided for @platformNotificationFunctionFailed.
  ///
  /// In en, this message translates to:
  /// **'Platform function failed'**
  String get platformNotificationFunctionFailed;

  /// No description provided for @platformNotificationUnknown.
  ///
  /// In en, this message translates to:
  /// **'Platform event'**
  String get platformNotificationUnknown;

  /// No description provided for @platformNotificationCompanyActorMessage.
  ///
  /// In en, this message translates to:
  /// **'{company} was updated by {actor}.'**
  String platformNotificationCompanyActorMessage(Object company, Object actor);

  /// No description provided for @platformNotificationCompanyMessage.
  ///
  /// In en, this message translates to:
  /// **'{company} has a new platform event.'**
  String platformNotificationCompanyMessage(Object company);

  /// No description provided for @platformNotificationActorMessage.
  ///
  /// In en, this message translates to:
  /// **'{actor} created a platform event.'**
  String platformNotificationActorMessage(Object actor);

  /// No description provided for @platformNotificationGenericMessage.
  ///
  /// In en, this message translates to:
  /// **'A platform event needs your attention.'**
  String get platformNotificationGenericMessage;

  /// No description provided for @storageUsageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Usage unavailable'**
  String get storageUsageUnavailable;

  /// No description provided for @storageNotTrackedYet.
  ///
  /// In en, this message translates to:
  /// **'Storage usage is not tracked yet.'**
  String get storageNotTrackedYet;

  /// No description provided for @storageLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get storageLastUpdated;

  /// No description provided for @refreshStorageUsage.
  ///
  /// In en, this message translates to:
  /// **'Refresh usage'**
  String get refreshStorageUsage;

  /// No description provided for @storageUsageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Storage usage updated.'**
  String get storageUsageUpdated;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @module.
  ///
  /// In en, this message translates to:
  /// **'Module'**
  String get module;

  /// No description provided for @severity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severity;

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// No description provided for @unresolved.
  ///
  /// In en, this message translates to:
  /// **'Unresolved'**
  String get unresolved;

  /// No description provided for @platformMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Monitoring'**
  String get platformMonitoring;

  /// No description provided for @platformMonitoringSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trace serious errors, repeated permission problems, and company-level incidents across Masar CRM.'**
  String get platformMonitoringSubtitle;

  /// No description provided for @activeIncidents.
  ///
  /// In en, this message translates to:
  /// **'Active incidents'**
  String get activeIncidents;

  /// No description provided for @fatalErrors.
  ///
  /// In en, this message translates to:
  /// **'Fatal errors'**
  String get fatalErrors;

  /// No description provided for @errorsToday.
  ///
  /// In en, this message translates to:
  /// **'Errors today'**
  String get errorsToday;

  /// No description provided for @affectedCompanies.
  ///
  /// In en, this message translates to:
  /// **'Affected companies'**
  String get affectedCompanies;

  /// No description provided for @allSeverities.
  ///
  /// In en, this message translates to:
  /// **'All severities'**
  String get allSeverities;

  /// No description provided for @allErrorSources.
  ///
  /// In en, this message translates to:
  /// **'All sources'**
  String get allErrorSources;

  /// No description provided for @allModules.
  ///
  /// In en, this message translates to:
  /// **'All modules'**
  String get allModules;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @last24Hours.
  ///
  /// In en, this message translates to:
  /// **'Last 24 hours'**
  String get last24Hours;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30Days;

  /// No description provided for @resolvedAndUnresolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved and unresolved'**
  String get resolvedAndUnresolved;

  /// No description provided for @unresolvedOnly.
  ///
  /// In en, this message translates to:
  /// **'Unresolved only'**
  String get unresolvedOnly;

  /// No description provided for @resolvedOnly.
  ///
  /// In en, this message translates to:
  /// **'Resolved only'**
  String get resolvedOnly;

  /// No description provided for @noPlatformErrors.
  ///
  /// In en, this message translates to:
  /// **'No monitoring incidents'**
  String get noPlatformErrors;

  /// No description provided for @noPlatformErrorsMessage.
  ///
  /// In en, this message translates to:
  /// **'Serious app, rule, storage, and function errors will appear here after they are reported.'**
  String get noPlatformErrorsMessage;

  /// No description provided for @occurrenceCount.
  ///
  /// In en, this message translates to:
  /// **'Occurrences'**
  String get occurrenceCount;

  /// No description provided for @firstSeenAt.
  ///
  /// In en, this message translates to:
  /// **'First seen'**
  String get firstSeenAt;

  /// No description provided for @lastSeenAt.
  ///
  /// In en, this message translates to:
  /// **'Last seen'**
  String get lastSeenAt;

  /// No description provided for @errorCode.
  ///
  /// In en, this message translates to:
  /// **'Error code'**
  String get errorCode;

  /// No description provided for @stackHash.
  ///
  /// In en, this message translates to:
  /// **'Stack hash'**
  String get stackHash;

  /// No description provided for @shortStack.
  ///
  /// In en, this message translates to:
  /// **'Short stack'**
  String get shortStack;

  /// No description provided for @metadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get metadata;

  /// No description provided for @ownerNotified.
  ///
  /// In en, this message translates to:
  /// **'Owner notified'**
  String get ownerNotified;

  /// No description provided for @markResolved.
  ///
  /// In en, this message translates to:
  /// **'Mark resolved'**
  String get markResolved;

  /// No description provided for @resolvedBy.
  ///
  /// In en, this message translates to:
  /// **'Resolved by'**
  String get resolvedBy;

  /// No description provided for @resolvedAt.
  ///
  /// In en, this message translates to:
  /// **'Resolved at'**
  String get resolvedAt;

  /// No description provided for @errorDetails.
  ///
  /// In en, this message translates to:
  /// **'Error details'**
  String get errorDetails;

  /// No description provided for @buildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build number'**
  String get buildNumber;

  /// No description provided for @errorSeverityInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get errorSeverityInfo;

  /// No description provided for @errorSeverityWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get errorSeverityWarning;

  /// No description provided for @errorSeverityError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorSeverityError;

  /// No description provided for @errorSeverityFatal.
  ///
  /// In en, this message translates to:
  /// **'Fatal'**
  String get errorSeverityFatal;

  /// No description provided for @errorSourceFlutterWeb.
  ///
  /// In en, this message translates to:
  /// **'Flutter Web'**
  String get errorSourceFlutterWeb;

  /// No description provided for @errorSourceFlutterMobile.
  ///
  /// In en, this message translates to:
  /// **'Flutter Mobile'**
  String get errorSourceFlutterMobile;

  /// No description provided for @errorSourceCloudFunction.
  ///
  /// In en, this message translates to:
  /// **'Cloud Function'**
  String get errorSourceCloudFunction;

  /// No description provided for @errorSourceFirestoreRule.
  ///
  /// In en, this message translates to:
  /// **'Firestore rule'**
  String get errorSourceFirestoreRule;

  /// No description provided for @errorSourceStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get errorSourceStorage;

  /// No description provided for @errorSourceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get errorSourceUnknown;

  /// No description provided for @platformMonitoringResolvedMessage.
  ///
  /// In en, this message translates to:
  /// **'Monitoring incident marked resolved.'**
  String get platformMonitoringResolvedMessage;

  /// No description provided for @enableTrial.
  ///
  /// In en, this message translates to:
  /// **'Enable trial period'**
  String get enableTrial;

  /// No description provided for @enableTrialSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Company remains active during the custom trial period, then access is stopped until support renews it.'**
  String get enableTrialSubtitle;

  /// No description provided for @trialPeriodDays.
  ///
  /// In en, this message translates to:
  /// **'Trial period'**
  String get trialPeriodDays;

  /// No description provided for @trialEndsAt.
  ///
  /// In en, this message translates to:
  /// **'Trial ends'**
  String get trialEndsAt;

  /// No description provided for @trialEnded.
  ///
  /// In en, this message translates to:
  /// **'Trial ended'**
  String get trialEnded;

  /// No description provided for @trialEndedAccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your trial period has ended. Please contact support or subscribe to continue using Masar CRM.'**
  String get trialEndedAccessMessage;

  /// No description provided for @trialReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Trial reminder'**
  String get trialReminderTitle;

  /// No description provided for @trialRemaining.
  ///
  /// In en, this message translates to:
  /// **'Trial remaining'**
  String get trialRemaining;

  /// No description provided for @trialFirstReminderMessage.
  ///
  /// In en, this message translates to:
  /// **'Your trial has passed its first checkpoint. Please plan your subscription before access stops.'**
  String get trialFirstReminderMessage;

  /// No description provided for @trialSecondReminderMessage.
  ///
  /// In en, this message translates to:
  /// **'Your trial is getting closer to the end. Subscribe or contact support to keep working without interruption.'**
  String get trialSecondReminderMessage;

  /// No description provided for @trialFinalReminderMessage.
  ///
  /// In en, this message translates to:
  /// **'Your trial is about to end soon. Subscribe or contact support now to avoid losing access.'**
  String get trialFinalReminderMessage;

  /// No description provided for @exportCompanyData.
  ///
  /// In en, this message translates to:
  /// **'Export company data'**
  String get exportCompanyData;

  /// No description provided for @companyDataExported.
  ///
  /// In en, this message translates to:
  /// **'Company data exported.'**
  String get companyDataExported;

  /// No description provided for @developedAndDesignedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed and designed by: Islam A. © 2026'**
  String get developedAndDesignedBy;

  /// No description provided for @clearNotification.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearNotification;

  /// No description provided for @collapseAttentionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapseAttentionNeeded;

  /// No description provided for @expandAttentionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expandAttentionNeeded;

  /// No description provided for @paymentFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Payment follow-up'**
  String get paymentFollowUp;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment status'**
  String get paymentStatus;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @dueSoon.
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get dueSoon;

  /// No description provided for @gracePeriod.
  ///
  /// In en, this message translates to:
  /// **'Grace period'**
  String get gracePeriod;

  /// No description provided for @suspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get suspended;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get markAsPaid;

  /// No description provided for @extendDueDate.
  ///
  /// In en, this message translates to:
  /// **'Extend due date'**
  String get extendDueDate;

  /// No description provided for @nextPaymentDue.
  ///
  /// In en, this message translates to:
  /// **'Next payment due'**
  String get nextPaymentDue;

  /// No description provided for @lastPayment.
  ///
  /// In en, this message translates to:
  /// **'Last payment'**
  String get lastPayment;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get paymentHistory;

  /// No description provided for @paymentNotes.
  ///
  /// In en, this message translates to:
  /// **'Payment notes'**
  String get paymentNotes;

  /// No description provided for @paymentCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get paymentCurrency;

  /// No description provided for @paymentCycle.
  ///
  /// In en, this message translates to:
  /// **'Payment cycle'**
  String get paymentCycle;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @quarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get quarterly;

  /// No description provided for @semiAnnual.
  ///
  /// In en, this message translates to:
  /// **'Semi-annual'**
  String get semiAnnual;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'Days remaining'**
  String get daysRemaining;

  /// No description provided for @paidCompanies.
  ///
  /// In en, this message translates to:
  /// **'Paid companies'**
  String get paidCompanies;

  /// No description provided for @expectedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Expected this month'**
  String get expectedThisMonth;

  /// No description provided for @moveToGracePeriod.
  ///
  /// In en, this message translates to:
  /// **'Move to grace period'**
  String get moveToGracePeriod;

  /// No description provided for @suspendCompany.
  ///
  /// In en, this message translates to:
  /// **'Suspend company'**
  String get suspendCompany;

  /// No description provided for @reactivateCompany.
  ///
  /// In en, this message translates to:
  /// **'Reactivate company'**
  String get reactivateCompany;

  /// No description provided for @gracePeriodEndsAt.
  ///
  /// In en, this message translates to:
  /// **'Grace period ends'**
  String get gracePeriodEndsAt;

  /// No description provided for @suspendedReason.
  ///
  /// In en, this message translates to:
  /// **'Suspension reason'**
  String get suspendedReason;

  /// No description provided for @markedPaid.
  ///
  /// In en, this message translates to:
  /// **'Marked paid'**
  String get markedPaid;

  /// No description provided for @extended.
  ///
  /// In en, this message translates to:
  /// **'Extended'**
  String get extended;

  /// No description provided for @reactivated.
  ///
  /// In en, this message translates to:
  /// **'Reactivated'**
  String get reactivated;

  /// No description provided for @noteAdded.
  ///
  /// In en, this message translates to:
  /// **'Note added'**
  String get noteAdded;

  /// No description provided for @noPaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment actions will appear here after the platform owner updates this company.'**
  String get noPaymentHistory;

  /// No description provided for @futureDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a future date.'**
  String get futureDateRequired;

  /// No description provided for @paymentAccessBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Company access is suspended because of payment status. Please contact support or the platform owner to reactivate the company.'**
  String get paymentAccessBlockedMessage;

  /// No description provided for @paymentDueSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'A company payment is due soon. Please contact support or the platform owner to keep access uninterrupted.'**
  String get paymentDueSoonMessage;

  /// No description provided for @paymentOverdueMessage.
  ///
  /// In en, this message translates to:
  /// **'A company payment is overdue. Please contact support or the platform owner to update the payment status.'**
  String get paymentOverdueMessage;

  /// No description provided for @paymentGraceMessage.
  ///
  /// In en, this message translates to:
  /// **'The company is in a payment grace period. Please contact support or the platform owner before access is suspended.'**
  String get paymentGraceMessage;

  /// No description provided for @daysRemainingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days remaining'**
  String daysRemainingCount(int count);

  /// No description provided for @overdueDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days overdue'**
  String overdueDaysCount(int count);

  /// No description provided for @swipeToSeeMore.
  ///
  /// In en, this message translates to:
  /// **'Swipe to see more'**
  String get swipeToSeeMore;

  /// No description provided for @dashboardActionNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'No answer'**
  String get dashboardActionNoAnswer;

  /// No description provided for @dashboardActionInterested.
  ///
  /// In en, this message translates to:
  /// **'Mark as hot opportunity'**
  String get dashboardActionInterested;

  /// No description provided for @dashboardActionNotInterested.
  ///
  /// In en, this message translates to:
  /// **'Mark not interested'**
  String get dashboardActionNotInterested;

  /// No description provided for @dashboardActionMarkTaskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark task completed'**
  String get dashboardActionMarkTaskCompleted;

  /// No description provided for @dashboardActionSaved.
  ///
  /// In en, this message translates to:
  /// **'Action saved.'**
  String get dashboardActionSaved;

  /// No description provided for @dashboardActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the action. Please try again.'**
  String get dashboardActionFailed;

  /// No description provided for @dashboardCallPhone.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get dashboardCallPhone;

  /// No description provided for @dashboardOpenWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Open WhatsApp'**
  String get dashboardOpenWhatsApp;

  /// No description provided for @dashboardLeadNoteContacted.
  ///
  /// In en, this message translates to:
  /// **'Follow-up outcome: contacted from the dashboard.'**
  String get dashboardLeadNoteContacted;

  /// No description provided for @dashboardLeadNoteNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'Follow-up outcome: no answer from the dashboard. Next follow-up scheduled for tomorrow.'**
  String get dashboardLeadNoteNoAnswer;

  /// No description provided for @dashboardLeadNoteInterested.
  ///
  /// In en, this message translates to:
  /// **'Follow-up outcome: interested from the dashboard.'**
  String get dashboardLeadNoteInterested;

  /// No description provided for @dashboardLeadNoteNotInterested.
  ///
  /// In en, this message translates to:
  /// **'Follow-up outcome: not interested from the dashboard.'**
  String get dashboardLeadNoteNotInterested;

  /// No description provided for @dashboardLeadNoteFollowUpScheduled.
  ///
  /// In en, this message translates to:
  /// **'Follow-up scheduled for {date} from the dashboard.'**
  String dashboardLeadNoteFollowUpScheduled(Object date);

  /// No description provided for @connectedJourneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Connected journey'**
  String get connectedJourneyTitle;

  /// No description provided for @connectedJourneySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Timeline, tasks, appointments, deals, and audit activity around this record.'**
  String get connectedJourneySubtitle;

  /// No description provided for @journeyRecommendedNextAction.
  ///
  /// In en, this message translates to:
  /// **'Recommended next action'**
  String get journeyRecommendedNextAction;

  /// No description provided for @journeyNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No connected activity yet.'**
  String get journeyNoActivity;

  /// No description provided for @journeyOpenRecord.
  ///
  /// In en, this message translates to:
  /// **'Open record'**
  String get journeyOpenRecord;

  /// No description provided for @journeyItemRecordCreated.
  ///
  /// In en, this message translates to:
  /// **'Record created'**
  String get journeyItemRecordCreated;

  /// No description provided for @journeyItemAuditCreated.
  ///
  /// In en, this message translates to:
  /// **'Audit event created'**
  String get journeyItemAuditCreated;

  /// No description provided for @journeyItemAuditUpdated.
  ///
  /// In en, this message translates to:
  /// **'Audit event updated'**
  String get journeyItemAuditUpdated;

  /// No description provided for @journeyActionEverythingCalm.
  ///
  /// In en, this message translates to:
  /// **'No urgent action'**
  String get journeyActionEverythingCalm;

  /// No description provided for @journeyActionEverythingCalmDescription.
  ///
  /// In en, this message translates to:
  /// **'This record has no urgent journey alerts right now.'**
  String get journeyActionEverythingCalmDescription;

  /// No description provided for @journeyActionOverdueFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Follow-up is overdue'**
  String get journeyActionOverdueFollowUp;

  /// No description provided for @journeyActionOverdueFollowUpDescription.
  ///
  /// In en, this message translates to:
  /// **'Contact this record today or create a task so it does not stay cold.'**
  String get journeyActionOverdueFollowUpDescription;

  /// No description provided for @journeyActionNoContact.
  ///
  /// In en, this message translates to:
  /// **'Needs a fresh touchpoint'**
  String get journeyActionNoContact;

  /// No description provided for @journeyActionNoContactDescription.
  ///
  /// In en, this message translates to:
  /// **'There has been no recent contact. Plan a call, task, or appointment.'**
  String get journeyActionNoContactDescription;

  /// No description provided for @journeyActionScheduleVisit.
  ///
  /// In en, this message translates to:
  /// **'Schedule the next appointment'**
  String get journeyActionScheduleVisit;

  /// No description provided for @journeyActionScheduleVisitDescription.
  ///
  /// In en, this message translates to:
  /// **'The record is warm enough for a clear next meeting or property visit.'**
  String get journeyActionScheduleVisitDescription;

  /// No description provided for @journeyActionCompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete missing details'**
  String get journeyActionCompleteProfile;

  /// No description provided for @journeyActionCompleteProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'Add the missing preferences so future matching and follow-up are useful.'**
  String get journeyActionCompleteProfileDescription;

  /// No description provided for @journeyActionStuckDeal.
  ///
  /// In en, this message translates to:
  /// **'Deal needs review'**
  String get journeyActionStuckDeal;

  /// No description provided for @journeyActionStuckDealDescription.
  ///
  /// In en, this message translates to:
  /// **'This deal has not moved recently. Review the stage and next commitment.'**
  String get journeyActionStuckDealDescription;

  /// No description provided for @journeyActionClosingDue.
  ///
  /// In en, this message translates to:
  /// **'Closing date needs attention'**
  String get journeyActionClosingDue;

  /// No description provided for @journeyActionClosingDueDescription.
  ///
  /// In en, this message translates to:
  /// **'The expected closing date has passed. Create a task or update the deal plan.'**
  String get journeyActionClosingDueDescription;

  /// No description provided for @activityHistory.
  ///
  /// In en, this message translates to:
  /// **'Activity history'**
  String get activityHistory;

  /// No description provided for @visibleAuditLogs.
  ///
  /// In en, this message translates to:
  /// **'Visible logs'**
  String get visibleAuditLogs;

  /// No description provided for @todayActivityCount.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayActivityCount;

  /// No description provided for @exportActivity.
  ///
  /// In en, this message translates to:
  /// **'Export activity'**
  String get exportActivity;

  /// No description provided for @importantActivity.
  ///
  /// In en, this message translates to:
  /// **'Important activity'**
  String get importantActivity;

  /// No description provided for @auditLogPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Audit logs are available only to Admin and Manager roles.'**
  String get auditLogPermissionMessage;

  /// No description provided for @auditLogsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load audit logs. Check indexes or permissions and try again.'**
  String get auditLogsLoadFailed;

  /// No description provided for @noAuditLogsFound.
  ///
  /// In en, this message translates to:
  /// **'No audit logs found'**
  String get noAuditLogsFound;

  /// No description provided for @noAuditLogsFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No activity matches the selected scoped filters.'**
  String get noAuditLogsFoundMessage;

  /// No description provided for @allActions.
  ///
  /// In en, this message translates to:
  /// **'All actions'**
  String get allActions;

  /// No description provided for @allUsers.
  ///
  /// In en, this message translates to:
  /// **'All users'**
  String get allUsers;

  /// No description provided for @searchAuditLogs.
  ///
  /// In en, this message translates to:
  /// **'Search activity'**
  String get searchAuditLogs;

  /// No description provided for @auditDetails.
  ///
  /// In en, this message translates to:
  /// **'Audit details'**
  String get auditDetails;

  /// No description provided for @detailsSummary.
  ///
  /// In en, this message translates to:
  /// **'Details summary'**
  String get detailsSummary;

  /// No description provided for @openRelatedRecord.
  ///
  /// In en, this message translates to:
  /// **'Open related record'**
  String get openRelatedRecord;

  /// No description provided for @technicalDetails.
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get technicalDetails;

  /// No description provided for @exportType.
  ///
  /// In en, this message translates to:
  /// **'Export type'**
  String get exportType;

  /// No description provided for @exportScope.
  ///
  /// In en, this message translates to:
  /// **'Export scope'**
  String get exportScope;

  /// No description provided for @fileFormat.
  ///
  /// In en, this message translates to:
  /// **'File format'**
  String get fileFormat;

  /// No description provided for @exportedRows.
  ///
  /// In en, this message translates to:
  /// **'Exported rows'**
  String get exportedRows;

  /// No description provided for @exportedColumns.
  ///
  /// In en, this message translates to:
  /// **'Exported columns'**
  String get exportedColumns;

  /// No description provided for @filterSummary.
  ///
  /// In en, this message translates to:
  /// **'Filter summary'**
  String get filterSummary;

  /// No description provided for @supervisorNotification.
  ///
  /// In en, this message translates to:
  /// **'Supervisor notification'**
  String get supervisorNotification;

  /// No description provided for @auditLogsExport.
  ///
  /// In en, this message translates to:
  /// **'Audit logs export'**
  String get auditLogsExport;

  /// No description provided for @reportsExport.
  ///
  /// In en, this message translates to:
  /// **'Reports export'**
  String get reportsExport;

  /// No description provided for @platformCompanyExport.
  ///
  /// In en, this message translates to:
  /// **'Platform company export'**
  String get platformCompanyExport;

  /// No description provided for @exportTrackingFailed.
  ///
  /// In en, this message translates to:
  /// **'Export was generated, but audit tracking failed. Please try again.'**
  String get exportTrackingFailed;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get openFile;

  /// No description provided for @openDownloads.
  ///
  /// In en, this message translates to:
  /// **'Open downloads'**
  String get openDownloads;

  /// No description provided for @exportSavedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to'**
  String get exportSavedTo;

  /// No description provided for @exportOpenFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the file on this device.'**
  String get exportOpenFileFailed;

  /// No description provided for @exportOpenDownloadsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open Downloads on this device.'**
  String get exportOpenDownloadsFailed;

  /// No description provided for @multipleReports.
  ///
  /// In en, this message translates to:
  /// **'Multiple reports'**
  String get multipleReports;

  /// No description provided for @multipleReportsColumnsHint.
  ///
  /// In en, this message translates to:
  /// **'Multiple report exports use the recommended columns for each selected report.'**
  String get multipleReportsColumnsHint;

  /// No description provided for @androidReleaseManagement.
  ///
  /// In en, this message translates to:
  /// **'Android release management'**
  String get androidReleaseManagement;

  /// No description provided for @androidReleaseManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control forced APK updates for Android users without editing Firestore manually.'**
  String get androidReleaseManagementSubtitle;

  /// No description provided for @releaseReady.
  ///
  /// In en, this message translates to:
  /// **'Release ready'**
  String get releaseReady;

  /// No description provided for @minimumSupportedBuild.
  ///
  /// In en, this message translates to:
  /// **'Minimum supported build'**
  String get minimumSupportedBuild;

  /// No description provided for @latestBuild.
  ///
  /// In en, this message translates to:
  /// **'Latest build'**
  String get latestBuild;

  /// No description provided for @updateUrl.
  ///
  /// In en, this message translates to:
  /// **'Update URL'**
  String get updateUrl;

  /// No description provided for @suggestedUpdateUrl.
  ///
  /// In en, this message translates to:
  /// **'Suggested update URL'**
  String get suggestedUpdateUrl;

  /// No description provided for @useSuggestedUpdateUrl.
  ///
  /// In en, this message translates to:
  /// **'Use suggested URL'**
  String get useSuggestedUpdateUrl;

  /// No description provided for @saveReleasePolicy.
  ///
  /// In en, this message translates to:
  /// **'Save release policy'**
  String get saveReleasePolicy;

  /// No description provided for @androidReleasePolicySaved.
  ///
  /// In en, this message translates to:
  /// **'Android release policy saved.'**
  String get androidReleasePolicySaved;

  /// No description provided for @androidReleasePolicyHint.
  ///
  /// In en, this message translates to:
  /// **'Keep Release ready off until the APK link is uploaded and tested.'**
  String get androidReleasePolicyHint;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @connectionLostSnackbar.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Some actions may not finish until the connection returns.'**
  String get connectionLostSnackbar;

  /// No description provided for @connectionRestoredSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Internet connection restored.'**
  String get connectionRestoredSnackbar;

  /// No description provided for @androidVersionAdoption.
  ///
  /// In en, this message translates to:
  /// **'Android version adoption'**
  String get androidVersionAdoption;

  /// No description provided for @androidVersionAdoptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Active Android users by installed app version, based on latest registered device tokens.'**
  String get androidVersionAdoptionSubtitle;

  /// No description provided for @activeDevices.
  ///
  /// In en, this message translates to:
  /// **'Active devices'**
  String get activeDevices;

  /// No description provided for @latestSeen.
  ///
  /// In en, this message translates to:
  /// **'Latest seen'**
  String get latestSeen;

  /// No description provided for @noAndroidVersionData.
  ///
  /// In en, this message translates to:
  /// **'No Android version data yet.'**
  String get noAndroidVersionData;

  /// No description provided for @releaseCenter.
  ///
  /// In en, this message translates to:
  /// **'Release Center'**
  String get releaseCenter;

  /// No description provided for @releaseOverview.
  ///
  /// In en, this message translates to:
  /// **'Release overview'**
  String get releaseOverview;

  /// No description provided for @releases.
  ///
  /// In en, this message translates to:
  /// **'Releases'**
  String get releases;

  /// No description provided for @versionAdoption.
  ///
  /// In en, this message translates to:
  /// **'Version adoption'**
  String get versionAdoption;

  /// No description provided for @devices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devices;

  /// No description provided for @versionHistory.
  ///
  /// In en, this message translates to:
  /// **'Version history'**
  String get versionHistory;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @latestWebVersion.
  ///
  /// In en, this message translates to:
  /// **'Latest Web version'**
  String get latestWebVersion;

  /// No description provided for @latestAndroidVersion.
  ///
  /// In en, this message translates to:
  /// **'Latest Android version'**
  String get latestAndroidVersion;

  /// No description provided for @latestActiveWeb.
  ///
  /// In en, this message translates to:
  /// **'Latest active Web'**
  String get latestActiveWeb;

  /// No description provided for @latestActiveAndroid.
  ///
  /// In en, this message translates to:
  /// **'Latest active Android'**
  String get latestActiveAndroid;

  /// No description provided for @latestReleasedWeb.
  ///
  /// In en, this message translates to:
  /// **'Latest released Web'**
  String get latestReleasedWeb;

  /// No description provided for @latestReleasedAndroid.
  ///
  /// In en, this message translates to:
  /// **'Latest released Android'**
  String get latestReleasedAndroid;

  /// No description provided for @webUsersDevices.
  ///
  /// In en, this message translates to:
  /// **'Web users/devices'**
  String get webUsersDevices;

  /// No description provided for @androidUsersDevices.
  ///
  /// In en, this message translates to:
  /// **'Android users/devices'**
  String get androidUsersDevices;

  /// No description provided for @oldBuilds.
  ///
  /// In en, this message translates to:
  /// **'Old builds'**
  String get oldBuilds;

  /// No description provided for @belowMinimumBuild.
  ///
  /// In en, this message translates to:
  /// **'Below minimum build'**
  String get belowMinimumBuild;

  /// No description provided for @pushHealth.
  ///
  /// In en, this message translates to:
  /// **'Push health'**
  String get pushHealth;

  /// No description provided for @currentAdoptionHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Current adoption shows active devices only. Version history shows previous builds.'**
  String get currentAdoptionHistoryHint;

  /// No description provided for @noAdoptionDataYet.
  ///
  /// In en, this message translates to:
  /// **'No adoption data yet'**
  String get noAdoptionDataYet;

  /// No description provided for @noReleaseRecordsYet.
  ///
  /// In en, this message translates to:
  /// **'No release records yet'**
  String get noReleaseRecordsYet;

  /// No description provided for @noDeviceDataYet.
  ///
  /// In en, this message translates to:
  /// **'No device data yet'**
  String get noDeviceDataYet;

  /// No description provided for @noVersionHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No version history yet'**
  String get noVersionHistoryYet;

  /// No description provided for @noHealthDataYet.
  ///
  /// In en, this message translates to:
  /// **'No health data yet'**
  String get noHealthDataYet;

  /// No description provided for @web.
  ///
  /// In en, this message translates to:
  /// **'Web'**
  String get web;

  /// No description provided for @androidPlatform.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get androidPlatform;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @oldBuild.
  ///
  /// In en, this message translates to:
  /// **'Old build'**
  String get oldBuild;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// No description provided for @missing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get missing;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get invalid;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @notReported.
  ///
  /// In en, this message translates to:
  /// **'Not reported'**
  String get notReported;

  /// No description provided for @invalidOrFailed.
  ///
  /// In en, this message translates to:
  /// **'Invalid / failed'**
  String get invalidOrFailed;

  /// No description provided for @deviceBrowser.
  ///
  /// In en, this message translates to:
  /// **'Device/browser'**
  String get deviceBrowser;

  /// No description provided for @createdBy.
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String get createdBy;

  /// No description provided for @createAction.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createAction;

  /// No description provided for @releaseCenterAllCompaniesHint.
  ///
  /// In en, this message translates to:
  /// **'Release Center is showing all companies.'**
  String get releaseCenterAllCompaniesHint;

  /// No description provided for @releaseCenterSelectedCompanyHint.
  ///
  /// In en, this message translates to:
  /// **'Release Center is filtered to the selected company.'**
  String get releaseCenterSelectedCompanyHint;

  /// No description provided for @releaseRecordsStartAfterRegistryEnabled.
  ///
  /// In en, this message translates to:
  /// **'No release records yet. Release records start after the release registry is enabled, or after you create a record from the current Android policy.'**
  String get releaseRecordsStartAfterRegistryEnabled;

  /// No description provided for @createReleaseRecordFromAndroidPolicy.
  ///
  /// In en, this message translates to:
  /// **'Create release record from current Android policy'**
  String get createReleaseRecordFromAndroidPolicy;

  /// No description provided for @createReleaseRecordFromAndroidPolicyConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will create a release registry record from the current Android forced-update policy. It will not change the policy or deploy anything.'**
  String get createReleaseRecordFromAndroidPolicyConfirm;

  /// No description provided for @releaseRecordCreated.
  ///
  /// In en, this message translates to:
  /// **'Release record created.'**
  String get releaseRecordCreated;

  /// No description provided for @versionHistoryStartsAfterBuildChange.
  ///
  /// In en, this message translates to:
  /// **'Version history starts when a device changes build after v2.31.0+102.'**
  String get versionHistoryStartsAfterBuildChange;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @released.
  ///
  /// In en, this message translates to:
  /// **'Released'**
  String get released;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @rolledBack.
  ///
  /// In en, this message translates to:
  /// **'Rolled back'**
  String get rolledBack;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @notificationPermissionEnabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get notificationPermissionEnabledTitle;

  /// No description provided for @notificationPermissionEnabledBody.
  ///
  /// In en, this message translates to:
  /// **'This device is connected and will receive important Masar CRM alerts.'**
  String get notificationPermissionEnabledBody;

  /// No description provided for @notificationPermissionNotConnectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Device notifications not connected'**
  String get notificationPermissionNotConnectedTitle;

  /// No description provided for @notificationPermissionBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked'**
  String get notificationPermissionBlockedTitle;

  /// No description provided for @notificationPermissionBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications from your browser or device settings when you want alerts.'**
  String get notificationPermissionBlockedBody;

  /// No description provided for @notificationPermissionConfigurationIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification setup needs configuration'**
  String get notificationPermissionConfigurationIssueTitle;

  /// No description provided for @notificationPermissionConfigurationIssueBody.
  ///
  /// In en, this message translates to:
  /// **'The Web push key is missing in this build. Rebuild the app with the Firebase VAPID key to enable browser notifications.'**
  String get notificationPermissionConfigurationIssueBody;

  /// No description provided for @platformActivityDeferredMessage.
  ///
  /// In en, this message translates to:
  /// **'Open activity to load selected-company users and login activity for this owner session.'**
  String get platformActivityDeferredMessage;

  /// No description provided for @platformWorkspaceSummaryDeferredMessage.
  ///
  /// In en, this message translates to:
  /// **'Open the workspace to load selected-company user counts for this owner session.'**
  String get platformWorkspaceSummaryDeferredMessage;

  /// No description provided for @releaseOverviewGuidance.
  ///
  /// In en, this message translates to:
  /// **'Use this page to confirm the latest published Web and Android versions, outdated devices, Android update readiness, and notification health before releasing a new build.'**
  String get releaseOverviewGuidance;

  /// No description provided for @releaseOverviewMixedScopeHint.
  ///
  /// In en, this message translates to:
  /// **'Latest releases and Android policy are platform-wide; device and history counts follow the selected company filter.'**
  String get releaseOverviewMixedScopeHint;

  /// No description provided for @releaseRegistryGuidance.
  ///
  /// In en, this message translates to:
  /// **'This registry shows prepared and published platform releases. Use it to confirm what was recorded as a release, not to change Android forced-update policy.'**
  String get releaseRegistryGuidance;

  /// No description provided for @releaseRegistryAndroidPolicyNote.
  ///
  /// In en, this message translates to:
  /// **'Android policy details are managed from Android release management.'**
  String get releaseRegistryAndroidPolicyNote;

  /// No description provided for @releaseAdoptionDevicesGuidance.
  ///
  /// In en, this message translates to:
  /// **'Use this tab to see real active devices and users by version. Adoption shows installed usage, not the release registry.'**
  String get releaseAdoptionDevicesGuidance;

  /// No description provided for @releaseAndroidPolicyGuidance.
  ///
  /// In en, this message translates to:
  /// **'Use this tab to manage Android forced-update readiness. Mark a release ready only after the APK is uploaded and the download link is tested.'**
  String get releaseAndroidPolicyGuidance;

  /// No description provided for @releaseHistoryGuidance.
  ///
  /// In en, this message translates to:
  /// **'Use this tab to review previous device version changes and release events for troubleshooting.'**
  String get releaseHistoryGuidance;

  /// No description provided for @releaseHistoryProfileLimitNote.
  ///
  /// In en, this message translates to:
  /// **'Older events may only contain a technical user reference; a shortened reference appears only for troubleshooting.'**
  String get releaseHistoryProfileLimitNote;

  /// No description provided for @releaseSectionPlatformWideNote.
  ///
  /// In en, this message translates to:
  /// **'This section is platform-wide and is not limited by the selected company.'**
  String get releaseSectionPlatformWideNote;

  /// No description provided for @notificationAdoptionSeparateNote.
  ///
  /// In en, this message translates to:
  /// **'Notification readiness is separate from version adoption.'**
  String get notificationAdoptionSeparateNote;

  /// No description provided for @androidPolicyBuildComparisonNote.
  ///
  /// In en, this message translates to:
  /// **'Android update decisions compare build numbers, not display version text.'**
  String get androidPolicyBuildComparisonNote;

  /// No description provided for @suggestedApkUrlNotProof.
  ///
  /// In en, this message translates to:
  /// **'The suggested URL is only a naming helper. Upload the APK and test the download link before marking the release ready.'**
  String get suggestedApkUrlNotProof;

  /// No description provided for @androidPolicyNotReadyAction.
  ///
  /// In en, this message translates to:
  /// **'Release is not ready. Upload and test the APK link before enabling ready state.'**
  String get androidPolicyNotReadyAction;

  /// No description provided for @androidPolicyReadyAction.
  ///
  /// In en, this message translates to:
  /// **'Release is marked ready. Android clients will compare update requirements by build number.'**
  String get androidPolicyReadyAction;

  /// No description provided for @notificationReadyDevices.
  ///
  /// In en, this message translates to:
  /// **'Notification-ready devices'**
  String get notificationReadyDevices;

  /// No description provided for @notificationReadyDevicesRatio.
  ///
  /// In en, this message translates to:
  /// **'{ready} / {total}'**
  String notificationReadyDevicesRatio(int ready, int total);

  /// No description provided for @notificationReadyDevicesSummary.
  ///
  /// In en, this message translates to:
  /// **'{ready} of {total} active devices can receive notifications.'**
  String notificationReadyDevicesSummary(int ready, int total);

  /// No description provided for @notificationBlockedDevices.
  ///
  /// In en, this message translates to:
  /// **'Notification-blocked devices'**
  String get notificationBlockedDevices;

  /// No description provided for @notificationMissingDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices without notification token'**
  String get notificationMissingDevices;

  /// No description provided for @notificationInvalidFailedDevices.
  ///
  /// In en, this message translates to:
  /// **'Invalid or failed notification devices'**
  String get notificationInvalidFailedDevices;

  /// No description provided for @devicesBelowLatestBuild.
  ///
  /// In en, this message translates to:
  /// **'Devices below latest build'**
  String get devicesBelowLatestBuild;

  /// No description provided for @devicesBelowLatestBuildSummary.
  ///
  /// In en, this message translates to:
  /// **'{users} users on {devices} devices are below the latest build.'**
  String devicesBelowLatestBuildSummary(int users, int devices);

  /// No description provided for @requiresReview.
  ///
  /// In en, this message translates to:
  /// **'Requires review'**
  String get requiresReview;

  /// No description provided for @unresolvedUser.
  ///
  /// In en, this message translates to:
  /// **'Unresolved user'**
  String get unresolvedUser;

  /// No description provided for @userProfileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'User profile unavailable'**
  String get userProfileUnavailable;

  /// No description provided for @releaseEventTechnicalReferenceOnly.
  ///
  /// In en, this message translates to:
  /// **'This release event only stored a technical user reference.'**
  String get releaseEventTechnicalReferenceOnly;

  /// No description provided for @technicalReference.
  ///
  /// In en, this message translates to:
  /// **'Technical reference'**
  String get technicalReference;

  /// No description provided for @dashboardPerformanceDailyActivityNote.
  ///
  /// In en, this message translates to:
  /// **'Shows daily activity, so days without new records appear as 0.'**
  String get dashboardPerformanceDailyActivityNote;

  /// No description provided for @dashboardPerformanceTotalTrend.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get dashboardPerformanceTotalTrend;

  /// No description provided for @dashboardPerformanceDailyTrend.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dashboardPerformanceDailyTrend;

  /// No description provided for @dashboardPerformanceTotalTrendNote.
  ///
  /// In en, this message translates to:
  /// **'Shows the running total across the selected period, so the line does not drop to 0 on quiet days.'**
  String get dashboardPerformanceTotalTrendNote;
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
