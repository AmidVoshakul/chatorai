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
  String get autoScrollDuringStreaming => '流式传输期间自动滚动';

  @override
  String get autoScrollDuringStreamingDesc => '出现新内容时自动向下滚动列表';

  @override
  String get showContinuationSuggestions => '显示对话续写建议';

  @override
  String get showContinuationSuggestionsDesc => '在 AI 回复后显示续写建议';

  @override
  String get expandReasoningByDefault => '默认展开推理过程';

  @override
  String get expandReasoningByDefaultDesc => 'AI 回复时默认展开思考/推理块';

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
  String get confirmOpenLink => '您确定要打开：';

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
  String get appDescription =>
      '通过 OpenRouter API 与 AI 模型聊天的应用程序。\n\n功能：\n• 与各种 AI 模型聊天\n• 聊天历史记录存储\n• 深色和浅色主题\n• 自适应界面\n\n使用 Flutter 开发';

  @override
  String get shareChat => '分享聊天';

  @override
  String get copyChat => '复制聊天';

  @override
  String get renameChat => '重命名聊天';

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
  String chatRenamedTo(Object name) {
    return '聊天已重命名为: $name';
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
  String contextMessages(Object percent, Object usable, Object used) {
    return '上下文: $used / $usable 令牌 ($percent%)';
  }

  @override
  String get contextInstructions => '指令';

  @override
  String get contextAgentPrompt => '代理提示词';

  @override
  String get contextUserPrompt => '用户提示词';

  @override
  String get contextCompactSession => '压缩会话';

  @override
  String get contextCompacting => '压缩中…';

  @override
  String get contextUsageBreakdown => '使用情况';

  @override
  String get contextPromptTokens => '输入令牌';

  @override
  String get contextOutputTokens => '输出令牌';

  @override
  String get contextCacheRead => '缓存读取';

  @override
  String get contextCacheWrite => '缓存写入';

  @override
  String get contextToolTokens => '工具令牌';

  @override
  String get contextSpentLabel => '已花费';

  @override
  String get contextTokensIncludedInPrompt => '工具令牌已包含在提示中';

  @override
  String contextAutoCompactAt(Object buffer, Object percent) {
    return '在 $percent% 自动压缩 · 缓冲区 $buffer 令牌';
  }

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
  String get loadingMsg1 => '等待服务器响应…';

  @override
  String get loadingMsg2 => '数据已发送 — 马上就好…';

  @override
  String get loadingMsg3 => '整理思绪中…';

  @override
  String get loadingMsg4 => '寻找最佳答案…';

  @override
  String get loadingMsg5 => '加载答案（即将完成）…';

  @override
  String get failedToSendMessage => '无法发送消息';

  @override
  String get retry => '重试';

  @override
  String get bootstrapErrorTitle => '启动应用失败';

  @override
  String get bootstrapErrorBody => '请检查配置后重试。';

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
  String editToolTitle(String path) {
    return '编辑 $path';
  }

  @override
  String patchToolTitle(String path) {
    return '补丁 $path';
  }

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
  String get welcomeQuestion27 => '2026 年最令人兴奋的技术是什么？';

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
  String get welcomeQuestion33 => '2026 年最值得学习的编程语言是什么？';

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
  String get addToFavorites => '添加到收藏';

  @override
  String get removeFromFavorites => '从收藏中移除';

  @override
  String get recentModels => '最近使用';

  @override
  String get loadingSkills => '正在加载技能';

  @override
  String get noSkillsInstalled => '未安装任何技能';

  @override
  String get noSkillsMatchSearch => '没有匹配搜索的技能';

  @override
  String get allSkillsRequirePermission => '所有技能都需要权限';

  @override
  String skillExecuted(Object name) {
    return '技能已执行';
  }

  @override
  String get configuration => '配置';

  @override
  String get stats => '统计';

  @override
  String get usageStatistics => '使用统计';

  @override
  String get totalSessions => '会话数';

  @override
  String get totalMessages => '消息数';

  @override
  String get days => '天';

  @override
  String get totalTokens => '总令牌数';

  @override
  String get totalCost => '总费用';

  @override
  String get avgCostPerDay => '日均费用';

  @override
  String get avgTokensPerSession => '平均令牌数/会话';

  @override
  String get medianTokensPerSession => '中位数令牌数/会话';

  @override
  String get cacheRead => '缓存读取';

  @override
  String get cacheWrite => '缓存写入';

  @override
  String get toolUsage => '工具使用';

  @override
  String get modelUsage => '模型使用';

  @override
  String get noStatsAvailable => '暂无统计数据';

  @override
  String get reasoningTokens => '推理令牌';

  @override
  String get addProvider => '添加提供商';

  @override
  String get applySettings => '应用设置';

  @override
  String get copyCodeTooltip => '复制代码';

  @override
  String get copiedFeedback => '已复制';

  @override
  String get defaultSuggestion1 => '请告诉我更多关于这个主题';

  @override
  String get defaultSuggestion2 => '你能提供例子吗？';

  @override
  String get defaultSuggestion3 => '有什么替代方案？';

  @override
  String get deleteChat => '删除聊天';

  @override
  String get manageProviders => '管理提供商';

  @override
  String get micAutoRestart => '重试中...';

  @override
  String get micNoSpeechDetected => '我没听到您的声音，请再试一次。';

  @override
  String get micStartFailed => '无法启动麦克风';

  @override
  String get micUnavailable => '麦克风不可用';

  @override
  String get modelParameters => '模型参数';

  @override
  String get modelSettings => '模型设置';

  @override
  String get noInternetConnection => '无网络连接';

  @override
  String get noModelSelected => '未选择模型';

  @override
  String get openaiCompatibleApi => 'OpenAI 兼容 API';

  @override
  String get openaiCompatibleApiDescription => '连接到任何 OpenAI 兼容的 API 端点';

  @override
  String get permissionAlways => '始终允许';

  @override
  String get permissionAlwaysConfirm => 'Always allow';

  @override
  String get permissionDialogPatterns => '请求访问:';

  @override
  String get permissionOnce => '仅一次';

  @override
  String get permissionReject => '拒绝';

  @override
  String get providers => '提供商';

  @override
  String get refreshQuestions => '刷新问题';

  @override
  String get resetToDefaults => '重置为默认值';

  @override
  String get settingsApplied => '设置应用成功';

  @override
  String get speechErrorNetwork => '网络错误。检查您的互联网连接。';

  @override
  String get speechErrorNoMatch => '无法识别语音。请重试。';

  @override
  String get speechErrorNotAuthorized => '无麦克风访问权限。检查设置中的权限。';

  @override
  String get speechErrorServer => '识别服务器错误。请稍后再试。';

  @override
  String get speechErrorTimeout => '监听超时。未听到任何内容。';

  @override
  String get speechErrorTooManyRequests => '请求过多。请稍后再试。';

  @override
  String get speechErrorUnknown => '语音识别错误';

  @override
  String get speechListening => '请说话...';

  @override
  String get speechPhase2 => '我听不到您...请大声一点';

  @override
  String get speechPreparing => '准备中...';

  @override
  String get speechProcessing => '处理中...';

  @override
  String speechStartError(Object error) {
    return '启动错误: $error';
  }

  @override
  String get systemPrompt => '系统提示';

  @override
  String get systemPromptDescription => 'AI助手的指令';

  @override
  String get systemPromptSuggestion =>
      '你是一个有用的助手。继续对话，为最后一条消息提供3个具体且合乎逻辑的延续。用中文回答。';

  @override
  String get temperature => '温度';

  @override
  String get temperatureDescription => '控制随机性: 低=更集中, 高=更具创造性';

  @override
  String get toggleNavigatorTooltip => '切换导航器';

  @override
  String get userPromptSuggestion => '为这条消息提供3个具体且合乎逻辑的延续。只回答列表，不要额外文本。';

  @override
  String get versionLabel => '版本:';

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

  @override
  String modelDoesNotSupportFiles(Object modelId) {
    return '模型 $modelId 不支持文件。您可以附加文件，但发送将不起作用。';
  }

  @override
  String generatingSuggestionsFailed(Object error) {
    return '生成建议失败: $error';
  }

  @override
  String get toggleSidebarTooltip => '切换侧边栏';

  @override
  String get openMenuTooltip => '打开菜单';

  @override
  String get addFileTooltip => '添加文件';

  @override
  String get modelSettingsTooltip => '模型设置';

  @override
  String get switchAgentTooltip => '切换代理';

  @override
  String get selectModelTooltip => '选择模型';

  @override
  String get removeFileTooltip => '移除文件';

  @override
  String get goToParentSessionTooltip => '转到父会话';

  @override
  String get previousSiblingTooltip => '上一个同级';

  @override
  String get nextSiblingTooltip => '下一个同级';

  @override
  String get cancellingRetryTooltip => '正在取消重试...';

  @override
  String get stopGenerationTooltip => '停止生成';

  @override
  String get question => '问题';

  @override
  String get skip => '跳过';

  @override
  String get answer => '答案';

  @override
  String get noAgentsAvailable => '没有可用的代理';

  @override
  String permissionAlwaysConfirmDescription(Object title) {
    return '这将允许 \"$title\" 直到应用重启。';
  }

  @override
  String get chatActionsMenuTooltip => '聊天菜单';

  @override
  String get startListening => '开始语音输入';

  @override
  String get stopListening => '停止语音输入';

  @override
  String get listening => '请说话...';

  @override
  String get linkCancel => '取消';

  @override
  String get linkCopied => '链接已复制';

  @override
  String get linkOpen => '打开';

  @override
  String get linkOpenFailed => '无法打开链接';

  @override
  String get sendMessage => '发送消息';

  @override
  String get maxTokens => '最大令牌数';

  @override
  String get maxTokensDescription => '生成响应的最大长度';

  @override
  String get activeModel => '活动模型';

  @override
  String apiLimitExceeded(Object limit) {
    return 'API限制已超出: $limit';
  }

  @override
  String valueExceedsApiLimit(Object limit) {
    return '值超出API限制 ($limit)。将使用最大值。';
  }

  @override
  String get micStopFailed => '无法停止麦克风';

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
  String get defaultSuggestion4 => '这在实践中如何应用？';

  @override
  String get fileAttachedButNotSupported => '文件已附加，但当前模型不支持';

  @override
  String get expandTooltip => '展开';

  @override
  String get collapseTooltip => '折叠';

  @override
  String get addProviderTitleEdit => '编辑提供商';

  @override
  String get addProviderTitleAdd => '添加提供商';

  @override
  String get addProviderLabelProvider => '提供商';

  @override
  String get addProviderCustomName => '自定义提供商...';

  @override
  String get addProviderFieldProviderName => '提供商名称';

  @override
  String get addProviderHintProviderName => '例如，我的自定义 AI';

  @override
  String get addProviderLabelApiKey => 'API 密钥';

  @override
  String get addProviderHintApiKey => '输入您的 API 密钥';

  @override
  String get addProviderHintCustomApiKey => '本地提供商可选';

  @override
  String get addProviderLabelBaseUrl => '基础 URL';

  @override
  String get addProviderHintBaseUrl => 'https://api.example.com/v1';

  @override
  String get addProviderActionSave => '保存';

  @override
  String get addProviderErrorApiKeyRequired => '需要 API 密钥';

  @override
  String get selectModels => '选择模型';

  @override
  String get deselectAll => '取消全选';

  @override
  String get selectAll => '全选';

  @override
  String get modelsAvailable => '无可用模型';

  @override
  String get modelsMatchSearch => '没有匹配搜索的模型';

  @override
  String selectModelsCount(Object count, Object total) {
    return '已选择 $count / $total';
  }

  @override
  String modelsLoadError(Object error) {
    return '加载模型失败: $error';
  }

  @override
  String get systemPromptHint => '你是一个有用的助手...';

  @override
  String get temperatureHint => '0.0 - 2.0';

  @override
  String get loadingSettings => '正在加载设置...';

  @override
  String errorApplyingSettings(Object error) {
    return '应用设置时出错: $error';
  }

  @override
  String deleteProviderTitle(Object providerName) {
    return '删除 $providerName?';
  }

  @override
  String get deleteProviderContent => '这将删除提供商及其所有设置。您需要重新添加它才能使用其模型。';

  @override
  String get errorLoadingProviders => '加载提供商时出错';

  @override
  String get noProvidersConfigured => '未配置提供商';

  @override
  String get addProviderToGetStarted => '添加带有 API 密钥的提供商以开始使用';

  @override
  String statsError(Object error) {
    return '错误: $error';
  }

  @override
  String get total => '总计';

  @override
  String modelsProviderCountFormat(Object count, Object providerName) {
    return '$providerName · $count';
  }

  @override
  String get mcpServers => 'MCP 服务器';

  @override
  String get mcpAddServer => '添加 MCP 服务器';

  @override
  String get mcpAddServerTitle => '添加 MCP 服务器';

  @override
  String get mcpNameLabel => '名称';

  @override
  String get mcpNameHint => '例如 filesystem';

  @override
  String get mcpNameHelper => 'chatorai.json 中的唯一标识符';

  @override
  String get mcpTypeLocal => '本地';

  @override
  String get mcpTypeRemote => '远程';

  @override
  String get mcpTypeLocalTooltip => '运行在您的机器上';

  @override
  String get mcpTypeRemoteTooltip => 'HTTP/SSE 端点';

  @override
  String get mcpCommandLabel => '命令';

  @override
  String get mcpCommandHint => 'uvx mcp-server-filesystem ~/docs';

  @override
  String get mcpCommandHelper => '完整命令，参数以空格分隔';

  @override
  String get mcpUrlLabel => 'URL';

  @override
  String get mcpUrlHint => 'https://example.com/mcp';

  @override
  String get mcpUrlHelper => '完整的 MCP 端点 URL';

  @override
  String get mcpEnvLabel => '环境变量 (JSON)';

  @override
  String get mcpEnvHint => 'GITHUB_TOKEN=ghp_xxx';

  @override
  String get mcpEnvHelper => '可选。粘贴字符串键的 JSON 对象，例如单个 TOKEN 条目。';

  @override
  String get mcpTokenLabel => '访问令牌';

  @override
  String get mcpTokenHint => '仅粘贴令牌（不要带 Bearer / 引号）';

  @override
  String get mcpTokenHelper => '可选。公共服务器可留空；只需粘贴令牌，请求头会自动添加。';

  @override
  String get mcpAuthTypeLabel => '令牌类型';

  @override
  String get mcpAuthTypeHelper =>
      '令牌的发送方式：Bearer（Authorization）、ApiKey（X-Api-Key）或纯 Token。';

  @override
  String get mcpHeadersLabel => '请求头 (JSON)';

  @override
  String get mcpHeadersHint => 'Authorization=Bearer token';

  @override
  String get mcpHeadersHelper => '可选。粘贴一个请求头的 JSON 对象。';

  @override
  String get mcpFormTab => '表单';

  @override
  String get mcpRawTab => '原始 JSON';

  @override
  String get mcpRawLabel => '服务器对象 (JSON)';

  @override
  String get mcpRawHelper =>
      '按文档粘贴服务器对象——服务器名称是外层键（例如 searxng）。也可以直接粘贴包含 mcpServers 外层包裹的完整块。';

  @override
  String mcpParseError(Object field, Object message) {
    return '$field 中的 JSON 无效：$message';
  }

  @override
  String get mcpAddAction => '添加';

  @override
  String get mcpCancelAction => '取消';

  @override
  String get mcpRemoveTitle => '删除 MCP 服务器？';

  @override
  String mcpRemoveContent(Object name) {
    return '从 chatorai.json 中删除 \"$name\"？';
  }

  @override
  String get mcpRemoveAction => '删除';

  @override
  String get mcpEditAction => '编辑';

  @override
  String get mcpEditServerTitle => '编辑 MCP 服务器';

  @override
  String get mcpSaveAction => '保存';

  @override
  String get mcpNoServers => '未配置 MCP 服务器';

  @override
  String get mcpNoServersHint => '添加 Model Context Protocol 服务器以扩展工具';

  @override
  String get mcpTooltipAdd => '添加服务器';

  @override
  String get mcpTooltipRefresh => '刷新';

  @override
  String get mcpMarketplaceTab => '市场';

  @override
  String get mcpInstalledTab => '已安装';

  @override
  String get mcpInstall => '安装';

  @override
  String get mcpInstalled => '已安装';

  @override
  String get mcpMarketplaceSearchHint => '搜索服务器…';

  @override
  String get mcpMarketplaceEmpty => '没有匹配的服务器';

  @override
  String get mcpMarketCategoryAll => '全部';

  @override
  String get mcpMarketCategorySearch => '搜索';

  @override
  String get mcpMarketCategoryDocs => '文档';

  @override
  String get mcpMarketCategoryDesign => '设计';

  @override
  String get mcpMarketCategoryDev => '开发';

  @override
  String get mcpMarketCategoryFinance => '金融';

  @override
  String get mcpMarketCategoryTravel => '旅行';

  @override
  String get mcpMarketCategoryJobs => '招聘';

  @override
  String get mcpMarketCategoryProductivity => '效率';

  @override
  String get mcpMarketCategorySocial => '社交';

  @override
  String get mcpMarketCategoryOther => '其他';

  @override
  String get mcpMarketNeedsToken => '需要密钥';

  @override
  String get mcpMarketDescExa =>
      'Exa 为 AI 工作流提供网页搜索和代码文档查询能力。其连接器为助手提供实时上下文，以便在需要依据外部信息作答时查找相关网页、技术文档和原始资料。';

  @override
  String get mcpMarketDescContext7 =>
      'Context7 为基于 AI 的程序员和代码编辑器提供最新的代码示例与文档。其 MCP 连接器将当前的库上下文集成到助手工作流中，减少切换标签页，并帮助生成的代码避免过时的 API、不存在的方法和陈旧的实现模式。';

  @override
  String get mcpMarketDescHuggingFace =>
      'Hugging Face 将语音助手连接到 Hugging Face Hub 和数千个 Gradio 应用。其连接器将模型、数据集、空间和应用的上下文集成到 AI 工作流中，用于发现、实验和机器学习研究。';

  @override
  String get mcpMarketDescParallel =>
      'Parallel Search 为以搜索为核心的 AI 工作流提供实时网页搜索与内容提取。其远程 MCP 服务器帮助助手获取最新的网页上下文、核验页面，并在回答需要新鲜信息的问题或研究主题时使用提取的内容。';

  @override
  String get mcpMarketDescTavily =>
      'Tavily 通过搜索、检索和研究 API 为 AI 智能体提供实时网络资源访问。其连接器帮助助手以实时数据为依据作答、提取相关内容，并通过安全控制在生产环境中支撑智能体工作流。';

  @override
  String get mcpMarketDescGithub =>
      'GitHub 是用于协作处理代码、议题、拉取请求和项目历史的平台。其官方远程 MCP 服务器为助手提供结构化的仓库上下文，以理解源码变更、评审、开发流程以及 GitHub 项目状态。';

  @override
  String get mcpMarketDescPostman =>
      'Postman 为编码智能体和开发者工作流提供 API 上下文。其连接器将 API 定义、文档与协作上下文集成到助手工作中，使智能体能够分析集成与实现细节。';

  @override
  String get mcpMarketDescSlack =>
      'Slack 是汇聚团队消息、频道、用户和共享工作区的协作中心。其远程 MCP 服务器将工作区对话上下文集成到助手工作流中，帮助用户查找答案、总结讨论并了解各频道的动态。';

  @override
  String get mcpMarketDescFigma =>
      'Figma 是用于界面设计、原型制作和开发者交接的产品设计平台。其远程 MCP 服务器将文件、项目和开发模式上下文带入助手工作流，使智能体理解视觉工作并将其映射到实现任务。';

  @override
  String get mcpMarketDescCanva =>
      'Canva 是用于演示文稿、社媒图形、文档和品牌素材的视觉传播平台。其远程 MCP 服务器让助手可访问 Canva 项目、资源、导出文件和评论，从而基于所获信息讨论、编辑并准备创意作品。';

  @override
  String get mcpMarketDescStripe =>
      'Stripe 是面向支付处理的支付与金融基础设施平台，涵盖账单、客户和开发者文档。其远程 MCP 服务器在 Stripe 支持下为助手提供账户与实现上下文，以理解客户流程、账单问题与支付任务。';

  @override
  String get mcpMarketDescTrivago =>
      'Trivago 帮助用户按坐标、城市、国家、日期和旅行上下文搜索酒店与住宿。其连接器为助手提供住宿搜索上下文，以便在目的地或景点附近找到合适的住宿。';

  @override
  String get mcpMarketDescSend =>
      'Send 帮助用户创建可共享文档、单页文档、演示文稿和幻灯片。其连接器让助手将所需材料转化为发布链接、交互式页面以及可追踪的交付物。';

  @override
  String get mcpMarketDescZiprecruiter =>
      'ZipRecruiter 帮助用户按职位名称、公司、地点、薪资、距离、工作风格、雇佣类型和发布日期搜索实时职位。其连接器在将申请交回 ZipRecruiter 之前，将求职上下文集成到助手工作流中。';

  @override
  String get mcpMarketDescAdobeCreativity =>
      'Adobe for Creativity 将 Photoshop、Lightroom、Illustrator、Firefly、Premiere、Express、InDesign 和 Stock 与 AI 驱动创意工作相结合。用户可使用自然语言生成、编辑并增强照片、设计素材和视频项目，同时作品始终关联到其 Adobe 账户。';

  @override
  String get mcpInstallToGlobal => '安装到全局';

  @override
  String get mcpInstallToProject => '安装到项目';

  @override
  String get mcpScopeGlobal => '全局';

  @override
  String get mcpScopeProject => '项目';

  @override
  String get mcpScopeGlobalProject => '全局 + 项目';

  @override
  String mcpRemoveFromScope(String scope) {
    return '从 $scope 移除';
  }

  @override
  String get mcpRemoveFromAll => '从所有位置移除';

  @override
  String get mcpTokenDialogTitle => '身份验证';

  @override
  String get mcpTokenDialogTitleHint => '选择与此服务器的身份验证方式';

  @override
  String get mcpTokenInputLabel => '令牌';

  @override
  String get mcpTokenInputHint => '粘贴您的访问令牌';

  @override
  String get mcpTokenInputHelper => '以 Authorization: Bearer <token> 形式发送';

  @override
  String get mcpOAuthClientIdLabel => '客户端 ID';

  @override
  String get mcpOAuthClientIdHint => 'OAuth 2.1 客户端 ID';

  @override
  String get mcpOAuthClientSecretLabel => '客户端密钥';

  @override
  String get mcpOAuthClientSecretHint => 'OAuth 2.1 客户端密钥（可选）';

  @override
  String get mcpOAuthScopeLabel => '范围';

  @override
  String get mcpOAuthScopeHint => '例如 read write';

  @override
  String get mcpAuthConfirm => '确认';

  @override
  String get agentsInstructions => '智能体指令';

  @override
  String get agentsInstructionsSubtitle => '管理 AGENTS.md 和自定义指令文件';

  @override
  String get agentsMdHint => '# 项目规则\n- 简洁\n- 先写测试';

  @override
  String get agentsMdSaved => 'AGENTS.md 已保存';

  @override
  String get instructionsAutoDetectedTitle => '检测到的文件';

  @override
  String get instructionsAutoDetectedHelper =>
      '为此范围找到的 AGENTS.md 和 CLAUDE.md。点按可查看或编辑。';

  @override
  String get instructionsFileNotCreated => '尚未创建';

  @override
  String get instructionsFileReadOnly => '只读';

  @override
  String get instructionsBadgeGlobal => '全局';

  @override
  String get instructionsBadgeProject => '项目';

  @override
  String get instructionsViewFile => '查看';

  @override
  String get instructionsEditFile => '编辑';

  @override
  String get instructionsSectionTitle => '指令文件';

  @override
  String get instructionsSectionHelper => '在 AGENTS.md 之后按顺序追加的额外 Markdown 文件。';

  @override
  String get instructionsAdd => '添加指令';

  @override
  String get instructionsAddInline => '手动编写';

  @override
  String get instructionsUploadFile => '上传 .md 文件';

  @override
  String get instructionsEmpty => '尚无指令文件';

  @override
  String get instructionsEmptyHint => '手动添加指令或上传 Markdown 文件。';

  @override
  String get instructionsNameLabel => '名称';

  @override
  String get instructionsNameHint => 'coding-style';

  @override
  String get instructionsContentLabel => '内容';

  @override
  String get instructionsContentHint => '使用 Markdown 编写你的指令……';

  @override
  String get instructionsAddedInline => '指令已添加';

  @override
  String instructionsAddedFile(Object name) {
    return '文件已添加：$name';
  }

  @override
  String get instructionsRemoveTitle => '移除指令';

  @override
  String instructionsRemoveContent(Object name) {
    return '要从指令中移除“$name”吗？';
  }

  @override
  String get instructionsRemoved => '指令已移除';

  @override
  String get instructionsEditTitle => '编辑指令路径';

  @override
  String get instructionsPathLabel => '路径';

  @override
  String get instructionsUpdated => '指令已更新';

  @override
  String get instructionsScopeGlobal => '全局';

  @override
  String get instructionsScopeProject => '项目';

  @override
  String get instructionsScopeGlobalHint => '适用于所有场景。存储在你的用户配置中。';

  @override
  String get instructionsScopeProjectHint => '适用于当前项目文件夹。';

  @override
  String get instructionsCreateAgents => '创建 AGENTS.md';

  @override
  String instructionsSaveError(Object error) {
    return '无法保存：$error';
  }

  @override
  String get configScopeGlobal => '全局';

  @override
  String get configScopeProject => '项目';

  @override
  String get configProjectOverrides => '项目设置会覆盖全局设置。';

  @override
  String get configPathLabel => '路径';

  @override
  String get configStatusLabel => '状态';

  @override
  String get configContentsTitle => '文件内容';

  @override
  String get configExists => '存在';

  @override
  String get configNotFound => '未找到';

  @override
  String get configWillBeCreated => '保存时将创建。';

  @override
  String get skillsTitle => '技能';

  @override
  String get skillsSubtitle => '助手可按需加载的可复用能力包。';

  @override
  String get skillsSectionTitle => '已安装的技能';

  @override
  String get skillsSectionHelper => '每个技能都是包含 SKILL.md 的文件夹。可自行添加或从网址安装。';

  @override
  String get skillsNewSkill => '新建技能';

  @override
  String get skillsInstallFromUrl => '从网址安装';

  @override
  String get skillsNameLabel => '名称';

  @override
  String get skillsNameHint => '例如：代码审查员';

  @override
  String get skillsDescriptionLabel => '描述';

  @override
  String get skillsDescriptionHint => '简要说明该技能的作用';

  @override
  String get skillsContentLabel => 'SKILL.md 内容';

  @override
  String get skillsContentHint => '# 标题\n给助手的说明…';

  @override
  String get skillsUrlLabel => 'index.json 网址';

  @override
  String get skillsUrlHint => 'https://example.com/skills';

  @override
  String get skillsApiKeyLabel => 'API 密钥（可选）';

  @override
  String get skillsReadOnly => '只读';

  @override
  String skillsFilesCount(int count) {
    return '$count 个文件';
  }

  @override
  String get skillsCreated => '技能已创建';

  @override
  String get skillsSaved => '技能已保存';

  @override
  String get skillsRemoved => '技能已移除';

  @override
  String skillsInstalled(int count) {
    return '已安装 $count 个技能';
  }

  @override
  String get skillsInstallNone => '该网址未找到技能';

  @override
  String get skillsRemoveTitle => '移除技能';

  @override
  String skillsRemoveContent(String name) {
    return '移除“$name”？这将从磁盘删除其文件夹。';
  }

  @override
  String skillsSaveError(String error) {
    return '无法完成：$error';
  }

  @override
  String get skillsEmpty => '暂无技能';

  @override
  String get skillsEmptyHint => '创建一个技能或从网址安装以开始使用。';

  @override
  String get skillsMarketplaceTab => '市场';

  @override
  String get skillsMarketplaceSearchHint => '搜索技能';

  @override
  String get skillsMarketplaceEmpty => '没有符合搜索的技能。';

  @override
  String get skillsInstalledBadge => '已安装';

  @override
  String get skillsInstallAction => '安装';

  @override
  String get skillsInstallToGlobal => '安装到 Global';

  @override
  String get skillsInstallToProject => '安装到 Project';

  @override
  String skillsInstalledToast(String name) {
    return '$name · 已安装';
  }

  @override
  String get skillsTabGlobalTooltip => '在所有项目中可用的技能';

  @override
  String get skillsTabProjectTooltip => '仅限本项目的技能';

  @override
  String get skillsTabMarketplaceTooltip => '浏览并安装现成技能';

  @override
  String get skillsPreviewClose => '关闭';

  @override
  String get skillsCategoryAll => '全部';

  @override
  String get skillsCategoryCoding => '编码';

  @override
  String get skillsCategoryWriting => '写作';

  @override
  String get skillsCategoryResearch => '研究';

  @override
  String get skillsCategoryDesign => '设计';

  @override
  String get skillsCategoryProductivity => '效率';

  @override
  String get skillsCategoryData => '数据';

  @override
  String get skillsCategoryOther => '其他';

  @override
  String get commonSave => '保存';

  @override
  String get commonCancel => '取消';

  @override
  String get commonAdd => '添加';

  @override
  String get commonRemove => '移除';

  @override
  String get commonEdit => '编辑';

  @override
  String get toolResultOriginal => '原始';

  @override
  String get toolResultRestore => '还原';

  @override
  String get toolResultRestoredSnackbar => '文件已还原到编辑前状态';

  @override
  String get toolResultOriginalTitle => '编辑前的原始内容';

  @override
  String restoreFailed(String error) {
    return '还原失败：$error';
  }

  @override
  String get compactingIndicator => '压缩中...';

  @override
  String get compactionAgentName => '压缩';

  @override
  String get workspaces => '工作区';

  @override
  String get directoryTitle => '目录';

  @override
  String get searchDirectories => '搜索目录';

  @override
  String get addDirectory => '添加目录';

  @override
  String get removeDirectory => '删除目录';

  @override
  String get noWorkspacesFound => '未找到目录';

  @override
  String get switchWorkspaceTitle => '切换工作区';

  @override
  String get currentSessionWillBeStopped => '当前会话将被停止。';

  @override
  String get continueText => '继续';

  @override
  String get changeWorkingDirectory => '切换当前目录';

  @override
  String get sessionsTitle => '会话';

  @override
  String get noSessions => '暂无会话';

  @override
  String get searchSessions => '搜索会话';

  @override
  String get newSession => '新会话';

  @override
  String get autoApproveTitle => '自动批准';

  @override
  String get autoApproveSubtitle => '配置自动权限批准';

  @override
  String get autoApproveExternalDirectoryDesc => '允许访问外部目录';

  @override
  String get autoApproveShellDesc => '允许执行 shell 命令';

  @override
  String get autoApproveReadDesc => '允许读取文件';

  @override
  String get autoApproveEditDesc => '允许编辑文件';

  @override
  String get autoApproveWriteDesc => '允许写入文件';

  @override
  String get autoApproveGlobDesc => '允许 glob 搜索';

  @override
  String get autoApproveGrepDesc => '允许 grep 搜索';

  @override
  String get autoApproveWebsearchDesc => '允许网络搜索';

  @override
  String get autoApproveWebfetchDesc => '允许获取网页';

  @override
  String get autoApproveDoomLoopDesc => '允许 doom loop 检测';

  @override
  String get autoApproveSkillDesc => '允许执行技能';

  @override
  String get autoApproveLspDesc => '允许使用 LSP';

  @override
  String get autoApproveTaskDesc => '允许使用 task';

  @override
  String get autoApproveTodowriteDesc => '允许 todo 写入操作';

  @override
  String get exceptionsTitle => '例外';

  @override
  String get addPath => '添加路径';

  @override
  String get addCommand => '添加命令';

  @override
  String get scopeGlobal => '全局';

  @override
  String get scopeProject => '项目';

  @override
  String get defaultInherit => '默认（继承）';

  @override
  String get defaultAllow => '允许';

  @override
  String get defaultAsk => '询问';

  @override
  String get defaultDeny => '拒绝';

  @override
  String autoApproveDefaultInherited(Object action) {
    return '默认（$action）';
  }

  @override
  String get autoApproveGroupFileAccess => '文件访问';

  @override
  String get autoApproveGroupShell => 'Shell 与命令';

  @override
  String get autoApproveGroupNetwork => '网络';

  @override
  String get autoApproveGroupAgents => '代理与自动化';

  @override
  String get autoApproveCommandPatternLabel => '命令模式';

  @override
  String get autoApprovePathPatternLabel => '路径模式';

  @override
  String get autoApproveCommandPatternHint => 'git *';

  @override
  String get autoApprovePathPatternHint => '/home/**/*.txt';

  @override
  String get autoApproveScopeHint => '全局适用于所有位置 · 项目按工作区覆盖';

  @override
  String get autoApproveNoExceptions => '无例外 — 所有模式均使用默认值';

  @override
  String get autoApproveBrowseDirectory => '浏览目录';

  @override
  String get autoApproveScopeProjectDisabledTooltip =>
      '未找到项目配置。创建 .chatorai/chatorai.json 以启用项目级权限。';

  @override
  String get autoApproveActionLabel => 'Action';

  @override
  String get autoApprovePatternHintFile =>
      '/home/user/project/** • ~/Documents/*';

  @override
  String get autoApprovePatternHintCommand => 'npm run * • git status';

  @override
  String autoApproveError(Object error) {
    return 'Error: $error';
  }

  @override
  String get settingsMcpSubtitle =>
      'Manage Model Context Protocol tool servers';

  @override
  String get mcpAuthNoAuth => 'No Auth';

  @override
  String get mcpAuthToken => 'Token';

  @override
  String get mcpAuthOAuth => 'OAuth 2.1';

  @override
  String get statsInput => 'Input';

  @override
  String get statsOutput => 'Output';

  @override
  String get statsCacheRead => 'Cache Read';

  @override
  String get keyboardShortcuts => '键盘快捷键';

  @override
  String get keyboardShortcutsSubtitle => '自定义应用程序键盘快捷键';

  @override
  String get keybindingsReadOnlyMobile => '键盘快捷键仅在桌面端可用';

  @override
  String get keyboardShortcutsResetConfirm => '您确定要将所有键盘快捷键重置为默认值吗？';

  @override
  String get bindingConflict => '冲突';

  @override
  String get captureHint => '按下按键组合...';

  @override
  String get shortcutCancelStreaming => '取消 AI 响应';

  @override
  String get shortcutCloseDialog => '关闭对话框';

  @override
  String get shortcutOpenLatestChild => '打开最新的子会话';

  @override
  String get shortcutNavPrevSibling => '上一个同级会话';

  @override
  String get shortcutNavNextSibling => '下一个同级会话';

  @override
  String get shortcutNavParent => '转到父会话';

  @override
  String get shortcutCyclePrimaryAgent => '切换主要代理';

  @override
  String get shortcutToggleSidebar => '切换侧边栏';

  @override
  String get shortcutNewChat => '新建聊天';

  @override
  String get shortcutOpenModelSelector => '打开模型选择器';

  @override
  String get shortcutOpenSettings => '打开设置';

  @override
  String get shortcutOpenWorkspace => '打开工作区';

  @override
  String get shortcutScrollToChatStart => '滚动到顶部';

  @override
  String get shortcutScrollToChatEnd => '滚动到底部';
}
