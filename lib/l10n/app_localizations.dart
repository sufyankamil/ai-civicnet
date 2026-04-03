import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

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
    Locale('en'),
    Locale('hi'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'CivicNet'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// No description provided for @communityTitle.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityTitle;

  /// No description provided for @eventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsTitle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How CivicNet Works'**
  String get howItWorks;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @biometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get biometricLogin;

  /// No description provided for @biometricDescription.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID / Fingerprint to log in securely'**
  String get biometricDescription;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @helpHistory.
  ///
  /// In en, this message translates to:
  /// **'Help History'**
  String get helpHistory;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @verifyPassword.
  ///
  /// In en, this message translates to:
  /// **'Please verify your password to enable biometric login.'**
  String get verifyPassword;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @findMatches.
  ///
  /// In en, this message translates to:
  /// **'Finding matches near you...'**
  String get findMatches;

  /// No description provided for @searchHelp.
  ///
  /// In en, this message translates to:
  /// **'Search help requests...'**
  String get searchHelp;

  /// No description provided for @searchNews.
  ///
  /// In en, this message translates to:
  /// **'Search news feed...'**
  String get searchNews;

  /// No description provided for @noRequests.
  ///
  /// In en, this message translates to:
  /// **'No Requests Nearby'**
  String get noRequests;

  /// No description provided for @noRequestsDescription.
  ///
  /// In en, this message translates to:
  /// **'There are no open help requests in your area right now. Be the first to post one!'**
  String get noRequestsDescription;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @postRequest.
  ///
  /// In en, this message translates to:
  /// **'Post a Request'**
  String get postRequest;

  /// No description provided for @activePolls.
  ///
  /// In en, this message translates to:
  /// **'Active Polls'**
  String get activePolls;

  /// No description provided for @pollsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Active Poll} other{{count} Active Polls}}'**
  String pollsCount(int count);

  /// No description provided for @findYourGuild.
  ///
  /// In en, this message translates to:
  /// **'Find Your Guild'**
  String get findYourGuild;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @communityCommitment.
  ///
  /// In en, this message translates to:
  /// **'Community Commitment'**
  String get communityCommitment;

  /// No description provided for @safetyDescription.
  ///
  /// In en, this message translates to:
  /// **'CivicNet is committed to community safety. We never ask for money for requests or events.'**
  String get safetyDescription;

  /// No description provided for @learnMoreSafety.
  ///
  /// In en, this message translates to:
  /// **'Learn More About Safety'**
  String get learnMoreSafety;

  /// No description provided for @couldNotLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile'**
  String get couldNotLoadProfile;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noName.
  ///
  /// In en, this message translates to:
  /// **'No Name Set'**
  String get noName;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get noEmail;

  /// No description provided for @verifiedLeader.
  ///
  /// In en, this message translates to:
  /// **'Verified Leader'**
  String get verifiedLeader;

  /// No description provided for @eliteHelper.
  ///
  /// In en, this message translates to:
  /// **'Elite Helper'**
  String get eliteHelper;

  /// No description provided for @trustedHelper.
  ///
  /// In en, this message translates to:
  /// **'Trusted Helper'**
  String get trustedHelper;

  /// No description provided for @activeMember.
  ///
  /// In en, this message translates to:
  /// **'Active Member'**
  String get activeMember;

  /// No description provided for @newMember.
  ///
  /// In en, this message translates to:
  /// **'New Member'**
  String get newMember;

  /// No description provided for @helps.
  ///
  /// In en, this message translates to:
  /// **'Helps'**
  String get helps;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addSkillsDescription.
  ///
  /// In en, this message translates to:
  /// **'Add skills so helpers can find you faster'**
  String get addSkillsDescription;

  /// No description provided for @adminControlPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Control Panel'**
  String get adminControlPanel;

  /// No description provided for @verifiedLeaderStatus.
  ///
  /// In en, this message translates to:
  /// **'Verified Leader Status'**
  String get verifiedLeaderStatus;

  /// No description provided for @commitmentSafety.
  ///
  /// In en, this message translates to:
  /// **'Our Commitment & Safety'**
  String get commitmentSafety;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @supportChat.
  ///
  /// In en, this message translates to:
  /// **'Support Chat'**
  String get supportChat;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutConfirm;

  /// No description provided for @logoutDescription.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of CivicNet?'**
  String get logoutDescription;

  /// No description provided for @civicKarma.
  ///
  /// In en, this message translates to:
  /// **'Civic Karma'**
  String get civicKarma;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @noBadges.
  ///
  /// In en, this message translates to:
  /// **'No badges earned yet. Keep helping the community!'**
  String get noBadges;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @techSupport.
  ///
  /// In en, this message translates to:
  /// **'Tech Support'**
  String get techSupport;

  /// No description provided for @household.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get household;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergency;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @errands.
  ///
  /// In en, this message translates to:
  /// **'Errands'**
  String get errands;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @localEventsUpdates.
  ///
  /// In en, this message translates to:
  /// **'Local events and updates'**
  String get localEventsUpdates;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No description provided for @noUpcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'No Upcoming Events'**
  String get noUpcomingEvents;

  /// No description provided for @noPastEvents.
  ///
  /// In en, this message translates to:
  /// **'No Past Events'**
  String get noPastEvents;

  /// No description provided for @firstToOrganize.
  ///
  /// In en, this message translates to:
  /// **'Be the first to organize a local gathering!'**
  String get firstToOrganize;

  /// No description provided for @postAnEvent.
  ///
  /// In en, this message translates to:
  /// **'Post an Event'**
  String get postAnEvent;

  /// No description provided for @myActivity.
  ///
  /// In en, this message translates to:
  /// **'My Activity'**
  String get myActivity;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// No description provided for @volunteering.
  ///
  /// In en, this message translates to:
  /// **'Volunteering'**
  String get volunteering;

  /// No description provided for @noActiveRequests.
  ///
  /// In en, this message translates to:
  /// **'No Active Requests'**
  String get noActiveRequests;

  /// No description provided for @noRequestsLately.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t posted any help requests lately.'**
  String get noRequestsLately;

  /// No description provided for @notVolunteeringYet.
  ///
  /// In en, this message translates to:
  /// **'Not Volunteering Yet'**
  String get notVolunteeringYet;

  /// No description provided for @offerHelpToSee.
  ///
  /// In en, this message translates to:
  /// **'Offer help on community requests to see them here.'**
  String get offerHelpToSee;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @notSelected.
  ///
  /// In en, this message translates to:
  /// **'Not Selected for This One'**
  String get notSelected;

  /// No description provided for @awaitingReview.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Review'**
  String get awaitingReview;

  /// No description provided for @appliedAt.
  ///
  /// In en, this message translates to:
  /// **'Applied {time}'**
  String appliedAt(String time);

  /// No description provided for @postedBy.
  ///
  /// In en, this message translates to:
  /// **'Posted by {name}'**
  String postedBy(String name);

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue connecting with your community.'**
  String get signInToContinue;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get enterEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get enterPassword;

  /// No description provided for @biometricLoginReason.
  ///
  /// In en, this message translates to:
  /// **'Log in securely with your biometrics'**
  String get biometricLoginReason;

  /// No description provided for @biometricLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login Failed: {error}'**
  String biometricLoginFailed(String error);

  /// No description provided for @noCredentialsFound.
  ///
  /// In en, this message translates to:
  /// **'No credentials found. Please log in manually and re-enable Biometrics.'**
  String get noCredentialsFound;

  /// No description provided for @loginWithBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Login with Biometrics'**
  String get loginWithBiometrics;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @joinCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join your community to help and be helped.'**
  String get joinCommunity;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get enterName;

  /// No description provided for @nameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 3 characters'**
  String get nameTooShort;

  /// No description provided for @enterPasswordSignup.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get enterPasswordSignup;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters required'**
  String get passwordTooShort;

  /// No description provided for @passwordUppercase.
  ///
  /// In en, this message translates to:
  /// **'Needs an uppercase letter'**
  String get passwordUppercase;

  /// No description provided for @passwordLowercase.
  ///
  /// In en, this message translates to:
  /// **'Needs a lowercase letter'**
  String get passwordLowercase;

  /// No description provided for @passwordNumber.
  ///
  /// In en, this message translates to:
  /// **'Needs a number'**
  String get passwordNumber;

  /// No description provided for @agreeTerms.
  ///
  /// In en, this message translates to:
  /// **'By continuing, I agree to {terms}'**
  String agreeTerms(String terms);

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @postedByTime.
  ///
  /// In en, this message translates to:
  /// **'{name} • {time}'**
  String postedByTime(String name, String time);

  /// No description provided for @tech.
  ///
  /// In en, this message translates to:
  /// **'Tech'**
  String get tech;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @atLeast8Chars.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get atLeast8Chars;

  /// No description provided for @oneUppercase.
  ///
  /// In en, this message translates to:
  /// **'At least one uppercase letter (A–Z)'**
  String get oneUppercase;

  /// No description provided for @oneLowercase.
  ///
  /// In en, this message translates to:
  /// **'At least one lowercase letter (a–z)'**
  String get oneLowercase;

  /// No description provided for @oneNumber.
  ///
  /// In en, this message translates to:
  /// **'At least one number (0–9)'**
  String get oneNumber;

  /// No description provided for @resetLinkResent.
  ///
  /// In en, this message translates to:
  /// **'Reset link resent successfully!'**
  String get resetLinkResent;

  /// No description provided for @noWorriesReset.
  ///
  /// In en, this message translates to:
  /// **'No worries! Enter your registered email and we\'ll send you a secure reset link.'**
  String get noWorriesReset;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @checkYourInbox.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox!'**
  String get checkYourInbox;

  /// No description provided for @resetSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a password reset link to\n{email}'**
  String resetSentTo(String email);

  /// No description provided for @linkExpires.
  ///
  /// In en, this message translates to:
  /// **'The link expires in 60 minutes.'**
  String get linkExpires;

  /// No description provided for @didntReceive.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive it? Resend'**
  String get didntReceive;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get setNewPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a new password for your account.'**
  String get enterNewPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @enterNewPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new password'**
  String get enterNewPasswordError;

  /// No description provided for @passwordLengthError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordLengthError;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated! Please log in.'**
  String get passwordUpdated;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @eventLabel.
  ///
  /// In en, this message translates to:
  /// **'EVENT'**
  String get eventLabel;

  /// No description provided for @attendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} attending'**
  String attendingCount(int count);

  /// No description provided for @attendedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} attended'**
  String attendedCount(int count);

  /// No description provided for @ended.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get ended;

  /// No description provided for @rsvp.
  ///
  /// In en, this message translates to:
  /// **'RSVP'**
  String get rsvp;

  /// No description provided for @attending.
  ///
  /// In en, this message translates to:
  /// **'Attending'**
  String get attending;

  /// No description provided for @eventEndedLabel.
  ///
  /// In en, this message translates to:
  /// **'Event Ended'**
  String get eventEndedLabel;

  /// No description provided for @attendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Attending'**
  String get attendingLabel;

  /// No description provided for @rsvpNow.
  ///
  /// In en, this message translates to:
  /// **'RSVP Now'**
  String get rsvpNow;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescription;

  /// No description provided for @membersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String membersCount(int count);

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @communityPollLabel.
  ///
  /// In en, this message translates to:
  /// **'COMMUNITY POLL'**
  String get communityPollLabel;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} days left'**
  String daysLeft(int count);

  /// No description provided for @votesCountSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} votes'**
  String votesCountSummary(int count);

  /// No description provided for @sourceInformation.
  ///
  /// In en, this message translates to:
  /// **'Source Information'**
  String get sourceInformation;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read More'**
  String get readMore;

  /// No description provided for @superAdminActions.
  ///
  /// In en, this message translates to:
  /// **'Super Admin Actions:'**
  String get superAdminActions;

  /// No description provided for @adminActions.
  ///
  /// In en, this message translates to:
  /// **'Admin Actions:'**
  String get adminActions;

  /// No description provided for @unverify.
  ///
  /// In en, this message translates to:
  /// **'Unverify'**
  String get unverify;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteAnnouncementTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Announcement?'**
  String get deleteAnnouncementTitle;

  /// No description provided for @deleteAnnouncementContent.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteAnnouncementContent;

  /// No description provided for @announcementDeleted.
  ///
  /// In en, this message translates to:
  /// **'Announcement deleted'**
  String get announcementDeleted;

  /// No description provided for @announcementVerified.
  ///
  /// In en, this message translates to:
  /// **'Announcement verified'**
  String get announcementVerified;

  /// No description provided for @verificationRemoved.
  ///
  /// In en, this message translates to:
  /// **'Verification removed'**
  String get verificationRemoved;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed: {error}'**
  String actionFailed(String error);

  /// No description provided for @enableLocation.
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get enableLocation;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notNow;

  /// No description provided for @allowAccess.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get allowAccess;

  /// No description provided for @deletePoll.
  ///
  /// In en, this message translates to:
  /// **'Delete Poll'**
  String get deletePoll;

  /// No description provided for @deletePollConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this poll? This action cannot be undone.'**
  String get deletePollConfirm;

  /// No description provided for @appFeedback.
  ///
  /// In en, this message translates to:
  /// **'App Feedback'**
  String get appFeedback;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'What can we improve? What do you love?'**
  String get feedbackHint;

  /// No description provided for @createPoll.
  ///
  /// In en, this message translates to:
  /// **'Create Poll'**
  String get createPoll;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @pollQuestionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Should we install more solar lights?'**
  String get pollQuestionHint;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// No description provided for @pollDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Provide context for this poll...'**
  String get pollDescriptionHint;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @addOption.
  ///
  /// In en, this message translates to:
  /// **'Add Option'**
  String get addOption;

  /// No description provided for @optionHint.
  ///
  /// In en, this message translates to:
  /// **'Option {index}'**
  String optionHint(int index);

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @blockedUserMessage.
  ///
  /// In en, this message translates to:
  /// **'You have blocked this user.'**
  String get blockedUserMessage;

  /// No description provided for @unblockToChat.
  ///
  /// In en, this message translates to:
  /// **'Unblock to chat'**
  String get unblockToChat;

  /// No description provided for @userProfile.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get userProfile;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUser;

  /// No description provided for @blockAndReport.
  ///
  /// In en, this message translates to:
  /// **'Block and Report'**
  String get blockAndReport;

  /// No description provided for @unblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock User'**
  String get unblockUser;

  /// No description provided for @blockUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Block User?'**
  String get blockUserConfirm;

  /// No description provided for @searchConversationsHint.
  ///
  /// In en, this message translates to:
  /// **'Search conversations...'**
  String get searchConversationsHint;

  /// No description provided for @reportHint.
  ///
  /// In en, this message translates to:
  /// **'Spam, harassment, etc.'**
  String get reportHint;

  /// No description provided for @typeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeMessageHint;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteAccountConfirm;

  /// No description provided for @verificationRoleHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your role or contributions to the community...'**
  String get verificationRoleHint;

  /// No description provided for @createAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Create Announcement'**
  String get createAnnouncement;

  /// No description provided for @announcementTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter announcement title...'**
  String get announcementTitleHint;

  /// No description provided for @announcementContentHint.
  ///
  /// In en, this message translates to:
  /// **'What\'s the news?'**
  String get announcementContentHint;

  /// No description provided for @announcementSourceHint.
  ///
  /// In en, this message translates to:
  /// **'Provide a link or source of information...'**
  String get announcementSourceHint;

  /// No description provided for @createRequest.
  ///
  /// In en, this message translates to:
  /// **'Create Help Request'**
  String get createRequest;

  /// No description provided for @requestTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title (e.g., Leaky Faucet)'**
  String get requestTitleHint;

  /// No description provided for @requestDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue in detail...'**
  String get requestDescriptionHint;

  /// No description provided for @createEvent.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get createEvent;

  /// No description provided for @eventTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Event Title (e.g., Park Cleanup)'**
  String get eventTitleHint;

  /// No description provided for @eventDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what\'s happening...'**
  String get eventDescriptionHint;

  /// No description provided for @locationNameHint.
  ///
  /// In en, this message translates to:
  /// **'Location Name (e.g., Central Park)'**
  String get locationNameHint;

  /// No description provided for @peopleAttended.
  ///
  /// In en, this message translates to:
  /// **'people attended'**
  String get peopleAttended;

  /// No description provided for @peopleAttending.
  ///
  /// In en, this message translates to:
  /// **'people are attending'**
  String get peopleAttending;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @pollCreationIntro.
  ///
  /// In en, this message translates to:
  /// **'Gather community input on local initiatives.'**
  String get pollCreationIntro;

  /// No description provided for @maxOptionsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum 5 options allowed'**
  String get maxOptionsAllowed;

  /// No description provided for @pollCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Poll created successfully!'**
  String get pollCreatedSuccessfully;

  /// No description provided for @failedToCreatePoll.
  ///
  /// In en, this message translates to:
  /// **'Failed to create poll'**
  String get failedToCreatePoll;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get categoryRecommended;

  /// No description provided for @categoryTechSupport.
  ///
  /// In en, this message translates to:
  /// **'Tech Support'**
  String get categoryTechSupport;

  /// No description provided for @categoryHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get categoryHousehold;

  /// No description provided for @categoryEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get categoryEmergency;

  /// No description provided for @categoryEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get categoryEducation;

  /// No description provided for @categoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get categoryGeneral;

  /// No description provided for @bestMatch.
  ///
  /// In en, this message translates to:
  /// **'Best Match'**
  String get bestMatch;

  /// No description provided for @goodMatch.
  ///
  /// In en, this message translates to:
  /// **'Good Match'**
  String get goodMatch;

  /// No description provided for @match.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get match;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @communityHelpers.
  ///
  /// In en, this message translates to:
  /// **'Community Helpers'**
  String get communityHelpers;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @nearbyMembersHelp.
  ///
  /// In en, this message translates to:
  /// **'Nearby members who might be able to help.'**
  String get nearbyMembersHelp;

  /// No description provided for @requester.
  ///
  /// In en, this message translates to:
  /// **'Requester'**
  String get requester;

  /// No description provided for @approximateLocation.
  ///
  /// In en, this message translates to:
  /// **'Approximate Location'**
  String get approximateLocation;

  /// No description provided for @applicationAccepted.
  ///
  /// In en, this message translates to:
  /// **'Application Accepted!'**
  String get applicationAccepted;

  /// No description provided for @interestSent.
  ///
  /// In en, this message translates to:
  /// **'Interest Sent (Pending)'**
  String get interestSent;

  /// No description provided for @taskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Task Completed!'**
  String get taskCompleted;

  /// No description provided for @earnedPoints.
  ///
  /// In en, this message translates to:
  /// **'You earned {count} points for helping out.'**
  String earnedPoints(int count);

  /// No description provided for @noHelpersYet.
  ///
  /// In en, this message translates to:
  /// **'No helpers available yet'**
  String get noHelpersYet;

  /// No description provided for @beTheFirstHelper.
  ///
  /// In en, this message translates to:
  /// **'Be the first to join the community!'**
  String get beTheFirstHelper;

  /// No description provided for @checkBackLater.
  ///
  /// In en, this message translates to:
  /// **'Check back later for community helpers!'**
  String get checkBackLater;

  /// No description provided for @communicateWithRequester.
  ///
  /// In en, this message translates to:
  /// **'You can now communicate with the requester.'**
  String get communicateWithRequester;

  /// No description provided for @chatWithRequester.
  ///
  /// In en, this message translates to:
  /// **'Chat with Requester'**
  String get chatWithRequester;

  /// No description provided for @imInterested.
  ///
  /// In en, this message translates to:
  /// **'I\'m Interested'**
  String get imInterested;

  /// No description provided for @requestNoLongerOpen.
  ///
  /// In en, this message translates to:
  /// **'This request is no longer open for applications.'**
  String get requestNoLongerOpen;

  /// No description provided for @yourRequest.
  ///
  /// In en, this message translates to:
  /// **'This is your request'**
  String get yourRequest;

  /// No description provided for @interestShown.
  ///
  /// In en, this message translates to:
  /// **'No interest shown yet.'**
  String get interestShown;

  /// No description provided for @helpsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} helps'**
  String helpsCount(int count);

  /// No description provided for @enjoyingApp.
  ///
  /// In en, this message translates to:
  /// **'Enjoying Civic Net?'**
  String get enjoyingApp;

  /// No description provided for @feedbackDescription.
  ///
  /// In en, this message translates to:
  /// **'Your feedback is invaluable to us. Would you like to share your thoughts or suggest improvements?'**
  String get feedbackDescription;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLater;

  /// No description provided for @giveFeedback.
  ///
  /// In en, this message translates to:
  /// **'Give Feedback'**
  String get giveFeedback;

  /// No description provided for @locationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get locationPermissionTitle;

  /// No description provided for @locationPermissionDesc.
  ///
  /// In en, this message translates to:
  /// **'To connect you with help requests and community matches in your immediate neighborhood, CivicNet requires location access.'**
  String get locationPermissionDesc;

  /// No description provided for @communityEvent.
  ///
  /// In en, this message translates to:
  /// **'COMMUNITY EVENT'**
  String get communityEvent;

  /// No description provided for @aboutThisEvent.
  ///
  /// In en, this message translates to:
  /// **'About this event'**
  String get aboutThisEvent;

  /// No description provided for @organizer.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get organizer;

  /// No description provided for @communityMember.
  ///
  /// In en, this message translates to:
  /// **'Community Member'**
  String get communityMember;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(int count);

  /// No description provided for @writeReply.
  ///
  /// In en, this message translates to:
  /// **'Write a reply...'**
  String get writeReply;

  /// No description provided for @askSomething.
  ///
  /// In en, this message translates to:
  /// **'Ask something...'**
  String get askSomething;

  /// No description provided for @onlyAttendingCanChat.
  ///
  /// In en, this message translates to:
  /// **'Only people attending this event can send messages.'**
  String get onlyAttendingCanChat;

  /// No description provided for @noCommentsBeFirst.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Be the first to ask!'**
  String get noCommentsBeFirst;

  /// No description provided for @deleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Delete Event'**
  String get deleteEvent;

  /// No description provided for @deleteEventConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this event? This action cannot be undone.'**
  String get deleteEventConfirm;

  /// No description provided for @eventDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Event deleted successfully'**
  String get eventDeletedSuccess;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'HOST'**
  String get host;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @replyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to '**
  String get replyingTo;

  /// No description provided for @tapToSeeOnMap.
  ///
  /// In en, this message translates to:
  /// **'Tap to see on map'**
  String get tapToSeeOnMap;

  /// No description provided for @locationSelectedOnMap.
  ///
  /// In en, this message translates to:
  /// **'Location selected on map'**
  String get locationSelectedOnMap;

  /// No description provided for @eventPostedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Event posted successfully!'**
  String get eventPostedSuccess;

  /// No description provided for @eventPostedError.
  ///
  /// In en, this message translates to:
  /// **'Failed to post event. Please try again.'**
  String get eventPostedError;

  /// No description provided for @postAnEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Post an Event'**
  String get postAnEventTitle;

  /// No description provided for @eventDetails.
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get eventDetails;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @whenAndWhere.
  ///
  /// In en, this message translates to:
  /// **'When & Where'**
  String get whenAndWhere;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @selectLocationOnMap.
  ///
  /// In en, this message translates to:
  /// **'Select exact location on map'**
  String get selectLocationOnMap;

  /// No description provided for @changeLocationOnMap.
  ///
  /// In en, this message translates to:
  /// **'Change location on map'**
  String get changeLocationOnMap;

  /// No description provided for @selectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected: {lat}, {lng}'**
  String selectedLocation(String lat, String lng);

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are required.'**
  String get locationPermissionRequired;

  /// No description provided for @gpsDisabled.
  ///
  /// In en, this message translates to:
  /// **'GPS is disabled. Please enable it.'**
  String get gpsDisabled;

  /// No description provided for @locationFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Location fetch failed: {error}'**
  String locationFetchFailed(String error);

  /// No description provided for @preciseLocationFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not get your precise location.'**
  String get preciseLocationFetchFailed;

  /// No description provided for @locationNotFoundDefault.
  ///
  /// In en, this message translates to:
  /// **'Could not find your location. Defaulting to India.'**
  String get locationNotFoundDefault;

  /// No description provided for @selectLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocationTitle;

  /// No description provided for @confirmAllCaps.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM'**
  String get confirmAllCaps;

  /// No description provided for @tapOnMapToSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Tap on the map to select a precise location for your event.'**
  String get tapOnMapToSelectLocation;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// No description provided for @beta.
  ///
  /// In en, this message translates to:
  /// **'BETA'**
  String get beta;
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
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
