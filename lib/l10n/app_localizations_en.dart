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
  String get ukrainian => 'Ukrainian';

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
  String get appDescription => 'Chat application with AI models through OpenRouter API.\n\nFeatures:\n• Chat with various AI models\n• Chat history storage\n• Dark and light themes\n• Adaptive interface\n\nVersion: 1.0.1.1\n\nDeveloped with ❤️ using Flutter';

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
  String get appTitle => 'Chat ORAI';

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
  String get areYouSureYouWantToRegenerateThisMessage => 'Are you sure you want to regenerate this message?';

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

  @override
  String get welcomeMessage => 'Welcome! How can I help you today?';

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
  String get welcomeQuestion6 => 'What are some good books for personal development?';

  @override
  String get welcomeQuestion7 => 'Help me brainstorm names for my new startup';

  @override
  String get welcomeQuestion8 => 'Create a meal plan for a healthy week';

  @override
  String get welcomeQuestion9 => 'What are the best practices for Flutter development?';

  @override
  String get welcomeQuestion10 => 'Explain the difference between async and sync programming';

  @override
  String get welcomeQuestion11 => 'How do I optimize my code for better performance?';

  @override
  String get welcomeQuestion12 => 'What are the most useful programming design patterns?';

  @override
  String get welcomeQuestion13 => 'Teach me the basics of machine learning';

  @override
  String get welcomeQuestion14 => 'What are the key concepts of cloud computing?';

  @override
  String get welcomeQuestion15 => 'Explain blockchain technology to a beginner';

  @override
  String get welcomeQuestion16 => 'How does the internet work from a technical perspective?';

  @override
  String get welcomeQuestion17 => 'What are the best productivity techniques?';

  @override
  String get welcomeQuestion18 => 'How can I improve my focus and concentration?';

  @override
  String get welcomeQuestion19 => 'Give me a daily routine for maximum productivity';

  @override
  String get welcomeQuestion20 => 'What are some good habits for success?';

  @override
  String get welcomeQuestion21 => 'How to prepare for a software engineering interview?';

  @override
  String get welcomeQuestion22 => 'What skills are most valuable in tech industry?';

  @override
  String get welcomeQuestion23 => 'How to negotiate a salary increase?';

  @override
  String get welcomeQuestion24 => 'What are the top tech companies to work for?';

  @override
  String get welcomeQuestion25 => 'What are the latest breakthroughs in space exploration?';

  @override
  String get welcomeQuestion26 => 'How is AI changing healthcare?';

  @override
  String get welcomeQuestion27 => 'What are the most exciting technologies of 2025?';

  @override
  String get welcomeQuestion28 => 'Explain the future of renewable energy';

  @override
  String get welcomeQuestion29 => 'What are the most important philosophical questions?';

  @override
  String get welcomeQuestion30 => 'How can I think more critically about problems?';

  @override
  String get welcomeQuestion31 => 'What are the best ways to learn new skills?';

  @override
  String get welcomeQuestion32 => 'How do I stay motivated when learning something difficult?';

  @override
  String get welcomeQuestion33 => 'What are the best programming languages to learn in 2025?';

  @override
  String get welcomeQuestion34 => 'How to build a strong portfolio for tech jobs?';

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
  String get welcomeQuestion40 => 'Explain REST API vs GraphQL';

  @override
  String get welcomeQuestion41 => 'What are the best cloud platforms to learn?';

  @override
  String get welcomeQuestion42 => 'How to prepare for technical interviews?';

  @override
  String get welcomeQuestion43 => 'What are soft skills every developer needs?';

  @override
  String get welcomeQuestion44 => 'How to negotiate salary as a developer?';

  @override
  String get welcomeQuestion45 => 'What are the best remote work tools?';

  @override
  String get welcomeQuestion46 => 'How to stay productive working from home?';

  @override
  String get welcomeQuestion47 => 'What are the best project management methodologies?';

  @override
  String get welcomeQuestion48 => 'How to handle difficult coworkers?';

  @override
  String get welcomeQuestion49 => 'What are the best books for leadership?';

  @override
  String get welcomeQuestion50 => 'How to start a successful tech startup?';

  @override
  String get welcomeQuestion51 => 'What are the latest trends in web development?';

  @override
  String get welcomeQuestion52 => 'How does blockchain technology work?';

  @override
  String get welcomeQuestion53 => 'What are NFTs and should I care?';

  @override
  String get welcomeQuestion54 => 'Explain the metaverse concept';

  @override
  String get welcomeQuestion55 => 'What are the best AI models for coding?';

  @override
  String get welcomeQuestion56 => 'How to use ChatGPT effectively?';

  @override
  String get welcomeQuestion57 => 'What are the ethics of AI?';

  @override
  String get welcomeQuestion58 => 'How will AI change jobs in the future?';

  @override
  String get welcomeQuestion59 => 'What are the best cybersecurity practices?';

  @override
  String get welcomeQuestion60 => 'How to protect my privacy online?';

  @override
  String get welcomeQuestion61 => 'What are the best data science tools?';

  @override
  String get welcomeQuestion62 => 'How to visualize data effectively?';

  @override
  String get welcomeQuestion63 => 'What are the best mobile app frameworks?';

  @override
  String get welcomeQuestion64 => 'How to build cross-platform apps?';

  @override
  String get welcomeQuestion65 => 'What are the best game development engines?';

  @override
  String get welcomeQuestion66 => 'How to get started with 3D modeling?';

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
  String get welcomeQuestion72 => 'How to give a great presentation?';

  @override
  String get welcomeQuestion73 => 'What are the best time management techniques?';

  @override
  String get welcomeQuestion74 => 'How to avoid burnout?';

  @override
  String get welcomeQuestion75 => 'What are the best meditation apps?';

  @override
  String get welcomeQuestion76 => 'How to improve sleep quality?';

  @override
  String get welcomeQuestion77 => 'What are the best exercise routines?';

  @override
  String get welcomeQuestion78 => 'How to eat healthy on a budget?';

  @override
  String get welcomeQuestion79 => 'What are the best travel destinations for tech workers?';

  @override
  String get welcomeQuestion80 => 'How to learn a new language quickly?';

  @override
  String get welcomeQuestion81 => 'What are the best practices for remote team collaboration?';

  @override
  String get welcomeQuestion82 => 'How to conduct effective code reviews?';

  @override
  String get welcomeQuestion83 => 'What are the top skills for software architects?';

  @override
  String get welcomeQuestion84 => 'How to design scalable database systems?';

  @override
  String get welcomeQuestion85 => 'What are the best DevOps tools to learn?';

  @override
  String get welcomeQuestion86 => 'How to implement CI/CD pipelines?';

  @override
  String get welcomeQuestion87 => 'What are container orchestration platforms?';

  @override
  String get welcomeQuestion88 => 'Explain serverless computing benefits';

  @override
  String get welcomeQuestion89 => 'What are the best practices for API security?';

  @override
  String get welcomeQuestion90 => 'How to optimize mobile app performance?';

  @override
  String get welcomeQuestion91 => 'What are progressive web apps?';

  @override
  String get welcomeQuestion92 => 'How to build accessible web applications?';

  @override
  String get welcomeQuestion93 => 'What are the best UI/UX design principles?';

  @override
  String get welcomeQuestion94 => 'How to conduct user research effectively?';

  @override
  String get welcomeQuestion95 => 'What are the best A/B testing strategies?';

  @override
  String get welcomeQuestion96 => 'How to analyze user behavior data?';

  @override
  String get welcomeQuestion97 => 'What are the best growth hacking techniques?';

  @override
  String get welcomeQuestion98 => 'How to build a community around your product?';

  @override
  String get welcomeQuestion99 => 'What are the best customer support tools?';

  @override
  String get welcomeQuestion100 => 'How to handle customer feedback effectively?';

  @override
  String get welcomeQuestion101 => 'What are the differences between React and Vue?';

  @override
  String get welcomeQuestion102 => 'How does TypeScript improve JavaScript development?';

  @override
  String get welcomeQuestion103 => 'What are the best practices for REST API design?';

  @override
  String get welcomeQuestion104 => 'How to implement authentication in web apps?';

  @override
  String get welcomeQuestion105 => 'What are GraphQL advantages over REST?';

  @override
  String get welcomeQuestion106 => 'How to optimize database queries for performance?';

  @override
  String get welcomeQuestion107 => 'What are microservices architecture patterns?';

  @override
  String get welcomeQuestion108 => 'How to implement caching strategies?';

  @override
  String get welcomeQuestion109 => 'What are the best testing frameworks for JavaScript?';

  @override
  String get welcomeQuestion110 => 'How to write unit tests for React components?';

  @override
  String get welcomeQuestion111 => 'What are the SOLID principles in OOP?';

  @override
  String get welcomeQuestion112 => 'How to implement design patterns in Python?';

  @override
  String get welcomeQuestion113 => 'What are the best practices for Git workflow?';

  @override
  String get welcomeQuestion114 => 'How to handle merge conflicts effectively?';

  @override
  String get welcomeQuestion115 => 'What are containerization best practices?';

  @override
  String get welcomeQuestion116 => 'How to secure Docker containers?';

  @override
  String get welcomeQuestion117 => 'What are Kubernetes deployment strategies?';

  @override
  String get welcomeQuestion118 => 'How to monitor application performance?';

  @override
  String get welcomeQuestion119 => 'What are the best logging practices?';

  @override
  String get welcomeQuestion120 => 'How to implement error handling in distributed systems?';

  @override
  String get continueConversation => 'Continue the conversation';

  @override
  String get generatingSuggestions => 'Generating suggestions...';

  @override
  String get searchChats => 'Search chats...';

  @override
  String noChatsFound(Object query) {
    return 'No chats found for \"$query\"';
  }

  @override
  String get tryDifferentSearchTerm => 'Try a different search term';

  @override
  String get appShortName => 'ChatORAI';

  @override
  String get typeYourMessage => 'Type your message...';

  @override
  String get addImage => 'Image';

  @override
  String get addCamera => 'Camera';

  @override
  String get addFile => 'File';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get searchFavorites => 'Search favorites...';

  @override
  String get showAllModels => 'Show All Models';

  @override
  String get showFavoritesOnly => 'Show Favorites Only';

  @override
  String get noFavoriteModels => 'No favorite models';

  @override
  String get tapHeartToAddFavorites => 'Tap the heart icon on models to add them to your favorites';

  @override
  String get startListening => 'Start voice input';

  @override
  String get stopListening => 'Stop voice input';

  @override
  String get listening => 'Listening...';

  @override
  String get micUnavailable => 'Microphone unavailable';

  @override
  String get sendMessage => 'Send message';

  @override
  String get modelSettings => 'Model Settings';

  @override
  String get temperature => 'Temperature';

  @override
  String get temperatureDescription => 'Controls randomness: lower = more focused, higher = more creative';

  @override
  String get maxTokens => 'Max Tokens';

  @override
  String get maxTokensDescription => 'Maximum length of generated response';

  @override
  String get topP => 'Top P';

  @override
  String get topPDescription => 'Nucleus sampling: lower = more focused, higher = more diverse';

  @override
  String get frequencyPenalty => 'Frequency Penalty';

  @override
  String get frequencyPenaltyDescription => 'Reduces repetition of similar tokens';

  @override
  String get presencePenalty => 'Presence Penalty';

  @override
  String get presencePenaltyDescription => 'Encourages new topics';

  @override
  String get systemPrompt => 'System Prompt';

  @override
  String get systemPromptDescription => 'Instructions for the AI assistant';

  @override
  String get streamResponse => 'Stream Response';

  @override
  String get streamResponseDescription => 'Receive responses in real-time';

  @override
  String get resetToDefaults => 'Reset to Defaults';

  @override
  String get applySettings => 'Apply Settings';

  @override
  String get modelParameters => 'Model Parameters';

  @override
  String get activeModel => 'Active Model';

  @override
  String get noModelSelected => 'No model selected';

  @override
  String get settingsApplied => 'Settings applied successfully';

  @override
  String get enableReasoning => 'Enable Reasoning';

  @override
  String get enableReasoningDescription => 'Include model reasoning/thoughts in responses';

  @override
  String apiLimitExceeded(Object limit) {
    return 'API limit exceeded: $limit';
  }

  @override
  String valueExceedsApiLimit(Object limit) {
    return 'Value exceeds API limit ($limit). Maximum value will be used.';
  }

  @override
  String get micStartFailed => 'Failed to start microphone';

  @override
  String get micStopFailed => 'Failed to stop microphone';

  @override
  String get speechErrorNoMatch => 'Could not recognize speech. Please try again.';

  @override
  String get speechErrorTimeout => 'Listening timeout. Nothing heard.';

  @override
  String get speechErrorNetwork => 'Network error. Check your internet connection.';

  @override
  String get speechErrorNotAuthorized => 'No microphone access. Check permissions in settings.';

  @override
  String get speechErrorServer => 'Recognition server error. Please try again later.';

  @override
  String get speechErrorTooManyRequests => 'Too many requests. Please try again later.';

  @override
  String get speechErrorUnknown => 'Speech recognition error';

  @override
  String get speechPreparing => 'Preparing...';

  @override
  String get speechListening => 'Speak now...';

  @override
  String get speechProcessing => 'Processing...';

  @override
  String get micNoSpeechDetected => 'I didn\'t hear you. Please try again.';

  @override
  String get micAutoRestart => 'Retrying...';

  @override
  String get speechPhase2 => 'I can\'t hear you...speak louder';

  @override
  String speechStartError(Object error) {
    return 'Start error: $error';
  }

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
  String generatingSuggestionsFailed(Object error) {
    return 'Failed to generate suggestions: $error';
  }

  @override
  String get selectModelTooltip => 'Select Model';

  @override
  String get toggleNavigatorTooltip => 'Toggle Navigator';

  @override
  String get defaultSuggestion1 => 'Tell me more about this topic';

  @override
  String get defaultSuggestion2 => 'Can you provide examples?';

  @override
  String get defaultSuggestion3 => 'What are the alternatives?';

  @override
  String get defaultSuggestion4 => 'How does this apply in practice?';

  @override
  String get systemPromptSuggestion => 'You are a helpful assistant. Continue the conversation by providing 3 specific and logical continuations of the last message. Respond in the same language as the user.';

  @override
  String get userPromptSuggestion => 'Provide 3 specific and logical continuations for this message. Answer only with the list, no additional text.';

  @override
  String get refreshQuestions => 'Refresh questions';

  @override
  String get noInternetConnection => 'No internet connection';
}
