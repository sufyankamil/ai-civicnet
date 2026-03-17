// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'CivicNet';

  @override
  String get homeTitle => 'होम';

  @override
  String get discoverTitle => 'खोजें';

  @override
  String get eventsTitle => 'कार्यक्रम';

  @override
  String get profileTitle => 'प्रोफ़ाइल';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get languageTitle => 'भाषा';

  @override
  String get chooseLanguage => 'अपनी भाषा चुनें';

  @override
  String get english => 'अंग्रेजी';

  @override
  String get hindi => 'हिन्दी';

  @override
  String get appearance => 'दिखावट';

  @override
  String get theme => 'थीम';

  @override
  String get system => 'सिस्टम';

  @override
  String get light => 'लाइट';

  @override
  String get dark => 'डार्क';

  @override
  String get support => 'सहायता';

  @override
  String get howItWorks => 'CivicNet कैसे काम करता है';

  @override
  String get faq => 'पूछे जाने वाले प्रश्न';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get security => 'सुरक्षा';

  @override
  String get biometricLogin => 'बायोमेट्रिक लॉगिन';

  @override
  String get biometricDescription =>
      'सुरक्षित रूप से लॉगिन करने के लिए फेस आईडी / फिंगरप्रिंट का उपयोग करें';

  @override
  String get account => 'अकाउंट';

  @override
  String get helpHistory => 'हेल्प हिस्ट्री';

  @override
  String get deleteAccount => 'अकाउंट हटाएं';

  @override
  String get about => 'के बारे में';

  @override
  String get version => 'वर्जन';

  @override
  String get confirmPassword => 'पासवर्ड की पुष्टि करें';

  @override
  String get verifyPassword =>
      'बायोमेट्रिक लॉगिन सक्षम करने के लिए कृपया अपने पासवर्ड की पुष्टि करें।';

  @override
  String get password => 'पासवर्ड';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get enable => 'सक्षम करें';

  @override
  String get findMatches => 'आपके आस-पास मैच ढूँढ रहे हैं...';

  @override
  String get searchHelp => 'मदद के अनुरोध खोजें...';

  @override
  String get searchNews => 'न्यूज़ फीड खोजें...';

  @override
  String get noRequests => 'आस-पास कोई अनुरोध नहीं';

  @override
  String get noRequestsDescription =>
      'अभी आपके क्षेत्र में कोई सहायता अनुरोध नहीं हैं। पहले पोस्ट करने वाले बनें!';

  @override
  String get refresh => 'रिफ्रेश';

  @override
  String get postRequest => 'अनुरोध पोस्ट करें';

  @override
  String get activePolls => 'सक्रिय पोल';

  @override
  String pollsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सक्रिय पोल',
      one: '1 सक्रिय पोल',
    );
    return '$_temp0';
  }

  @override
  String get findYourGuild => 'अपना समाज ढूँढें';

  @override
  String get seeAll => 'सभी देखें';

  @override
  String get communityCommitment => 'सामुदायिक प्रतिबद्धता';

  @override
  String get safetyDescription =>
      'CivicNet सामुदायिक सुरक्षा के लिए प्रतिबद्ध है। हम अनुरोधों या कार्यक्रमों के लिए कभी पैसे नहीं मांगते।';

  @override
  String get learnMoreSafety => 'सुरक्षा के बारे में और जानें';

  @override
  String get couldNotLoadProfile => 'प्रोफ़ाइल लोड नहीं की जा सकी';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get noName => 'कोई नाम सेट नहीं';

  @override
  String get editProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get noEmail => 'कोई ईमेल नहीं';

  @override
  String get verifiedLeader => 'सत्यापित नेता';

  @override
  String get eliteHelper => 'अभिजात वर्ग सहायक';

  @override
  String get trustedHelper => 'विश्वसनीय सहायक';

  @override
  String get activeMember => 'सक्रिय सदस्य';

  @override
  String get newMember => 'नया सदस्य';

  @override
  String get helps => 'मदद';

  @override
  String get rating => 'रेटिंग';

  @override
  String get points => 'अंक';

  @override
  String get skills => 'कौशल';

  @override
  String get add => 'जोड़ें';

  @override
  String get addSkillsDescription =>
      'कौशल जोड़ें ताकि सहायक आपको तेज़ी से ढूंढ सकें';

  @override
  String get adminControlPanel => 'एडमिन कंट्रोल पैनल';

  @override
  String get verifiedLeaderStatus => 'सत्यापित नेता स्थिति';

  @override
  String get commitmentSafety => 'हमारी प्रतिबद्धता और सुरक्षा';

  @override
  String get appSettings => 'ऐप सेटिंग्स';

  @override
  String get supportChat => 'सपोर्ट चैट';

  @override
  String get logout => 'लॉग आउट';

  @override
  String get logoutConfirm => 'लॉग आउट करें?';

  @override
  String get logoutDescription =>
      'क्या आप वाकई CivicNet से लॉग आउट करना चाहते हैं?';

  @override
  String get civicKarma => 'सिविक कर्मा';

  @override
  String get score => 'स्कोर';

  @override
  String get achievements => 'उपलब्धियां';

  @override
  String get noBadges =>
      'अभी तक कोई बैज नहीं मिला है। समुदाय की मदद करते रहें!';

  @override
  String get categories => 'श्रेणियाँ';

  @override
  String get techSupport => 'तकनीकी सहायता';

  @override
  String get household => 'घरेलू';

  @override
  String get emergency => 'आपातकालीन';

  @override
  String get education => 'शिक्षा';

  @override
  String get health => 'स्वास्थ्य';

  @override
  String get transport => 'यातायात एवं परिवहन';

  @override
  String get errands => 'दौड़-धूप और काम';

  @override
  String get other => 'अन्य';

  @override
  String get localEventsUpdates => 'स्थानीय कार्यक्रम और अपडेट';

  @override
  String get upcoming => 'आगामी';

  @override
  String get past => 'विगत';

  @override
  String get noUpcomingEvents => 'कोई आगामी कार्यक्रम नहीं';

  @override
  String get noPastEvents => 'कोई पिछला कार्यक्रम नहीं';

  @override
  String get firstToOrganize =>
      'स्थानीय सभा आयोजित करने वाले पहले व्यक्ति बनें!';

  @override
  String get postAnEvent => 'एक कार्यक्रम पोस्ट करें';

  @override
  String get myActivity => 'मेरी गतिविधि';

  @override
  String get myRequests => 'मेरे अनुरोध';

  @override
  String get volunteering => 'स्वयंसेवा';

  @override
  String get noActiveRequests => 'कोई सक्रिय अनुरोध नहीं';

  @override
  String get noRequestsLately =>
      'आपने हाल ही में कोई सहायता अनुरोध पोस्ट नहीं किया है।';

  @override
  String get notVolunteeringYet => 'अभी स्वयंसेवा नहीं कर रहे';

  @override
  String get offerHelpToSee =>
      'उन्हें यहाँ देखने के लिए सामुदायिक अनुरोधों पर सहायता की पेशकश करें।';

  @override
  String get accepted => 'स्वीकार किया गया';

  @override
  String get notSelected => 'इसके लिए चयन नहीं हुआ';

  @override
  String get awaitingReview => 'समीक्षा की प्रतीक्षा है';

  @override
  String appliedAt(String time) {
    return '$time पहले आवेदन किया';
  }

  @override
  String postedBy(String name) {
    return '$name द्वारा पोस्ट किया गया';
  }

  @override
  String get login => 'लॉगिन';

  @override
  String get signup => 'साइन अप करें';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get dontHaveAccount => 'अकाउंट नहीं है? साइन अप करें';

  @override
  String get alreadyHaveAccount => 'पहले से ही एक अकाउंट है? लॉगिन करें';

  @override
  String get welcomeBack => 'वापसी पर आपका स्वागत है!';

  @override
  String get signInToContinue =>
      'अपने समुदाय से जुड़े रहने के लिए साइन इन करें।';

  @override
  String get emailAddress => 'ईमेल पता';

  @override
  String get enterEmail => 'कृपया अपना ईमेल दर्ज करें';

  @override
  String get enterPassword => 'कृपया अपना पासवर्ड दर्ज करें';

  @override
  String get biometricLoginReason =>
      'अपने बायोमेट्रिक्स के साथ सुरक्षित रूप से लॉग इन करें';

  @override
  String biometricLoginFailed(String error) {
    return 'बायोमेट्रिक लॉगिन विफल: $error';
  }

  @override
  String get noCredentialsFound =>
      'कोई क्रेडेंशियल नहीं मिला। कृपया मैन्युअल रूप से लॉग इन करें और बायोमेट्रिक्स को फिर से सक्षम करें।';

  @override
  String get loginWithBiometrics => 'बायोमेट्रिक्स के साथ लॉगिन करें';

  @override
  String get createAccount => 'अकाउंट बनाएं';

  @override
  String get joinCommunity =>
      'मदद करने और मदद पाने के लिए अपने समुदाय में शामिल हों।';

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get enterName => 'कृपया अपना नाम दर्ज करें';

  @override
  String get nameTooShort => 'नाम कम से कम 3 अक्षर का होना चाहिए';

  @override
  String get enterPasswordSignup => 'कृपया एक पासवर्ड दर्ज करें';

  @override
  String get passwordTooShort => 'कम से कम 8 अक्षर आवश्यक हैं';

  @override
  String get passwordUppercase => 'एक बड़े अक्षर की आवश्यकता है';

  @override
  String get passwordLowercase => 'एक छोटे अक्षर की आवश्यकता है';

  @override
  String get passwordNumber => 'एक नंबर की आवश्यकता है';

  @override
  String agreeTerms(String terms) {
    return 'जारी रखकर, मैं $terms से सहमत हूँ';
  }

  @override
  String get termsAndConditions => 'नियम और शर्तें';

  @override
  String postedByTime(String name, String time) {
    return '$name • $time';
  }

  @override
  String get tech => 'तकनीकी';

  @override
  String get general => 'सामान्य';

  @override
  String get atLeast8Chars => 'कम से कम 8 अक्षर';

  @override
  String get oneUppercase => 'कम से कम एक बड़ा अक्षर (A–Z)';

  @override
  String get oneLowercase => 'कम से कम एक छोटा अक्षर (a–z)';

  @override
  String get oneNumber => 'कम से कम एक नंबर (0–9)';

  @override
  String get resetLinkResent => 'रीसेट लिंक सफलतापूर्वक फिर से भेजा गया!';

  @override
  String get noWorriesReset =>
      'कोई चिंता नहीं! अपना पंजीकृत ईमेल दर्ज करें और हम आपको एक सुरक्षित रीसेट लिंक भेजेंगे।';

  @override
  String get enterValidEmail => 'कृपया एक मान्य ईमेल दर्ज करें';

  @override
  String get sendResetLink => 'रीसेट लिंक भेजें';

  @override
  String get backToLogin => 'लॉगिन पर वापस जाएं';

  @override
  String get checkYourInbox => 'अपना इनबॉक्स चेक करें!';

  @override
  String resetSentTo(String email) {
    return 'हमने $email पर पासवर्ड रीसेट लिंक भेजा है';
  }

  @override
  String get linkExpires => 'लिंक 60 मिनट में समाप्त हो जाता है।';

  @override
  String get didntReceive => 'नहीं मिला? फिर से भेजें';

  @override
  String get setNewPassword => 'नया पासवर्ड सेट करें';

  @override
  String get enterNewPassword => 'अपने अकाउंट के लिए एक नया पासवर्ड दर्ज करें।';

  @override
  String get newPassword => 'नया पासवर्ड';

  @override
  String get enterNewPasswordError => 'कृपया नया पासवर्ड दर्ज करें';

  @override
  String get passwordLengthError => 'पासवर्ड कम से कम 6 अक्षर का होना चाहिए';

  @override
  String get passwordsDoNotMatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String get updatePassword => 'पासवर्ड अपडेट करें';

  @override
  String get passwordUpdated => 'पासवर्ड अपडेट कर दिया गया! कृपया लॉगिन करें।';

  @override
  String get somethingWentWrong => 'कुछ गलत हो गया। कृपया फिर से प्रयास करें।';

  @override
  String get eventLabel => 'कार्यक्रम';

  @override
  String attendingCount(int count) {
    return '$count शामिल हो रहे हैं';
  }

  @override
  String attendedCount(int count) {
    return '$count शामिल हुए';
  }

  @override
  String get ended => 'समाप्त';

  @override
  String get rsvp => 'आने की सूचना दें';

  @override
  String get attending => 'शाामिल हो रहे हैं';

  @override
  String get eventEndedLabel => 'कार्यक्रम समाप्त';

  @override
  String get attendingLabel => 'शामिल हो रहे हैं';

  @override
  String get rsvpNow => 'अभी शामिल हों';

  @override
  String get noDescription => 'कोई विवरण उपलब्ध नहीं है।';

  @override
  String membersCount(int count) {
    return '$count सदस्य';
  }

  @override
  String get joined => 'शामिल हुए';

  @override
  String get join => 'शामिल हों';

  @override
  String get communityPollLabel => 'सामुदायिक पोल';

  @override
  String daysLeft(int count) {
    return '$count दिन शेष';
  }

  @override
  String votesCountSummary(int count) {
    return '$count वोट';
  }

  @override
  String get sourceInformation => 'स्रोत जानकारी';

  @override
  String get readMore => 'और पढ़ें';

  @override
  String get superAdminActions => 'सुपर एडमिन क्रियाएँ:';

  @override
  String get adminActions => 'एडमिन क्रियाएँ:';

  @override
  String get unverify => 'सत्यापन हटाएं';

  @override
  String get verify => 'सत्यापित करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get deleteAnnouncementTitle => 'घोषणा हटाएं?';

  @override
  String get deleteAnnouncementContent => 'यह क्रिया पूर्ववत नहीं की जा सकती।';

  @override
  String get announcementDeleted => 'घोषणा हटा दी गई';

  @override
  String get announcementVerified => 'घोषणा सत्यापित';

  @override
  String get verificationRemoved => 'सत्यापन हटा दिया गया';

  @override
  String actionFailed(String error) {
    return 'क्रिया विफल: $error';
  }

  @override
  String get enableLocation => 'स्थान सक्षम करें';

  @override
  String get notNow => 'अभी नहीं';

  @override
  String get allowAccess => 'पहुंच की अनुमति दें';

  @override
  String get deletePoll => 'पोल हटाएं';

  @override
  String get deletePollConfirm =>
      'क्या आप वाकई इस पोल को हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती।';

  @override
  String get appFeedback => 'ऐप फीडबैक';

  @override
  String get feedbackHint => 'हम क्या सुधार सकते हैं? आपको क्या पसंद है?';

  @override
  String get createPoll => 'पोल बनाएं';

  @override
  String get question => 'प्रश्न';

  @override
  String get pollQuestionHint => 'जैसे, क्या हमें और सोलर लाइटें लगानी चाहिए?';

  @override
  String get descriptionOptional => 'विवरण (वैकल्पिक)';

  @override
  String get pollDescriptionHint => 'इस पोल के लिए संदर्भ प्रदान करें...';

  @override
  String get options => 'विकल्प';

  @override
  String get addOption => 'विकल्प जोड़ें';

  @override
  String optionHint(int index) {
    return 'विकल्प $index';
  }

  @override
  String get noMessagesYet => 'अभी तक कोई संदेश नहीं';

  @override
  String get blockedUserMessage => 'आपने इस उपयोगकर्ता को ब्लॉक कर दिया है।';

  @override
  String get unblockToChat => 'चैट करने के लिए अनब्लॉक करें';

  @override
  String get userProfile => 'उपयोगकर्ता प्रोफ़ाइल';

  @override
  String get blockUser => 'उपयोगकर्ता को ब्लॉक करें';

  @override
  String get blockAndReport => 'ब्लॉक और रिपोर्ट करें';

  @override
  String get unblockUser => 'उपयोगकर्ता को अनब्लॉक करें';

  @override
  String get blockUserConfirm => 'उपयोगकर्ता को ब्लॉक करें?';

  @override
  String get searchConversationsHint => 'बातचीत खोजें...';

  @override
  String get reportHint => 'स्पैम, उत्पीड़न, आदि।';

  @override
  String get typeMessageHint => 'अपना संदेश टाइप करें...';

  @override
  String get deleteAccountConfirm => 'हटाएं (DELETE)';

  @override
  String get verificationRoleHint =>
      'समुदाय में अपनी भूमिका या योगदान का वर्णन करें...';

  @override
  String get createAnnouncement => 'घोषणा बनाएं';

  @override
  String get announcementTitleHint => 'घोषणा का शीर्षक दर्ज करें...';

  @override
  String get announcementContentHint => 'खबर क्या है?';

  @override
  String get announcementSourceHint =>
      'जानकारी का लिंक या स्रोत प्रदान करें...';

  @override
  String get createRequest => 'मदद का अनुरोध बनाएं';

  @override
  String get requestTitleHint => 'शीर्षक (जैसे, टपकता हुआ नल)';

  @override
  String get requestDescriptionHint =>
      'अपनी समस्या का विस्तार से वर्णन करें...';

  @override
  String get createEvent => 'कार्यक्रम बनाएं';

  @override
  String get eventTitleHint => 'कार्यक्रम का शीर्षक (जैसे, पार्क की सफाई)';

  @override
  String get eventDescriptionHint => 'बताएं कि क्या हो रहा है...';

  @override
  String get locationNameHint => 'स्थान का नाम (जैसे, सेंट्रल पार्क)';

  @override
  String get peopleAttended => 'लोग शामिल हुए';

  @override
  String get peopleAttending => 'लोग शामिल हो रहे हैं';

  @override
  String get fieldRequired => 'यह फ़ील्ड आवश्यक है';

  @override
  String get pollCreationIntro => 'स्थानीय पहलों पर सामुदायिक इनपुट लें।';

  @override
  String get maxOptionsAllowed => 'अधिकतम 5 विकल्पों की अनुमति है';

  @override
  String get pollCreatedSuccessfully => 'पोल सफलतापूर्वक बनाया गया!';

  @override
  String get failedToCreatePoll => 'पोल बनाने में विफल';

  @override
  String get categoryAll => 'सभी';

  @override
  String get categoryRecommended => 'अनुशंसित';

  @override
  String get categoryTechSupport => 'तकनीकी सहायता';

  @override
  String get categoryHousehold => 'घरेलू';

  @override
  String get categoryEmergency => 'आपातकालीन';

  @override
  String get categoryEducation => 'शिक्षा';

  @override
  String get categoryGeneral => 'सामान्य';

  @override
  String get bestMatch => 'सबसे अच्छा मैच';

  @override
  String get goodMatch => 'अच्छा मैच';

  @override
  String get match => 'मैच';

  @override
  String get description => 'विवरण';

  @override
  String get communityHelpers => 'सामुदायिक सहायक';

  @override
  String get viewAll => 'सभी देखें';

  @override
  String get nearbyMembersHelp => 'आस-पास के सदस्य जो मदद कर सकते हैं।';

  @override
  String get requester => 'अनुरोधकर्ता';

  @override
  String get approximateLocation => 'अनुमानित स्थान';

  @override
  String get applicationAccepted => 'आवेदन स्वीकार कर लिया गया!';

  @override
  String get interestSent => 'रुचि भेजी गई (लंबित)';

  @override
  String get taskCompleted => 'कार्य पूर्ण!';

  @override
  String earnedPoints(int count) {
    return 'मदद करने के लिए आपने $count अंक अर्जित किए।';
  }

  @override
  String get noHelpersYet => 'अभी तक कोई सहायक उपलब्ध नहीं है';

  @override
  String get beTheFirstHelper =>
      'समुदाय में शामिल होने वाले पहले व्यक्ति बनें!';

  @override
  String get communicateWithRequester =>
      'अब आप अनुरोधकर्ता के साथ संवाद कर सकते हैं।';

  @override
  String get chatWithRequester => 'अनुरोधकर्ता के साथ चैट करें';

  @override
  String get imInterested => 'मुझे रुचि है';

  @override
  String get requestNoLongerOpen => 'यह अनुरोध अब आवेदनों के लिए खुला नहीं है।';

  @override
  String get yourRequest => 'यह आपका अनुरोध है';

  @override
  String get interestShown => 'अभी तक कोई रुचि नहीं दिखाई गई है।';

  @override
  String helpsCount(int count) {
    return '$count मदद';
  }

  @override
  String get enjoyingApp => 'Civic Net पसंद आ रहा है?';

  @override
  String get feedbackDescription =>
      'आपकी प्रतिक्रिया हमारे लिए अमूल्य है। क्या आप अपने विचार साझा करना चाहेंगे या सुधार सुझाना चाहेंगे?';

  @override
  String get maybeLater => 'बाद में';

  @override
  String get giveFeedback => 'प्रतिक्रिया दें';

  @override
  String get locationPermissionTitle => 'स्थान सक्षम करें';

  @override
  String get locationPermissionDesc =>
      'आपको अपने आस-पास के सटीक सहायता अनुरोध और मैच दिखाने के लिए, Civic Net को आपके स्थान तक पहुँच की आवश्यकता है।';

  @override
  String get communityEvent => 'सामुदायिक कार्यक्रम';

  @override
  String get aboutThisEvent => 'इस कार्यक्रम के बारे में';

  @override
  String get organizer => 'आयोजक';

  @override
  String get communityMember => 'सामुदायिक सदस्य';

  @override
  String get comments => 'टिप्पणियाँ';

  @override
  String itemsCount(int count) {
    return '$count आइटम';
  }

  @override
  String get writeReply => 'जवाब लिखें...';

  @override
  String get askSomething => 'कुछ पूछें...';

  @override
  String get onlyAttendingCanChat =>
      'केवल इस कार्यक्रम में शामिल होने वाले लोग ही संदेश भेज सकते हैं।';

  @override
  String get noCommentsBeFirst =>
      'अभी तक कोई टिप्पणी नहीं। पूछने वाले पहले व्यक्ति बनें!';

  @override
  String get deleteEvent => 'कार्यक्रम हटाएं';

  @override
  String get deleteEventConfirm =>
      'क्या आप वाकई इस कार्यक्रम को हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती।';

  @override
  String get eventDeletedSuccess => 'कार्यक्रम सफलतापूर्वक हटा दिया गया';

  @override
  String get host => 'होस्ट';

  @override
  String get reply => 'जवाब दें';

  @override
  String get replyingTo => 'को जवाब दे रहे हैं ';

  @override
  String get tapToSeeOnMap => 'मैप पर देखने के लिए टैप करें';

  @override
  String get locationSelectedOnMap => 'मैप पर स्थान चुना गया';

  @override
  String get eventPostedSuccess => 'कार्यक्रम सफलतापूर्वक पोस्ट किया गया!';

  @override
  String get eventPostedError =>
      'कार्यक्रम पोस्ट करने में विफल। कृपया फिर से प्रयास करें।';

  @override
  String get postAnEventTitle => 'एक कार्यक्रम पोस्ट करें';

  @override
  String get eventDetails => 'कार्यक्रम का विवरण';

  @override
  String get required => 'आवश्यक';

  @override
  String get whenAndWhere => 'कब और कहाँ';

  @override
  String get dateLabel => 'तारीख';

  @override
  String get timeLabel => 'समय';

  @override
  String get selectLocationOnMap => 'मैप पर सटीक स्थान चुनें';

  @override
  String get changeLocationOnMap => 'मैप पर स्थान बदलें';

  @override
  String selectedLocation(String lat, String lng) {
    return 'चुना गया: $lat, $lng';
  }

  @override
  String get locationPermissionRequired => 'स्थान अनुमति आवश्यक है।';

  @override
  String get gpsDisabled => 'GPS बंद है। कृपया इसे सक्षम करें।';

  @override
  String locationFetchFailed(String error) {
    return 'स्थान प्राप्त करना विफल रहा: $error';
  }

  @override
  String get preciseLocationFetchFailed =>
      'आपका सटीक स्थान प्राप्त नहीं किया जा सका।';

  @override
  String get locationNotFoundDefault =>
      'आपका स्थान नहीं मिल सका। भारत को डिफ़ॉल्ट मान रहे हैं।';

  @override
  String get selectLocationTitle => 'स्थान चुनें';

  @override
  String get confirmAllCaps => 'पुष्टि करें';

  @override
  String get tapOnMapToSelectLocation =>
      'मैप पर टैप करके अपने कार्यक्रम के लिए सटीक स्थान चुनें।';

  @override
  String get confirmLocation => 'स्थान की पुष्टि करें';

  @override
  String get beta => 'बीटा';
}
