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
    Locale('ja'),
    Locale('ru'),
    Locale('uk'),
    Locale('zh'),
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

  /// Title shown on the bootstrap error screen when app initialization fails
  ///
  /// In en, this message translates to:
  /// **'Failed to start the app'**
  String get bootstrapErrorTitle;

  /// Body text shown on the bootstrap error screen
  ///
  /// In en, this message translates to:
  /// **'Check your configuration and try again.'**
  String get bootstrapErrorBody;

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

  /// No description provided for @editToolTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {path}'**
  String editToolTitle(String path);

  /// No description provided for @patchToolTitle.
  ///
  /// In en, this message translates to:
  /// **'Patch {path}'**
  String patchToolTitle(String path);

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
  /// **'What are the most exciting technologies of 2026?'**
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
  /// **'Which programming languages are best to learn in 2026?'**
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

  /// No description provided for @recentModels.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentModels;

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
  /// **'Version:'**
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

  /// No description provided for @addProviderTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Provider'**
  String get addProviderTitleEdit;

  /// No description provided for @addProviderTitleAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Provider'**
  String get addProviderTitleAdd;

  /// No description provided for @addProviderLabelProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get addProviderLabelProvider;

  /// No description provided for @addProviderCustomName.
  ///
  /// In en, this message translates to:
  /// **'Custom Provider...'**
  String get addProviderCustomName;

  /// No description provided for @addProviderFieldProviderName.
  ///
  /// In en, this message translates to:
  /// **'Provider Name'**
  String get addProviderFieldProviderName;

  /// No description provided for @addProviderHintProviderName.
  ///
  /// In en, this message translates to:
  /// **'e.g. My Custom AI'**
  String get addProviderHintProviderName;

  /// No description provided for @addProviderLabelApiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get addProviderLabelApiKey;

  /// No description provided for @addProviderHintApiKey.
  ///
  /// In en, this message translates to:
  /// **'Enter your API key'**
  String get addProviderHintApiKey;

  /// No description provided for @addProviderHintCustomApiKey.
  ///
  /// In en, this message translates to:
  /// **'Optional for local providers'**
  String get addProviderHintCustomApiKey;

  /// No description provided for @addProviderLabelBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get addProviderLabelBaseUrl;

  /// No description provided for @addProviderHintBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'https://api.example.com/v1'**
  String get addProviderHintBaseUrl;

  /// No description provided for @addProviderActionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get addProviderActionSave;

  /// No description provided for @addProviderErrorApiKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'API key is required'**
  String get addProviderErrorApiKeyRequired;

  /// No description provided for @selectModels.
  ///
  /// In en, this message translates to:
  /// **'Select Models'**
  String get selectModels;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @modelsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No models available'**
  String get modelsAvailable;

  /// No description provided for @modelsMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No models match your search'**
  String get modelsMatchSearch;

  /// No description provided for @selectModelsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} selected'**
  String selectModelsCount(Object count, Object total);

  /// No description provided for @modelsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load models: {error}'**
  String modelsLoadError(Object error);

  /// No description provided for @systemPromptHint.
  ///
  /// In en, this message translates to:
  /// **'You are a helpful assistant...'**
  String get systemPromptHint;

  /// No description provided for @temperatureHint.
  ///
  /// In en, this message translates to:
  /// **'0.0 - 2.0'**
  String get temperatureHint;

  /// No description provided for @loadingSettings.
  ///
  /// In en, this message translates to:
  /// **'Loading settings...'**
  String get loadingSettings;

  /// No description provided for @errorApplyingSettings.
  ///
  /// In en, this message translates to:
  /// **'Error applying settings: {error}'**
  String errorApplyingSettings(Object error);

  /// No description provided for @deleteProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {providerName}?'**
  String deleteProviderTitle(Object providerName);

  /// No description provided for @deleteProviderContent.
  ///
  /// In en, this message translates to:
  /// **'This will remove the provider and all its settings. You will need to add it again to use its models.'**
  String get deleteProviderContent;

  /// No description provided for @errorLoadingProviders.
  ///
  /// In en, this message translates to:
  /// **'Error loading providers'**
  String get errorLoadingProviders;

  /// No description provided for @noProvidersConfigured.
  ///
  /// In en, this message translates to:
  /// **'No providers configured'**
  String get noProvidersConfigured;

  /// No description provided for @addProviderToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Add a provider with an API key to get started'**
  String get addProviderToGetStarted;

  /// No description provided for @statsError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String statsError(Object error);

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @modelsProviderCountFormat.
  ///
  /// In en, this message translates to:
  /// **'{providerName} · {count}'**
  String modelsProviderCountFormat(Object count, Object providerName);

  /// No description provided for @mcpServers.
  ///
  /// In en, this message translates to:
  /// **'MCP servers'**
  String get mcpServers;

  /// No description provided for @mcpAddServer.
  ///
  /// In en, this message translates to:
  /// **'Add MCP server'**
  String get mcpAddServer;

  /// No description provided for @mcpAddServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Add MCP server'**
  String get mcpAddServerTitle;

  /// No description provided for @mcpNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get mcpNameLabel;

  /// No description provided for @mcpNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. filesystem'**
  String get mcpNameHint;

  /// No description provided for @mcpNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Unique identifier used in chatorai.json'**
  String get mcpNameHelper;

  /// No description provided for @mcpTypeLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get mcpTypeLocal;

  /// No description provided for @mcpTypeRemote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get mcpTypeRemote;

  /// No description provided for @mcpTypeLocalTooltip.
  ///
  /// In en, this message translates to:
  /// **'Runs on your machine'**
  String get mcpTypeLocalTooltip;

  /// No description provided for @mcpTypeRemoteTooltip.
  ///
  /// In en, this message translates to:
  /// **'HTTP/SSE endpoint'**
  String get mcpTypeRemoteTooltip;

  /// No description provided for @mcpCommandLabel.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get mcpCommandLabel;

  /// No description provided for @mcpCommandHint.
  ///
  /// In en, this message translates to:
  /// **'uvx mcp-server-filesystem ~/docs'**
  String get mcpCommandHint;

  /// No description provided for @mcpCommandHelper.
  ///
  /// In en, this message translates to:
  /// **'Full command with arguments, space-separated'**
  String get mcpCommandHelper;

  /// No description provided for @mcpUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get mcpUrlLabel;

  /// No description provided for @mcpUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://example.com/mcp'**
  String get mcpUrlHint;

  /// No description provided for @mcpUrlHelper.
  ///
  /// In en, this message translates to:
  /// **'Full MCP endpoint URL'**
  String get mcpUrlHelper;

  /// No description provided for @mcpEnvLabel.
  ///
  /// In en, this message translates to:
  /// **'Environment variables (JSON)'**
  String get mcpEnvLabel;

  /// No description provided for @mcpEnvHint.
  ///
  /// In en, this message translates to:
  /// **'GITHUB_TOKEN=ghp_xxx'**
  String get mcpEnvHint;

  /// No description provided for @mcpEnvHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional. Paste a JSON object of string keys, e.g. a single TOKEN entry.'**
  String get mcpEnvHelper;

  /// No description provided for @mcpTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Access token'**
  String get mcpTokenLabel;

  /// No description provided for @mcpTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Paste your token only (no Bearer / quotes)'**
  String get mcpTokenHint;

  /// No description provided for @mcpTokenHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional. Leave empty for public servers; paste just the token and the header is added automatically.'**
  String get mcpTokenHelper;

  /// No description provided for @mcpAuthTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Token type'**
  String get mcpAuthTypeLabel;

  /// No description provided for @mcpAuthTypeHelper.
  ///
  /// In en, this message translates to:
  /// **'How the token is sent: Bearer (Authorization), ApiKey (X-Api-Key), or plain Token.'**
  String get mcpAuthTypeHelper;

  /// No description provided for @mcpHeadersLabel.
  ///
  /// In en, this message translates to:
  /// **'Headers (JSON)'**
  String get mcpHeadersLabel;

  /// No description provided for @mcpHeadersHint.
  ///
  /// In en, this message translates to:
  /// **'Authorization=Bearer token'**
  String get mcpHeadersHint;

  /// No description provided for @mcpHeadersHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional. Paste a JSON object of string header keys.'**
  String get mcpHeadersHelper;

  /// No description provided for @mcpFormTab.
  ///
  /// In en, this message translates to:
  /// **'Form'**
  String get mcpFormTab;

  /// No description provided for @mcpRawTab.
  ///
  /// In en, this message translates to:
  /// **'Raw JSON'**
  String get mcpRawTab;

  /// No description provided for @mcpRawLabel.
  ///
  /// In en, this message translates to:
  /// **'Server object (JSON)'**
  String get mcpRawLabel;

  /// No description provided for @mcpRawHelper.
  ///
  /// In en, this message translates to:
  /// **'Paste the server object as in the docs — the server name is the outer key (e.g. searxng). You can paste the full block including the mcpServers wrapper.'**
  String get mcpRawHelper;

  /// No description provided for @mcpParseError.
  ///
  /// In en, this message translates to:
  /// **'Invalid JSON in {field}: {message}'**
  String mcpParseError(Object field, Object message);

  /// No description provided for @mcpAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get mcpAddAction;

  /// No description provided for @mcpCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get mcpCancelAction;

  /// No description provided for @mcpRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove MCP server?'**
  String get mcpRemoveTitle;

  /// No description provided for @mcpRemoveContent.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from chatorai.json?'**
  String mcpRemoveContent(Object name);

  /// No description provided for @mcpRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get mcpRemoveAction;

  /// No description provided for @mcpEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get mcpEditAction;

  /// No description provided for @mcpEditServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit MCP server'**
  String get mcpEditServerTitle;

  /// No description provided for @mcpSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get mcpSaveAction;

  /// No description provided for @mcpNoServers.
  ///
  /// In en, this message translates to:
  /// **'No MCP servers configured'**
  String get mcpNoServers;

  /// No description provided for @mcpNoServersHint.
  ///
  /// In en, this message translates to:
  /// **'Add a Model Context Protocol server to extend tooling'**
  String get mcpNoServersHint;

  /// No description provided for @mcpTooltipAdd.
  ///
  /// In en, this message translates to:
  /// **'Add server'**
  String get mcpTooltipAdd;

  /// No description provided for @mcpTooltipRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get mcpTooltipRefresh;

  /// No description provided for @mcpMarketplaceTab.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get mcpMarketplaceTab;

  /// No description provided for @mcpInstalledTab.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get mcpInstalledTab;

  /// No description provided for @mcpInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get mcpInstall;

  /// No description provided for @mcpInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get mcpInstalled;

  /// No description provided for @mcpMarketplaceSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search servers…'**
  String get mcpMarketplaceSearchHint;

  /// No description provided for @mcpMarketplaceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No servers match your search'**
  String get mcpMarketplaceEmpty;

  /// No description provided for @mcpMarketCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get mcpMarketCategoryAll;

  /// No description provided for @mcpMarketCategorySearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get mcpMarketCategorySearch;

  /// No description provided for @mcpMarketCategoryDocs.
  ///
  /// In en, this message translates to:
  /// **'Docs'**
  String get mcpMarketCategoryDocs;

  /// No description provided for @mcpMarketCategoryDesign.
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get mcpMarketCategoryDesign;

  /// No description provided for @mcpMarketCategoryDev.
  ///
  /// In en, this message translates to:
  /// **'Dev'**
  String get mcpMarketCategoryDev;

  /// No description provided for @mcpMarketCategoryFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get mcpMarketCategoryFinance;

  /// No description provided for @mcpMarketCategoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get mcpMarketCategoryTravel;

  /// No description provided for @mcpMarketCategoryJobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get mcpMarketCategoryJobs;

  /// No description provided for @mcpMarketCategoryProductivity.
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get mcpMarketCategoryProductivity;

  /// No description provided for @mcpMarketCategorySocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get mcpMarketCategorySocial;

  /// No description provided for @mcpMarketCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get mcpMarketCategoryOther;

  /// No description provided for @mcpMarketNeedsToken.
  ///
  /// In en, this message translates to:
  /// **'Needs key'**
  String get mcpMarketNeedsToken;

  /// No description provided for @mcpMarketDescExa.
  ///
  /// In en, this message translates to:
  /// **'Exa provides web search and code documentation lookup for AI workflows. Its connector feeds assistants real-time context to find relevant web pages, technical docs, and source material when grounded external information is needed for an answer.'**
  String get mcpMarketDescExa;

  /// No description provided for @mcpMarketDescContext7.
  ///
  /// In en, this message translates to:
  /// **'Context7 delivers up-to-date code examples and documentation for AI-powered programmers and code editors. Its MCP connector integrates current library context into assistant workflows, reducing tab-switching and helping generated code avoid outdated APIs, nonexistent methods, and stale implementation patterns.'**
  String get mcpMarketDescContext7;

  /// No description provided for @mcpMarketDescHuggingFace.
  ///
  /// In en, this message translates to:
  /// **'Hugging Face connects voice assistants to the Hugging Face Hub and thousands of Gradio apps. Its connector integrates model, dataset, space, and app context into AI workflows for discovery, experimentation, and machine learning research.'**
  String get mcpMarketDescHuggingFace;

  /// No description provided for @mcpMarketDescParallel.
  ///
  /// In en, this message translates to:
  /// **'Parallel Search provides real-time web search and content extraction for search-driven AI workflows. Its remote MCP server helps assistants fetch current web-page context, verify pages, and use extracted content when answering questions or researching topics that need fresh information.'**
  String get mcpMarketDescParallel;

  /// No description provided for @mcpMarketDescTavily.
  ///
  /// In en, this message translates to:
  /// **'Tavily gives AI agents real-time access to web resources via APIs for search, retrieval, and research. Its connector helps assistants ground answers in live data, extract relevant content, and support production agent workflows with safety controls.'**
  String get mcpMarketDescTavily;

  /// No description provided for @mcpMarketDescGithub.
  ///
  /// In en, this message translates to:
  /// **'GitHub is a platform for collaborating on code, issues, pull requests, and project history. Its official remote MCP server gives assistants structured repository context to understand source changes, reviews, development workflows, and GitHub project status.'**
  String get mcpMarketDescGithub;

  /// No description provided for @mcpMarketDescPostman.
  ///
  /// In en, this message translates to:
  /// **'Postman provides API context for coding agents and developer workflows. Its connector integrates API definitions, documentation, and collaboration context into assistant work, letting agents analyze integrations and implementation details.'**
  String get mcpMarketDescPostman;

  /// No description provided for @mcpMarketDescSlack.
  ///
  /// In en, this message translates to:
  /// **'Slack is a collaboration hub uniting team messages, channels, users, and shared workspaces. Its remote MCP server integrates workspace conversation context into assistant workflows, helping users find answers, summarize discussions, and understand activity across channels.'**
  String get mcpMarketDescSlack;

  /// No description provided for @mcpMarketDescFigma.
  ///
  /// In en, this message translates to:
  /// **'Figma is a product design platform for UI design, prototyping, and developer handoff. Its remote MCP server brings files, projects, and dev-mode context into assistant workflows, letting agents understand visual work and map it to implementation tasks.'**
  String get mcpMarketDescFigma;

  /// No description provided for @mcpMarketDescCanva.
  ///
  /// In en, this message translates to:
  /// **'Canva is a visual communication platform for presentations, social graphics, documents, and brand materials. Its remote MCP server gives assistants access to Canva projects, assets, exported files, and comments, letting them discuss, edit, and prepare creative work from gathered info.'**
  String get mcpMarketDescCanva;

  /// No description provided for @mcpMarketDescStripe.
  ///
  /// In en, this message translates to:
  /// **'Stripe is a payments and financial infrastructure platform for processing payments, billing, customers, and developer documentation. Its remote MCP server gives assistants account and implementation context backed by Stripe to understand customer workflows, billing questions, and payment tasks.'**
  String get mcpMarketDescStripe;

  /// No description provided for @mcpMarketDescTrivago.
  ///
  /// In en, this message translates to:
  /// **'Trivago helps users search for hotels and lodging by coordinates, city, country, dates, and travel context. Its connector gives assistants lodging-search context to find suitable stays near destinations or points of interest.'**
  String get mcpMarketDescTrivago;

  /// No description provided for @mcpMarketDescSend.
  ///
  /// In en, this message translates to:
  /// **'Send helps users create shareable documents, one-page docs, presentations, and slides. Its connector lets assistants turn requested materials into published links, interactive pages, and trackable deliverables for recipients.'**
  String get mcpMarketDescSend;

  /// No description provided for @mcpMarketDescZiprecruiter.
  ///
  /// In en, this message translates to:
  /// **'ZipRecruiter helps users search live jobs by title, company, location, salary, distance, work style, employment type, and posting date. Its connector integrates job-search context into assistant workflows before handing applications back to ZipRecruiter.'**
  String get mcpMarketDescZiprecruiter;

  /// No description provided for @mcpMarketDescAdobeCreativity.
  ///
  /// In en, this message translates to:
  /// **'Adobe for Creativity unites Photoshop, Lightroom, Illustrator, Firefly, Premiere, Express, InDesign, and Stock with AI-driven creative work. Users can generate, edit, and enhance photos, design assets, and video projects using natural language while work stays tied to their Adobe account.'**
  String get mcpMarketDescAdobeCreativity;

  /// No description provided for @mcpInstallToGlobal.
  ///
  /// In en, this message translates to:
  /// **'Install to Global'**
  String get mcpInstallToGlobal;

  /// No description provided for @mcpInstallToProject.
  ///
  /// In en, this message translates to:
  /// **'Install to Project'**
  String get mcpInstallToProject;

  /// No description provided for @mcpScopeGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get mcpScopeGlobal;

  /// No description provided for @mcpScopeProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get mcpScopeProject;

  /// No description provided for @mcpScopeGlobalProject.
  ///
  /// In en, this message translates to:
  /// **'Global + Project'**
  String get mcpScopeGlobalProject;

  /// No description provided for @mcpRemoveFromScope.
  ///
  /// In en, this message translates to:
  /// **'Remove from {scope}'**
  String mcpRemoveFromScope(String scope);

  /// No description provided for @mcpRemoveFromAll.
  ///
  /// In en, this message translates to:
  /// **'Remove from all'**
  String get mcpRemoveFromAll;

  /// No description provided for @mcpTokenDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get mcpTokenDialogTitle;

  /// No description provided for @mcpTokenDialogTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Choose how to authenticate with this server'**
  String get mcpTokenDialogTitleHint;

  /// No description provided for @mcpTokenInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get mcpTokenInputLabel;

  /// No description provided for @mcpTokenInputHint.
  ///
  /// In en, this message translates to:
  /// **'Paste your access token'**
  String get mcpTokenInputHint;

  /// No description provided for @mcpTokenInputHelper.
  ///
  /// In en, this message translates to:
  /// **'Sent as Authorization: Bearer <token>'**
  String get mcpTokenInputHelper;

  /// No description provided for @mcpOAuthClientIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Client ID'**
  String get mcpOAuthClientIdLabel;

  /// No description provided for @mcpOAuthClientIdHint.
  ///
  /// In en, this message translates to:
  /// **'OAuth 2.1 client ID'**
  String get mcpOAuthClientIdHint;

  /// No description provided for @mcpOAuthClientSecretLabel.
  ///
  /// In en, this message translates to:
  /// **'Client Secret'**
  String get mcpOAuthClientSecretLabel;

  /// No description provided for @mcpOAuthClientSecretHint.
  ///
  /// In en, this message translates to:
  /// **'OAuth 2.1 client secret (optional)'**
  String get mcpOAuthClientSecretHint;

  /// No description provided for @mcpOAuthScopeLabel.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get mcpOAuthScopeLabel;

  /// No description provided for @mcpOAuthScopeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. read write'**
  String get mcpOAuthScopeHint;

  /// No description provided for @mcpAuthConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get mcpAuthConfirm;

  /// No description provided for @agentsInstructions.
  ///
  /// In en, this message translates to:
  /// **'Agents Instructions'**
  String get agentsInstructions;

  /// No description provided for @agentsInstructionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage AGENTS.md and custom instruction files'**
  String get agentsInstructionsSubtitle;

  /// No description provided for @agentsMdHint.
  ///
  /// In en, this message translates to:
  /// **'# Project rules\n- Be concise\n- Write tests first'**
  String get agentsMdHint;

  /// No description provided for @agentsMdSaved.
  ///
  /// In en, this message translates to:
  /// **'AGENTS.md saved'**
  String get agentsMdSaved;

  /// No description provided for @instructionsAutoDetectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Detected files'**
  String get instructionsAutoDetectedTitle;

  /// No description provided for @instructionsAutoDetectedHelper.
  ///
  /// In en, this message translates to:
  /// **'AGENTS.md and CLAUDE.md found for this scope. Tap to view or edit.'**
  String get instructionsAutoDetectedHelper;

  /// No description provided for @instructionsFileNotCreated.
  ///
  /// In en, this message translates to:
  /// **'Not created yet'**
  String get instructionsFileNotCreated;

  /// No description provided for @instructionsFileReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get instructionsFileReadOnly;

  /// No description provided for @instructionsBadgeGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get instructionsBadgeGlobal;

  /// No description provided for @instructionsBadgeProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get instructionsBadgeProject;

  /// No description provided for @instructionsViewFile.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get instructionsViewFile;

  /// No description provided for @instructionsEditFile.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get instructionsEditFile;

  /// No description provided for @instructionsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Instruction files'**
  String get instructionsSectionTitle;

  /// No description provided for @instructionsSectionHelper.
  ///
  /// In en, this message translates to:
  /// **'Extra Markdown files appended after AGENTS.md, in order.'**
  String get instructionsSectionHelper;

  /// No description provided for @instructionsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add instruction'**
  String get instructionsAdd;

  /// No description provided for @instructionsAddInline.
  ///
  /// In en, this message translates to:
  /// **'Write inline'**
  String get instructionsAddInline;

  /// No description provided for @instructionsUploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload .md file'**
  String get instructionsUploadFile;

  /// No description provided for @instructionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No instruction files yet'**
  String get instructionsEmpty;

  /// No description provided for @instructionsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add an inline instruction or upload a Markdown file.'**
  String get instructionsEmptyHint;

  /// No description provided for @instructionsNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get instructionsNameLabel;

  /// No description provided for @instructionsNameHint.
  ///
  /// In en, this message translates to:
  /// **'coding-style'**
  String get instructionsNameHint;

  /// No description provided for @instructionsContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get instructionsContentLabel;

  /// No description provided for @instructionsContentHint.
  ///
  /// In en, this message translates to:
  /// **'Write your instructions in Markdown…'**
  String get instructionsContentHint;

  /// No description provided for @instructionsAddedInline.
  ///
  /// In en, this message translates to:
  /// **'Instruction added'**
  String get instructionsAddedInline;

  /// No description provided for @instructionsAddedFile.
  ///
  /// In en, this message translates to:
  /// **'File added: {name}'**
  String instructionsAddedFile(Object name);

  /// No description provided for @instructionsRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove instruction'**
  String get instructionsRemoveTitle;

  /// No description provided for @instructionsRemoveContent.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from instructions?'**
  String instructionsRemoveContent(Object name);

  /// No description provided for @instructionsRemoved.
  ///
  /// In en, this message translates to:
  /// **'Instruction removed'**
  String get instructionsRemoved;

  /// No description provided for @instructionsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit instruction path'**
  String get instructionsEditTitle;

  /// No description provided for @instructionsPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get instructionsPathLabel;

  /// No description provided for @instructionsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Instruction updated'**
  String get instructionsUpdated;

  /// No description provided for @instructionsScopeGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get instructionsScopeGlobal;

  /// No description provided for @instructionsScopeProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get instructionsScopeProject;

  /// No description provided for @instructionsScopeGlobalHint.
  ///
  /// In en, this message translates to:
  /// **'Applies everywhere. Stored in your user config.'**
  String get instructionsScopeGlobalHint;

  /// No description provided for @instructionsScopeProjectHint.
  ///
  /// In en, this message translates to:
  /// **'Applies to the current project folder.'**
  String get instructionsScopeProjectHint;

  /// No description provided for @instructionsCreateAgents.
  ///
  /// In en, this message translates to:
  /// **'Create AGENTS.md'**
  String get instructionsCreateAgents;

  /// No description provided for @instructionsSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String instructionsSaveError(Object error);

  /// No description provided for @configScopeGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get configScopeGlobal;

  /// No description provided for @configScopeProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get configScopeProject;

  /// No description provided for @configProjectOverrides.
  ///
  /// In en, this message translates to:
  /// **'Project settings override global settings.'**
  String get configProjectOverrides;

  /// No description provided for @configPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get configPathLabel;

  /// No description provided for @configStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get configStatusLabel;

  /// No description provided for @configContentsTitle.
  ///
  /// In en, this message translates to:
  /// **'File contents'**
  String get configContentsTitle;

  /// No description provided for @configExists.
  ///
  /// In en, this message translates to:
  /// **'Exists'**
  String get configExists;

  /// No description provided for @configNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get configNotFound;

  /// No description provided for @configWillBeCreated.
  ///
  /// In en, this message translates to:
  /// **'Will be created when you save.'**
  String get configWillBeCreated;

  /// No description provided for @skillsTitle.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skillsTitle;

  /// No description provided for @skillsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reusable capability packs the assistant can load on demand.'**
  String get skillsSubtitle;

  /// No description provided for @skillsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Installed skills'**
  String get skillsSectionTitle;

  /// No description provided for @skillsSectionHelper.
  ///
  /// In en, this message translates to:
  /// **'Each skill is a folder with a SKILL.md. Add your own or install from a URL.'**
  String get skillsSectionHelper;

  /// No description provided for @skillsNewSkill.
  ///
  /// In en, this message translates to:
  /// **'New skill'**
  String get skillsNewSkill;

  /// No description provided for @skillsInstallFromUrl.
  ///
  /// In en, this message translates to:
  /// **'Install from URL'**
  String get skillsInstallFromUrl;

  /// No description provided for @skillsNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get skillsNameLabel;

  /// No description provided for @skillsNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Code Reviewer'**
  String get skillsNameHint;

  /// No description provided for @skillsDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get skillsDescriptionLabel;

  /// No description provided for @skillsDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Short summary of what this skill does'**
  String get skillsDescriptionHint;

  /// No description provided for @skillsContentLabel.
  ///
  /// In en, this message translates to:
  /// **'SKILL.md content'**
  String get skillsContentLabel;

  /// No description provided for @skillsContentHint.
  ///
  /// In en, this message translates to:
  /// **'# Heading\nInstructions for the assistant…'**
  String get skillsContentHint;

  /// No description provided for @skillsUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'index.json URL'**
  String get skillsUrlLabel;

  /// No description provided for @skillsUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://example.com/skills'**
  String get skillsUrlHint;

  /// No description provided for @skillsApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'API key (optional)'**
  String get skillsApiKeyLabel;

  /// No description provided for @skillsReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get skillsReadOnly;

  /// No description provided for @skillsFilesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} files'**
  String skillsFilesCount(int count);

  /// No description provided for @skillsCreated.
  ///
  /// In en, this message translates to:
  /// **'Skill created'**
  String get skillsCreated;

  /// No description provided for @skillsSaved.
  ///
  /// In en, this message translates to:
  /// **'Skill saved'**
  String get skillsSaved;

  /// No description provided for @skillsRemoved.
  ///
  /// In en, this message translates to:
  /// **'Skill removed'**
  String get skillsRemoved;

  /// No description provided for @skillsInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed {count} skill(s)'**
  String skillsInstalled(int count);

  /// No description provided for @skillsInstallNone.
  ///
  /// In en, this message translates to:
  /// **'No skills found at that URL'**
  String get skillsInstallNone;

  /// No description provided for @skillsRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove skill'**
  String get skillsRemoveTitle;

  /// No description provided for @skillsRemoveContent.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\"? This deletes its folder from disk.'**
  String skillsRemoveContent(String name);

  /// No description provided for @skillsSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not complete: {error}'**
  String skillsSaveError(String error);

  /// No description provided for @skillsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No skills yet'**
  String get skillsEmpty;

  /// No description provided for @skillsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Create a skill or install one from a URL to get started.'**
  String get skillsEmptyHint;

  /// No description provided for @skillsMarketplaceTab.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get skillsMarketplaceTab;

  /// No description provided for @skillsMarketplaceSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search skills'**
  String get skillsMarketplaceSearchHint;

  /// No description provided for @skillsMarketplaceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No skills match your search.'**
  String get skillsMarketplaceEmpty;

  /// No description provided for @skillsInstalledBadge.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get skillsInstalledBadge;

  /// No description provided for @skillsInstallAction.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get skillsInstallAction;

  /// No description provided for @skillsInstallToGlobal.
  ///
  /// In en, this message translates to:
  /// **'Install to Global'**
  String get skillsInstallToGlobal;

  /// No description provided for @skillsInstallToProject.
  ///
  /// In en, this message translates to:
  /// **'Install to Project'**
  String get skillsInstallToProject;

  /// No description provided for @skillsInstalledToast.
  ///
  /// In en, this message translates to:
  /// **'{name} · installed'**
  String skillsInstalledToast(String name);

  /// No description provided for @skillsTabGlobalTooltip.
  ///
  /// In en, this message translates to:
  /// **'Skills available in every project'**
  String get skillsTabGlobalTooltip;

  /// No description provided for @skillsTabProjectTooltip.
  ///
  /// In en, this message translates to:
  /// **'Skills scoped to this project'**
  String get skillsTabProjectTooltip;

  /// No description provided for @skillsTabMarketplaceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Browse and install ready-made skills'**
  String get skillsTabMarketplaceTooltip;

  /// No description provided for @skillsPreviewClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get skillsPreviewClose;

  /// No description provided for @skillsCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get skillsCategoryAll;

  /// No description provided for @skillsCategoryCoding.
  ///
  /// In en, this message translates to:
  /// **'Coding'**
  String get skillsCategoryCoding;

  /// No description provided for @skillsCategoryWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get skillsCategoryWriting;

  /// No description provided for @skillsCategoryResearch.
  ///
  /// In en, this message translates to:
  /// **'Research'**
  String get skillsCategoryResearch;

  /// No description provided for @skillsCategoryDesign.
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get skillsCategoryDesign;

  /// No description provided for @skillsCategoryProductivity.
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get skillsCategoryProductivity;

  /// No description provided for @skillsCategoryData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get skillsCategoryData;

  /// No description provided for @skillsCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get skillsCategoryOther;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @toolResultOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get toolResultOriginal;

  /// No description provided for @toolResultRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get toolResultRestore;

  /// No description provided for @toolResultRestoredSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Files restored to before-edit state'**
  String get toolResultRestoredSnackbar;

  /// No description provided for @toolResultOriginalTitle.
  ///
  /// In en, this message translates to:
  /// **'Original content before edit'**
  String get toolResultOriginalTitle;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restoreFailed(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'en',
    'ja',
    'ru',
    'uk',
    'zh',
  ].contains(locale.languageCode);

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
    case 'ja':
      return AppLocalizationsJa();
    case 'ru':
      return AppLocalizationsRu();
    case 'uk':
      return AppLocalizationsUk();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
