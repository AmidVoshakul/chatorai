// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ChatORAI';

  @override
  String get settings => 'Settings';

  @override
  String get providerConfiguration => 'Provider Configuration';

  @override
  String get apiKey => 'API Key';

  @override
  String get enterApiKey => 'Enter your OpenRouter API Key';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get validateApiKey => 'Validate API Key';

  @override
  String get apiKeyValid => 'API Key is valid';

  @override
  String get apiKeyInvalid => 'Invalid API Key format';

  @override
  String get apiKeyEmpty => 'API key cannot be empty';

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
  String get fontSize => 'Font size';

  @override
  String currentSize(Object percentage) {
    return 'Current size: $percentage%';
  }

  @override
  String get accessibility => 'Accessibility';

  @override
  String get reduceMotion => 'Reduce motion';

  @override
  String get disableAnimation => 'Disable or reduce motion effects';

  @override
  String get highContrast => 'High contrast';

  @override
  String get increaseContrast => 'Increase contrast for better readability';

  @override
  String get wideScreenMode => 'Wide screen mode';

  @override
  String get useFullScreenWidth => 'Use full screen width for chat content';

  @override
  String get autoScrollDuringStreaming => 'Auto-scroll during streaming';

  @override
  String get autoScrollDuringStreamingDesc => 'Automatically scroll down when new content appears';

  @override
  String get showContinuationSuggestions => 'Show continuation suggestions';

  @override
  String get showContinuationSuggestionsDesc => 'Display suggested follow-up messages after AI responses';

  @override
  String get expandReasoningByDefault => 'Expand reasoning by default';

  @override
  String get expandReasoningByDefaultDesc => 'Show reasoning/thought blocks expanded when AI responds';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get russian => 'Russian';

  @override
  String get ukrainian => 'Ukrainian';

  @override
  String get arabic => 'Arabic (right-to-left)';

  @override
  String get chinese => 'Chinese';

  @override
  String get japanese => 'Japanese';

  @override
  String get resetSettings => 'Reset settings';

  @override
  String get resetAllSettings => 'Reset all settings to defaults';

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
  String get apiKeySaved => 'API key saved';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get settingsReset => 'Settings reset';

  @override
  String get appInfo => 'App Info';

  @override
  String get appDescription => 'AI Chat Application powered by multiple LLM providers';

  @override
  String get shareChat => 'Share Chat';

  @override
  String get copyChat => 'Copy Chat';

  @override
  String get renameChat => 'Rename Chat';

  @override
  String get failedToShowMenu => 'Failed to show menu';

  @override
  String get failedToRenameChat => 'Failed to rename chat';

  @override
  String get failedToCopyChat => 'Failed to copy chat';

  @override
  String get chatSharingNotImplemented => 'Chat sharing not implemented';

  @override
  String get newChat => 'New Chat';

  @override
  String get noChatsYet => 'No chats yet';

  @override
  String get startConversation => 'Start a conversation';

  @override
  String get reasoning => 'Reasoning';

  @override
  String get tapToExpand => 'Tap to expand';

  @override
  String get collapse => 'Collapse';

  @override
  String get expand => 'Expand';

  @override
  String chatRenamedTo(Object name) {
    return 'Chat renamed to $name';
  }

  @override
  String get appTitle => 'ChatORAI';

  @override
  String get justNow => 'Just now';

  @override
  String minAgo(Object minutes) {
    return '$minutes min ago';
  }

  @override
  String get onlyOneMinuteAgo => '1 minute ago';

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
  String get modelSelected => 'Model selected';

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
  String get loadingMsg1 => 'Waiting for server response…';

  @override
  String get loadingMsg2 => 'Data sent — almost there…';

  @override
  String get loadingMsg3 => 'Formulating thoughts…';

  @override
  String get loadingMsg4 => 'Finding the best answer…';

  @override
  String get loadingMsg5 => 'Loading response (almost)…';

  @override
  String get failedToSendMessage => 'Failed to send message';

  @override
  String get retry => 'Retry';

  @override
  String get bootstrapErrorTitle => 'Failed to start the app';

  @override
  String get bootstrapErrorBody => 'Check your configuration and try again.';

  @override
  String get enterYourMessage => 'Enter your message';

  @override
  String get saveAndSend => 'Save and send';

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
  String confirmDeleteMessage(Object chatTitle) {
    return 'Confirm delete message';
  }

  @override
  String get areYouSureYouWantToRegenerateThisMessage => 'Are you sure you want to regenerate this message?';

  @override
  String modelDoesNotSupportImages(Object modelId) {
    return 'Model does not support images';
  }

  @override
  String chatTitleUpdated(Object title) {
    return 'Chat title updated';
  }

  @override
  String get messageDeletedSuccessfully => 'Message deleted successfully';

  @override
  String get failedToDeleteMessage => 'Failed to delete message';

  @override
  String get regenerationStarted => 'Regeneration started';

  @override
  String get failedToRegenerateMessage => 'Failed to regenerate message';

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
  String get copyMessage => 'Copy message';

  @override
  String get delete => 'Delete';

  @override
  String get listen => 'Listen';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get continueResponse => 'Continue response';

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

  @override
  String get welcomeMessage => 'Welcome to ChatORAI';

  @override
  String get welcomeQuestion1 => 'Explain quantum computing in simple terms';

  @override
  String get welcomeQuestion2 => 'What are the latest trends in artificial intelligence?';

  @override
  String get welcomeQuestion3 => 'Help me write a professional email to my team';

  @override
  String get welcomeQuestion4 => 'What should I learn to become a better programmer?';

  @override
  String get welcomeQuestion5 => 'Give me 5 creative ideas for a weekend project';

  @override
  String get welcomeQuestion6 => 'What are some good books on personal growth?';

  @override
  String get welcomeQuestion7 => 'Help me come up with names for my startup';

  @override
  String get welcomeQuestion8 => 'Create a meal plan for a healthy week';

  @override
  String get welcomeQuestion9 => 'What are the best practices for Flutter development?';

  @override
  String get welcomeQuestion10 => 'Explain the difference between asynchronous and synchronous programming';

  @override
  String get welcomeQuestion11 => 'How to optimize code for better performance?';

  @override
  String get welcomeQuestion12 => 'What are the most useful design patterns?';

  @override
  String get welcomeQuestion13 => 'Teach me the basics of machine learning';

  @override
  String get welcomeQuestion14 => 'What are the key concepts of cloud computing?';

  @override
  String get welcomeQuestion15 => 'Explain blockchain technology for a beginner';

  @override
  String get welcomeQuestion16 => 'How does the internet work from a technical perspective?';

  @override
  String get welcomeQuestion17 => 'What are the best productivity techniques?';

  @override
  String get welcomeQuestion18 => 'How to improve concentration and focus?';

  @override
  String get welcomeQuestion19 => 'Give me a daily schedule for maximum productivity';

  @override
  String get welcomeQuestion20 => 'What are some good habits for success?';

  @override
  String get welcomeQuestion21 => 'How to prepare for an IT interview?';

  @override
  String get welcomeQuestion22 => 'What skills are needed in the tech industry?';

  @override
  String get welcomeQuestion23 => 'How to negotiate a salary increase?';

  @override
  String get welcomeQuestion24 => 'What are the top tech companies to work for?';

  @override
  String get welcomeQuestion25 => 'What are the latest breakthroughs in space research?';

  @override
  String get welcomeQuestion26 => 'How is AI changing healthcare?';

  @override
  String get welcomeQuestion27 => 'What are the most exciting technologies of 2026?';

  @override
  String get welcomeQuestion28 => 'Explain the future of renewable energy';

  @override
  String get welcomeQuestion29 => 'What are the most important philosophical questions?';

  @override
  String get welcomeQuestion30 => 'How to learn to think more critically?';

  @override
  String get welcomeQuestion31 => 'What are the best ways to learn new skills?';

  @override
  String get welcomeQuestion32 => 'How to stay motivated when learning complex material?';

  @override
  String get welcomeQuestion33 => 'Which programming languages are best to learn in 2026?';

  @override
  String get welcomeQuestion34 => 'How to create a strong portfolio for IT jobs?';

  @override
  String get welcomeQuestion35 => 'What are the top AI tools for productivity?';

  @override
  String get welcomeQuestion36 => 'How does machine learning actually work?';

  @override
  String get welcomeQuestion37 => 'What are the best practices for code review?';

  @override
  String get welcomeQuestion38 => 'How to write clean and maintainable code?';

  @override
  String get welcomeQuestion39 => 'What are microservices and when to use them?';

  @override
  String get welcomeQuestion40 => 'Explain the difference between REST API and GraphQL';

  @override
  String get welcomeQuestion41 => 'Which cloud platforms are best to learn?';

  @override
  String get welcomeQuestion42 => 'How to prepare for technical interviews?';

  @override
  String get welcomeQuestion43 => 'What soft skills does every developer need?';

  @override
  String get welcomeQuestion44 => 'How to negotiate a developer\'s salary?';

  @override
  String get welcomeQuestion45 => 'What are the best tools for remote work?';

  @override
  String get welcomeQuestion46 => 'How to stay productive while working remotely?';

  @override
  String get welcomeQuestion47 => 'What are the best project management methodologies?';

  @override
  String get welcomeQuestion48 => 'How to work with difficult colleagues?';

  @override
  String get welcomeQuestion49 => 'What are the best books on leadership?';

  @override
  String get welcomeQuestion50 => 'How to launch a successful tech startup?';

  @override
  String get welcomeQuestion51 => 'What are the latest trends in web development?';

  @override
  String get welcomeQuestion52 => 'How does blockchain technology work?';

  @override
  String get welcomeQuestion53 => 'What are NFTs and are they worth paying attention to?';

  @override
  String get welcomeQuestion54 => 'Explain the concept of the metaverse';

  @override
  String get welcomeQuestion55 => 'What are the best AI models for programming?';

  @override
  String get welcomeQuestion56 => 'How to use ChatGPT effectively?';

  @override
  String get welcomeQuestion57 => 'What are the ethical aspects of AI to consider?';

  @override
  String get welcomeQuestion58 => 'How will AI change work in the future?';

  @override
  String get welcomeQuestion59 => 'What are the best cybersecurity practices?';

  @override
  String get welcomeQuestion60 => 'How to protect your privacy online?';

  @override
  String get welcomeQuestion61 => 'What are the best data science tools?';

  @override
  String get welcomeQuestion62 => 'How to visualize data effectively?';

  @override
  String get welcomeQuestion63 => 'What are the best frameworks for mobile apps?';

  @override
  String get welcomeQuestion64 => 'How to build cross-platform applications?';

  @override
  String get welcomeQuestion65 => 'What are the best game development engines?';

  @override
  String get welcomeQuestion66 => 'How to start working with 3D modeling?';

  @override
  String get welcomeQuestion67 => 'What are the best video editing tools?';

  @override
  String get welcomeQuestion68 => 'How to create engaging content?';

  @override
  String get welcomeQuestion69 => 'What are the best social media strategies?';

  @override
  String get welcomeQuestion70 => 'How to build a personal brand?';

  @override
  String get welcomeQuestion71 => 'What are the best networking tips?';

  @override
  String get welcomeQuestion72 => 'How to make a great presentation?';

  @override
  String get welcomeQuestion73 => 'What are the best time management techniques?';

  @override
  String get welcomeQuestion74 => 'How to avoid burnout?';

  @override
  String get welcomeQuestion75 => 'What are the best meditation apps?';

  @override
  String get welcomeQuestion76 => 'How to improve sleep quality?';

  @override
  String get welcomeQuestion77 => 'What are the best workouts?';

  @override
  String get welcomeQuestion78 => 'How to eat healthy on a limited budget?';

  @override
  String get welcomeQuestion79 => 'What are the best travel destinations for tech specialists?';

  @override
  String get welcomeQuestion80 => 'How to learn a new language quickly?';

  @override
  String get welcomeQuestion81 => 'What are the best practices for remote team collaboration?';

  @override
  String get welcomeQuestion82 => 'How to conduct effective code reviews?';

  @override
  String get welcomeQuestion83 => 'What are the top skills for software architects?';

  @override
  String get welcomeQuestion84 => 'How to design scalable databases?';

  @override
  String get welcomeQuestion85 => 'What are the best DevOps tools to learn?';

  @override
  String get welcomeQuestion86 => 'How to implement CI/CD pipelines?';

  @override
  String get welcomeQuestion87 => 'What is container orchestration?';

  @override
  String get welcomeQuestion88 => 'Explain the benefits of serverless computing';

  @override
  String get welcomeQuestion89 => 'What are the best API security practices?';

  @override
  String get welcomeQuestion90 => 'How to optimize mobile app performance?';

  @override
  String get welcomeQuestion91 => 'What are progressive web apps?';

  @override
  String get welcomeQuestion92 => 'How to create accessible web applications?';

  @override
  String get welcomeQuestion93 => 'What are the best UI/UX design principles?';

  @override
  String get welcomeQuestion94 => 'How to conduct effective user research?';

  @override
  String get welcomeQuestion95 => 'What are the best A/B testing strategies?';

  @override
  String get welcomeQuestion96 => 'How to analyze user behavior?';

  @override
  String get welcomeQuestion97 => 'What are the best growth hacking techniques?';

  @override
  String get welcomeQuestion98 => 'How to build a community around a product?';

  @override
  String get welcomeQuestion99 => 'What are the best customer support tools?';

  @override
  String get welcomeQuestion100 => 'How to effectively handle customer feedback?';

  @override
  String get welcomeQuestion101 => 'What is the difference between React and Vue?';

  @override
  String get welcomeQuestion102 => 'How does TypeScript improve JavaScript development?';

  @override
  String get welcomeQuestion103 => 'What are the best practices for REST API design?';

  @override
  String get welcomeQuestion104 => 'How to implement authentication in web apps?';

  @override
  String get welcomeQuestion105 => 'What are the advantages of GraphQL over REST?';

  @override
  String get welcomeQuestion106 => 'How to optimize database queries for performance?';

  @override
  String get welcomeQuestion107 => 'What are microservices architecture patterns?';

  @override
  String get welcomeQuestion108 => 'How to implement caching strategies?';

  @override
  String get welcomeQuestion109 => 'What are the best JavaScript testing frameworks?';

  @override
  String get welcomeQuestion110 => 'How to write unit tests for React components?';

  @override
  String get welcomeQuestion111 => 'What are the SOLID principles in OOP?';

  @override
  String get welcomeQuestion112 => 'How to implement design patterns in Python?';

  @override
  String get welcomeQuestion113 => 'What are the best practices for Git workflow?';

  @override
  String get welcomeQuestion114 => 'How to effectively resolve merge conflicts?';

  @override
  String get welcomeQuestion115 => 'What are the best practices for containerization?';

  @override
  String get welcomeQuestion116 => 'How to secure Docker containers?';

  @override
  String get welcomeQuestion117 => 'What are Kubernetes deployment strategies?';

  @override
  String get welcomeQuestion118 => 'How to monitor application performance?';

  @override
  String get welcomeQuestion119 => 'What are the best practices for logging?';

  @override
  String get welcomeQuestion120 => 'How to implement error handling in distributed systems?';

  @override
  String get continueConversation => 'Continue conversation';

  @override
  String get generatingSuggestions => 'Generating suggestions';

  @override
  String get searchChats => 'Search chats';

  @override
  String noChatsFound(Object query) {
    return 'No chats found';
  }

  @override
  String get tryDifferentSearchTerm => 'Try a different search term';

  @override
  String get appShortName => 'Chatorai';

  @override
  String get typeYourMessage => 'Type your message';

  @override
  String get addImage => 'Add image';

  @override
  String get addCamera => 'Take photo';

  @override
  String get addFile => 'Add file';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get searchFavorites => 'Search favorites';

  @override
  String get showAllModels => 'Show all models';

  @override
  String get showFavoritesOnly => 'Show favorites only';

  @override
  String get noFavoriteModels => 'No favorite models';

  @override
  String get tapHeartToAddFavorites => 'Tap heart to add favorites';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get recentModels => 'Recent';

  @override
  String get loadingSkills => 'Loading skills';

  @override
  String get noSkillsInstalled => 'No skills installed';

  @override
  String get noSkillsMatchSearch => 'No skills match your search';

  @override
  String get allSkillsRequirePermission => 'All skills require permission';

  @override
  String skillExecuted(Object name) {
    return 'Skill executed';
  }

  @override
  String get configuration => 'Configuration';

  @override
  String get stats => 'Stats';

  @override
  String get usageStatistics => 'Usage Statistics';

  @override
  String get totalSessions => 'Sessions';

  @override
  String get totalMessages => 'Messages';

  @override
  String get days => 'Days';

  @override
  String get totalTokens => 'Total Tokens';

  @override
  String get totalCost => 'Total Cost';

  @override
  String get avgCostPerDay => 'Avg Cost/Day';

  @override
  String get avgTokensPerSession => 'Avg Tokens/Session';

  @override
  String get medianTokensPerSession => 'Median Tokens/Session';

  @override
  String get cacheRead => 'Cache Read';

  @override
  String get cacheWrite => 'Cache Write';

  @override
  String get toolUsage => 'Tool Usage';

  @override
  String get modelUsage => 'Model Usage';

  @override
  String get noStatsAvailable => 'No statistics available';

  @override
  String get reasoningTokens => 'Reasoning';

  @override
  String get addProvider => 'Add Provider';

  @override
  String get applySettings => 'Apply Settings';

  @override
  String get copyCodeTooltip => 'Copy code';

  @override
  String get copiedFeedback => 'Copied';

  @override
  String get defaultSuggestion1 => 'What can you do?';

  @override
  String get defaultSuggestion2 => 'Help me write code';

  @override
  String get defaultSuggestion3 => 'Explain a concept';

  @override
  String get deleteChat => 'Delete chat';

  @override
  String get manageProviders => 'Manage Providers';

  @override
  String get micAutoRestart => 'Auto-restarting microphone...';

  @override
  String get micNoSpeechDetected => 'No speech detected';

  @override
  String get micStartFailed => 'Failed to start microphone';

  @override
  String get micUnavailable => 'Microphone not available';

  @override
  String get modelParameters => 'Model Parameters';

  @override
  String get modelSettings => 'Model Settings';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get noModelSelected => 'No model selected';

  @override
  String get openaiCompatibleApi => 'OpenAI-Compatible API';

  @override
  String get openaiCompatibleApiDescription => 'Connect to any OpenAI-compatible API endpoint';

  @override
  String get permissionAlways => 'Always';

  @override
  String get permissionAlwaysConfirm => 'Always allow this action?';

  @override
  String get permissionDialogPatterns => 'Permission patterns';

  @override
  String get permissionOnce => 'Once';

  @override
  String get permissionReject => 'Reject';

  @override
  String get providers => 'Providers';

  @override
  String get refreshQuestions => 'Refresh questions';

  @override
  String get resetToDefaults => 'Reset to Defaults';

  @override
  String get settingsApplied => 'Settings applied';

  @override
  String get speechErrorNetwork => 'Network error';

  @override
  String get speechErrorNoMatch => 'No speech match';

  @override
  String get speechErrorNotAuthorized => 'Not authorized';

  @override
  String get speechErrorServer => 'Server error';

  @override
  String get speechErrorTimeout => 'Timeout';

  @override
  String get speechErrorTooManyRequests => 'Too many requests';

  @override
  String get speechErrorUnknown => 'Unknown error';

  @override
  String get speechListening => 'Listening...';

  @override
  String get speechPhase2 => 'Processing speech...';

  @override
  String get speechPreparing => 'Preparing...';

  @override
  String get speechProcessing => 'Processing...';

  @override
  String speechStartError(Object error) {
    return 'Failed to start speech recognition';
  }

  @override
  String get systemPrompt => 'System Prompt';

  @override
  String get systemPromptDescription => 'Instructions that define how the AI behaves';

  @override
  String get systemPromptSuggestion => 'You are a helpful assistant.';

  @override
  String get temperature => 'Temperature';

  @override
  String get temperatureDescription => 'Higher values make output more random';

  @override
  String get toggleNavigatorTooltip => 'Toggle navigation';

  @override
  String get userPromptSuggestion => 'How can I help you today?';

  @override
  String get versionLabel => 'Version:';

  @override
  String get welcomeGreeting1 => 'Welcome!';

  @override
  String get welcomeGreeting2 => 'How can I help you?';

  @override
  String get welcomeGreeting3 => 'Ask me anything';

  @override
  String get welcomeGreeting4 => 'I can help you with coding, writing, and analysis';

  @override
  String get welcomeGreeting5 => 'Let\'s get started';

  @override
  String get welcomeGreeting6 => 'What would you like to work on?';

  @override
  String get welcomeGreeting7 => 'Ready to help';

  @override
  String get welcomeGreeting8 => 'Your AI companion is here';

  @override
  String get welcomeGreeting9 => 'Start a conversation';

  @override
  String get welcomeGreeting10 => 'Discover what I can do';

  @override
  String get welcomeGreeting11 => 'Need help? Just ask';

  @override
  String get welcomeGreeting12 => 'I\'m here to help';

  @override
  String modelDoesNotSupportFiles(Object modelId) {
    return 'This model does not support file attachments';
  }

  @override
  String generatingSuggestionsFailed(Object error) {
    return 'Failed to generate suggestions';
  }

  @override
  String get toggleSidebarTooltip => 'Toggle sidebar';

  @override
  String get openMenuTooltip => 'Open menu';

  @override
  String get addFileTooltip => 'Add file';

  @override
  String get modelSettingsTooltip => 'Model settings';

  @override
  String get switchAgentTooltip => 'Switch agent';

  @override
  String get selectModelTooltip => 'Select model';

  @override
  String get removeFileTooltip => 'Remove file';

  @override
  String get goToParentSessionTooltip => 'Go to parent session';

  @override
  String get previousSiblingTooltip => 'Previous sibling';

  @override
  String get nextSiblingTooltip => 'Next sibling';

  @override
  String get cancellingRetryTooltip => 'Cancelling retry...';

  @override
  String get stopGenerationTooltip => 'Stop generation';

  @override
  String get question => 'Question';

  @override
  String get skip => 'Skip';

  @override
  String get answer => 'Answer';

  @override
  String get noAgentsAvailable => 'No agents available';

  @override
  String permissionAlwaysConfirmDescription(Object title) {
    return 'This will allow \"$title\" until the app is restarted.';
  }

  @override
  String get chatActionsMenuTooltip => 'Chat menu';

  @override
  String get startListening => 'Start voice input';

  @override
  String get stopListening => 'Stop voice input';

  @override
  String get listening => 'Listening...';

  @override
  String get sendMessage => 'Send message';

  @override
  String get maxTokens => 'Max Tokens';

  @override
  String get maxTokensDescription => 'Maximum length of generated response';

  @override
  String get activeModel => 'Active Model';

  @override
  String apiLimitExceeded(Object limit) {
    return 'API limit exceeded: $limit';
  }

  @override
  String valueExceedsApiLimit(Object limit) {
    return 'Value exceeds API limit ($limit). Maximum value will be used.';
  }

  @override
  String get micStopFailed => 'Failed to stop microphone';

  @override
  String get errorProcessingRequest => 'Sorry, I encountered an error while processing your request. Please try again.';

  @override
  String rateLimitRetryMessage(Object seconds) {
    return 'Rate limit exceeded. Retrying in $seconds seconds...';
  }

  @override
  String get messageNotFound => 'Message not found';

  @override
  String get errorEditingMessage => 'Error editing message';

  @override
  String get errorEditAndSendMessage => 'Error editing and sending message';

  @override
  String get defaultSuggestion4 => 'How does this apply in practice?';

  @override
  String get fileAttachedButNotSupported => 'File attached but not supported by the current model';

  @override
  String get expandTooltip => 'Expand';

  @override
  String get collapseTooltip => 'Collapse';

  @override
  String get addProviderTitleEdit => 'Edit Provider';

  @override
  String get addProviderTitleAdd => 'Add Provider';

  @override
  String get addProviderLabelProvider => 'Provider';

  @override
  String get addProviderCustomName => 'Custom Provider...';

  @override
  String get addProviderFieldProviderName => 'Provider Name';

  @override
  String get addProviderHintProviderName => 'e.g. My Custom AI';

  @override
  String get addProviderLabelApiKey => 'API Key';

  @override
  String get addProviderHintApiKey => 'Enter your API key';

  @override
  String get addProviderHintCustomApiKey => 'Optional for local providers';

  @override
  String get addProviderLabelBaseUrl => 'Base URL';

  @override
  String get addProviderHintBaseUrl => 'https://api.example.com/v1';

  @override
  String get addProviderActionSave => 'Save';

  @override
  String get addProviderErrorApiKeyRequired => 'API key is required';

  @override
  String get selectModels => 'Select Models';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get selectAll => 'Select All';

  @override
  String get modelsAvailable => 'No models available';

  @override
  String get modelsMatchSearch => 'No models match your search';

  @override
  String selectModelsCount(Object count, Object total) {
    return '$count of $total selected';
  }

  @override
  String modelsLoadError(Object error) {
    return 'Failed to load models: $error';
  }

  @override
  String get systemPromptHint => 'You are a helpful assistant...';

  @override
  String get temperatureHint => '0.0 - 2.0';

  @override
  String get loadingSettings => 'Loading settings...';

  @override
  String errorApplyingSettings(Object error) {
    return 'Error applying settings: $error';
  }

  @override
  String deleteProviderTitle(Object providerName) {
    return 'Delete $providerName?';
  }

  @override
  String get deleteProviderContent => 'This will remove the provider and all its settings. You will need to add it again to use its models.';

  @override
  String get errorLoadingProviders => 'Error loading providers';

  @override
  String get noProvidersConfigured => 'No providers configured';

  @override
  String get addProviderToGetStarted => 'Add a provider with an API key to get started';

  @override
  String statsError(Object error) {
    return 'Error: $error';
  }

  @override
  String get total => 'Total';

  @override
  String modelsProviderCountFormat(Object count, Object providerName) {
    return '$providerName · $count';
  }

  @override
  String get mcpServers => 'MCP servers';

  @override
  String get mcpAddServer => 'Add MCP server';

  @override
  String get mcpAddServerTitle => 'Add MCP server';

  @override
  String get mcpNameLabel => 'Name';

  @override
  String get mcpNameHint => 'e.g. filesystem';

  @override
  String get mcpNameHelper => 'Unique identifier used in chatorai.json';

  @override
  String get mcpTypeLocal => 'Local';

  @override
  String get mcpTypeRemote => 'Remote';

  @override
  String get mcpTypeLocalTooltip => 'Runs on your machine';

  @override
  String get mcpTypeRemoteTooltip => 'HTTP/SSE endpoint';

  @override
  String get mcpCommandLabel => 'Command';

  @override
  String get mcpCommandHint => 'uvx mcp-server-filesystem ~/docs';

  @override
  String get mcpCommandHelper => 'Full command with arguments, space-separated';

  @override
  String get mcpUrlLabel => 'URL';

  @override
  String get mcpUrlHint => 'https://example.com/mcp';

  @override
  String get mcpUrlHelper => 'Full MCP endpoint URL';

  @override
  String get mcpEnvLabel => 'Environment variables (JSON)';

  @override
  String get mcpEnvHint => 'GITHUB_TOKEN=ghp_xxx';

  @override
  String get mcpEnvHelper => 'Optional. Paste a JSON object of string keys, e.g. a single TOKEN entry.';

  @override
  String get mcpTokenLabel => 'Access token';

  @override
  String get mcpTokenHint => 'Paste your token only (no Bearer / quotes)';

  @override
  String get mcpTokenHelper => 'Optional. Leave empty for public servers; paste just the token and the header is added automatically.';

  @override
  String get mcpAuthTypeLabel => 'Token type';

  @override
  String get mcpAuthTypeHelper => 'How the token is sent: Bearer (Authorization), ApiKey (X-Api-Key), or plain Token.';

  @override
  String get mcpHeadersLabel => 'Headers (JSON)';

  @override
  String get mcpHeadersHint => 'Authorization=Bearer token';

  @override
  String get mcpHeadersHelper => 'Optional. Paste a JSON object of string header keys.';

  @override
  String get mcpFormTab => 'Form';

  @override
  String get mcpRawTab => 'Raw JSON';

  @override
  String get mcpRawLabel => 'Server object (JSON)';

  @override
  String get mcpRawHelper => 'Paste the server object as in the docs — the server name is the outer key (e.g. searxng). You can paste the full block including the mcpServers wrapper.';

  @override
  String mcpParseError(Object field, Object message) {
    return 'Invalid JSON in $field: $message';
  }

  @override
  String get mcpAddAction => 'Add';

  @override
  String get mcpCancelAction => 'Cancel';

  @override
  String get mcpRemoveTitle => 'Remove MCP server?';

  @override
  String mcpRemoveContent(Object name) {
    return 'Remove \"$name\" from chatorai.json?';
  }

  @override
  String get mcpRemoveAction => 'Remove';

  @override
  String get mcpEditAction => 'Edit';

  @override
  String get mcpEditServerTitle => 'Edit MCP server';

  @override
  String get mcpSaveAction => 'Save';

  @override
  String get mcpNoServers => 'No MCP servers configured';

  @override
  String get mcpNoServersHint => 'Add a Model Context Protocol server to extend tooling';

  @override
  String get mcpTooltipAdd => 'Add server';

  @override
  String get mcpTooltipRefresh => 'Refresh';

  @override
  String get mcpMarketplaceTab => 'Marketplace';

  @override
  String get mcpInstalledTab => 'Installed';

  @override
  String get mcpInstall => 'Install';

  @override
  String get mcpInstalled => 'Installed';

  @override
  String get mcpMarketplaceSearchHint => 'Search servers…';

  @override
  String get mcpMarketplaceEmpty => 'No servers match your search';

  @override
  String get mcpMarketCategoryAll => 'All';

  @override
  String get mcpMarketCategorySearch => 'Search';

  @override
  String get mcpMarketCategoryDocs => 'Docs';

  @override
  String get mcpMarketCategoryDesign => 'Design';

  @override
  String get mcpMarketCategoryDev => 'Dev';

  @override
  String get mcpMarketCategoryFinance => 'Finance';

  @override
  String get mcpMarketCategoryTravel => 'Travel';

  @override
  String get mcpMarketCategoryJobs => 'Jobs';

  @override
  String get mcpMarketCategoryProductivity => 'Productivity';

  @override
  String get mcpMarketCategorySocial => 'Social';

  @override
  String get mcpMarketCategoryOther => 'Other';

  @override
  String get mcpMarketNeedsToken => 'Needs key';

  @override
  String get mcpMarketDescExa => 'Exa provides web search and code documentation lookup for AI workflows. Its connector feeds assistants real-time context to find relevant web pages, technical docs, and source material when grounded external information is needed for an answer.';

  @override
  String get mcpMarketDescContext7 => 'Context7 delivers up-to-date code examples and documentation for AI-powered programmers and code editors. Its MCP connector integrates current library context into assistant workflows, reducing tab-switching and helping generated code avoid outdated APIs, nonexistent methods, and stale implementation patterns.';

  @override
  String get mcpMarketDescHuggingFace => 'Hugging Face connects voice assistants to the Hugging Face Hub and thousands of Gradio apps. Its connector integrates model, dataset, space, and app context into AI workflows for discovery, experimentation, and machine learning research.';

  @override
  String get mcpMarketDescParallel => 'Parallel Search provides real-time web search and content extraction for search-driven AI workflows. Its remote MCP server helps assistants fetch current web-page context, verify pages, and use extracted content when answering questions or researching topics that need fresh information.';

  @override
  String get mcpMarketDescTavily => 'Tavily gives AI agents real-time access to web resources via APIs for search, retrieval, and research. Its connector helps assistants ground answers in live data, extract relevant content, and support production agent workflows with safety controls.';

  @override
  String get mcpMarketDescGithub => 'GitHub is a platform for collaborating on code, issues, pull requests, and project history. Its official remote MCP server gives assistants structured repository context to understand source changes, reviews, development workflows, and GitHub project status.';

  @override
  String get mcpMarketDescPostman => 'Postman provides API context for coding agents and developer workflows. Its connector integrates API definitions, documentation, and collaboration context into assistant work, letting agents analyze integrations and implementation details.';

  @override
  String get mcpMarketDescSlack => 'Slack is a collaboration hub uniting team messages, channels, users, and shared workspaces. Its remote MCP server integrates workspace conversation context into assistant workflows, helping users find answers, summarize discussions, and understand activity across channels.';

  @override
  String get mcpMarketDescFigma => 'Figma is a product design platform for UI design, prototyping, and developer handoff. Its remote MCP server brings files, projects, and dev-mode context into assistant workflows, letting agents understand visual work and map it to implementation tasks.';

  @override
  String get mcpMarketDescCanva => 'Canva is a visual communication platform for presentations, social graphics, documents, and brand materials. Its remote MCP server gives assistants access to Canva projects, assets, exported files, and comments, letting them discuss, edit, and prepare creative work from gathered info.';

  @override
  String get mcpMarketDescStripe => 'Stripe is a payments and financial infrastructure platform for processing payments, billing, customers, and developer documentation. Its remote MCP server gives assistants account and implementation context backed by Stripe to understand customer workflows, billing questions, and payment tasks.';

  @override
  String get mcpMarketDescTrivago => 'Trivago helps users search for hotels and lodging by coordinates, city, country, dates, and travel context. Its connector gives assistants lodging-search context to find suitable stays near destinations or points of interest.';

  @override
  String get mcpMarketDescSend => 'Send helps users create shareable documents, one-page docs, presentations, and slides. Its connector lets assistants turn requested materials into published links, interactive pages, and trackable deliverables for recipients.';

  @override
  String get mcpMarketDescZiprecruiter => 'ZipRecruiter helps users search live jobs by title, company, location, salary, distance, work style, employment type, and posting date. Its connector integrates job-search context into assistant workflows before handing applications back to ZipRecruiter.';

  @override
  String get mcpMarketDescAdobeCreativity => 'Adobe for Creativity unites Photoshop, Lightroom, Illustrator, Firefly, Premiere, Express, InDesign, and Stock with AI-driven creative work. Users can generate, edit, and enhance photos, design assets, and video projects using natural language while work stays tied to their Adobe account.';
}
