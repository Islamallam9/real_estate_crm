// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Real Estate CRM';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get logout => 'Logout';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get leads => 'Leads';

  @override
  String get properties => 'Properties';

  @override
  String get clients => 'Clients';

  @override
  String get tasks => 'Tasks';

  @override
  String get deals => 'Deals';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get arabic => 'Arabic';

  @override
  String get english => 'English';

  @override
  String get salesWorkspace => 'Sales workspace';

  @override
  String get searchCrm => 'Search CRM';

  @override
  String get notifications => 'Notifications';

  @override
  String get crmUser => 'CRM User';

  @override
  String get workspace => 'Workspace';

  @override
  String get crmOverview => 'CRM overview';

  @override
  String get dashboardPlaceholderDescription =>
      'Key sales, leads, follow-ups, and property activity will appear here.';

  @override
  String get totalLeads => 'Total leads';

  @override
  String get newLeads => 'New leads';

  @override
  String get activeLeads => 'Contacted / active leads';

  @override
  String get unassignedLeads => 'Unassigned leads';

  @override
  String get followUpsDue => 'Follow-ups due';

  @override
  String get openDeals => 'Open deals';

  @override
  String get availableProperties => 'Available properties';

  @override
  String get authScreenPlaceholder => 'Authentication screen placeholder';

  @override
  String get openDashboard => 'Open dashboard';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to continue to your CRM workspace.';

  @override
  String get emailRequired => 'Email is required.';

  @override
  String get passwordRequired => 'Password is required.';

  @override
  String get invalidEmail => 'Enter a valid email address.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signingIn => 'Signing in...';

  @override
  String get authErrorInvalidCredentials => 'Invalid email or password.';

  @override
  String get authErrorConnection =>
      'Connection error. Check your internet connection.';

  @override
  String get authErrorSignInFailed => 'Unable to sign in. Please try again.';

  @override
  String get authErrorSignOutFailed => 'Unable to sign out. Please try again.';

  @override
  String get authErrorProfileMissing => 'Unable to load your user profile.';

  @override
  String get authErrorInactiveAccount =>
      'Your account is inactive. Please contact an administrator.';

  @override
  String get logoutTooltip => 'Logout';

  @override
  String get createLead => 'Create lead';

  @override
  String get leadDetails => 'Lead details';

  @override
  String get leadName => 'Lead name';

  @override
  String get phone => 'Phone';

  @override
  String get source => 'Source';

  @override
  String get status => 'Status';

  @override
  String get priority => 'Priority';

  @override
  String get budgetMin => 'Minimum budget';

  @override
  String get budgetMax => 'Maximum budget';

  @override
  String get preferredLocation => 'Preferred location';

  @override
  String get preferredPropertyType => 'Preferred property type';

  @override
  String get assignedTo => 'Assigned to';

  @override
  String get notes => 'Notes';

  @override
  String get saveLead => 'Save lead';

  @override
  String get leadCreated => 'Lead created successfully.';

  @override
  String get noLeads => 'No leads yet.';

  @override
  String get unableToLoadLeads => 'Unable to load leads. Please try again.';

  @override
  String get unableToCreateLead => 'Unable to create lead. Please try again.';

  @override
  String get requiredField => 'This field is required.';

  @override
  String get notAvailable => 'Not available';

  @override
  String get newLead => 'New';

  @override
  String get newLeadStatus => 'New';

  @override
  String get contacted => 'Contacted';

  @override
  String get contactedLeadStatus => 'Contacted';

  @override
  String get interested => 'Interested';

  @override
  String get interestedLeadStatus => 'Interested';

  @override
  String get visitScheduled => 'Visit scheduled';

  @override
  String get visitScheduledLeadStatus => 'Visit scheduled';

  @override
  String get negotiation => 'Negotiation';

  @override
  String get negotiationLeadStatus => 'Negotiation';

  @override
  String get won => 'Won';

  @override
  String get wonLeadStatus => 'Won';

  @override
  String get lost => 'Lost';

  @override
  String get lostLeadStatus => 'Lost';

  @override
  String get low => 'Low';

  @override
  String get medium => 'Medium';

  @override
  String get high => 'High';

  @override
  String get facebook => 'Facebook';

  @override
  String get website => 'Website';

  @override
  String get phoneCall => 'Phone call';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get referral => 'Referral';

  @override
  String get walkIn => 'Walk-in';

  @override
  String get other => 'Other';

  @override
  String get leadsSubtitle =>
      'Track new inquiries and follow up with prospects.';

  @override
  String get cancel => 'Cancel';

  @override
  String get back => 'Back';

  @override
  String get archive => 'Archive';

  @override
  String get archiveLead => 'Archive lead';

  @override
  String get archiveLeadConfirmation =>
      'This lead will be archived and hidden from the active leads list.';

  @override
  String get leadArchived => 'Lead archived successfully.';

  @override
  String get unableToArchiveLead => 'Unable to archive lead. Please try again.';

  @override
  String get permissionDenied =>
      'You do not have permission to perform this action.';

  @override
  String get contactInformation => 'Contact information';

  @override
  String get leadPreferences => 'Lead preferences';

  @override
  String get leadAssignment => 'Assignment and notes';

  @override
  String get missingCompanyProfile =>
      'Unable to load your company profile. Please sign in again.';

  @override
  String get editLead => 'Edit lead';

  @override
  String get updateLead => 'Update lead';

  @override
  String get leadUpdated => 'Lead updated successfully.';

  @override
  String get searchLeads => 'Search leads';

  @override
  String get allStatuses => 'All statuses';

  @override
  String get allSources => 'All sources';

  @override
  String get allPriorities => 'All priorities';

  @override
  String get allAgents => 'All agents';

  @override
  String get changeStatus => 'Change status';

  @override
  String get addNote => 'Add note';

  @override
  String get note => 'Note';

  @override
  String get notesHistory => 'Notes history';

  @override
  String get noNotes => 'No notes yet.';

  @override
  String get saveNote => 'Save note';

  @override
  String get unableToLoadNotes => 'Unable to load notes. Please try again.';

  @override
  String get unableToAddNote => 'Unable to add note. Please try again.';

  @override
  String get activeUsers => 'Active users';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get onlyAdminsManagersCanAssign =>
      'Only admins and managers can assign leads.';

  @override
  String get cannotAssignAcrossCompanies =>
      'Cannot assign a lead outside your company.';

  @override
  String get accessDenied => 'Access denied';

  @override
  String get assignedUser => 'Assigned user';

  @override
  String get assignedUserUnavailable => 'Assigned user unavailable';

  @override
  String get youDoNotHavePermissionToViewLead =>
      'You do not have permission to view this lead.';

  @override
  String get youDoNotHavePermissionToEditLead =>
      'You do not have permission to edit this lead.';

  @override
  String get timeline => 'Timeline';

  @override
  String get leadCreatedEvent => 'Lead created';

  @override
  String get leadAssignedEvent => 'Lead assigned';

  @override
  String get leadReassignedEvent => 'Lead reassigned';

  @override
  String get statusChangedEvent => 'Status changed';

  @override
  String get noteAddedEvent => 'Note added';

  @override
  String get archivedEvent => 'Lead archived';

  @override
  String get updatedEvent => 'Lead updated';

  @override
  String get changedFrom => 'Changed from';

  @override
  String get changedTo => 'Changed to';

  @override
  String get unknownUser => 'Unknown user';

  @override
  String leadCreatedBy(Object user) {
    return 'Lead created by $user';
  }

  @override
  String statusChangedToBy(Object status, Object user) {
    return 'Status changed to $status by $user';
  }

  @override
  String noteAddedBy(Object user) {
    return 'Note added by $user';
  }

  @override
  String leadReassignedBy(Object user) {
    return 'Lead reassigned by $user';
  }

  @override
  String leadReassignedFromToBy(Object fromUser, Object toUser, Object actor) {
    return 'Lead reassigned from $fromUser to $toUser by $actor';
  }

  @override
  String leadArchivedBy(Object user) {
    return 'Lead archived by $user';
  }

  @override
  String get noLeadsAvailable => 'No leads available.';

  @override
  String get noNotesAvailable => 'No notes available.';

  @override
  String get noTimelineEvents => 'No timeline events yet.';

  @override
  String fieldChangedBy(Object field, Object user) {
    return '$field changed by $user';
  }

  @override
  String changedFromTo(Object oldValue, Object newValue) {
    return 'Changed from $oldValue to $newValue';
  }

  @override
  String get assignedToLabel => 'Assigned to';

  @override
  String leadAssignedTo(Object name) {
    return 'Assigned to: $name';
  }

  @override
  String get fullNameUpdated => 'Full name';

  @override
  String get phoneUpdated => 'Phone';

  @override
  String get emailUpdated => 'Email';

  @override
  String get sourceUpdated => 'Source';

  @override
  String get statusUpdated => 'Status';

  @override
  String get priorityUpdated => 'Priority';

  @override
  String get budgetUpdated => 'Budget';

  @override
  String get preferredLocationUpdated => 'Preferred location';

  @override
  String get preferredPropertyTypeUpdated => 'Preferred property type';

  @override
  String get more => 'More';

  @override
  String get filters => 'Filters';

  @override
  String get applyFilters => 'Apply filters';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get updated => 'Updated';

  @override
  String get details => 'Details';

  @override
  String get viewDetails => 'View details';

  @override
  String get selectLeadPreview => 'Select a lead';

  @override
  String get selectLeadPreviewMessage =>
      'Choose a lead from the list to preview contact, status, and next actions.';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get tryAgain => 'Try again';

  @override
  String get unableToConnect =>
      'Unable to connect. Check your internet connection and try again.';

  @override
  String get leadUpdateFailed => 'Unable to update lead. Please try again.';

  @override
  String get noData => 'No data available.';

  @override
  String get leadCreatedSuccessfully => 'Lead created successfully.';

  @override
  String get leadUpdatedSuccessfully => 'Lead updated successfully.';

  @override
  String get leadArchivedSuccessfully => 'Lead archived successfully.';

  @override
  String get leadStatusUpdatedSuccessfully =>
      'Lead status updated successfully.';

  @override
  String get leadAssignedSuccessfully => 'Lead assigned successfully.';

  @override
  String get noteAddedSuccessfully => 'Note added successfully.';
}
