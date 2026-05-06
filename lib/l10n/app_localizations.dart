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
  /// **'Real Estate CRM'**
  String get appName;

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
  /// **'Sales workspace'**
  String get salesWorkspace;

  /// No description provided for @searchCrm.
  ///
  /// In en, this message translates to:
  /// **'Search CRM'**
  String get searchCrm;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @crmUser.
  ///
  /// In en, this message translates to:
  /// **'CRM User'**
  String get crmUser;

  /// No description provided for @workspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get workspace;

  /// No description provided for @crmOverview.
  ///
  /// In en, this message translates to:
  /// **'CRM overview'**
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
  /// **'Sign in to continue to your CRM workspace.'**
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

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredField;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

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

  /// No description provided for @allPriorities.
  ///
  /// In en, this message translates to:
  /// **'All priorities'**
  String get allPriorities;

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

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get unknownUser;

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

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

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
