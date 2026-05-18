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
  /// **'From lead to deal, one clear path.'**
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

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get allStatuses;

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
  /// **'Activity history'**
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
  /// **'Review CRM performance using real leads, deals, tasks, and properties for the selected period.'**
  String get reportsOverview;

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

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

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

  /// No description provided for @commissionTotal.
  ///
  /// In en, this message translates to:
  /// **'Commission total'**
  String get commissionTotal;

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
  /// **'This notification cannot be opened from your current access.'**
  String get notificationRouteUnavailable;

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

  /// No description provided for @markMissedConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Mark this appointment as missed?'**
  String get markMissedConfirmation;

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
