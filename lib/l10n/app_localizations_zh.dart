// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'ChatORAI';

  @override
  String get settings => '设置';

  @override
  String get providerConfiguration => '提供商配置';

  @override
  String get apiKey => 'API 密钥';

  @override
  String get enterApiKey => '输入您的 OpenRouter API 密钥';

  @override
  String get baseUrl => '基础 URL';

  @override
  String get validateApiKey => '验证 API 密钥';

  @override
  String get apiKeyValid => 'API 密钥有效';

  @override
  String get apiKeyInvalid => 'API 密钥格式无效';

  @override
  String get apiKeyEmpty => 'API 密钥不能为空';

  @override
  String get appearance => '外观';

  @override
  String get theme => '主题';

  @override
  String get system => '系统';

  @override
  String get useSystemTheme => '使用系统主题';

  @override
  String get light => '浅色';

  @override
  String get useLightTheme => '使用浅色主题';

  @override
  String get dark => '深色';

  @override
  String get useDarkTheme => '使用深色主题';

  @override
  String get fontSize => '字体大小';

  @override
  String currentSize(Object percentage) {
    return '当前大小: $percentage%';
  }

  @override
  String get accessibility => '无障碍';

  @override
  String get reduceMotion => '减少动画';

  @override
  String get disableAnimation => '禁用或减少动画效果';

  @override
  String get highContrast => '高对比度';

  @override
  String get increaseContrast => '增加对比度以提高可读性';

  @override
  String get wideScreenMode => '宽屏模式';

  @override
  String get useFullScreenWidth => '使用全屏宽度显示聊天内容';

  @override
  String get language => '语言';

  @override
  String get english => '英语';

  @override
  String get russian => '俄语';

  @override
  String get ukrainian => '乌克兰语';

  @override
  String get arabic => '阿拉伯语 (RTL)';

  @override
  String get chinese => '中文';

  @override
  String get japanese => '日语';

  @override
  String get resetSettings => '重置设置';

  @override
  String get resetAllSettings => '将所有设置重置为默认值';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get close => '关闭';

  @override
  String get copy => '复制';

  @override
  String get apiKeyCopied => 'API 密钥已复制';

  @override
  String get apiKeySaved => 'API 密钥保存成功';

  @override
  String get settingsSaved => '设置已保存！';

  @override
  String get settingsReset => '设置已重置为默认值';

  @override
  String get appInfo => '应用信息';

  @override
  String get appDescription => '通过 OpenRouter API 与 AI 模型聊天的应用程序。\n\n功能：\n• 与各种 AI 模型聊天\n• 聊天历史记录存储\n• 深色和浅色主题\n• 自适应界面\n\n版本: 1.0.1.1\n\n使用 Flutter 开发';

  @override
  String get shareChat => '分享聊天';

  @override
  String get copyChat => '复制聊天';

  @override
  String get renameChat => '重命名聊天';

  @override
  String get deleteChat => '删除聊天';

  @override
  String get failedToShowMenu => '无法显示菜单';

  @override
  String get failedToRenameChat => '无法重命名聊天';

  @override
  String get failedToCopyChat => '无法复制聊天';

  @override
  String get chatSharingNotImplemented => '聊天分享功能尚未实现';

  @override
  String get newChat => '新聊天';

  @override
  String get noChatsYet => '尚无聊天';

  @override
  String get startConversation => '点击“新聊天”开始对话';

  @override
  String get reasoning => '推理';

  @override
  String get tapToExpand => '点击展开';

  @override
  String get collapse => '折叠';

  @override
  String get expand => '展开';

  @override
  String chatRenamedTo(Object title) {
    return '聊天已重命名为: $title';
  }

  @override
  String get appTitle => 'Chat ORAI';

  @override
  String get justNow => '刚刚';

  @override
  String minAgo(Object minutes) {
    return '$minutes 分钟前';
  }

  @override
  String get onlyOneMinuteAgo => '1 分钟前';

  @override
  String hoursAgo(Object hours) {
    return '$hours 小时前';
  }

  @override
  String get onlyOneHourAgo => '1 小时前';

  @override
  String daysAgo(Object days) {
    return '$days 天前';
  }

  @override
  String get onlyOneDayAgo => '1 天前';

  @override
  String get renameChatTitle => '重命名聊天';

  @override
  String get enterNewChatName => '输入新聊天名称';

  @override
  String get rename => '重命名';

  @override
  String get ok => '确定';

  @override
  String get modelSelected => '模型已选择';

  @override
  String get errorLoadingModels => '加载模型时出错';

  @override
  String get models => '模型';

  @override
  String get searchModels => '搜索模型';

  @override
  String get refresh => '刷新';

  @override
  String get details => '详情';

  @override
  String get context => '上下文';

  @override
  String get free => '免费';

  @override
  String get paid => '付费';

  @override
  String get multimodal => '多模态';

  @override
  String get vision => '视觉';

  @override
  String get tools => '工具';

  @override
  String get available => '可用';

  @override
  String get description => '描述';

  @override
  String get technicalDetails => '技术详情';

  @override
  String get provider => '提供商';

  @override
  String get inputTokens => '输入令牌';

  @override
  String get notAvailable => '不可用';

  @override
  String get outputTokens => '输出令牌';

  @override
  String get features => '特性';

  @override
  String get featuresDisplayedBasedOnActualModelCapabilities => '特性根据模型实际能力显示';

  @override
  String get noModelsFound => '未找到模型';

  @override
  String get noAvailableModels => '无可用模型';

  @override
  String get tryADifferentSearchQuery => '尝试不同的搜索查询';

  @override
  String get tryRefreshingOrCheckYourInternetConnection => '尝试刷新或检查您的网络连接';

  @override
  String get aiIsTyping => 'AI 正在输入';

  @override
  String get failedToSendMessage => '无法发送消息';

  @override
  String get retry => '重试';

  @override
  String get enterYourMessage => '输入您的消息...';

  @override
  String get saveAndSend => '保存并发送';

  @override
  String get messageEditedSuccessfully => '消息编辑成功';

  @override
  String get failedToEditMessage => '无法编辑消息';

  @override
  String get messageEditedAndResponseRegenerated => '消息已编辑并重新生成响应';

  @override
  String get failedToEditAndSendMessage => '无法编辑并发送消息';

  @override
  String get areYouSureYouWantToDeleteThisMessage => '您确定要删除此消息吗？';

  @override
  String confirmDeleteMessage(Object chatTitle) {
    return '您确定要删除聊天\"$chatTitle\"吗？';
  }

  @override
  String get areYouSureYouWantToRegenerateThisMessage => '您确定要重新生成此消息吗？';

  @override
  String modelDoesNotSupportImages(Object modelId) {
    return '模型 $modelId 不支持图像。您可以附加照片，但发送将不起作用。';
  }

  @override
  String chatTitleUpdated(Object title) {
    return '聊天已重命名为: $title';
  }

  @override
  String get messageDeletedSuccessfully => '消息删除成功';

  @override
  String get failedToDeleteMessage => '无法删除消息';

  @override
  String get regenerationStarted => '重新生成已开始';

  @override
  String get failedToRegenerateMessage => '无法重新生成消息';

  @override
  String get messageCopied => '消息已复制';

  @override
  String get failedToCopyMessage => '无法复制消息';

  @override
  String get messageShared => '消息已分享';

  @override
  String get failedToShareMessage => '无法分享消息';

  @override
  String get edit => '编辑';

  @override
  String get share => '分享';

  @override
  String get copyMessage => '复制消息';

  @override
  String get delete => '删除';

  @override
  String get listen => '收听';

  @override
  String get regenerate => '重新生成';

  @override
  String get continueResponse => '继续响应';

  @override
  String get like => '喜欢';

  @override
  String get dislike => '不喜欢';

  @override
  String get copiedToClipboard => '已复制到剪贴板';

  @override
  String get failedToCopy => '复制失败';

  @override
  String get messageDeleted => '消息已删除';

  @override
  String get errorMessage => '错误消息';

  @override
  String get welcomeMessage => '欢迎！今天我能帮您什么？';

  @override
  String get welcomeQuestion1 => '用简单的术语解释量子计算';

  @override
  String get welcomeQuestion2 => '人工智能的最新趋势是什么？';

  @override
  String get welcomeQuestion3 => '帮助我写一封专业的团队邮件';

  @override
  String get welcomeQuestion4 => '我应该学习什么才能成为更好的程序员？';

  @override
  String get welcomeQuestion5 => '给我5个周末项目的创意想法';

  @override
  String get welcomeQuestion6 => '有哪些好的个人发展书籍？';

  @override
  String get welcomeQuestion7 => '帮助我为新创业公司想名字';

  @override
  String get welcomeQuestion8 => '制定健康的一周饮食计划';

  @override
  String get welcomeQuestion9 => 'Flutter 开发的最佳实践是什么？';

  @override
  String get welcomeQuestion10 => '解释异步和同步编程的区别';

  @override
  String get welcomeQuestion11 => '如何优化代码以获得更好的性能？';

  @override
  String get welcomeQuestion12 => '最有用的编程设计模式是什么？';

  @override
  String get welcomeQuestion13 => '教我机器学习的基础知识';

  @override
  String get welcomeQuestion14 => '云计算的关键概念是什么？';

  @override
  String get welcomeQuestion15 => '向初学者解释区块链技术';

  @override
  String get welcomeQuestion16 => '互联网从技术角度如何工作？';

  @override
  String get welcomeQuestion17 => '最佳的生产力技巧是什么？';

  @override
  String get welcomeQuestion18 => '如何提高专注力？';

  @override
  String get welcomeQuestion19 => '给我一个最大化生产力的日常计划';

  @override
  String get welcomeQuestion20 => '成功的良好习惯有哪些？';

  @override
  String get welcomeQuestion21 => '如何准备软件工程面试？';

  @override
  String get welcomeQuestion22 => '科技行业最有价值的技能是什么？';

  @override
  String get welcomeQuestion23 => '如何协商加薪？';

  @override
  String get welcomeQuestion24 => '顶级科技公司有哪些？';

  @override
  String get welcomeQuestion25 => '太空探索的最新突破是什么？';

  @override
  String get welcomeQuestion26 => 'AI 如何改变医疗保健？';

  @override
  String get welcomeQuestion27 => '2025 年最令人兴奋的技术是什么？';

  @override
  String get welcomeQuestion28 => '解释可再生能源的未来';

  @override
  String get welcomeQuestion29 => '最重要的哲学问题是什么？';

  @override
  String get welcomeQuestion30 => '如何更批判性地思考问题？';

  @override
  String get welcomeQuestion31 => '学习新技能的最佳方法是什么？';

  @override
  String get welcomeQuestion32 => '如何在学习困难事物时保持动力？';

  @override
  String get welcomeQuestion33 => '2025 年最值得学习的编程语言是什么？';

  @override
  String get welcomeQuestion34 => '如何为技术工作建立强大的作品集？';

  @override
  String get welcomeQuestion35 => '顶级 AI 生产力工具有哪些？';

  @override
  String get welcomeQuestion36 => '机器学习实际上是如何工作的？';

  @override
  String get welcomeQuestion37 => '代码审查的最佳实践是什么？';

  @override
  String get welcomeQuestion38 => '如何编写干净且可维护的代码？';

  @override
  String get welcomeQuestion39 => '什么是微服务以及何时使用它们？';

  @override
  String get welcomeQuestion40 => '解释 REST API 与 GraphQL';

  @override
  String get welcomeQuestion41 => '最值得学习的云平台有哪些？';

  @override
  String get welcomeQuestion42 => '如何准备技术面试？';

  @override
  String get welcomeQuestion43 => '每个开发人员需要哪些软技能？';

  @override
  String get welcomeQuestion44 => '作为开发人员如何协商薪资？';

  @override
  String get welcomeQuestion45 => '最佳的远程工作工具有哪些？';

  @override
  String get welcomeQuestion46 => '如何在家工作时保持高效？';

  @override
  String get welcomeQuestion47 => '最佳的项目管理方法是什么？';

  @override
  String get welcomeQuestion48 => '如何处理难相处的同事？';

  @override
  String get welcomeQuestion49 => '最好的领导力书籍有哪些？';

  @override
  String get welcomeQuestion50 => '如何创办成功的科技初创公司？';

  @override
  String get welcomeQuestion51 => 'Web 开发的最新趋势是什么？';

  @override
  String get welcomeQuestion52 => '区块链技术如何工作？';

  @override
  String get welcomeQuestion53 => '什么是 NFT？我应该关心吗？';

  @override
  String get welcomeQuestion54 => '解释元宇宙概念';

  @override
  String get welcomeQuestion55 => '最好的 AI 编程模型有哪些？';

  @override
  String get welcomeQuestion56 => '如何有效使用 ChatGPT？';

  @override
  String get welcomeQuestion57 => 'AI 的伦理是什么？';

  @override
  String get welcomeQuestion58 => 'AI 将如何改变未来的工作？';

  @override
  String get welcomeQuestion59 => '最佳的网络安全实践是什么？';

  @override
  String get welcomeQuestion60 => '如何保护我的在线隐私？';

  @override
  String get welcomeQuestion61 => '最好的数据科学工具有哪些？';

  @override
  String get welcomeQuestion62 => '如何有效地可视化数据？';

  @override
  String get welcomeQuestion63 => '最好的移动应用框架有哪些？';

  @override
  String get welcomeQuestion64 => '如何构建跨平台应用？';

  @override
  String get welcomeQuestion65 => '最好的游戏开发引擎有哪些？';

  @override
  String get welcomeQuestion66 => '如何开始 3D 建模？';

  @override
  String get welcomeQuestion67 => '最好的视频编辑工具有哪些？';

  @override
  String get welcomeQuestion68 => '如何创建引人入胜的内容？';

  @override
  String get welcomeQuestion69 => '最佳的社交媒体策略是什么？';

  @override
  String get welcomeQuestion70 => '如何建立个人品牌？';

  @override
  String get welcomeQuestion71 => '最佳的社交技巧是什么？';

  @override
  String get welcomeQuestion72 => '如何做一场精彩的演示？';

  @override
  String get welcomeQuestion73 => '最佳的时间管理技巧是什么？';

  @override
  String get welcomeQuestion74 => '如何避免倦怠？';

  @override
  String get welcomeQuestion75 => '最好的冥想应用有哪些？';

  @override
  String get welcomeQuestion76 => '如何改善睡眠质量？';

  @override
  String get welcomeQuestion77 => '最好的锻炼方式是什么？';

  @override
  String get welcomeQuestion78 => '如何在预算有限的情况下健康饮食？';

  @override
  String get welcomeQuestion79 => '技术工作者的最佳旅行目的地是哪里？';

  @override
  String get welcomeQuestion80 => '如何快速学习一门新语言？';

  @override
  String get welcomeQuestion81 => '远程团队协作的最佳实践是什么？';

  @override
  String get welcomeQuestion82 => '如何进行有效的代码审查？';

  @override
  String get welcomeQuestion83 => '软件架构师最重要的技能是什么？';

  @override
  String get welcomeQuestion84 => '如何设计可扩展的数据库系统？';

  @override
  String get welcomeQuestion85 => '最值得学习的 DevOps 工具有哪些？';

  @override
  String get welcomeQuestion86 => '如何实施 CI/CD 流水线？';

  @override
  String get welcomeQuestion87 => '什么是容器编排平台？';

  @override
  String get welcomeQuestion88 => '解释无服务器计算的优势';

  @override
  String get welcomeQuestion89 => 'API 安全的最佳实践是什么？';

  @override
  String get welcomeQuestion90 => '如何优化移动应用性能？';

  @override
  String get welcomeQuestion91 => '什么是渐进式 Web 应用？';

  @override
  String get welcomeQuestion92 => '如何构建可访问的 Web 应用？';

  @override
  String get welcomeQuestion93 => '最佳的 UI/UX 设计原则是什么？';

  @override
  String get welcomeQuestion94 => '如何有效地进行用户研究？';

  @override
  String get welcomeQuestion95 => '最佳的 A/B 测试策略是什么？';

  @override
  String get welcomeQuestion96 => '如何分析用户行为数据？';

  @override
  String get welcomeQuestion97 => '最佳的增长黑客技巧是什么？';

  @override
  String get welcomeQuestion98 => '如何围绕产品建立社区？';

  @override
  String get welcomeQuestion99 => '最佳的客户支持工具有哪些？';

  @override
  String get welcomeQuestion100 => '如何有效处理客户反馈？';

  @override
  String get welcomeQuestion101 => 'React 和 Vue 有什么区别？';

  @override
  String get welcomeQuestion102 => 'TypeScript 如何改进 JavaScript 开发？';

  @override
  String get welcomeQuestion103 => 'REST API 设计的最佳实践是什么？';

  @override
  String get welcomeQuestion104 => '如何在 Web 应用中实现身份验证？';

  @override
  String get welcomeQuestion105 => 'GraphQL 相比 REST 有什么优势？';

  @override
  String get welcomeQuestion106 => '如何优化数据库查询以提高性能？';

  @override
  String get welcomeQuestion107 => '什么是微服务架构模式？';

  @override
  String get welcomeQuestion108 => '如何实现缓存策略？';

  @override
  String get welcomeQuestion109 => 'JavaScript 的最佳测试框架有哪些？';

  @override
  String get welcomeQuestion110 => '如何为 React 组件编写单元测试？';

  @override
  String get welcomeQuestion111 => '什么是 OOP 中的 SOLID 原则？';

  @override
  String get welcomeQuestion112 => '如何在 Python 中实现设计模式？';

  @override
  String get welcomeQuestion113 => 'Git 工作流的最佳实践是什么？';

  @override
  String get welcomeQuestion114 => '如何有效处理合并冲突？';

  @override
  String get welcomeQuestion115 => '容器化的最佳实践是什么？';

  @override
  String get welcomeQuestion116 => '如何保护 Docker 容器？';

  @override
  String get welcomeQuestion117 => '什么是 Kubernetes 部署策略？';

  @override
  String get welcomeQuestion118 => '如何监控应用程序性能？';

  @override
  String get welcomeQuestion119 => '最佳的日志记录实践是什么？';

  @override
  String get welcomeQuestion120 => '如何在分布式系统中实现错误处理？';

  @override
  String get continueConversation => '继续对话';

  @override
  String get generatingSuggestions => '生成建议中...';

  @override
  String get searchChats => '搜索聊天...';

  @override
  String noChatsFound(Object query) {
    return '未找到聊天记录: \"$query\"';
  }

  @override
  String get tryDifferentSearchTerm => '尝试不同的搜索词';

  @override
  String get appShortName => 'ChatORAI';

  @override
  String get typeYourMessage => '输入您的消息...';

  @override
  String get addImage => '图片';

  @override
  String get addCamera => '相机';

  @override
  String get addFile => '文件';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get searchFavorites => '搜索收藏...';

  @override
  String get showAllModels => '显示所有模型';

  @override
  String get showFavoritesOnly => '仅显示收藏';

  @override
  String get noFavoriteModels => '无收藏模型';

  @override
  String get tapHeartToAddFavorites => '点击模型上的爱心图标将其添加到收藏';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get startListening => '开始语音输入';

  @override
  String get stopListening => '停止语音输入';

  @override
  String get listening => '请说话...';

  @override
  String get micUnavailable => '麦克风不可用';

  @override
  String get sendMessage => '发送消息';

  @override
  String get modelSettings => '模型设置';

  @override
  String get temperature => '温度';

  @override
  String get temperatureDescription => '控制随机性: 低=更集中, 高=更具创造性';

  @override
  String get maxTokens => '最大令牌数';

  @override
  String get maxTokensDescription => '生成响应的最大长度';

  @override
  String get topP => 'Top P';

  @override
  String get topPDescription => '核心采样: 低=更集中, 高=更多样化';

  @override
  String get frequencyPenalty => '频率惩罚';

  @override
  String get frequencyPenaltyDescription => '减少相似令牌的重复';

  @override
  String get presencePenalty => '存在惩罚';

  @override
  String get presencePenaltyDescription => '鼓励新主题';

  @override
  String get systemPrompt => '系统提示';

  @override
  String get systemPromptDescription => 'AI助手的指令';

  @override
  String get resetToDefaults => '重置为默认值';

  @override
  String get applySettings => '应用设置';

  @override
  String get modelParameters => '模型参数';

  @override
  String get activeModel => '活动模型';

  @override
  String get noModelSelected => '未选择模型';

  @override
  String get settingsApplied => '设置应用成功';

  @override
  String apiLimitExceeded(Object limit) {
    return 'API限制已超出: $limit';
  }

  @override
  String valueExceedsApiLimit(Object limit) {
    return '值超出API限制 ($limit)。将使用最大值。';
  }

  @override
  String get micStartFailed => '无法启动麦克风';

  @override
  String get micStopFailed => '无法停止麦克风';

  @override
  String get speechErrorNoMatch => '无法识别语音。请重试。';

  @override
  String get speechErrorTimeout => '监听超时。未听到任何内容。';

  @override
  String get speechErrorNetwork => '网络错误。检查您的互联网连接。';

  @override
  String get speechErrorNotAuthorized => '无麦克风访问权限。检查设置中的权限。';

  @override
  String get speechErrorServer => '识别服务器错误。请稍后再试。';

  @override
  String get speechErrorTooManyRequests => '请求过多。请稍后再试。';

  @override
  String get speechErrorUnknown => '语音识别错误';

  @override
  String get speechPreparing => '准备中...';

  @override
  String get speechListening => '请说话...';

  @override
  String get speechProcessing => '处理中...';

  @override
  String get micNoSpeechDetected => '我没听到您的声音，请再试一次。';

  @override
  String get micAutoRestart => '重试中...';

  @override
  String get speechPhase2 => '我听不到您...请大声一点';

  @override
  String speechStartError(Object error) {
    return '启动错误: $error';
  }

  @override
  String get errorProcessingRequest => '抱歉，处理您的请求时发生错误。请重试。';

  @override
  String rateLimitRetryMessage(Object seconds) {
    return '已达到速率限制。$seconds秒后重试...';
  }

  @override
  String get messageNotFound => '未找到消息';

  @override
  String get errorEditingMessage => '编辑消息错误';

  @override
  String get errorEditAndSendMessage => '编辑和发送消息错误';

  @override
  String generatingSuggestionsFailed(Object error) {
    return '生成建议失败: $error';
  }

  @override
  String get selectModelTooltip => '选择模型';

  @override
  String get toggleNavigatorTooltip => '切换导航器';

  @override
  String get defaultSuggestion1 => '请告诉我更多关于这个主题';

  @override
  String get defaultSuggestion2 => '你能提供例子吗？';

  @override
  String get defaultSuggestion3 => '有什么替代方案？';

  @override
  String get defaultSuggestion4 => '这在实践中如何应用？';

  @override
  String get systemPromptSuggestion => '你是一个有用的助手。继续对话，为最后一条消息提供3个具体且合乎逻辑的延续。用中文回答。';

  @override
  String get userPromptSuggestion => '为这条消息提供3个具体且合乎逻辑的延续。只回答列表，不要额外文本。';

  @override
  String get refreshQuestions => '刷新问题';

  @override
  String get noInternetConnection => '无网络连接';

  @override
  String modelDoesNotSupportFiles(Object modelId) {
    return '模型 $modelId 不支持文件。您可以附加文件，但发送将不起作用。';
  }

  @override
  String get fileAttachedButNotSupported => '文件已附加，但当前模型不支持';

  @override
  String get copyCodeTooltip => '复制代码';

  @override
  String get expandTooltip => '展开';

  @override
  String get collapseTooltip => '折叠';

  @override
  String get welcomeGreeting1 => '问吧、探索吧、创造吧 — 让我们一起弄清楚。';

  @override
  String get welcomeGreeting2 => '提问题、描述任务，或者直接开始对话。';

  @override
  String get welcomeGreeting3 => '提问题或开始探索。';

  @override
  String get welcomeGreeting4 => '问任何问题、分享想法或寻求帮助 — 我在这里帮助你。';

  @override
  String get welcomeGreeting5 => '有想法吗？让我们来分析。';

  @override
  String get welcomeGreeting6 => '为对话设定方向。';

  @override
  String get welcomeGreeting7 => '今天探索什么？';

  @override
  String get welcomeGreeting8 => '写下想法。让我们一起分析。';

  @override
  String get welcomeGreeting9 => '好奇心是受欢迎的。';

  @override
  String get welcomeGreeting10 => '你的问题是我下一个答案。';

  @override
  String get welcomeGreeting11 => '让我们把想法变成答案。';

  @override
  String get welcomeGreeting12 => '输入问题。其他的是我的工作。';
}
