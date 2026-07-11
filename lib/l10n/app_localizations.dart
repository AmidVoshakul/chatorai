import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_zh.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('ja'),
    Locale('ru'),
    Locale('uk'),
    Locale('zh')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'ChatORAI'**
  String get appName;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @providerConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Provider Configuration'**
  String get providerConfiguration;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// No description provided for @enterApiKey.
  ///
  /// In en, this message translates to:
  /// **'Enter your OpenRouter API Key'**
  String get enterApiKey;

  /// No description provided for @baseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get baseUrl;

  /// No description provided for @validateApiKey.
  ///
  /// In en, this message translates to:
  /// **'Validate API Key'**
  String get validateApiKey;

  /// No description provided for @apiKeyValid.
  ///
  /// In en, this message translates to:
  /// **'API Key is valid'**
  String get apiKeyValid;

  /// No description provided for @apiKeyInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid API Key format'**
  String get apiKeyInvalid;

  /// No description provided for @apiKeyEmpty.
  ///
  /// In en, this message translates to:
  /// **'API key cannot be empty'**
  String get apiKeyEmpty;

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

  /// No description provided for @useSystemTheme.
  ///
  /// In en, this message translates to:
  /// **'Use system theme'**
  String get useSystemTheme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @useLightTheme.
  ///
  /// In en, this message translates to:
  /// **'Use light theme'**
  String get useLightTheme;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @useDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme'**
  String get useDarkTheme;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSize;

  /// No description provided for @currentSize.
  ///
  /// In en, this message translates to:
  /// **'Current size: {percentage}%'**
  String currentSize(Object percentage);

  /// No description provided for @accessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibility;

  /// No description provided for @reduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get reduceMotion;

  /// No description provided for @disableAnimation.
  ///
  /// In en, this message translates to:
  /// **'Disable or reduce motion effects'**
  String get disableAnimation;

  /// No description provided for @highContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get highContrast;

  /// No description provided for @increaseContrast.
  ///
  /// In en, this message translates to:
  /// **'Increase contrast for better readability'**
  String get increaseContrast;

  /// No description provided for @wideScreenMode.
  ///
  /// In en, this message translates to:
  /// **'Wide screen mode'**
  String get wideScreenMode;

  /// No description provided for @useFullScreenWidth.
  ///
  /// In en, this message translates to:
  /// **'Use full screen width for chat content'**
  String get useFullScreenWidth;

  /// No description provided for @autoScrollDuringStreaming.
  ///
  /// In en, this message translates to:
  /// **'Auto-scroll during streaming'**
  String get autoScrollDuringStreaming;

  /// No description provided for @autoScrollDuringStreamingDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically scroll down when new content appears'**
  String get autoScrollDuringStreamingDesc;

  /// No description provided for @showContinuationSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Show continuation suggestions'**
  String get showContinuationSuggestions;

  /// No description provided for @showContinuationSuggestionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Display suggested follow-up messages after AI responses'**
  String get showContinuationSuggestionsDesc;

  /// No description provided for @expandReasoningByDefault.
  ///
  /// In en, this message translates to:
  /// **'Expand reasoning by default'**
  String get expandReasoningByDefault;

  /// No description provided for @expandReasoningByDefaultDesc.
  ///
  /// In en, this message translates to:
  /// **'Show reasoning/thought blocks expanded when AI responds'**
  String get expandReasoningByDefaultDesc;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// No description provided for @ukrainian.
  ///
  /// In en, this message translates to:
  /// **'Ukrainian'**
  String get ukrainian;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic (right-to-left)'**
  String get arabic;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get chinese;

  /// No description provided for @japanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get japanese;

  /// No description provided for @resetSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset settings'**
  String get resetSettings;

  /// No description provided for @resetAllSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset all settings to defaults'**
  String get resetAllSettings;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @apiKeyCopied.
  ///
  /// In en, this message translates to:
  /// **'API key copied'**
  String get apiKeyCopied;

  /// No description provided for @apiKeySaved.
  ///
  /// In en, this message translates to:
  /// **'API key saved'**
  String get apiKeySaved;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @settingsReset.
  ///
  /// In en, this message translates to:
  /// **'Settings reset'**
  String get settingsReset;

  /// No description provided for @appInfo.
  ///
  /// In en, this message translates to:
  /// **'App Info'**
  String get appInfo;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'AI Chat Application powered by multiple LLM providers'**
  String get appDescription;

  /// No description provided for @shareChat.
  ///
  /// In en, this message translates to:
  /// **'Share Chat'**
  String get shareChat;

  /// No description provided for @copyChat.
  ///
  /// In en, this message translates to:
  /// **'Copy Chat'**
  String get copyChat;

  /// No description provided for @renameChat.
  ///
  /// In en, this message translates to:
  /// **'Rename Chat'**
  String get renameChat;

  /// No description provided for @failedToShowMenu.
  ///
  /// In en, this message translates to:
  /// **'Failed to show menu'**
  String get failedToShowMenu;

  /// No description provided for @failedToRenameChat.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename chat'**
  String get failedToRenameChat;

  /// No description provided for @failedToCopyChat.
  ///
  /// In en, this message translates to:
  /// **'Failed to copy chat'**
  String get failedToCopyChat;

  /// No description provided for @chatSharingNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Chat sharing not implemented'**
  String get chatSharingNotImplemented;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// No description provided for @noChatsYet.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get noChatsYet;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get startConversation;

  /// No description provided for @reasoning.
  ///
  /// In en, this message translates to:
  /// **'Reasoning'**
  String get reasoning;

  /// No description provided for @tapToExpand.
  ///
  /// In en, this message translates to:
  /// **'Tap to expand'**
  String get tapToExpand;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// No description provided for @chatRenamedTo.
  ///
  /// In en, this message translates to:
  /// **'Chat renamed to {name}'**
  String chatRenamedTo(Object name);

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ChatORAI'**
  String get appTitle;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String minAgo(Object minutes);

  /// No description provided for @onlyOneMinuteAgo.
  ///
  /// In en, this message translates to:
  /// **'1 minute ago'**
  String get onlyOneMinuteAgo;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String hoursAgo(Object hours);

  /// No description provided for @onlyOneHourAgo.
  ///
  /// In en, this message translates to:
  /// **'1 hour ago'**
  String get onlyOneHourAgo;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgo(Object days);

  /// No description provided for @onlyOneDayAgo.
  ///
  /// In en, this message translates to:
  /// **'1 day ago'**
  String get onlyOneDayAgo;

  /// No description provided for @renameChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Chat'**
  String get renameChatTitle;

  /// No description provided for @enterNewChatName.
  ///
  /// In en, this message translates to:
  /// **'Enter new chat name'**
  String get enterNewChatName;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @modelSelected.
  ///
  /// In en, this message translates to:
  /// **'Model selected'**
  String get modelSelected;

  /// No description provided for @errorLoadingModels.
  ///
  /// In en, this message translates to:
  /// **'Error loading models'**
  String get errorLoadingModels;

  /// No description provided for @models.
  ///
  /// In en, this message translates to:
  /// **'Models'**
  String get models;

  /// No description provided for @searchModels.
  ///
  /// In en, this message translates to:
  /// **'Search models'**
  String get searchModels;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @context.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get context;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @multimodal.
  ///
  /// In en, this message translates to:
  /// **'Multimodal'**
  String get multimodal;

  /// No description provided for @vision.
  ///
  /// In en, this message translates to:
  /// **'Vision'**
  String get vision;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @technicalDetails.
  ///
  /// In en, this message translates to:
  /// **'Technical Details'**
  String get technicalDetails;

  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// No description provided for @inputTokens.
  ///
  /// In en, this message translates to:
  /// **'Input Tokens'**
  String get inputTokens;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @outputTokens.
  ///
  /// In en, this message translates to:
  /// **'Output Tokens'**
  String get outputTokens;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// No description provided for @featuresDisplayedBasedOnActualModelCapabilities.
  ///
  /// In en, this message translates to:
  /// **'Features displayed based on actual model capabilities'**
  String get featuresDisplayedBasedOnActualModelCapabilities;

  /// No description provided for @noModelsFound.
  ///
  /// In en, this message translates to:
  /// **'No models found'**
  String get noModelsFound;

  /// No description provided for @noAvailableModels.
  ///
  /// In en, this message translates to:
  /// **'No available models'**
  String get noAvailableModels;

  /// No description provided for @tryADifferentSearchQuery.
  ///
  /// In en, this message translates to:
  /// **'Try a different search query'**
  String get tryADifferentSearchQuery;

  /// No description provided for @tryRefreshingOrCheckYourInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'Try refreshing or check your internet connection'**
  String get tryRefreshingOrCheckYourInternetConnection;

  /// No description provided for @aiIsTyping.
  ///
  /// In en, this message translates to:
  /// **'AI is typing'**
  String get aiIsTyping;

  /// No description provided for @loadingMsg1.
  ///
  /// In en, this message translates to:
  /// **'Waiting for server response…'**
  String get loadingMsg1;

  /// No description provided for @loadingMsg2.
  ///
  /// In en, this message translates to:
  /// **'Data sent — almost there…'**
  String get loadingMsg2;

  /// No description provided for @loadingMsg3.
  ///
  /// In en, this message translates to:
  /// **'Formulating thoughts…'**
  String get loadingMsg3;

  /// No description provided for @loadingMsg4.
  ///
  /// In en, this message translates to:
  /// **'Finding the best answer…'**
  String get loadingMsg4;

  /// No description provided for @loadingMsg5.
  ///
  /// In en, this message translates to:
  /// **'Loading response (almost)…'**
  String get loadingMsg5;

  /// No description provided for @failedToSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String get failedToSendMessage;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @enterYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter your message'**
  String get enterYourMessage;

  /// No description provided for @saveAndSend.
  ///
  /// In en, this message translates to:
  /// **'Save and send'**
  String get saveAndSend;

  /// No description provided for @messageEditedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Message edited successfully'**
  String get messageEditedSuccessfully;

  /// No description provided for @failedToEditMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to edit message'**
  String get failedToEditMessage;

  /// No description provided for @messageEditedAndResponseRegenerated.
  ///
  /// In en, this message translates to:
  /// **'Message edited and response regenerated'**
  String get messageEditedAndResponseRegenerated;

  /// No description provided for @failedToEditAndSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to edit and send message'**
  String get failedToEditAndSendMessage;

  /// No description provided for @areYouSureYouWantToDeleteThisMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message?'**
  String get areYouSureYouWantToDeleteThisMessage;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Confirm delete message'**
  String confirmDeleteMessage(Object chatTitle);

  /// No description provided for @areYouSureYouWantToRegenerateThisMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to regenerate this message?'**
  String get areYouSureYouWantToRegenerateThisMessage;

  /// No description provided for @modelDoesNotSupportImages.
  ///
  /// In en, this message translates to:
  /// **'Model does not support images'**
  String modelDoesNotSupportImages(Object modelId);

  /// No description provided for @chatTitleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Chat title updated'**
  String chatTitleUpdated(Object title);

  /// No description provided for @messageDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Message deleted successfully'**
  String get messageDeletedSuccessfully;

  /// No description provided for @failedToDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete message'**
  String get failedToDeleteMessage;

  /// No description provided for @regenerationStarted.
  ///
  /// In en, this message translates to:
  /// **'Regeneration started'**
  String get regenerationStarted;

  /// No description provided for @failedToRegenerateMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to regenerate message'**
  String get failedToRegenerateMessage;

  /// No description provided for @messageCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied'**
  String get messageCopied;

  /// No description provided for @failedToCopyMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to copy message'**
  String get failedToCopyMessage;

  /// No description provided for @messageShared.
  ///
  /// In en, this message translates to:
  /// **'Message shared'**
  String get messageShared;

  /// No description provided for @failedToShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to share message'**
  String get failedToShareMessage;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copyMessage.
  ///
  /// In en, this message translates to:
  /// **'Copy message'**
  String get copyMessage;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listen;

  /// No description provided for @regenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerate;

  /// No description provided for @continueResponse.
  ///
  /// In en, this message translates to:
  /// **'Continue response'**
  String get continueResponse;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @dislike.
  ///
  /// In en, this message translates to:
  /// **'Dislike'**
  String get dislike;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @failedToCopy.
  ///
  /// In en, this message translates to:
  /// **'Failed to copy'**
  String get failedToCopy;

  /// No description provided for @messageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get messageDeleted;

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error message'**
  String get errorMessage;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to ChatORAI'**
  String get welcomeMessage;

  /// No description provided for @welcomeQuestion1.
  ///
  /// In en, this message translates to:
  /// **'Explain quantum computing in simple terms'**
  String get welcomeQuestion1;

  /// No description provided for @welcomeQuestion2.
  ///
  /// In en, this message translates to:
  /// **'What are the latest trends in artificial intelligence?'**
  String get welcomeQuestion2;

  /// No description provided for @welcomeQuestion3.
  ///
  /// In en, this message translates to:
  /// **'Help me write a professional email to my team'**
  String get welcomeQuestion3;

  /// No description provided for @welcomeQuestion4.
  ///
  /// In en, this message translates to:
  /// **'What should I learn to become a better programmer?'**
  String get welcomeQuestion4;

  /// No description provided for @welcomeQuestion5.
  ///
  /// In en, this message translates to:
  /// **'Give me 5 creative ideas for a weekend project'**
  String get welcomeQuestion5;

  /// No description provided for @welcomeQuestion6.
  ///
  /// In en, this message translates to:
  /// **'What are some good books on personal growth?'**
  String get welcomeQuestion6;

  /// No description provided for @welcomeQuestion7.
  ///
  /// In en, this message translates to:
  /// **'Help me come up with names for my startup'**
  String get welcomeQuestion7;

  /// No description provided for @welcomeQuestion8.
  ///
  /// In en, this message translates to:
  /// **'Create a meal plan for a healthy week'**
  String get welcomeQuestion8;

  /// No description provided for @welcomeQuestion9.
  ///
  /// In en, this message translates to:
  /// **'What are the best practices for Flutter development?'**
  String get welcomeQuestion9;

  /// No description provided for @welcomeQuestion10.
  ///
  /// In en, this message translates to:
  /// **'Explain the difference between asynchronous and synchronous programming'**
  String get welcomeQuestion10;

  /// No description provided for @welcomeQuestion11.
  ///
  /// In en, this message translates to:
  /// **'How to optimize code for better performance?'**
  String get welcomeQuestion11;

  /// No description provided for @welcomeQuestion12.
  ///
  /// In en, this message translates to:
  /// **'What are the most useful design patterns?'**
  String get welcomeQuestion12;

  /// No description provided for @welcomeQuestion13.
  ///
  /// In en, this message translates to:
  /// **'Teach me the basics of machine learning'**
  String get welcomeQuestion13;

  /// No description provided for @welcomeQuestion14.
  ///
  /// In en, this message translates to:
  /// **'What are the key concepts of cloud computing?'**
  String get welcomeQuestion14;

  /// No description provided for @welcomeQuestion15.
  ///
  /// In en, this message translates to:
  /// **'Explain blockchain technology for a beginner'**
  String get welcomeQuestion15;

  /// No description provided for @welcomeQuestion16.
  ///
  /// In en, this message translates to:
  /// **'How does the internet work from a technical perspective?'**
  String get welcomeQuestion16;

  /// No description provided for @welcomeQuestion17.
  ///
  /// In en, this message translates to:
  /// **'What are the best productivity techniques?'**
  String get welcomeQuestion17;

  /// No description provided for @welcomeQuestion18.
  ///
  /// In en, this message translates to:
  /// **'How to improve concentration and focus?'**
  String get welcomeQuestion18;

  /// No description provided for @welcomeQuestion19.
  ///
  /// In en, this message translates to:
  /// **'Give me a daily schedule for maximum productivity'**
  String get welcomeQuestion19;

  /// No description provided for @welcomeQuestion20.
  ///
  /// In en, this message translates to:
  /// **'What are some good habits for success?'**
  String get welcomeQuestion20;

  /// No description provided for @welcomeQuestion21.
  ///
  /// In en, this message translates to:
  /// **'How to prepare for an IT interview?'**
  String get welcomeQuestion21;

  /// No description provided for @welcomeQuestion22.
  ///
  /// In en, this message translates to:
  /// **'What skills are needed in the tech industry?'**
  String get welcomeQuestion22;

  /// No description provided for @welcomeQuestion23.
  ///
  /// In en, this message translates to:
  /// **'How to negotiate a salary increase?'**
  String get welcomeQuestion23;

  /// No description provided for @welcomeQuestion24.
  ///
  /// In en, this message translates to:
  /// **'What are the top tech companies to work for?'**
  String get welcomeQuestion24;

  /// No description provided for @welcomeQuestion25.
  ///
  /// In en, this message translates to:
  /// **'What are the latest breakthroughs in space research?'**
  String get welcomeQuestion25;

  /// No description provided for @welcomeQuestion26.
  ///
  /// In en, this message translates to:
  /// **'How is AI changing healthcare?'**
  String get welcomeQuestion26;

  /// No description provided for @welcomeQuestion27.
  ///
  /// In en, this message translates to:
  /// **'What are the most exciting technologies of 2025?'**
  String get welcomeQuestion27;

  /// No description provided for @welcomeQuestion28.
  ///
  /// In en, this message translates to:
  /// **'Explain the future of renewable energy'**
  String get welcomeQuestion28;

  /// No description provided for @welcomeQuestion29.
  ///
  /// In en, this message translates to:
  /// **'What are the most important philosophical questions?'**
  String get welcomeQuestion29;

  /// No description provided for @welcomeQuestion30.
  ///
  /// In en, this message translates to:
  /// **'How to learn to think more critically?'**
  String get welcomeQuestion30;

  /// No description provided for @welcomeQuestion31.
  ///
  /// In en, this message translates to:
  /// **'What are the best ways to learn new skills?'**
  String get welcomeQuestion31;

  /// No description provided for @welcomeQuestion32.
  ///
  /// In en, this message translates to:
  /// **'How to stay motivated when learning complex material?'**
  String get welcomeQuestion32;

  /// No description provided for @welcomeQuestion33.
  ///
  /// In en, this message translates to:
  /// **'Which programming languages are best to learn in 2025?'**
  String get welcomeQuestion33;

  /// No description provided for @welcomeQuestion34.
  ///
  /// In en, this message translates to:
  /// **'How to create a strong portfolio for IT jobs?'**
  String get welcomeQuestion34;

  /// No description provided for @welcomeQuestion35.
  ///
  /// In en, this message translates to:
  /// **'What are the top AI tools for productivity?'**
  String get welcomeQuestion35;

  /// No description provided for @welcomeQuestion36.
  ///
  /// In en, this message translates to:
  /// **'How does machine learning actually work?'**
  String get welcomeQuestion36;

  /// No description provided for @welcomeQuestion37.
  ///
  /// In en, this message translates to:
  /// **'What are the best practices for code review?'**
  String get welcomeQuestion37;

  /// No description provided for @welcomeQuestion38.
  ///
  /// In en, this message translates to:
  /// **'How to write clean and maintainable code?'**
  String get welcomeQuestion38;

  /// No description provided for @welcomeQuestion39.
  ///
  /// In en, this message translates to:
  /// **'What are microservices and when to use them?'**
  String get welcomeQuestion39;

  /// No description provided for @welcomeQuestion40.
  ///
  /// In en, this message translates to:
  /// **'Explain the difference between REST API and GraphQL'**
  String get welcomeQuestion40;

  /// No description provided for @welcomeQuestion41.
  ///
  /// In en, this message translates to:
  /// **'Which cloud platforms are best to learn?'**
  String get welcomeQuestion41;

  /// No description provided for @welcomeQuestion42.
  ///
  /// In en, this message translates to:
  /// **'How to prepare for technical interviews?'**
  String get welcomeQuestion42;

  /// No description provided for @welcomeQuestion43.
  ///
  /// In en, this message translates to:
  /// **'What soft skills does every developer need?'**
  String get welcomeQuestion43;

  /// No description provided for @welcomeQuestion44.
  ///
  /// In en, this message translates to:
  /// **'How to negotiate a developer\'s salary?'**
  String get welcomeQuestion44;

  /// No description provided for @welcomeQuestion45.
  ///
  /// In en, this message translates to:
  /// **'What are the best tools for remote work?'**
  String get welcomeQuestion45;

  /// No description provided for @welcomeQuestion46.
  ///
  /// In en, this message translates to:
  /// **'How to stay productive while working remotely?'**
  String get welcomeQuestion46;

  /// No description provided for @welcomeQuestion47.
  ///
  /// In en, this message translates to:
  /// **'What are the best project management methodologies?'**
  String get welcomeQuestion47;

  /// No description provided for @welcomeQuestion48.
  ///
  /// In en, this message translates to:
  /// **'How to work with difficult colleagues?'**
  String get welcomeQuestion48;

  /// No description provided for @welcomeQuestion49.
  ///
  /// In en, this message translates to:
  /// **'What are the best books on leadership?'**
  String get welcomeQuestion49;

  /// No description provided for @welcomeQuestion50.
  ///
  /// In en, this message translates to:
  /// **'How to launch a successful tech startup?'**
  String get welcomeQuestion50;

  /// No description provided for @welcomeQuestion51.
  ///
  /// In en, this message translates to:
  /// **'What are the latest trends in web development?'**
  String get welcomeQuestion51;

  /// No description provided for @welcomeQuestion52.
  ///
  /// In en, this message translates to:
  /// **'How does blockchain technology work?'**
  String get welcomeQuestion52;

  /// No description provided for @welcomeQuestion53.
  ///
  /// In en, this message translates to:
  /// **'What are NFTs and are they worth paying attention to?'**
  String get welcomeQuestion53;

  /// No description provided for @welcomeQuestion54.
  ///
  /// In en, this message translates to:
  /// **'Explain the concept of the metaverse'**
  String get welcomeQuestion54;

  /// No description provided for @welcomeQuestion55.
  ///
  /// In en, this message translates to:
  /// **'What are the best AI models for programming?'**
  String get welcomeQuestion55;

  /// No description provided for @welcomeQuestion56.
  ///
  /// In en, this message translates to:
  /// **'How to use ChatGPT effectively?'**
  String get welcomeQuestion56;

  /// No description provided for @welcomeQuestion57.
  ///
  /// In en, this message translates to:
  /// **'What are the ethical aspects of AI to consider?'**
  String get welcomeQuestion57;

  /// No description provided for @welcomeQuestion58.
  ///
  /// In en, this message translates to:
  /// **'How will AI change work in the future?'**
  String get welcomeQuestion58;

  /// No description provided for @welcomeQuestion59.
  ///
  /// In en, this message translates to:
  /// **'What are the best cybersecurity practices?'**
  String get welcomeQuestion59;

  /// No description provided for @welcomeQuestion60.
  ///
  /// In en, this message translates to:
  /// **'How to protect your privacy online?'**
  String get welcomeQuestion60;

  /// No description provided for @welcomeQuestion61.
  ///
  /// In en, this message translates to:
  /// **'What are the best data science tools?'**
  String get welcomeQuestion61;

  /// No description provided for @welcomeQuestion62.
  ///
  /// In en, this message translates to:
  /// **'How to visualize data effectively?'**
  String get welcomeQuestion62;

  /// No description provided for @welcomeQuestion63.
  ///
  /// In en, this message translates to:
  /// **'What are the best frameworks for mobile apps?'**
  String get welcomeQuestion63;

  /// No description provided for @welcomeQuestion64.
  ///
  /// In en, this message translates to:
  /// **'How to build cross-platform applications?'**
  String get welcomeQuestion64;

  /// No description provided for @welcomeQuestion65.
  ///
  /// In en, this message translates to:
  /// **'What are the best game development engines?'**
  String get welcomeQuestion65;

  /// No description provided for @welcomeQuestion66.
  ///
  /// In en, this message translates to:
  /// **'How to start working with 3D modeling?'**
  String get welcomeQuestion66;

  /// No description provided for @welcomeQuestion67.
  ///
  /// In en, this message translates to:
  /// **'What are the best video editing tools?'**
  String get welcomeQuestion67;

  /// No description provided for @welcomeQuestion68.
  ///
  /// In en, this message translates to:
  /// **'How to create engaging content?'**
  String get welcomeQuestion68;

  /// No description provided for @welcomeQuestion69.
  ///
  /// In en, this message translates to:
  /// **'What are the best social media strategies?'**
  String get welcomeQuestion69;

  /// No description provided for @welcomeQuestion70.
  ///
  /// In en, this message translates to:
  /// **'How to build a personal brand?'**
  String get welcomeQuestion70;

  /// No description provided for @welcomeQuestion71.
  ///
  /// In en, this message translates to:
  /// **'What are the best networking tips?'**
  String get welcomeQuestion71;

  /// No description provided for @welcomeQuestion72.
  ///
  /// In en, this message translates to:
  /// **'How to make a great presentation?'**
  String get welcomeQuestion72;

  /// No description provided for @welcomeQuestion73.
  ///
  /// In en, this message translates to:
  /// **'What are the best time management techniques?'**
  String get welcomeQuestion73;

  /// No description provided for @welcomeQuestion74.
  ///
  /// In en, this message translates to:
  /// **'How to avoid burnout?'**
  String get welcomeQuestion74;

  /// No description provided for @welcomeQuestion75.
  ///
  /// In en, this message translates to:
  /// **'What are the best meditation apps?'**
  String get welcomeQuestion75;

  /// No description provided for @welcomeQuestion76.
  ///
  /// In en, this message translates to:
  /// **'How to improve sleep quality?'**
  String get welcomeQuestion76;

  /// No description provided for @welcomeQuestion77.
  ///
  /// In en, this message translates to:
  /// **'What are the best workouts?'**
  String get welcomeQuestion77;

  /// No description provided for @welcomeQuestion78.
  ///
  /// In en, this message translates to:
  /// **'How to eat healthy on a limited budget?'**
  String get welcomeQuestion78;

  /// No description provided for @welcomeQuestion79.
  ///
  /// In en, this message translates to:
  /// **'What are the best travel destinations for tech specialists?'**
  String get welcomeQuestion79;

  /// No description provided for @welcomeQuestion80.
  ///
  /// In en, this message translates to:
  /// **'How to learn a new language quickly?'**
  String get welcomeQuestion80;

  /// No description provided for @welcomeQuestion81.
  ///
  /// In en, this message translates to:
  /// **'What are the best practices for remote team collaboration?'**
  String get welcomeQuestion81;

  /// No description provided for @welcomeQuestion82.
  ///
  /// In en, this message translates to:
  /// **'How to conduct effective code reviews?'**
  String get welcomeQuestion82;

  /// No description provided for @welcomeQuestion83.
  ///
  /// In en, this message translates to:
  /// **'What are the top skills for software architects?'**
  String get welcomeQuestion83;

  /// No description provided for @welcomeQuestion84.
  ///
  /// In en, this message translates to:
  /// **'How to design scalable databases?'**
  String get welcomeQuestion84;

  /// No description provided for @welcomeQuestion85.
  ///
  /// In en, this message translates to:
  /// **'What are the best DevOps tools to learn?'**
  String get welcomeQuestion85;

  /// No description provided for @welcomeQuestion86.
  ///
  /// In en, this message translates to:
  /// **'How to implement CI/CD pipelines?'**
  String get welcomeQuestion86;

  /// No description provided for @welcomeQuestion87.
  ///
  /// In en, this message translates to:
  /// **'What is container orchestration?'**
  String get welcomeQuestion87;

  /// No description provided for @welcomeQuestion88.
  ///
  /// In en, this message translates to:
  /// **'Explain the benefits of serverless computing'**
  String get welcomeQuestion88;

  /// No description provided for @welcomeQuestion89.
  ///
  /// In en, this message translates to:
  /// **'What are the best API security practices?'**
  String get welcomeQuestion89;

  /// No description provided for @welcomeQuestion90.
  ///
  /// In en, this message translates to:
  /// **'How to optimize mobile app performance?'**
  String get welcomeQuestion90;

  /// No description provided for @welcomeQuestion91.
  ///
  /// In en, this message translates to:
  /// **'What are progressive web apps?'**
  String get welcomeQuestion91;

  /// No description provided for @welcomeQuestion92.
  ///
  /// In en, this message translates to:
  /// **'How to create accessible web applications?'**
  String get welcomeQuestion92;

  /// No description provided for @welcomeQuestion93.
  ///
  /// In en, this message translates to:
  /// **'What are the best UI/UX design principles?'**
  String get welcomeQuestion93;

  /// No description provided for @welcomeQuestion94.
  ///
  /// In en, this message translates to:
  /// **'How to conduct effective user research?'**
  String get welcomeQuestion94;

  /// No description provided for @welcomeQuestion95.
  ///
  /// In en, this message translates to:
  /// **'What are the best A/B testing strategies?'**
  String get welcomeQuestion95;

  /// No description provided for @welcomeQuestion96.
  ///
  /// In en, this message translates to:
  /// **'How to analyze user behavior?'**
  String get welcomeQuestion96;

  /// No description provided for @welcomeQuestion97.
  ///
  /// In en, this message translates to:
  /// **'What are the best growth hacking techniques?'**
  String get welcomeQuestion97;

  /// No description provided for @welcomeQuestion98.
  ///
  /// In en, this message translates to:
  /// **'How to build a community around a product?'**
  String get welcomeQuestion98;

  /// No description provided for @welcomeQuestion99.
  ///
  /// In en, this message translates to:
  /// **'What are the best customer support tools?'**
  String get welcomeQuestion99;

  /// No description provided for @welcomeQuestion100.
  ///
  /// In en, this message translates to:
  /// **'How to effectively handle customer feedback?'**
  String get welcomeQuestion100;

  /// No description provided for @welcomeQuestion101.
  ///
  /// In en, this message translates to:
  /// **'What is the difference between React and Vue?'**
  String get welcomeQuestion101;

  /// No description provided for @welcomeQuestion102.
  ///
  /// In en, this message translates to:
  /// **'How does TypeScript improve JavaScript development?'**
  String get welcomeQuestion102;

  /// No description provided for @welcomeQuestion103.
  ///
  /// In en, this message translates to:
  /// **'What are the best practices for REST API design?'**
  String get welcomeQuestion103;

  /// No description provided for @welcomeQuestion104.
  ///
  /// In en, this message translates to:
  /// **'How to implement authentication in web apps?'**
  String get welcomeQuestion104;

  /// No description provided for @welcomeQuestion105.
  ///
  /// In en, this message translates to:
  /// **'What are the advantages of GraphQL over REST?'**
  String get welcomeQuestion105;

  /// No description provided for @welcomeQuestion106.
  ///
  /// In en, this message translates to:
  /// **'How to optimize database queries for performance?'**
  String get welcomeQuestion106;

  /// No description provided for @welcomeQuestion107.
  ///
  /// In en, this message translates to:
  /// **'What are microservices architecture patterns?'**
  String get welcomeQuestion107;

  /// No description provided for @welcomeQuestion108.
  ///
  /// In en, this message translates to:
  /// **'How to implement caching strategies?'**
  String get welcomeQuestion108;

  /// No description provided for @welcomeQuestion109.
  ///
  /// In en, this message translates to:
  /// **'What are the best JavaScript testing frameworks?'**
  String get welcomeQuestion109;

  /// No description provided for @welcomeQuestion110.
  ///
  /// In en, this message translates to:
  /// **'How to write unit tests for React components?'**
  String get welcomeQuestion110;

  /// No description provided for @welcomeQuestion111.
  ///
  /// In en, this message translates to:
  /// **'What are the SOLID principles in OOP?'**
  String get welcomeQuestion111;

  /// No description provided for @welcomeQuestion112.
  ///
  /// In en, this message translates to:
  /// **'How to implement design patterns in Python?'**
  String get welcomeQuestion112;

  /// No description provided for @welcomeQuestion113.
  ///
  /// In en, this message translates to:
  /// **'What are the best practices for Git workflow?'**
  String get welcomeQuestion113;

  /// No description provided for @welcomeQuestion114.
  ///
  /// In en, this message translates to:
  /// **'How to effectively resolve merge conflicts?'**
  String get welcomeQuestion114;

  /// No description provided for @welcomeQuestion115.
  ///
  /// In en, this message translates to:
  /// **'What are the best practices for containerization?'**
  String get welcomeQuestion115;

  /// No description provided for @welcomeQuestion116.
  ///
  /// In en, this message translates to:
  /// **'How to secure Docker containers?'**
  String get welcomeQuestion116;

  /// No description provided for @welcomeQuestion117.
  ///
  /// In en, this message translates to:
  /// **'What are Kubernetes deployment strategies?'**
  String get welcomeQuestion117;

  /// No description provided for @welcomeQuestion118.
  ///
  /// In en, this message translates to:
  /// **'How to monitor application performance?'**
  String get welcomeQuestion118;

  /// No description provided for @welcomeQuestion119.
  ///
  /// In en, this message translates to:
  /// **'What are the best practices for logging?'**
  String get welcomeQuestion119;

  /// No description provided for @welcomeQuestion120.
  ///
  /// In en, this message translates to:
  /// **'How to implement error handling in distributed systems?'**
  String get welcomeQuestion120;

  /// No description provided for @continueConversation.
  ///
  /// In en, this message translates to:
  /// **'Continue conversation'**
  String get continueConversation;

  /// No description provided for @generatingSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Generating suggestions'**
  String get generatingSuggestions;

  /// No description provided for @searchChats.
  ///
  /// In en, this message translates to:
  /// **'Search chats'**
  String get searchChats;

  /// No description provided for @noChatsFound.
  ///
  /// In en, this message translates to:
  /// **'No chats found'**
  String noChatsFound(Object query);

  /// No description provided for @tryDifferentSearchTerm.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearchTerm;

  /// No description provided for @appShortName.
  ///
  /// In en, this message translates to:
  /// **'Chatorai'**
  String get appShortName;

  /// No description provided for @typeYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message'**
  String get typeYourMessage;

  /// No description provided for @addImage.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get addImage;

  /// No description provided for @addCamera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get addCamera;

  /// No description provided for @addFile.
  ///
  /// In en, this message translates to:
  /// **'Add file'**
  String get addFile;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get selectLanguage;

  /// No description provided for @searchFavorites.
  ///
  /// In en, this message translates to:
  /// **'Search favorites'**
  String get searchFavorites;

  /// No description provided for @showAllModels.
  ///
  /// In en, this message translates to:
  /// **'Show all models'**
  String get showAllModels;

  /// No description provided for @showFavoritesOnly.
  ///
  /// In en, this message translates to:
  /// **'Show favorites only'**
  String get showFavoritesOnly;

  /// No description provided for @noFavoriteModels.
  ///
  /// In en, this message translates to:
  /// **'No favorite models'**
  String get noFavoriteModels;

  /// No description provided for @tapHeartToAddFavorites.
  ///
  /// In en, this message translates to:
  /// **'Tap heart to add favorites'**
  String get tapHeartToAddFavorites;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @loadingSkills.
  ///
  /// In en, this message translates to:
  /// **'Loading skills'**
  String get loadingSkills;

  /// No description provided for @noSkillsInstalled.
  ///
  /// In en, this message translates to:
  /// **'No skills installed'**
  String get noSkillsInstalled;

  /// No description provided for @noSkillsMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No skills match your search'**
  String get noSkillsMatchSearch;

  /// No description provided for @allSkillsRequirePermission.
  ///
  /// In en, this message translates to:
  /// **'All skills require permission'**
  String get allSkillsRequirePermission;

  /// No description provided for @skillExecuted.
  ///
  /// In en, this message translates to:
  /// **'Skill executed'**
  String skillExecuted(Object name);

  /// No description provided for @configuration.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get configuration;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @usageStatistics.
  ///
  /// In en, this message translates to:
  /// **'Usage Statistics'**
  String get usageStatistics;

  /// No description provided for @totalSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get totalSessions;

  /// No description provided for @totalMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get totalMessages;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @totalTokens.
  ///
  /// In en, this message translates to:
  /// **'Total Tokens'**
  String get totalTokens;

  /// No description provided for @totalCost.
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get totalCost;

  /// No description provided for @avgCostPerDay.
  ///
  /// In en, this message translates to:
  /// **'Avg Cost/Day'**
  String get avgCostPerDay;

  /// No description provided for @avgTokensPerSession.
  ///
  /// In en, this message translates to:
  /// **'Avg Tokens/Session'**
  String get avgTokensPerSession;

  /// No description provided for @medianTokensPerSession.
  ///
  /// In en, this message translates to:
  /// **'Median Tokens/Session'**
  String get medianTokensPerSession;

  /// No description provided for @cacheRead.
  ///
  /// In en, this message translates to:
  /// **'Cache Read'**
  String get cacheRead;

  /// No description provided for @cacheWrite.
  ///
  /// In en, this message translates to:
  /// **'Cache Write'**
  String get cacheWrite;

  /// No description provided for @toolUsage.
  ///
  /// In en, this message translates to:
  /// **'Tool Usage'**
  String get toolUsage;

  /// No description provided for @modelUsage.
  ///
  /// In en, this message translates to:
  /// **'Model Usage'**
  String get modelUsage;

  /// No description provided for @noStatsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No statistics available'**
  String get noStatsAvailable;

  /// No description provided for @reasoningTokens.
  ///
  /// In en, this message translates to:
  /// **'Reasoning'**
  String get reasoningTokens;

  /// No description provided for @addProvider.
  ///
  /// In en, this message translates to:
  /// **'Add Provider'**
  String get addProvider;

  /// No description provided for @applySettings.
  ///
  /// In en, this message translates to:
  /// **'Apply Settings'**
  String get applySettings;

  /// No description provided for @copyCodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCodeTooltip;

  /// No description provided for @copiedFeedback.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copiedFeedback;

  /// No description provided for @defaultSuggestion1.
  ///
  /// In en, this message translates to:
  /// **'What can you do?'**
  String get defaultSuggestion1;

  /// No description provided for @defaultSuggestion2.
  ///
  /// In en, this message translates to:
  /// **'Help me write code'**
  String get defaultSuggestion2;

  /// No description provided for @defaultSuggestion3.
  ///
  /// In en, this message translates to:
  /// **'Explain a concept'**
  String get defaultSuggestion3;

  /// No description provided for @deleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete chat'**
  String get deleteChat;

  /// No description provided for @manageProviders.
  ///
  /// In en, this message translates to:
  /// **'Manage Providers'**
  String get manageProviders;

  /// No description provided for @micAutoRestart.
  ///
  /// In en, this message translates to:
  /// **'Auto-restarting microphone...'**
  String get micAutoRestart;

  /// No description provided for @micNoSpeechDetected.
  ///
  /// In en, this message translates to:
  /// **'No speech detected'**
  String get micNoSpeechDetected;

  /// No description provided for @micStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to start microphone'**
  String get micStartFailed;

  /// No description provided for @micUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Microphone not available'**
  String get micUnavailable;

  /// No description provided for @modelParameters.
  ///
  /// In en, this message translates to:
  /// **'Model Parameters'**
  String get modelParameters;

  /// No description provided for @modelSettings.
  ///
  /// In en, this message translates to:
  /// **'Model Settings'**
  String get modelSettings;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @noModelSelected.
  ///
  /// In en, this message translates to:
  /// **'No model selected'**
  String get noModelSelected;

  /// No description provided for @openaiCompatibleApi.
  ///
  /// In en, this message translates to:
  /// **'OpenAI-Compatible API'**
  String get openaiCompatibleApi;

  /// No description provided for @openaiCompatibleApiDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect to any OpenAI-compatible API endpoint'**
  String get openaiCompatibleApiDescription;

  /// No description provided for @permissionAlways.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get permissionAlways;

  /// No description provided for @permissionAlwaysConfirm.
  ///
  /// In en, this message translates to:
  /// **'Always allow this action?'**
  String get permissionAlwaysConfirm;

  /// No description provided for @permissionDialogPatterns.
  ///
  /// In en, this message translates to:
  /// **'Permission patterns'**
  String get permissionDialogPatterns;

  /// No description provided for @permissionOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get permissionOnce;

  /// No description provided for @permissionReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get permissionReject;

  /// No description provided for @providers.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get providers;

  /// No description provided for @refreshQuestions.
  ///
  /// In en, this message translates to:
  /// **'Refresh questions'**
  String get refreshQuestions;

  /// No description provided for @resetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get resetToDefaults;

  /// No description provided for @settingsApplied.
  ///
  /// In en, this message translates to:
  /// **'Settings applied'**
  String get settingsApplied;

  /// No description provided for @speechErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get speechErrorNetwork;

  /// No description provided for @speechErrorNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No speech match'**
  String get speechErrorNoMatch;

  /// No description provided for @speechErrorNotAuthorized.
  ///
  /// In en, this message translates to:
  /// **'Not authorized'**
  String get speechErrorNotAuthorized;

  /// No description provided for @speechErrorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get speechErrorServer;

  /// No description provided for @speechErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout'**
  String get speechErrorTimeout;

  /// No description provided for @speechErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests'**
  String get speechErrorTooManyRequests;

  /// No description provided for @speechErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get speechErrorUnknown;

  /// No description provided for @speechListening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get speechListening;

  /// No description provided for @speechPhase2.
  ///
  /// In en, this message translates to:
  /// **'Processing speech...'**
  String get speechPhase2;

  /// No description provided for @speechPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get speechPreparing;

  /// No description provided for @speechProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get speechProcessing;

  /// No description provided for @speechStartError.
  ///
  /// In en, this message translates to:
  /// **'Failed to start speech recognition'**
  String speechStartError(Object error);

  /// No description provided for @systemPrompt.
  ///
  /// In en, this message translates to:
  /// **'System Prompt'**
  String get systemPrompt;

  /// No description provided for @systemPromptDescription.
  ///
  /// In en, this message translates to:
  /// **'Instructions that define how the AI behaves'**
  String get systemPromptDescription;

  /// No description provided for @systemPromptSuggestion.
  ///
  /// In en, this message translates to:
  /// **'You are a helpful assistant.'**
  String get systemPromptSuggestion;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @temperatureDescription.
  ///
  /// In en, this message translates to:
  /// **'Higher values make output more random'**
  String get temperatureDescription;

  /// No description provided for @toggleNavigatorTooltip.
  ///
  /// In en, this message translates to:
  /// **'Toggle navigation'**
  String get toggleNavigatorTooltip;

  /// No description provided for @userPromptSuggestion.
  ///
  /// In en, this message translates to:
  /// **'How can I help you today?'**
  String get userPromptSuggestion;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// No description provided for @welcomeGreeting1.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcomeGreeting1;

  /// No description provided for @welcomeGreeting2.
  ///
  /// In en, this message translates to:
  /// **'How can I help you?'**
  String get welcomeGreeting2;

  /// No description provided for @welcomeGreeting3.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything'**
  String get welcomeGreeting3;

  /// No description provided for @welcomeGreeting4.
  ///
  /// In en, this message translates to:
  /// **'I can help you with coding, writing, and analysis'**
  String get welcomeGreeting4;

  /// No description provided for @welcomeGreeting5.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get started'**
  String get welcomeGreeting5;

  /// No description provided for @welcomeGreeting6.
  ///
  /// In en, this message translates to:
  /// **'What would you like to work on?'**
  String get welcomeGreeting6;

  /// No description provided for @welcomeGreeting7.
  ///
  /// In en, this message translates to:
  /// **'Ready to help'**
  String get welcomeGreeting7;

  /// No description provided for @welcomeGreeting8.
  ///
  /// In en, this message translates to:
  /// **'Your AI companion is here'**
  String get welcomeGreeting8;

  /// No description provided for @welcomeGreeting9.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get welcomeGreeting9;

  /// No description provided for @welcomeGreeting10.
  ///
  /// In en, this message translates to:
  /// **'Discover what I can do'**
  String get welcomeGreeting10;

  /// No description provided for @welcomeGreeting11.
  ///
  /// In en, this message translates to:
  /// **'Need help? Just ask'**
  String get welcomeGreeting11;

  /// No description provided for @welcomeGreeting12.
  ///
  /// In en, this message translates to:
  /// **'I\'m here to help'**
  String get welcomeGreeting12;

  /// No description provided for @modelDoesNotSupportFiles.
  ///
  /// In en, this message translates to:
  /// **'This model does not support file attachments'**
  String modelDoesNotSupportFiles(Object modelId);

  /// No description provided for @generatingSuggestionsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate suggestions'**
  String generatingSuggestionsFailed(Object error);

  /// No description provided for @toggleSidebarTooltip.
  ///
  /// In en, this message translates to:
  /// **'Toggle sidebar'**
  String get toggleSidebarTooltip;

  /// No description provided for @openMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get openMenuTooltip;

  /// No description provided for @addFileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add file'**
  String get addFileTooltip;

  /// No description provided for @modelSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Model settings'**
  String get modelSettingsTooltip;

  /// No description provided for @switchAgentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch agent'**
  String get switchAgentTooltip;

  /// No description provided for @selectModelTooltip.
  ///
  /// In en, this message translates to:
  /// **'Select model'**
  String get selectModelTooltip;

  /// No description provided for @removeFileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove file'**
  String get removeFileTooltip;

  /// No description provided for @goToParentSessionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Go to parent session'**
  String get goToParentSessionTooltip;

  /// No description provided for @previousSiblingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Previous sibling'**
  String get previousSiblingTooltip;

  /// No description provided for @nextSiblingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Next sibling'**
  String get nextSiblingTooltip;

  /// No description provided for @cancellingRetryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancelling retry...'**
  String get cancellingRetryTooltip;

  /// No description provided for @stopGenerationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stop generation'**
  String get stopGenerationTooltip;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answer;

  /// No description provided for @noAgentsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No agents available'**
  String get noAgentsAvailable;

  /// No description provided for @permissionAlwaysConfirmDescription.
  ///
  /// In en, this message translates to:
  /// **'This will allow \"{title}\" until the app is restarted.'**
  String permissionAlwaysConfirmDescription(Object title);

  /// No description provided for @chatActionsMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Chat menu'**
  String get chatActionsMenuTooltip;

  /// No description provided for @startListening.
  ///
  /// In en, this message translates to:
  /// **'Start voice input'**
  String get startListening;

  /// No description provided for @stopListening.
  ///
  /// In en, this message translates to:
  /// **'Stop voice input'**
  String get stopListening;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// No description provided for @maxTokens.
  ///
  /// In en, this message translates to:
  /// **'Max Tokens'**
  String get maxTokens;

  /// No description provided for @maxTokensDescription.
  ///
  /// In en, this message translates to:
  /// **'Maximum length of generated response'**
  String get maxTokensDescription;

  /// No description provided for @activeModel.
  ///
  /// In en, this message translates to:
  /// **'Active Model'**
  String get activeModel;

  /// No description provided for @apiLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'API limit exceeded: {limit}'**
  String apiLimitExceeded(Object limit);

  /// No description provided for @valueExceedsApiLimit.
  ///
  /// In en, this message translates to:
  /// **'Value exceeds API limit ({limit}). Maximum value will be used.'**
  String valueExceedsApiLimit(Object limit);

  /// No description provided for @micStopFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to stop microphone'**
  String get micStopFailed;

  /// No description provided for @errorProcessingRequest.
  ///
  /// In en, this message translates to:
  /// **'Sorry, I encountered an error while processing your request. Please try again.'**
  String get errorProcessingRequest;

  /// No description provided for @rateLimitRetryMessage.
  ///
  /// In en, this message translates to:
  /// **'Rate limit exceeded. Retrying in {seconds} seconds...'**
  String rateLimitRetryMessage(Object seconds);

  /// No description provided for @messageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Message not found'**
  String get messageNotFound;

  /// No description provided for @errorEditingMessage.
  ///
  /// In en, this message translates to:
  /// **'Error editing message'**
  String get errorEditingMessage;

  /// No description provided for @errorEditAndSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Error editing and sending message'**
  String get errorEditAndSendMessage;

  /// No description provided for @defaultSuggestion4.
  ///
  /// In en, this message translates to:
  /// **'How does this apply in practice?'**
  String get defaultSuggestion4;

  /// No description provided for @fileAttachedButNotSupported.
  ///
  /// In en, this message translates to:
  /// **'File attached but not supported by the current model'**
  String get fileAttachedButNotSupported;

  /// No description provided for @expandTooltip.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expandTooltip;

  /// No description provided for @collapseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapseTooltip;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'ja', 'ru', 'uk', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
    case 'ja': return AppLocalizationsJa();
    case 'ru': return AppLocalizationsRu();
    case 'uk': return AppLocalizationsUk();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
