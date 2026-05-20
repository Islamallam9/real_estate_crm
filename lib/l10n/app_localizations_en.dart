// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Masar';

  @override
  String get loginBrandName => 'Masar | مسار';

  @override
  String get websiteTitle => 'Masar | CRM';

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
  String get loggedOutSuccessfully => 'Logged out successfully.';

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
  String get tasksSubtitle =>
      'Plan follow-ups and internal task work by due date, status, and priority.';

  @override
  String get createTask => 'Create task';

  @override
  String get editTask => 'Edit task';

  @override
  String get updateTask => 'Update task';

  @override
  String get agentPerformanceSummary =>
      'Compare agent workload, deal activity, task completion, and overdue risk.';

  @override
  String get agent => 'Agent';

  @override
  String get performanceScore => 'Score';

  @override
  String get searchReports => 'Search reports';

  @override
  String get taskCreatedSuccessfully => 'Task created successfully.';

  @override
  String get taskUpdatedSuccessfully => 'Task updated successfully.';

  @override
  String get taskCompletedSuccessfully => 'Task marked completed.';

  @override
  String get taskCancelledSuccessfully => 'Task cancelled successfully.';

  @override
  String get markTaskCompleted => 'Mark completed';

  @override
  String get cancelTask => 'Cancel task';

  @override
  String get cancelTaskConfirmation =>
      'This task will be marked as cancelled and remain visible in task lists.';

  @override
  String get taskNotFound => 'Task not found. Open it from the tasks list.';

  @override
  String get taskInformation => 'Task information';

  @override
  String get taskTitle => 'Task title';

  @override
  String get relatedType => 'Related type';

  @override
  String get relatedRecordId => 'Related record ID';

  @override
  String get relatedRecord => 'Related record';

  @override
  String get selectRelatedRecord => 'Select related record';

  @override
  String get relatedRecordRequired => 'Select a related record.';

  @override
  String get relatedRecordUnavailable => 'Related record unavailable';

  @override
  String get noLeadsFound => 'No leads found.';

  @override
  String get agentActivityResults => 'Agent activity and results';

  @override
  String get agentActivityResultsSummary =>
      'Review workload, won deals, completed tasks, and overdue follow-ups by agent.';

  @override
  String get workload => 'Workload';

  @override
  String get results => 'Results';

  @override
  String get followUps => 'Follow-ups';

  @override
  String get wonDeals => 'Won deals';

  @override
  String get taskCompletion => 'Task completion';

  @override
  String get overdueTasks => 'Overdue tasks';

  @override
  String get noPropertiesFound => 'No properties found.';

  @override
  String get scheduleAndPriority => 'Schedule and priority';

  @override
  String get selectDueDate => 'Select due date';

  @override
  String get dueDate => 'Due date';

  @override
  String get dashboardRecentActivity => 'Recent activity';

  @override
  String get dashboardRecentActivitySubtitle =>
      'Latest logged CRM changes for this company.';

  @override
  String get dashboardNoRecentActivity => 'No recent activity yet.';

  @override
  String get dashboardUnableToLoadRecentActivity =>
      'Unable to load recent activity.';

  @override
  String get teamRecentActivity => 'Team Recent Activity';

  @override
  String get teamRecentActivitySubtitle =>
      'Latest logged CRM changes for your team.';

  @override
  String get noRecentTeamActivity => 'No recent team activity yet.';

  @override
  String dashboardAuditActionLabel(Object module, Object action) {
    return '$module · $action';
  }

  @override
  String get dashboardAuditCreated => 'Created';

  @override
  String get dashboardAuditUpdated => 'Updated';

  @override
  String get dashboardAuditArchived => 'Archived';

  @override
  String get dashboardAuditDeactivated => 'Deactivated';

  @override
  String get dashboardAuditAssigned => 'Assigned';

  @override
  String get dashboardAuditStatusChanged => 'Status changed';

  @override
  String get dashboardAuditStageChanged => 'Stage changed';

  @override
  String get dashboardAuditCompleted => 'Completed';

  @override
  String get dashboardAuditCancelled => 'Cancelled';

  @override
  String get dashboardAuditImageAdded => 'Image added';

  @override
  String get dashboardAuditImageRemoved => 'Image removed';

  @override
  String get dashboardAuditLead => 'Lead';

  @override
  String get dashboardAuditClient => 'Client';

  @override
  String get dashboardAuditProperty => 'Property';

  @override
  String get dashboardAuditTask => 'Task';

  @override
  String get dashboardAuditDeal => 'Deal';

  @override
  String get dashboardActivityLeadUpdated => 'Lead updated';

  @override
  String get dashboardActivityClientUpdated => 'Client updated';

  @override
  String get dashboardActivityPropertyUpdated => 'Property updated';

  @override
  String get dashboardActivityTaskUpdated => 'Task updated';

  @override
  String get dashboardActivityTaskCompleted => 'Task completed';

  @override
  String get dashboardActivityDealUpdated => 'Deal updated';

  @override
  String get dashboardActivityDealWon => 'Deal won';

  @override
  String get dashboardActivityDealLost => 'Deal lost';

  @override
  String get dashboardJustNow => 'Just now';

  @override
  String dashboardMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String dashboardHoursAgo(int count) {
    return '$count hr ago';
  }

  @override
  String get dashboardYesterday => 'Yesterday';

  @override
  String byUser(String name) {
    return 'By $name';
  }

  @override
  String get unknownUser => 'Unknown user';

  @override
  String get dueDateRequired => 'Due date is required.';

  @override
  String get pending => 'Pending';

  @override
  String get inProgress => 'In progress';

  @override
  String get completed => 'Completed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get allPriorities => 'All priorities';

  @override
  String get noTasksYet => 'No tasks have been created yet.';

  @override
  String get noTasksMatchFilters => 'No tasks match the current filters.';

  @override
  String get lead => 'Lead';

  @override
  String get client => 'Client';

  @override
  String get property => 'Property';

  @override
  String get deal => 'Deal';

  @override
  String get general => 'General';

  @override
  String get deals => 'Deals';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get lightMode => 'Light mode';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get arabic => 'Arabic';

  @override
  String get english => 'English';

  @override
  String get salesWorkspace => 'From lead to deal, one clear path.';

  @override
  String get searchCrm => 'Search Masar CRM';

  @override
  String get notifications => 'Notifications';

  @override
  String get crmUser => 'Masar user';

  @override
  String get workspace => 'Workspace';

  @override
  String get crmOverview => 'Masar CRM overview';

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
  String get loginSubtitle => 'From lead to deal, one clear path.';

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
  String get authErrorAccountNotLinked =>
      'This account is not linked to an active company.';

  @override
  String get authErrorCompanyInactive =>
      'This company is inactive. Please contact platform support.';

  @override
  String get logoutTooltip => 'Logout';

  @override
  String get createLead => 'Create lead';

  @override
  String get quickAdd => 'Quick add';

  @override
  String get addLead => 'Add lead';

  @override
  String get addClient => 'Add client';

  @override
  String get savedSuccessfully => 'Saved successfully.';

  @override
  String get updatedSuccessfully => 'Updated successfully.';

  @override
  String get unableToSave => 'Unable to save. Please try again.';

  @override
  String get unableToAssignClient =>
      'Unable to assign client. Please try again.';

  @override
  String get unableToUpdateTask => 'Unable to update task. Please try again.';

  @override
  String get actionCompletedSuccessfully => 'Action completed successfully.';

  @override
  String get actionFailed => 'Action failed. Please try again.';

  @override
  String get createClient => 'Create client';

  @override
  String get editClient => 'Edit client';

  @override
  String get updateClient => 'Update client';

  @override
  String get clientDetails => 'Client details';

  @override
  String get clientCreatedSuccessfully => 'Client created successfully.';

  @override
  String get clientUpdatedSuccessfully => 'Client updated successfully.';

  @override
  String get assignClient => 'Assign client';

  @override
  String get clientAssignedSuccessfully => 'Client assigned successfully.';

  @override
  String get noClientsFound => 'No clients found.';

  @override
  String get noAssignedClientsFound => 'No assigned clients found.';

  @override
  String get archiveClient => 'Archive client';

  @override
  String get archiveClientConfirmation =>
      'This client will be archived and hidden from the active clients list.';

  @override
  String get clientArchivedSuccessfully => 'Client archived successfully.';

  @override
  String get clientNotFoundMessage =>
      'Client not found. Open it from the clients list.';

  @override
  String get backToClients => 'Back to clients';

  @override
  String get clientPreferences => 'Client preferences';

  @override
  String get budgetMaxMustBeGreaterThanBudgetMin =>
      'Maximum budget cannot be less than minimum budget.';

  @override
  String get createProperty => 'Create property';

  @override
  String get editProperty => 'Edit property';

  @override
  String get updateProperty => 'Update property';

  @override
  String get leadDetails => 'Lead details';

  @override
  String get leadName => 'Lead name';

  @override
  String get phone => 'Phone';

  @override
  String get source => 'Source';

  @override
  String get sourceDetails => 'Source details';

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
  String get propertiesSubtitle =>
      'Manage company listings and availability in one practical view.';

  @override
  String get noProperties => 'No properties yet.';

  @override
  String get unableToLoadProperties =>
      'Unable to load properties. Please try again.';

  @override
  String get propertyTitle => 'Title';

  @override
  String get propertyType => 'Property type';

  @override
  String get listingType => 'Listing type';

  @override
  String get price => 'Price';

  @override
  String get area => 'Area';

  @override
  String get location => 'Location';

  @override
  String get apartment => 'Apartment';

  @override
  String get villa => 'Villa';

  @override
  String get office => 'Office';

  @override
  String get shop => 'Shop';

  @override
  String get land => 'Land';

  @override
  String get studio => 'Studio';

  @override
  String get duplex => 'Duplex';

  @override
  String get penthouse => 'Penthouse';

  @override
  String get sale => 'Sale';

  @override
  String get rent => 'Rent';

  @override
  String get available => 'Available';

  @override
  String get reserved => 'Reserved';

  @override
  String get sold => 'Sold';

  @override
  String get rented => 'Rented';

  @override
  String get inactive => 'Inactive';

  @override
  String get requiredField => 'This field is required.';

  @override
  String get enterValidNumber => 'Enter a valid number.';

  @override
  String get valueMustBePositive => 'Value must be greater than zero.';

  @override
  String get valueMustBeNonNegative => 'Value cannot be negative.';

  @override
  String get notAvailable => 'Not available';

  @override
  String get description => 'Description';

  @override
  String get bedrooms => 'Bedrooms';

  @override
  String get bathrooms => 'Bathrooms';

  @override
  String get compound => 'Compound';

  @override
  String get ownerName => 'Owner name';

  @override
  String get ownerPhone => 'Owner phone';

  @override
  String get propertyBasicInformation => 'Basic information';

  @override
  String get propertyMetrics => 'Property metrics';

  @override
  String get propertyLocationSection => 'Location';

  @override
  String get propertyOwnerSection => 'Owner information';

  @override
  String get propertyImages => 'Property images';

  @override
  String get propertyImagesHint =>
      'Upload clear property photos. The first image is used as the cover.';

  @override
  String get addPropertyImages => 'Add images';

  @override
  String get noPropertyImagesYet => 'No property images yet.';

  @override
  String get removeImage => 'Remove image';

  @override
  String get newImage => 'New';

  @override
  String get propertyImageInvalidType => 'Only image files are allowed.';

  @override
  String get propertyImageTooLarge =>
      'Each property image must be 5 MB or smaller.';

  @override
  String get unableToPickPropertyImages =>
      'Unable to select property images. Please try again.';

  @override
  String get propertyCreatedSuccessfully => 'Property created successfully.';

  @override
  String get propertyUpdatedSuccessfully => 'Property updated successfully.';

  @override
  String get propertyDetails => 'Property details';

  @override
  String get searchProperties => 'Search properties';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get noMatchingProperties => 'No properties match your filters.';

  @override
  String get adjustPropertyFiltersHint =>
      'Try changing search text or filter values.';

  @override
  String get allPropertyTypes => 'All property types';

  @override
  String get allListingTypes => 'All listing types';

  @override
  String propertiesResultsCount(Object shown, Object total) {
    return '$shown of $total properties';
  }

  @override
  String get propertyNotFoundMessage =>
      'Property not found. Open it from the properties list.';

  @override
  String get backToProperties => 'Back to properties';

  @override
  String get createdAt => 'Created at';

  @override
  String get updatedAt => 'Updated at';

  @override
  String get auditInfo => 'Audit info';

  @override
  String get unableToLoadPropertyForEdit =>
      'Unable to load property for editing. Open it from the properties list.';

  @override
  String get actions => 'Actions';

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
  String get deactivate => 'Deactivate';

  @override
  String get deactivateProperty => 'Deactivate property';

  @override
  String get deactivatePropertyConfirmation =>
      'This property will be marked as inactive.';

  @override
  String get propertyDeactivatedSuccessfully =>
      'Property deactivated successfully.';

  @override
  String get unableToDeactivateProperty =>
      'Unable to deactivate property. Please try again.';

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
  String get lastContact => 'Last contact';

  @override
  String get nextFollowUp => 'Next follow-up';

  @override
  String get clearDate => 'Clear date';

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
  String get allAgents => 'All agents';

  @override
  String get assignee => 'Assignee';

  @override
  String get allAssignees => 'All assignees';

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
  String get recordMustBeAssignedBeforeSaving =>
      'This record must be assigned before saving.';

  @override
  String get canOnlyAssignRecordsToYourTeam =>
      'You can only assign records to users in your team.';

  @override
  String get selectedAssigneeInactive => 'The selected assignee is inactive.';

  @override
  String get selectedAssigneeNotEligible =>
      'The selected assignee is not eligible for this record.';

  @override
  String get permissionToViewAnotherTeamRecordsDenied =>
      'You do not have permission to view records from another team.';

  @override
  String get sessionOrCompanyProfileMissing =>
      'Your session or company profile is missing. Please sign in again.';

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

  @override
  String get overdue => 'Overdue';

  @override
  String get dueToday => 'Due today';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get allDueDates => 'All due dates';

  @override
  String get dueDateFilter => 'Due date';

  @override
  String get notScheduled => 'Not scheduled';

  @override
  String get allFollowUps => 'All follow-ups';

  @override
  String get needsAttention => 'Needs attention';

  @override
  String get staleLead => 'Stale lead';

  @override
  String get markContactedToday => 'Mark contacted today';

  @override
  String get leadMarkedContactedToday => 'Lead marked as contacted today.';

  @override
  String get scheduleFollowUp => 'Schedule follow-up';

  @override
  String get duplicateLeadFound =>
      'A lead with this phone or email already exists.';

  @override
  String get dashboardGoodMorning => 'Good morning';

  @override
  String get dashboardGoodAfternoon => 'Good afternoon';

  @override
  String get dashboardGoodEvening => 'Good evening';

  @override
  String get dashboardOverdueFollowUps => 'Overdue follow-ups';

  @override
  String get dashboardUpcomingFollowUps => 'Upcoming follow-ups';

  @override
  String get dashboardAvailableProperties => 'Available properties';

  @override
  String get dashboardVisualAnalytics => 'Workspace analytics';

  @override
  String get dashboardLeadStatusDistribution => 'Lead status distribution';

  @override
  String get dashboardTasksDueBreakdown => 'Tasks due breakdown';

  @override
  String get dashboardPropertyStatusDistribution =>
      'Property status distribution';

  @override
  String get dashboardTodaysFollowUps => 'Today’s follow-ups';

  @override
  String get dashboardOverdueTasks => 'Overdue tasks';

  @override
  String get dashboardAppointmentsTitle => 'Appointment control';

  @override
  String get nextAppointment => 'Next appointment';

  @override
  String get noUpcomingAppointments => 'No upcoming appointments';

  @override
  String get dashboardUnassignedLeads => 'Unassigned leads';

  @override
  String get dashboardRecentlyUpdatedLeads => 'Recently updated leads';

  @override
  String get dashboardQuickActions => 'Quick actions';

  @override
  String get dashboardActive => 'Active';

  @override
  String get dashboardInactive => 'Inactive';

  @override
  String get dashboardReservedOrClosed => 'Reserved or closed';

  @override
  String get dashboardGeneralTask => 'General task';

  @override
  String get clientsSubtitle =>
      'Keep client profiles, preferences, and assignments ready for follow-up.';

  @override
  String get searchClients => 'Search clients';

  @override
  String get searchTasks => 'Search tasks';

  @override
  String get createDeal => 'Create deal';

  @override
  String get editDeal => 'Edit deal';

  @override
  String get updateDeal => 'Update deal';

  @override
  String get dealDetails => 'Deal details';

  @override
  String get dealsSubtitle =>
      'Track client opportunities, property value, commission, and closing progress.';

  @override
  String get dealInformation => 'Deal information';

  @override
  String get dealValueAndStage => 'Value and stage';

  @override
  String get dealSummary => 'Deal summary';

  @override
  String get noDeals => 'No deals yet.';

  @override
  String get noDealsAvailable => 'No deals available.';

  @override
  String get noDealsMatchFilters => 'No deals match the current filters.';

  @override
  String get searchDeals => 'Search deals';

  @override
  String get dealStage => 'Deal stage';

  @override
  String get newDealStage => 'New';

  @override
  String get qualified => 'Qualified';

  @override
  String get proposal => 'Proposal';

  @override
  String get expectedValue => 'Expected value';

  @override
  String get commission => 'Commission';

  @override
  String get closingDate => 'Closing date';

  @override
  String get lostReason => 'Lost reason';

  @override
  String get assignedAgent => 'Assigned agent';

  @override
  String get updateStage => 'Update stage';

  @override
  String get archiveDeal => 'Archive deal';

  @override
  String get archiveDealConfirmation =>
      'This deal will be archived and hidden from active deal lists.';

  @override
  String get dealCreatedSuccessfully => 'Deal created successfully.';

  @override
  String get dealUpdatedSuccessfully => 'Deal updated successfully.';

  @override
  String get dealArchivedSuccessfully => 'Deal archived successfully.';

  @override
  String get dealStageUpdatedSuccessfully => 'Deal stage updated successfully.';

  @override
  String get unableToSaveDeal => 'Unable to save deal. Please try again.';

  @override
  String get lostReasonRequired => 'Lost reason is required.';

  @override
  String get selectClient => 'Select client';

  @override
  String get selectLead => 'Select lead';

  @override
  String get selectProperty => 'Select property';

  @override
  String get selectAssignedAgent => 'Select assigned agent';

  @override
  String get allClosingDates => 'All closing dates';

  @override
  String get pastClosing => 'Past closing';

  @override
  String get thisWeek => 'This week';

  @override
  String get thisMonth => 'This month';

  @override
  String get backToDeals => 'Back to deals';

  @override
  String get dealNotFoundMessage =>
      'Deal not found. Open it from the deals list.';

  @override
  String get reportsComingSoon => 'Reports are coming soon.';

  @override
  String get myProfile => 'My profile';

  @override
  String get profileInformation => 'Profile information';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get uploadProfileImage => 'Upload profile image';

  @override
  String get removeProfileImage => 'Remove profile image';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully.';

  @override
  String get unableToPickProfileImage =>
      'Unable to select profile image. Please try again.';

  @override
  String get fullNameRequired => 'Full name is required.';

  @override
  String get role => 'Role';

  @override
  String get accountStatus => 'Account status';

  @override
  String get active => 'Active';

  @override
  String get fullName => 'Full name';

  @override
  String get edit => 'Edit';

  @override
  String get preferences => 'Preferences';

  @override
  String get appearance => 'Appearance';

  @override
  String get account => 'Account';

  @override
  String get aboutApp => 'About app';

  @override
  String get admin => 'Admin';

  @override
  String get manager => 'Manager';

  @override
  String get salesAgent => 'Sales agent';

  @override
  String get marketing => 'Marketing';

  @override
  String get viewer => 'Viewer';

  @override
  String get platformDashboard => 'Platform dashboard';

  @override
  String get platformDashboardSubtitle =>
      'Manage company access, health, settings, and users across the Masar platform.';

  @override
  String get platformAdmin => 'Platform admin';

  @override
  String get platformOverview => 'Overview';

  @override
  String get platformCompanies => 'Companies';

  @override
  String get totalCompanies => 'Total companies';

  @override
  String get activeCompanies => 'Active companies';

  @override
  String get inactiveCompanies => 'Inactive companies';

  @override
  String get trialCompanies => 'Trial companies';

  @override
  String get recentlyCreatedCompanies => 'Recently created';

  @override
  String get searchCompanies => 'Search companies';

  @override
  String get allCompanies => 'All companies';

  @override
  String get noCompaniesFound => 'No companies found';

  @override
  String get noCompaniesFoundMessage => 'Adjust the search or status filter.';

  @override
  String get createCompany => 'Create company';

  @override
  String get createCompanySuccess => 'Company created successfully.';

  @override
  String get addUserSuccess => 'User added successfully.';

  @override
  String get companyName => 'Company name';

  @override
  String get companyDisplayName => 'Display name';

  @override
  String get companyIdSlug => 'Company ID';

  @override
  String get firstAdminFullName => 'First admin full name';

  @override
  String get firstAdminEmail => 'First admin email';

  @override
  String get firstAdminPhone => 'First admin phone';

  @override
  String get temporaryPassword => 'Temporary password';

  @override
  String get defaultLocale => 'Default locale';

  @override
  String get timezone => 'Timezone';

  @override
  String get companyDetails => 'Company details';

  @override
  String get companySettings => 'Company settings';

  @override
  String get dataHealth => 'Data health';

  @override
  String get runDataHealthCheck => 'Run data health check';

  @override
  String get dataHealthNotRun => 'No data health report yet';

  @override
  String get dataHealthNotRunMessage =>
      'Run a company-scoped check to find missing assignment snapshots and invalid assignees.';

  @override
  String get dataHealthClean => 'No assignment issues found';

  @override
  String get dataHealthCleanMessage =>
      'The scanned records are consistent with the current assignee policy.';

  @override
  String get dataHealthAffectedRecords => 'Affected records';

  @override
  String get missingSnapshots => 'Missing snapshots';

  @override
  String get invalidAssignees => 'Invalid assignees';

  @override
  String get inactiveAssignees => 'Inactive assignees';

  @override
  String get staleTeamSnapshots => 'Stale team snapshots';

  @override
  String get missingAssignee => 'Missing assignee';

  @override
  String get safeBackfillAvailable => 'Safe backfill';

  @override
  String get manualReview => 'Manual review';

  @override
  String get editCompanySettings => 'Edit company settings';

  @override
  String get saveSettings => 'Save settings';

  @override
  String get settingsSaved => 'Settings saved successfully.';

  @override
  String get companyLimits => 'Company limits';

  @override
  String get companyFeatures => 'Company features';

  @override
  String get featureEnabled => 'Enabled';

  @override
  String get featureDisabled => 'Disabled';

  @override
  String get enableFeature => 'Enable feature';

  @override
  String get disableFeature => 'Disable feature';

  @override
  String get locale => 'Locale';

  @override
  String get userLimit => 'User limit';

  @override
  String get usersUsed => 'Users used';

  @override
  String get userLimitReached =>
      'User limit reached. Increase the limit before adding more users.';

  @override
  String get storageLimitMb => 'Storage limit (MB)';

  @override
  String get trial => 'Trial';

  @override
  String get auditLogs => 'Activity history';

  @override
  String get previewDashboard => 'Preview dashboard';

  @override
  String get readOnlyPreview => 'Read-only preview';

  @override
  String get companyDashboardPreview => 'Company dashboard preview';

  @override
  String get platformAccessDenied => 'Platform access denied.';

  @override
  String get companyUsers => 'Company users';

  @override
  String get addUser => 'Add user';

  @override
  String get platformSupportAddUser => 'Support add user';

  @override
  String get platformCurrentCompany => 'Current company';

  @override
  String get platformDashboardHeroSubtitle =>
      'Complete overview of platform performance, companies, and users.';

  @override
  String get platformSearchHint => 'Search platform...';

  @override
  String get platformCompanySelector => 'Company selector';

  @override
  String get platformSelectedCompany => 'Selected company';

  @override
  String get platformCompanyFeatures => 'Enabled features';

  @override
  String get platformStorageUsage => 'Storage usage';

  @override
  String get platformRecentActivity => 'Recent activity';

  @override
  String get platformWorkspaceSummary => 'Workspace summary';

  @override
  String get platformViewAllLogs => 'View all logs';

  @override
  String get platformViewAllCompanies => 'View all companies';

  @override
  String get platformNoRecentActivity => 'No recent activity yet';

  @override
  String get platformTotalUsers => 'Total users';

  @override
  String get platformAdminsManagers => 'Admins / Managers';

  @override
  String get platformActiveUsers => 'Active users';

  @override
  String platformOwnerGreeting(Object name) {
    return 'Good evening, $name';
  }

  @override
  String get activateCompany => 'Activate company';

  @override
  String get deactivateCompany => 'Deactivate company';

  @override
  String get activateUser => 'Activate user';

  @override
  String get deactivateUser => 'Deactivate user';

  @override
  String get noCompanies => 'No companies yet';

  @override
  String get noCompaniesMessage =>
      'Create the first trial company when the platform seed is ready.';

  @override
  String get noCompanySelected => 'No company selected';

  @override
  String get noCompanySelectedMessage =>
      'Select a company to view users and metadata.';

  @override
  String get noCompanyUsers => 'No company users yet';

  @override
  String get noCompanyUsersMessage =>
      'Add the first users through the secure Cloud Function.';

  @override
  String get connectionTimeout =>
      'Unable to load data. Check your connection and try again.';

  @override
  String get unableToLoadReports => 'Unable to load reports. Please try again.';

  @override
  String get reportsOverview =>
      'Review CRM performance using real leads, deals, tasks, and properties for the selected period.';

  @override
  String get reportPeriod => 'Report period';

  @override
  String get selectedPeriod => 'Selected period';

  @override
  String get allTime => 'All time';

  @override
  String get today => 'Today';

  @override
  String get totalDeals => 'Total deals';

  @override
  String get lostDeals => 'Lost deals';

  @override
  String get expectedValueTotal => 'Expected value total';

  @override
  String get commissionTotal => 'Commission total';

  @override
  String get dealsByStage => 'Deals by stage';

  @override
  String get dealPipeline => 'Deal pipeline';

  @override
  String get pipelineValue => 'Pipeline value';

  @override
  String get recentDeals => 'Recent deals';

  @override
  String get dueTodayTasks => 'Due today tasks';

  @override
  String get upcomingTasks => 'Upcoming tasks';

  @override
  String get completedTasks => 'Completed tasks';

  @override
  String get cancelledTasks => 'Cancelled tasks';

  @override
  String get completionRate => 'Completion rate';

  @override
  String get overdueRate => 'Overdue rate';

  @override
  String get leadsReport => 'Leads performance';

  @override
  String get dealsReport => 'Deals performance';

  @override
  String get tasksReport => 'Tasks and follow-ups';

  @override
  String get propertiesReport => 'Properties report';

  @override
  String get teamReport => 'Agent report';

  @override
  String get leadsByStatus => 'Leads by status';

  @override
  String get leadsBySource => 'Leads by source';

  @override
  String get leadsByPriority => 'Leads by priority';

  @override
  String get propertiesByStatus => 'Properties by status';

  @override
  String get propertiesByType => 'Properties by type';

  @override
  String get taskStatusDistribution => 'Task status distribution';

  @override
  String get agentPerformance => 'Agent performance';

  @override
  String get highestPriorityTasks => 'Highest priority tasks';

  @override
  String get inventoryValue => 'Inventory value';

  @override
  String get totalListedValue => 'Total listed value';

  @override
  String get averagePrice => 'Average price';

  @override
  String get wonValue => 'Won value';

  @override
  String get lostValue => 'Lost value';

  @override
  String get noReportData => 'No report data for the selected filters.';

  @override
  String get addDeal => 'Add deal';

  @override
  String get appVersion => 'App version';

  @override
  String get version => 'Version';

  @override
  String get featureUnavailable => 'Feature unavailable';

  @override
  String get featureUnavailableMessage =>
      'This feature is disabled for this company. Contact the platform owner to enable it.';

  @override
  String get moduleDisabled => 'Module disabled';

  @override
  String authRetryCountdown(int seconds) {
    return 'Try again in $seconds seconds.';
  }

  @override
  String get passwordResetEmailSent =>
      'Password reset email sent. Check your inbox.';

  @override
  String get passwordResetEmailFailed =>
      'Unable to send password reset email. Please try again.';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get changeEmail => 'Change email';

  @override
  String get changePassword => 'Change password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordChangedSuccessfully => 'Password changed successfully.';

  @override
  String get passwordChangeFailed =>
      'Password change failed. Please try again.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get currentPasswordRequired => 'Current password is required.';

  @override
  String get currentPasswordIncorrect => 'Current password is incorrect.';

  @override
  String get recentLoginRequired =>
      'Please sign in again before changing your password.';

  @override
  String get newPasswordRequired => 'New password is required.';

  @override
  String get newPasswordTooShort =>
      'New password must be at least 8 characters.';

  @override
  String get generateResetLink => 'Generate reset link';

  @override
  String get resetLinkGenerated => 'Reset link generated.';

  @override
  String get copyResetLink => 'Copy reset link';

  @override
  String get resetLinkCopied => 'Reset link copied.';

  @override
  String get sendThisLinkManuallyToTheUser =>
      'Send this link manually to the user.';

  @override
  String get platformEmailChanged => 'User email updated.';

  @override
  String get platformPasswordChanged => 'Platform password changed.';

  @override
  String get notAllowedToChangePassword =>
      'You are not allowed to change this password.';

  @override
  String get lastLogin => 'Last login';

  @override
  String get lastLoginDetails => 'Last login details';

  @override
  String get ipAddress => 'IP address';

  @override
  String get device => 'Device';

  @override
  String get browser => 'Browser';

  @override
  String get platform => 'Platform';

  @override
  String get loginActivity => 'Login activity';

  @override
  String get recentLoginActivity => 'Recent login activity';

  @override
  String get noLoginActivityYet => 'No login activity yet.';

  @override
  String get security => 'Security';

  @override
  String get userSecurity => 'User security';

  @override
  String get teamManagement => 'Team Management';

  @override
  String get teamManagementSubtitle =>
      'Create manager-owned teams and keep sales and marketing users organized by company.';

  @override
  String get teams => 'Teams';

  @override
  String get myTeam => 'My Team';

  @override
  String get myTeamSubtitle =>
      'View your assigned team and active team members.';

  @override
  String get createTeam => 'Create Team';

  @override
  String get editTeam => 'Edit Team';

  @override
  String get teamDetails => 'Team Details';

  @override
  String get teamName => 'Team Name';

  @override
  String get teamDescription => 'Team Description';

  @override
  String get teamManager => 'Team Manager';

  @override
  String get teamMembers => 'Team Members';

  @override
  String get teamMembersShort => 'Team members';

  @override
  String get addMembers => 'Add Members';

  @override
  String get manageMembers => 'Manage members';

  @override
  String get removeMember => 'Remove Member';

  @override
  String get moveToTeam => 'Move to Team';

  @override
  String get unassignedUsers => 'Unassigned Users';

  @override
  String get usersWithoutTeam => 'Users Without Team';

  @override
  String get activeTeams => 'Active Teams';

  @override
  String get inactiveTeams => 'Inactive Teams';

  @override
  String get members => 'Members';

  @override
  String teamMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
      zero: 'No members',
    );
    return '$_temp0';
  }

  @override
  String get managersWithTeams => 'Managers with teams';

  @override
  String get noTeamsYet => 'No teams yet';

  @override
  String get noTeamsYetMessage =>
      'Create the first team and assign an active manager.';

  @override
  String get noTeamMembersYet => 'No team members yet';

  @override
  String get noTeamMembersYetMessage =>
      'Add sales or marketing users to this team.';

  @override
  String get noTeamAssigned => 'No team assigned';

  @override
  String get noTeamAssignedMessage =>
      'Ask an admin to assign you as a team manager.';

  @override
  String get assignManager => 'Assign Manager';

  @override
  String get changeManager => 'Change Manager';

  @override
  String get deactivateTeam => 'Deactivate Team';

  @override
  String get activateTeam => 'Activate Team';

  @override
  String get teamSavedSuccessfully => 'Team saved successfully.';

  @override
  String get teamUpdateFailed => 'Team update failed.';

  @override
  String get teamPermissionDenied =>
      'You do not have permission to manage team members.';

  @override
  String get teamSessionExpired =>
      'Your session expired. Sign in again and retry.';

  @override
  String get teamUserInactive =>
      'This user is inactive. Activate the user before assigning them.';

  @override
  String get teamInactive => 'This team is inactive. Activate the team first.';

  @override
  String get teamMemberIneligible =>
      'Only Sales Agent and Marketing users can be team members.';

  @override
  String get teamManagerUnavailable =>
      'Team manager must be an active Manager user.';

  @override
  String get teamManagerAlreadyHasTeam =>
      'This manager already owns an active team.';

  @override
  String get teamUserNotFound =>
      'The selected user no longer exists. Refresh and try again.';

  @override
  String get teamNotFound =>
      'The selected team no longer exists. Refresh and try again.';

  @override
  String get teamCompanyInactive => 'The selected company is inactive.';

  @override
  String get teamCompanyMismatch =>
      'User and team must belong to the same company.';

  @override
  String get teamConnectionInterrupted =>
      'The connection was interrupted. Check your internet and try again.';

  @override
  String get teamRecordChanged => 'Team data changed. Refresh and try again.';

  @override
  String get teamInvalidInput =>
      'Check the selected team and user, then try again.';

  @override
  String get userAddedToTeam => 'User added to team.';

  @override
  String get userRemovedFromTeam => 'User removed from team.';

  @override
  String get searchTeams => 'Search teams';

  @override
  String get noManagersAvailable => 'No managers available';

  @override
  String get noManagersAvailableMessage =>
      'Add an active Manager user before creating a team.';

  @override
  String get noUnassignedUsers => 'No eligible users';

  @override
  String get noUnassignedUsersMessage =>
      'Sales and marketing users are already assigned or unavailable.';

  @override
  String get backfillSnapshots => 'Backfill snapshots';

  @override
  String get dataHealthRepairSuccess => 'Snapshots repaired successfully.';

  @override
  String get companyDataHealthMessage =>
      'Company admin tools for fixing invalid assignment ownership and stale team snapshots.';

  @override
  String get reassignRecord => 'Reassign record';

  @override
  String get notifyManager => 'Notify manager';

  @override
  String get noManagerForDataHealthIssue =>
      'No responsible manager is available for this issue.';

  @override
  String get managerNotificationSent => 'Manager notified successfully.';

  @override
  String get notificationsComingSoon => 'Notifications are not available yet.';

  @override
  String get noEligibleAssignees => 'No eligible assignees';

  @override
  String get noEligibleAssigneesMessage =>
      'There are no active eligible users for this record type.';

  @override
  String get dataHealthReassignSuccess => 'Record reassigned successfully.';

  @override
  String get companyAdminActionRequired => 'Company admin action required.';

  @override
  String get notificationCenter => 'Notification center';

  @override
  String notificationCenterSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread notifications',
      one: '1 unread notification',
      zero: 'No unread notifications',
    );
    return '$_temp0';
  }

  @override
  String get all => 'All';

  @override
  String get unread => 'Unread';

  @override
  String get attention => 'Attention';

  @override
  String get system => 'System';

  @override
  String get open => 'Open';

  @override
  String get viewAll => 'View all';

  @override
  String get markRead => 'Mark read';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get attentionNeeded => 'Attention needed';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get noNotificationsYetMessage =>
      'Important assignment updates and system alerts will appear here.';

  @override
  String get notificationDataRepairNeededTitle =>
      'Notification data repair needed';

  @override
  String get notificationDataRepairNeededMessage =>
      'Some notifications need data repair. New notifications will appear after the next activity.';

  @override
  String get notificationStreamError =>
      'Unable to load notifications. Please try again.';

  @override
  String get noUrgentReminders => 'No urgent reminders';

  @override
  String get noUrgentRemindersMessage =>
      'Due and overdue work will appear here when it needs attention.';

  @override
  String get notificationLeadAssignedTitle => 'New lead assigned to you';

  @override
  String get notificationLeadReassignedTitle => 'Lead reassigned to you';

  @override
  String get notificationLeadRemovedFromYouTitle =>
      'Lead removed from your pipeline';

  @override
  String get notificationTaskAssignedTitle => 'New task assigned';

  @override
  String get notificationTaskReassignedTitle => 'Task reassigned to you';

  @override
  String get notificationTaskRemovedFromYouTitle =>
      'Task removed from your work';

  @override
  String get notificationClientAssignedTitle => 'New client assigned to you';

  @override
  String get notificationClientReassignedTitle => 'Client reassigned to you';

  @override
  String get notificationClientRemovedFromYouTitle =>
      'Client removed from your pipeline';

  @override
  String get notificationDealAssignedTitle => 'New deal assigned to you';

  @override
  String get notificationDealReassignedTitle => 'Deal reassigned to you';

  @override
  String get notificationDealRemovedFromYouTitle =>
      'Deal removed from your pipeline';

  @override
  String get notificationLeadImportantStatusChangedTitle =>
      'Important lead status changed';

  @override
  String get notificationDealStageChangedTitle => 'Deal stage changed';

  @override
  String get notificationDealImportantStatusChangedTitle =>
      'Important deal status changed';

  @override
  String get notificationDealWonTitle => 'Deal won';

  @override
  String get notificationDealLostTitle => 'Deal lost';

  @override
  String get notificationTaskStatusChangedTitle => 'Task status changed';

  @override
  String get notificationTeamMemberAssignedTitle => 'Team assignment';

  @override
  String get notificationTeamMemberReassignedTitle => 'Team reassignment';

  @override
  String get notificationTeamMemberRemovedTitle => 'Team assignment removed';

  @override
  String get notificationTeamLeadStatusChangedTitle =>
      'Team lead status changed';

  @override
  String get notificationTeamDealStageChangedTitle => 'Team deal stage changed';

  @override
  String get notificationTeamTaskStatusChangedTitle =>
      'Team task status changed';

  @override
  String get notificationGenericStatusChangedTitle => 'Status changed';

  @override
  String get notificationFollowUpDueTodayTitle => 'Follow-up due today';

  @override
  String get notificationFollowUpOverdueTitle => 'Follow-up overdue';

  @override
  String get notificationTaskDueTodayTitle => 'Task due today';

  @override
  String get notificationTaskOverdueTitle => 'Task overdue';

  @override
  String get notificationSystemInfoTitle => 'System notification';

  @override
  String get notificationDataHealthIssueTitle => 'Data health needs attention';

  @override
  String notificationDataHealthIssueBody(Object record, Object issue) {
    return '$record needs review: $issue.';
  }

  @override
  String get notificationGenericTitle => 'CRM notification';

  @override
  String get notificationUnassignedLeadTitle =>
      'Unassigned lead needs attention';

  @override
  String get notificationRecordFallback => 'Record';

  @override
  String get notificationSystemModule => 'System';

  @override
  String notificationRecordBody(Object record) {
    return '$record needs your attention.';
  }

  @override
  String notificationRecordByActorBody(Object record, Object actor) {
    return '$record was updated by $actor.';
  }

  @override
  String notificationRecordNoLongerAssignedBody(Object record) {
    return '$record is no longer assigned to you.';
  }

  @override
  String notificationGenericBody(Object record) {
    return 'Open $record to review the latest update.';
  }

  @override
  String notificationReminderAssignedBody(Object record, Object assignee) {
    return '$record is assigned to $assignee.';
  }

  @override
  String notificationUnassignedLeadBody(Object record) {
    return '$record is still unassigned.';
  }

  @override
  String notificationStatusChangedBody(Object record, Object status) {
    return '$record changed to $status.';
  }

  @override
  String notificationStatusChangedByActorBody(
    Object record,
    Object status,
    Object actor,
  ) {
    return '$record changed to $status by $actor.';
  }

  @override
  String notificationTeamMemberAssignedBody(Object record, Object member) {
    return '$member was assigned to $record.';
  }

  @override
  String notificationTeamMemberAssignedByActorBody(
    Object record,
    Object member,
    Object actor,
  ) {
    return '$actor assigned $member to $record.';
  }

  @override
  String notificationTeamMemberReassignedBody(
    Object record,
    Object oldMember,
    Object newMember,
  ) {
    return '$record moved from $oldMember to $newMember.';
  }

  @override
  String notificationTeamMemberReassignedByActorBody(
    Object record,
    Object oldMember,
    Object newMember,
    Object actor,
  ) {
    return '$actor moved $record from $oldMember to $newMember.';
  }

  @override
  String notificationTeamMemberRemovedBody(Object record, Object member) {
    return '$member was removed from $record.';
  }

  @override
  String notificationTeamMemberRemovedByActorBody(
    Object record,
    Object member,
    Object actor,
  ) {
    return '$actor removed $member from $record.';
  }

  @override
  String get notificationRouteUnavailable =>
      'This notification cannot be opened from your current access.';

  @override
  String get notificationsUnavailableInPlatform =>
      'Tenant sales notifications are not available in platform mode.';

  @override
  String get appointments => 'Appointments';

  @override
  String get appointmentsSubtitle =>
      'Plan viewings, meetings, calls, and deal follow-ups in one controlled schedule.';

  @override
  String get newAppointment => 'New appointment';

  @override
  String get editAppointment => 'Edit appointment';

  @override
  String get appointmentDetails => 'Appointment details';

  @override
  String get appointmentTitle => 'Appointment title';

  @override
  String get appointmentType => 'Appointment type';

  @override
  String get appointmentSchedule => 'Schedule';

  @override
  String get appointmentNotes => 'Notes and outcome';

  @override
  String get outcomeNotes => 'Outcome notes';

  @override
  String get appointmentTime => 'Time';

  @override
  String get duration => 'Duration';

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get selectAppointmentDate => 'Select date';

  @override
  String get selectStartTime => 'Select start time';

  @override
  String get saveAppointment => 'Save appointment';

  @override
  String get updateAppointment => 'Update appointment';

  @override
  String get appointmentDateRequired =>
      'Select appointment date and start time.';

  @override
  String get appointmentDurationRequired =>
      'Appointment duration must be greater than zero.';

  @override
  String get appointmentAssigneeRequired =>
      'Select an assigned user before saving.';

  @override
  String get appointmentEndAfterStartRequired =>
      'Appointment end time must be after start time.';

  @override
  String get appointmentSaved => 'Appointment saved.';

  @override
  String get appointmentUpdated => 'Appointment updated.';

  @override
  String get appointmentCancelled => 'Appointment cancelled.';

  @override
  String get appointmentCompleted => 'Appointment completed.';

  @override
  String get appointmentMissed => 'Appointment marked missed.';

  @override
  String get appointmentRescheduled => 'Appointment rescheduled.';

  @override
  String get appointmentNotFound => 'Appointment was not found.';

  @override
  String get appointmentAttention => 'Appointment attention';

  @override
  String get todaysAppointments => 'Today';

  @override
  String get upcomingAppointments => 'Upcoming';

  @override
  String get missedAppointments => 'Missed';

  @override
  String get completedAppointments => 'Completed';

  @override
  String get cancelledAppointments => 'Cancelled appointments';

  @override
  String get rescheduledAppointments => 'Rescheduled appointments';

  @override
  String get searchAppointments => 'Search appointments';

  @override
  String get filterByDate => 'Filter by date';

  @override
  String get filterByStatus => 'Filter by status';

  @override
  String get filterByType => 'Filter by type';

  @override
  String get allAppointments => 'All appointments';

  @override
  String get allAppointmentTypes => 'All types';

  @override
  String get noAppointmentsYet => 'No appointments yet';

  @override
  String get createFirstAppointment => 'Create the first appointment';

  @override
  String get noAppointmentsMatchFilters => 'No appointments match filters';

  @override
  String get completeAppointment => 'Complete appointment';

  @override
  String get cancelAppointment => 'Cancel appointment';

  @override
  String get markMissed => 'Mark missed';

  @override
  String get reschedule => 'Reschedule';

  @override
  String get cancelAppointmentConfirmation =>
      'Cancel this appointment? The record will stay in history.';

  @override
  String get markMissedConfirmation => 'Mark this appointment as missed?';

  @override
  String get appointmentTypeCall => 'Call';

  @override
  String get appointmentTypeMeeting => 'Meeting';

  @override
  String get appointmentTypePropertyViewing => 'Property viewing';

  @override
  String get appointmentTypeSiteVisit => 'Site visit';

  @override
  String get appointmentTypeContractMeeting => 'Contract meeting';

  @override
  String get appointmentTypeReservationMeeting => 'Reservation meeting';

  @override
  String get appointmentTypeFollowUp => 'Follow-up';

  @override
  String get appointmentTypeOther => 'Other';

  @override
  String get appointmentStatusScheduled => 'Scheduled';

  @override
  String get appointmentStatusCompleted => 'Completed';

  @override
  String get appointmentStatusCancelled => 'Cancelled';

  @override
  String get appointmentStatusMissed => 'Missed';

  @override
  String get appointmentStatusRescheduled => 'Rescheduled';

  @override
  String get notificationAppointmentAssignedTitle => 'New appointment assigned';

  @override
  String get notificationAppointmentReassignedTitle =>
      'Appointment reassigned to you';

  @override
  String get notificationAppointmentRemovedFromYouTitle =>
      'Appointment removed from your schedule';

  @override
  String get notificationAppointmentRescheduledTitle =>
      'Appointment rescheduled';

  @override
  String get notificationAppointmentCancelledTitle => 'Appointment cancelled';

  @override
  String get notificationAppointmentCompletedTitle => 'Appointment completed';

  @override
  String get notificationAppointmentMissedTitle => 'Appointment missed';

  @override
  String get notificationAppointmentTodayAttentionTitle => 'Appointment today';

  @override
  String get notificationAppointmentDueNowTitle => 'Appointment due now';

  @override
  String get notificationAppointmentMissedAttentionTitle =>
      'Missed appointment';

  @override
  String get notificationAppointmentUpcomingSoonTitle =>
      'Appointment coming up';

  @override
  String get notificationTeamAppointmentAssignedTitle =>
      'Team appointment assigned';

  @override
  String get notificationTeamAppointmentReassignedTitle =>
      'Team appointment reassigned';

  @override
  String get notificationTeamAppointmentRescheduledTitle =>
      'Team appointment rescheduled';

  @override
  String get notificationTeamAppointmentCancelledTitle =>
      'Team appointment cancelled';

  @override
  String get notificationTeamAppointmentCompletedTitle =>
      'Team appointment completed';

  @override
  String get notificationTeamAppointmentMissedTitle =>
      'Team appointment missed';

  @override
  String get invitations => 'Invitations';

  @override
  String get createInvitation => 'Create invitation';

  @override
  String get invitationCode => 'Invitation code';

  @override
  String get invitationLink => 'Invitation link';

  @override
  String get copyCode => 'Copy code';

  @override
  String get copyLink => 'Copy link';

  @override
  String get revokeInvitation => 'Revoke invitation';

  @override
  String get invitationActive => 'Invitation active';

  @override
  String get invitationUsed => 'Invitation used';

  @override
  String get invitationExpired => 'Invitation expired';

  @override
  String get invitationRevoked => 'Invitation revoked';

  @override
  String get expiresAt => 'Expires at';

  @override
  String get plan => 'Plan';

  @override
  String get planId => 'Plan ID';

  @override
  String get features => 'Features';

  @override
  String get allowedAdminEmail => 'Allowed admin email';

  @override
  String get manualSupportSetup => 'Manual support setup';

  @override
  String get invitationOnboarding => 'Invitation onboarding';

  @override
  String get companyAdminInvitation => 'Company admin invitation';

  @override
  String get invitationOnboardingNote =>
      'Invitation onboarding lets a company admin register their own company workspace. Manual setup remains available for support cases.';

  @override
  String get noInvitationsYet => 'No invitations yet';

  @override
  String get noInvitationsYetMessage =>
      'Create an invitation code for the next subscribing company admin.';

  @override
  String get invitationCreated =>
      'Invitation created. Copy the code or link now; the full code is shown only once.';

  @override
  String get invitationCodeCopied => 'Invitation code copied.';

  @override
  String get invitationLinkCopied => 'Invitation link copied.';

  @override
  String get expiresInDays => 'Expires in days';

  @override
  String get registerYourCompany => 'Register your company';

  @override
  String get enterInvitationCode => 'Enter invitation code';

  @override
  String get validateInvitation => 'Validate invitation';

  @override
  String get invitationValid => 'Invitation valid';

  @override
  String get invitationInvalid => 'Invitation invalid';

  @override
  String get adminAccount => 'Admin account';

  @override
  String get reviewAndCreate => 'Review and create';

  @override
  String get createWorkspace => 'Create workspace';

  @override
  String get companyEmail => 'Company email';

  @override
  String get companyPhone => 'Company phone';

  @override
  String get cityLocation => 'City/location';

  @override
  String get preferredLanguage => 'Preferred language';

  @override
  String get adminFullName => 'Admin full name';

  @override
  String get adminEmail => 'Admin email';

  @override
  String get adminPhone => 'Admin phone';

  @override
  String get companyRegistrationCompleted => 'Company registration completed.';

  @override
  String get invitationAlreadyUsed => 'Invitation already used';

  @override
  String get companyIdAlreadyExists => 'Company ID already exists';

  @override
  String get companyIdInvalid =>
      'Company ID must use lowercase letters, numbers, hyphens, or underscores.';

  @override
  String get next => 'Next';

  @override
  String get onboardingTitle =>
      'From lead to deal, run your real estate sales workspace in one place.';

  @override
  String get onboardingSubtitle =>
      'Masar connects teams, leads, properties, appointments, notifications, and reports in a secure company workspace.';

  @override
  String get onboardingOperationsTitle => 'Operational CRM workspace';

  @override
  String get onboardingOperationsMessage =>
      'Manage leads, clients, properties, tasks, deals, and appointments with role-scoped access.';

  @override
  String get onboardingInvitationTitle => 'Invitation-based company setup';

  @override
  String get onboardingInvitationMessage =>
      'Use your invitation code to create the company workspace and start as the first company admin.';

  @override
  String get onboardingAnalyticsTitle => 'Live dashboards and reports';

  @override
  String get onboardingAnalyticsMessage =>
      'Track team performance, due work, appointments, and sales activity from polished dashboards.';

  @override
  String get signInExistingAccount => 'Sign in to existing account';

  @override
  String get createAdminWorkspace => 'Create company workspace';

  @override
  String get companyIdGeneratedAutomatically =>
      'Company ID is generated automatically';

  @override
  String get companyIdGeneratedMessage =>
      'It will be generated from the company name.';

  @override
  String get invalidPhone => 'Enter a valid phone number.';

  @override
  String get invalidUrl =>
      'Enter a valid website URL starting with http:// or https://.';

  @override
  String get invalidName => 'Enter a valid name.';

  @override
  String get userManagement => 'User Management';

  @override
  String get userManagementSubtitle =>
      'Create managers, sales agents, marketing users, and viewers for this company.';

  @override
  String get createUser => 'Create user';

  @override
  String get searchUsers => 'Search users';

  @override
  String get companyUsersEmptyMessage =>
      'Create the first company user or manager from this page.';

  @override
  String get userCreatedResetLinkTitle => 'User created';

  @override
  String get userCreatedSuccessfully => 'User created successfully';

  @override
  String get sendSetupLinkToUser =>
      'Send this setup link to the user so they can set their password.';

  @override
  String get copySetupLink => 'Copy setup link';

  @override
  String get openSetupLink => 'Open setup link';

  @override
  String get linkCopied => 'Link copied.';

  @override
  String get generateSetupLink => 'Generate setup link';

  @override
  String get done => 'Done';

  @override
  String get userCreatedNoResetLinkMessage =>
      'The user was created, but no password reset link was returned.';

  @override
  String get companyUserAlreadyExists =>
      'This user already belongs to the company.';

  @override
  String get registrationInvitationInvalid =>
      'This invitation is no longer valid.';

  @override
  String get registrationInvitationExpired => 'This invitation has expired.';

  @override
  String get registrationInvitationUsed =>
      'This invitation has already been used.';

  @override
  String get registrationInvitationRevoked =>
      'This invitation has been revoked.';

  @override
  String get registrationInvitationLimitReached =>
      'This invitation has reached its usage limit.';

  @override
  String get adminEmailAlreadyExists => 'This admin email is already used.';

  @override
  String get companyNameAlreadyRegistered =>
      'This company name is already registered. Try another name.';

  @override
  String get weakPassword => 'The password is too weak.';

  @override
  String get emailPasswordAuthDisabled =>
      'Email and password sign-in is not enabled. Contact the platform owner.';

  @override
  String get unableToCreateAdminUser =>
      'Unable to create the admin user. Please check the data and try again.';

  @override
  String get unableToCreateWorkspace =>
      'Unable to create the workspace. Please check the data and try again.';

  @override
  String get unableToCompleteRegistration =>
      'Unable to complete registration. Please try again later.';

  @override
  String get registrationConflict =>
      'Registration is already in progress or the workspace was just created. Please try again.';

  @override
  String get createYourAdminPassword => 'Create your admin password';

  @override
  String get adminPasswordHelp =>
      'This password will be used to log in as company admin.';

  @override
  String get companyAdminPassword => 'Company admin password';

  @override
  String get confirmCompanyAdminPassword => 'Confirm company admin password';

  @override
  String get notificationsDisabledForCompany =>
      'Notifications are disabled for this company.';

  @override
  String get featureNotEnabledForWorkspace =>
      'This feature is not enabled for your workspace.';

  @override
  String get errorOccurred => 'Something went wrong';

  @override
  String get skip => 'Skip';

  @override
  String get setTemporaryPassword => 'Set temporary password';

  @override
  String get confirmTemporaryPassword => 'Confirm temporary password';

  @override
  String get temporaryPasswordHelp =>
      'Optional. The user can sign in with this temporary password and should change it from Settings after first login.';

  @override
  String get temporaryPasswordCreatedMessage =>
      'The user was created with a temporary password. Share the temporary password securely and ask the user to change it after first login.';

  @override
  String get mustChangePassword => 'Must change password';

  @override
  String get temporaryPasswordChangeRequiredTitle => 'Create a new password';

  @override
  String get temporaryPasswordChangeRequiredMessage =>
      'You are using a temporary password. Please create a new password before continuing to Masar CRM.';

  @override
  String get updatePasswordAndContinue => 'Update password and continue';

  @override
  String get supportCenter => 'Support Center';

  @override
  String get supportCenterSubtitle =>
      'Send support requests or lightweight product feedback from inside your workspace.';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get contactSupportSubtitle =>
      'Create a support request with the page, version, and workspace context attached automatically.';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get sendFeedbackSubtitle =>
      'Share a quick product note without opening a full support ticket.';

  @override
  String get myRequests => 'My Requests';

  @override
  String get supportTitle => 'Title';

  @override
  String get supportMessage => 'Message';

  @override
  String get supportCategory => 'Category';

  @override
  String get supportPriority => 'Priority';

  @override
  String get feedbackRating => 'Rating';

  @override
  String get feedbackCategory => 'Feedback category';

  @override
  String get feedbackMessage => 'Feedback message';

  @override
  String get submitSupportRequest => 'Submit request';

  @override
  String get submitFeedback => 'Submit feedback';

  @override
  String get supportTicketCreated => 'Support request submitted.';

  @override
  String get feedbackSubmitted => 'Feedback submitted.';

  @override
  String get supportNoRequestsTitle => 'No requests yet';

  @override
  String get supportNoRequestsMessage =>
      'Submitted support requests and feedback will appear here.';

  @override
  String get supportCategoryAccountLogin => 'Account and login';

  @override
  String get supportCategoryUsersPermissions => 'Users and permissions';

  @override
  String get supportCategoryBillingSubscription => 'Billing and subscription';

  @override
  String get supportCategoryBug => 'Bug';

  @override
  String get feedbackCategorySuggestion => 'Suggestion';

  @override
  String get feedbackCategoryUiImprovement => 'UI improvement';

  @override
  String get feedbackCategoryMissingFeature => 'Missing feature';

  @override
  String get feedbackCategoryConfusingBehavior => 'Confusing behavior';

  @override
  String get feedbackCategoryPerformance => 'Performance';

  @override
  String get feedbackCategoryGeneralFeedback => 'General feedback';

  @override
  String get supportPriorityLow => 'Low';

  @override
  String get supportPriorityNormal => 'Normal';

  @override
  String get supportPriorityUrgent => 'Urgent';

  @override
  String get supportStatusOpen => 'Open';

  @override
  String get supportStatusInReview => 'In review';

  @override
  String get supportStatusWaitingForUser => 'Waiting for user';

  @override
  String get supportStatusResolved => 'Resolved';

  @override
  String get supportStatusClosed => 'Closed';

  @override
  String get platformSupportInbox => 'Support Inbox';

  @override
  String get supportOpenTickets => 'Open tickets';

  @override
  String get supportUrgentTickets => 'Urgent tickets';

  @override
  String get supportFeedbackCount => 'Feedback';

  @override
  String get supportResolvedThisMonth => 'Resolved this month';

  @override
  String get searchSupportRequests => 'Search support';

  @override
  String get requestType => 'Type';

  @override
  String get allTypes => 'All types';

  @override
  String get requestTypeSupport => 'Support';

  @override
  String get requestTypeFeedback => 'Feedback';

  @override
  String get allCategories => 'All categories';

  @override
  String get supportDetails => 'Request details';

  @override
  String get updateStatus => 'Update status';

  @override
  String get supportStatusUpdated => 'Status updated.';

  @override
  String get company => 'Company';

  @override
  String get user => 'User';

  @override
  String get currentRoute => 'Current route';

  @override
  String get deviceInfo => 'Device info';

  @override
  String get platformNotifications => 'Platform Notifications';

  @override
  String get platformNotificationsSubtitle =>
      'Track important owner actions and SaaS events across Masar CRM.';

  @override
  String get noPlatformNotifications => 'No platform notifications yet';

  @override
  String get noPlatformNotificationsMessage =>
      'Important platform actions and SaaS events will appear here.';

  @override
  String get markUnread => 'Mark unread';

  @override
  String get platformNotificationStorageLabel => 'Storage';

  @override
  String get platformNotificationSeverityInfo => 'Info';

  @override
  String get platformNotificationSeveritySuccess => 'Success';

  @override
  String get platformNotificationSeverityWarning => 'Warning';

  @override
  String get platformNotificationSeverityUrgent => 'Urgent';

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get platformNotificationCompanyRegistered => 'Company registered';

  @override
  String get platformNotificationCompanyCreated => 'Company created';

  @override
  String get platformNotificationCompanyStatusChanged =>
      'Company status changed';

  @override
  String get platformNotificationCompanySettingsChanged =>
      'Company settings changed';

  @override
  String get platformNotificationCompanyFeatureChanged =>
      'Company features changed';

  @override
  String get platformNotificationCompanyLimitChanged =>
      'Company limits changed';

  @override
  String get platformNotificationCompanyUserCreated => 'Company user created';

  @override
  String get platformNotificationCompanyUserStatusChanged =>
      'Company user status changed';

  @override
  String get platformNotificationCompanyUserPasswordReset =>
      'Company user password action';

  @override
  String get platformNotificationInvitationCreated => 'Invitation created';

  @override
  String get platformNotificationInvitationAccepted => 'Invitation accepted';

  @override
  String get platformNotificationInvitationRevoked => 'Invitation revoked';

  @override
  String get platformNotificationSupportTicketCreated =>
      'Support ticket created';

  @override
  String get platformNotificationFeedbackSubmitted => 'Feedback submitted';

  @override
  String get platformNotificationSupportTicketStatusChanged =>
      'Support status changed';

  @override
  String get platformNotificationStorageUsageRefreshed =>
      'Storage usage refreshed';

  @override
  String get platformNotificationStorageNearLimit => 'Storage near limit';

  @override
  String get platformNotificationFunctionFailed => 'Platform function failed';

  @override
  String get platformNotificationUnknown => 'Platform event';

  @override
  String platformNotificationCompanyActorMessage(Object company, Object actor) {
    return '$company was updated by $actor.';
  }

  @override
  String platformNotificationCompanyMessage(Object company) {
    return '$company has a new platform event.';
  }

  @override
  String platformNotificationActorMessage(Object actor) {
    return '$actor created a platform event.';
  }

  @override
  String get platformNotificationGenericMessage =>
      'A platform event needs your attention.';

  @override
  String get storageUsageUnavailable => 'Usage unavailable';

  @override
  String get storageNotTrackedYet => 'Storage usage is not tracked yet.';

  @override
  String get storageLastUpdated => 'Last updated';

  @override
  String get refreshStorageUsage => 'Refresh usage';

  @override
  String get storageUsageUpdated => 'Storage usage updated.';
}
