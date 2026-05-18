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
}
