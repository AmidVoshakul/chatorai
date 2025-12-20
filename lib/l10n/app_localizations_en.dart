// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'GenUI Chat AI';

  @override
  String get settings => 'Settings';

  @override
  String get openRouterConfiguration => 'OpenRouter Configuration';

  @override
  String get apiKey => 'API Key';

  @override
  String get enterApiKey => 'Enter your OpenRouter API key';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get system => 'System';

  @override
  String get useSystemTheme => 'Use system theme';

  @override
  String get light => 'Light';

  @override
  String get useLightTheme => 'Use light theme';

  @override
  String get dark => 'Dark';

  @override
  String get useDarkTheme => 'Use dark theme';

  @override
  String get fontSize => 'Font Size';

  @override
  String currentSize(Object percentage) {
    return 'Current size: $percentage%';
  }

  @override
  String get accessibility => 'Accessibility';

  @override
  String get reduceMotion => 'Reduce Motion';

  @override
  String get disableAnimation => 'Disable or reduce animation effects';

  @override
  String get highContrast => 'High Contrast';

  @override
  String get increaseContrast => 'Increase contrast for better readability';

  @override
  String get wideScreenMode => 'Wide Screen Mode';

  @override
  String get useFullScreenWidth => 'Use full screen width for chat content';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get russian => 'Russian';

  @override
  String get arabic => 'Arabic (RTL)';

  @override
  String get chinese => 'Chinese';

  @override
  String get japanese => 'Japanese';

  @override
  String get resetSettings => 'Reset Settings';

  @override
  String get resetAllSettings => 'Reset all settings to default values';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get copy => 'Copy';

  @override
  String get apiKeyCopied => 'API key copied';

  @override
  String get settingsSaved => 'Settings saved!';

  @override
  String get settingsReset => 'Settings reset to default values';

  @override
  String get appInfo => 'App Info';

  @override
  String get appDescription => 'Chat application with AI models through OpenRouter API.\n\nFeatures:\n• Chat with various AI models\n• Chat history storage\n• Dark and light themes\n• Adaptive interface\n\nDeveloped with ❤️ using Flutter';

  @override
  String get shareChat => 'Share Chat';

  @override
  String get copyChat => 'Copy Chat';

  @override
  String get renameChat => 'Rename Chat';

  @override
  String get deleteChat => 'Delete Chat';

  @override
  String get failedToShowMenu => 'Failed to show menu';

  @override
  String get failedToRenameChat => 'Failed to rename chat';

  @override
  String get failedToCopyChat => 'Failed to copy chat';

  @override
  String get chatSharingNotImplemented => 'Chat sharing is not implemented yet';

  @override
  String get newChat => 'New Chat';

  @override
  String get noChatsYet => 'No chats yet';

  @override
  String get startConversation => 'Start a conversation by clicking \"New Chat\"';

  @override
  String get reasoning => 'Reasoning';

  @override
  String get tapToExpand => 'Tap to expand';

  @override
  String get collapse => 'Collapse';

  @override
  String get expand => 'Expand';

  @override
  String chatRenamedTo(Object title) {
    return 'Chat renamed to: $title';
  }

  @override
  String get appTitle => 'Chat AI';

  @override
  String get justNow => 'Just now';

  @override
  String minAgo(Object minutes) {
    return '$minutes min ago';
  }

  @override
  String get onlyOneMinuteAgo => '1 min ago';

  @override
  String hoursAgo(Object hours) {
    return '$hours hours ago';
  }

  @override
  String get onlyOneHourAgo => '1 hour ago';

  @override
  String daysAgo(Object days) {
    return '$days days ago';
  }

  @override
  String get onlyOneDayAgo => '1 day ago';

  @override
  String get renameChatTitle => 'Rename Chat';

  @override
  String get enterNewChatName => 'Enter new chat name';

  @override
  String get rename => 'Rename';

  @override
  String get ok => 'OK';

  @override
  String get modelSelected => 'Model Selected';

  @override
  String get errorLoadingModels => 'Error loading models';

  @override
  String get models => 'Models';

  @override
  String get searchModels => 'Search models';

  @override
  String get refresh => 'Refresh';

  @override
  String get details => 'Details';

  @override
  String get context => 'Context';

  @override
  String get free => 'Free';

  @override
  String get paid => 'Paid';

  @override
  String get multimodal => 'Multimodal';

  @override
  String get vision => 'Vision';

  @override
  String get tools => 'Tools';

  @override
  String get available => 'Available';

  @override
  String get description => 'Description';

  @override
  String get technicalDetails => 'Technical Details';

  @override
  String get provider => 'Provider';

  @override
  String get inputTokens => 'Input Tokens';

  @override
  String get notAvailable => 'Not available';

  @override
  String get outputTokens => 'Output Tokens';

  @override
  String get features => 'Features';

  @override
  String get featuresDisplayedBasedOnActualModelCapabilities => 'Features displayed based on actual model capabilities';

  @override
  String get noModelsFound => 'No models found';

  @override
  String get noAvailableModels => 'No available models';

  @override
  String get tryADifferentSearchQuery => 'Try a different search query';

  @override
  String get tryRefreshingOrCheckYourInternetConnection => 'Try refreshing or check your internet connection';

  @override
  String get aiIsTyping => 'AI is typing';

  @override
  String get failedToSendMessage => 'Failed to send message';

  @override
  String get retry => 'Retry';

  @override
  String get enterYourMessage => 'Enter your message...';

  @override
  String get saveAndSend => 'Save & Send';

  @override
  String get messageEditedSuccessfully => 'Message edited successfully';

  @override
  String get failedToEditMessage => 'Failed to edit message';

  @override
  String get messageEditedAndResponseRegenerated => 'Message edited and response regenerated';

  @override
  String get failedToEditAndSendMessage => 'Failed to edit and send message';

  @override
  String get areYouSureYouWantToDeleteThisMessage => 'Are you sure you want to delete this message?';

  @override
  String get messageDeletedSuccessfully => 'Message deleted successfully';

  @override
  String get failedToDeleteMessage => 'Failed to delete message';

  @override
  String get messageCopied => 'Message copied';

  @override
  String get failedToCopyMessage => 'Failed to copy message';

  @override
  String get messageShared => 'Message shared';

  @override
  String get failedToShareMessage => 'Failed to share message';

  @override
  String get edit => 'Edit';

  @override
  String get share => 'Share';

  @override
  String get copyMessage => 'Copy Message';

  @override
  String get delete => 'Delete';

  @override
  String get listen => 'Listen';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get continueResponse => 'Continue Response';

  @override
  String get like => 'Like';

  @override
  String get dislike => 'Dislike';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get failedToCopy => 'Failed to copy';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String get errorMessage => 'Error message';
}
