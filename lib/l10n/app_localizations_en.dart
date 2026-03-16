// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CivicNet';

  @override
  String get homeTitle => 'Home';

  @override
  String get discoverTitle => 'Discover';

  @override
  String get eventsTitle => 'Events';

  @override
  String get profileTitle => 'Profile';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageTitle => 'Language';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get english => 'English';

  @override
  String get hindi => 'Hindi';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get support => 'Support';

  @override
  String get howItWorks => 'How CivicNet Works';

  @override
  String get faq => 'FAQ';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get security => 'Security';

  @override
  String get biometricLogin => 'Biometric Login';

  @override
  String get biometricDescription =>
      'Use Face ID / Fingerprint to log in securely';

  @override
  String get account => 'Account';

  @override
  String get helpHistory => 'Help History';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get verifyPassword =>
      'Please verify your password to enable biometric login.';

  @override
  String get password => 'Password';

  @override
  String get cancel => 'Cancel';

  @override
  String get enable => 'Enable';

  @override
  String get findMatches => 'Find Matches';

  @override
  String get searchHelp => 'Search help requests...';

  @override
  String get searchNews => 'Search news...';

  @override
  String get noRequests => 'No Requests';

  @override
  String get noRequestsDescription => 'No help requests in your area yet.';

  @override
  String get refresh => 'Refresh';

  @override
  String get postRequest => 'Post a Request';

  @override
  String get activePolls => 'Active Polls';

  @override
  String pollsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Polls',
      one: '1 Poll',
    );
    return '$_temp0';
  }

  @override
  String get findYourGuild => 'Find Your Guild';

  @override
  String get seeAll => 'See All';

  @override
  String get communityCommitment => 'Community Commitment';

  @override
  String get safetyDescription =>
      'Review our safety guidelines and shared community commitment.';

  @override
  String get learnMoreSafety => 'Learn More';

  @override
  String get couldNotLoadProfile => 'Could not load profile';

  @override
  String get retry => 'Retry';

  @override
  String get noName => 'No Name Set';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get noEmail => 'No email';

  @override
  String get verifiedLeader => 'Verified Leader';

  @override
  String get eliteHelper => 'Elite Helper';

  @override
  String get trustedHelper => 'Trusted Helper';

  @override
  String get activeMember => 'Active Member';

  @override
  String get newMember => 'New Member';

  @override
  String get helps => 'Helps';

  @override
  String get rating => 'Rating';

  @override
  String get points => 'Points';

  @override
  String get skills => 'Skills';

  @override
  String get add => 'Add';

  @override
  String get addSkillsDescription =>
      'Add skills so helpers can find you faster';

  @override
  String get adminControlPanel => 'Admin Control Panel';

  @override
  String get verifiedLeaderStatus => 'Verified Leader Status';

  @override
  String get commitmentSafety => 'Our Commitment & Safety';

  @override
  String get appSettings => 'App Settings';

  @override
  String get supportChat => 'Support Chat';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirm => 'Log out?';

  @override
  String get logoutDescription =>
      'Are you sure you want to log out of CivicNet?';

  @override
  String get civicKarma => 'Civic Karma';

  @override
  String get score => 'Score';

  @override
  String get achievements => 'Achievements';

  @override
  String get noBadges => 'No badges earned yet. Keep helping the community!';

  @override
  String get categories => 'Categories';

  @override
  String get techSupport => 'Tech Support';

  @override
  String get household => 'Household';

  @override
  String get emergency => 'Emergency';

  @override
  String get education => 'Education';

  @override
  String get health => 'Health';

  @override
  String get transport => 'Transport';

  @override
  String get errands => 'Errands';

  @override
  String get other => 'Other';

  @override
  String get localEventsUpdates => 'Local events and updates';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get past => 'Past';

  @override
  String get noUpcomingEvents => 'No Upcoming Events';

  @override
  String get noPastEvents => 'No Past Events';

  @override
  String get firstToOrganize => 'Be the first to organize a local gathering!';

  @override
  String get postAnEvent => 'Post an Event';

  @override
  String get myActivity => 'My Activity';

  @override
  String get myRequests => 'My Requests';

  @override
  String get volunteering => 'Volunteering';

  @override
  String get noActiveRequests => 'No Active Requests';

  @override
  String get noRequestsLately =>
      'You haven\'t posted any help requests lately.';

  @override
  String get notVolunteeringYet => 'Not Volunteering Yet';

  @override
  String get offerHelpToSee =>
      'Offer help on community requests to see them here.';

  @override
  String get accepted => 'Accepted';

  @override
  String get notSelected => 'Not Selected';

  @override
  String get awaitingReview => 'Awaiting Review';

  @override
  String appliedAt(String time) {
    return 'Applied $time';
  }

  @override
  String postedBy(String name) {
    return 'Posted by $name';
  }

  @override
  String get login => 'Login';

  @override
  String get signup => 'Sign Up';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Sign Up';

  @override
  String get alreadyHaveAccount => 'Already have an account? Login';

  @override
  String get welcomeBack => 'Welcome Back!';

  @override
  String get signInToContinue =>
      'Sign in to continue connecting with your community.';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get enterEmail => 'Please enter your email';

  @override
  String get enterPassword => 'Please enter your password';

  @override
  String get biometricLoginReason => 'Log in securely with your biometrics';

  @override
  String biometricLoginFailed(String error) {
    return 'Biometric Login Failed: $error';
  }

  @override
  String get noCredentialsFound =>
      'No credentials found. Please log in manually and re-enable Biometrics.';

  @override
  String get loginWithBiometrics => 'Login with Biometrics';

  @override
  String get createAccount => 'Create Account';

  @override
  String get joinCommunity => 'Join your community to help and be helped.';

  @override
  String get fullName => 'Full Name';

  @override
  String get enterName => 'Please enter your name';

  @override
  String get nameTooShort => 'Name must be at least 3 characters';

  @override
  String get enterPasswordSignup => 'Please enter a password';

  @override
  String get passwordTooShort => 'At least 8 characters required';

  @override
  String get passwordUppercase => 'Needs an uppercase letter';

  @override
  String get passwordLowercase => 'Needs a lowercase letter';

  @override
  String get passwordNumber => 'Needs a number';

  @override
  String agreeTerms(String terms) {
    return 'By continuing, I agree to $terms';
  }

  @override
  String get termsAndConditions => 'Terms and Conditions';

  @override
  String postedByTime(String name, String time) {
    return '$name • $time';
  }

  @override
  String get tech => 'Tech';

  @override
  String get general => 'General';

  @override
  String get atLeast8Chars => 'At least 8 characters';

  @override
  String get oneUppercase => 'At least one uppercase letter (A–Z)';

  @override
  String get oneLowercase => 'At least one lowercase letter (a–z)';

  @override
  String get oneNumber => 'At least one number (0–9)';

  @override
  String get resetLinkResent => 'Reset link resent successfully!';

  @override
  String get noWorriesReset =>
      'No worries! Enter your registered email and we\'ll send you a secure reset link.';

  @override
  String get enterValidEmail => 'Please enter a valid email';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get checkYourInbox => 'Check your inbox!';

  @override
  String resetSentTo(String email) {
    return 'We sent a password reset link to\n$email';
  }

  @override
  String get linkExpires => 'The link expires in 60 minutes.';

  @override
  String get didntReceive => 'Didn\'t receive it? Resend';

  @override
  String get setNewPassword => 'Set New Password';

  @override
  String get enterNewPassword => 'Enter a new password for your account.';

  @override
  String get newPassword => 'New Password';

  @override
  String get enterNewPasswordError => 'Please enter a new password';

  @override
  String get passwordLengthError => 'Password must be at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get updatePassword => 'Update Password';

  @override
  String get passwordUpdated => 'Password updated! Please log in.';

  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';

  @override
  String get eventLabel => 'EVENT';

  @override
  String attendingCount(int count) {
    return '$count attending';
  }

  @override
  String get ended => 'Ended';

  @override
  String get rsvp => 'RSVP';

  @override
  String get attending => 'Attending';

  @override
  String get noDescription => 'No description available.';

  @override
  String membersCount(int count) {
    return '$count members';
  }

  @override
  String get joined => 'Joined';

  @override
  String get join => 'Join';

  @override
  String get communityPollLabel => 'COMMUNITY POLL';

  @override
  String daysLeft(int count) {
    return '$count days left';
  }

  @override
  String votesCountSummary(int count) {
    return '$count votes';
  }

  @override
  String get sourceInformation => 'Source Information';

  @override
  String get readMore => 'Read More';

  @override
  String get superAdminActions => 'Super Admin Actions:';

  @override
  String get adminActions => 'Admin Actions:';

  @override
  String get unverify => 'Unverify';

  @override
  String get verify => 'Verify';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAnnouncementTitle => 'Delete Announcement?';

  @override
  String get deleteAnnouncementContent => 'This action cannot be undone.';

  @override
  String get announcementDeleted => 'Announcement deleted';

  @override
  String get announcementVerified => 'Announcement verified';

  @override
  String get verificationRemoved => 'Verification removed';

  @override
  String actionFailed(String error) {
    return 'Action failed: $error';
  }

  @override
  String get enableLocation => 'Enable Location';

  @override
  String get notNow => 'Not Now';

  @override
  String get allowAccess => 'Allow Access';

  @override
  String get deletePoll => 'Delete Poll';

  @override
  String get deletePollConfirm =>
      'Are you sure you want to delete this poll? This action cannot be undone.';

  @override
  String get appFeedback => 'App Feedback';

  @override
  String get feedbackHint => 'What can we improve? What do you love?';

  @override
  String get createPoll => 'Create Poll';

  @override
  String get question => 'Question';

  @override
  String get pollQuestionHint => 'e.g., Should we install more solar lights?';

  @override
  String get descriptionOptional => 'Description (Optional)';

  @override
  String get pollDescriptionHint => 'Provide context for this poll...';

  @override
  String get options => 'Options';

  @override
  String get addOption => 'Add Option';

  @override
  String optionHint(int index) {
    return 'Option $index';
  }

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get blockedUserMessage => 'You have blocked this user.';

  @override
  String get unblockToChat => 'Unblock to chat';

  @override
  String get userProfile => 'User Profile';

  @override
  String get blockUser => 'Block User';

  @override
  String get blockAndReport => 'Block and Report';

  @override
  String get unblockUser => 'Unblock User';

  @override
  String get blockUserConfirm => 'Block User?';

  @override
  String get searchConversationsHint => 'Search conversations...';

  @override
  String get reportHint => 'Spam, harassment, etc.';

  @override
  String get typeMessageHint => 'Type your message...';

  @override
  String get deleteAccountConfirm => 'DELETE';

  @override
  String get verificationRoleHint =>
      'Describe your role or contributions to the community...';

  @override
  String get createAnnouncement => 'Create Announcement';

  @override
  String get announcementTitleHint => 'Enter announcement title...';

  @override
  String get announcementContentHint => 'What\'s the news?';

  @override
  String get announcementSourceHint =>
      'Provide a link or source of information...';

  @override
  String get createRequest => 'Create Help Request';

  @override
  String get requestTitleHint => 'Title (e.g., Leaky Faucet)';

  @override
  String get requestDescriptionHint => 'Describe your issue in detail...';

  @override
  String get createEvent => 'Create Event';

  @override
  String get eventTitleHint => 'Event Title (e.g., Park Cleanup)';

  @override
  String get eventDescriptionHint => 'Describe what\'s happening...';

  @override
  String get locationNameHint => 'Location Name (e.g., Central Park)';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get pollCreationIntro =>
      'Gather community input on local initiatives.';

  @override
  String get maxOptionsAllowed => 'Maximum 5 options allowed';

  @override
  String get pollCreatedSuccessfully => 'Poll created successfully!';

  @override
  String get failedToCreatePoll => 'Failed to create poll';
}
