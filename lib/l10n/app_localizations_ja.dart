// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'チャットORAI';

  @override
  String get settings => '設定';

  @override
  String get providerConfiguration => 'プロバイダー設定';

  @override
  String get apiKey => 'API キー';

  @override
  String get enterApiKey => 'あなたの OpenRouter API キーを入力してください';

  @override
  String get baseUrl => 'ベース URL';

  @override
  String get validateApiKey => 'API キーを検証';

  @override
  String get apiKeyValid => 'API キーは有効です';

  @override
  String get apiKeyInvalid => 'API キーの形式が無効です';

  @override
  String get apiKeyEmpty => 'API キーは空にできません';

  @override
  String get appearance => '外観';

  @override
  String get theme => 'テーマ';

  @override
  String get system => 'システム';

  @override
  String get useSystemTheme => 'システムのテーマを使用';

  @override
  String get light => 'ライト';

  @override
  String get useLightTheme => 'ライト テーマを使用';

  @override
  String get dark => 'ダーク';

  @override
  String get useDarkTheme => 'ダーク テーマを使用';

  @override
  String get fontSize => 'フォント サイズ';

  @override
  String currentSize(Object percentage) {
    return '現在のサイズ: $percentage%';
  }

  @override
  String get accessibility => 'アクセシビリティ';

  @override
  String get reduceMotion => 'モーションを減らす';

  @override
  String get disableAnimation => 'アニメーションを無転送または減らす';

  @override
  String get highContrast => '高コントラスト';

  @override
  String get increaseContrast => 'コントラストを増加させて読みやすさを向上';

  @override
  String get wideScreenMode => 'ワイドスクリーン モード';

  @override
  String get useFullScreenWidth => 'チャットコンテンツのために全画面幅を使用';

  @override
  String get autoScrollDuringStreaming => 'ストリーミング中の自動スクロール';

  @override
  String get autoScrollDuringStreamingDesc => '新しいコンテンツが追加されるとリストを自動的に下にスクロール';

  @override
  String get showContinuationSuggestions => '継続提案を表示';

  @override
  String get showContinuationSuggestionsDesc => 'AIの応答後にフォローアップ提案を表示します';

  @override
  String get expandReasoningByDefault => 'デフォルトで推論を展開';

  @override
  String get expandReasoningByDefaultDesc => 'AIの応答時に思考ブロックを展開して表示します';

  @override
  String get language => '言語';

  @override
  String get english => '英語';

  @override
  String get russian => 'ロシア語';

  @override
  String get ukrainian => 'ウクライナ語';

  @override
  String get arabic => 'アラビア語 (RTL)';

  @override
  String get chinese => '中国語';

  @override
  String get japanese => '日本語';

  @override
  String get resetSettings => '設定をリセット';

  @override
  String get resetAllSettings => 'すべての設定をデフォルト値にリセット';

  @override
  String get save => '保存';

  @override
  String get cancel => 'キャンセル';

  @override
  String get close => '閉じる';

  @override
  String get copy => 'コピー';

  @override
  String get apiKeyCopied => 'API キーがコピーされました';

  @override
  String get apiKeySaved => 'API キーが保存されました';

  @override
  String get settingsSaved => '設定が保存されました！';

  @override
  String get settingsReset => '設定がデフォルト値にリセットされました';

  @override
  String get appInfo => 'アプリ情報';

  @override
  String get appDescription =>
      'AI モデルとの会話アプリケーションです。\n\n特徴:\n• さまざまな AI モデルとの会話\n• チャット履歴の保存\n• ダークとライト テーマ\n• 適応型インターフェース\n\nDeveloped with ❤️ using Flutter';

  @override
  String get shareChat => 'チャットを共有';

  @override
  String get copyChat => 'チャットをコピー';

  @override
  String get renameChat => 'チャットを名前変更';

  @override
  String get failedToShowMenu => 'メニューを表示できませんでした';

  @override
  String get failedToRenameChat => 'チャットを名前変更できませんでした';

  @override
  String get failedToCopyChat => 'チャットをコピーできませんでした';

  @override
  String get chatSharingNotImplemented => 'チャット共有はまだ実装されていません';

  @override
  String get newChat => '新しいチャット';

  @override
  String get noChatsYet => 'まだチャットがありません';

  @override
  String get startConversation => '新しいチャットをクリックして会話を開始してください';

  @override
  String get reasoning => '考察';

  @override
  String get tapToExpand => '展開するにはタップ';

  @override
  String get collapse => '折りたたむ';

  @override
  String get expand => '展開';

  @override
  String chatRenamedTo(Object name) {
    return 'チャットは$nameに名前変更されました';
  }

  @override
  String get appTitle => 'チャット AI';

  @override
  String get justNow => '直前';

  @override
  String minAgo(Object minutes) {
    return '$minutes 分前';
  }

  @override
  String get onlyOneMinuteAgo => '1 分前';

  @override
  String hoursAgo(Object hours) {
    return '$hours 時間前';
  }

  @override
  String get onlyOneHourAgo => '1 時間前';

  @override
  String daysAgo(Object days) {
    return '$days 日前';
  }

  @override
  String get onlyOneDayAgo => '1 日前';

  @override
  String get renameChatTitle => 'チャットを名前変更';

  @override
  String get enterNewChatName => '新しいチャット名を入力';

  @override
  String get rename => '名前変更';

  @override
  String get ok => 'OK';

  @override
  String get modelSelected => 'モデルが選択されました';

  @override
  String get errorLoadingModels => 'モデルの読み込みにエラーが発生しました';

  @override
  String get models => 'モデル';

  @override
  String get searchModels => 'モデルを検索';

  @override
  String get refresh => '更新';

  @override
  String get details => '詳細';

  @override
  String get context => 'コンテキスト';

  @override
  String contextMessages(Object percent, Object usable, Object used) {
    return 'コンテキスト: $used / $usable トークン ($percent%)';
  }

  @override
  String get contextInstructions => '指示';

  @override
  String get contextAgentPrompt => 'エージェントプロンプト';

  @override
  String get contextUserPrompt => 'ユーザープロンプト';

  @override
  String get contextCompactSession => 'セッションを圧縮';

  @override
  String get contextCompacting => '圧縮中…';

  @override
  String get contextUsageBreakdown => '使用状況';

  @override
  String get contextPromptTokens => '入力トークン';

  @override
  String get contextOutputTokens => '出力トークン';

  @override
  String get contextCacheRead => 'キャッシュ読み取り';

  @override
  String get contextCacheWrite => 'キャッシュ書き込み';

  @override
  String get contextToolTokens => 'ツールトークン';

  @override
  String get contextSpentLabel => '使用額';

  @override
  String get contextTokensIncludedInPrompt => 'ツールトークンはプロンプトに含まれています';

  @override
  String contextAutoCompactAt(Object buffer, Object percent) {
    return '$percent% で自動圧縮 · バッファ $buffer トークン';
  }

  @override
  String get free => '無料';

  @override
  String get paid => '有料';

  @override
  String get multimodal => 'マルチモーダル';

  @override
  String get vision => 'ビジョン';

  @override
  String get tools => 'ツール';

  @override
  String get available => '利用可能';

  @override
  String get description => '説明';

  @override
  String get technicalDetails => '技術的詳細';

  @override
  String get provider => 'プロバイダー';

  @override
  String get inputTokens => '入力トークン';

  @override
  String get notAvailable => '利用不可';

  @override
  String get outputTokens => '出力トークン';

  @override
  String get features => '特徴';

  @override
  String get featuresDisplayedBasedOnActualModelCapabilities =>
      '実際のモデルの機能に基づいて特徴が表示されます';

  @override
  String get noModelsFound => 'モデルが見つかりません';

  @override
  String get noAvailableModels => '利用可能なモデルがありません';

  @override
  String get tryADifferentSearchQuery => '異なる検索クエリを試してください';

  @override
  String get tryRefreshingOrCheckYourInternetConnection =>
      '更新またはインターネット接続を確認してください';

  @override
  String get aiIsTyping => 'AI が入力中です';

  @override
  String get loadingMsg1 => 'サーバーの応答を待っています…';

  @override
  String get loadingMsg2 => 'データ送信完了 — もう少し…';

  @override
  String get loadingMsg3 => '考えをまとめています…';

  @override
  String get loadingMsg4 => '最適な回答を選んでいます…';

  @override
  String get loadingMsg5 => '回答を読み込み中（もうすぐ）…';

  @override
  String get failedToSendMessage => 'メッセージの送信に失敗しました';

  @override
  String get retry => '再試行';

  @override
  String get bootstrapErrorTitle => 'アプリの起動に失敗しました';

  @override
  String get bootstrapErrorBody => '設定を確認してもう一度お試しください。';

  @override
  String get enterYourMessage => 'あなたのメッセージを入力してください...';

  @override
  String get saveAndSend => '保存して送信';

  @override
  String get messageEditedSuccessfully => 'メッセージが正常に編集されました';

  @override
  String get failedToEditMessage => 'メッセージの編集に失敗しました';

  @override
  String get messageEditedAndResponseRegenerated => 'メッセージが編集され、応答が再生成されました';

  @override
  String get failedToEditAndSendMessage => 'メッセージの編集と送信に失敗しました';

  @override
  String get areYouSureYouWantToDeleteThisMessage => 'このメッセージを削除してもよろしいですか？';

  @override
  String confirmDeleteMessage(Object chatTitle) {
    return 'チャット\"$chatTitle\"を削除してもよろしいですか？';
  }

  @override
  String get areYouSureYouWantToRegenerateThisMessage =>
      'このメッセージを再生成してもよろしいですか？';

  @override
  String modelDoesNotSupportImages(Object modelId) {
    return 'モデル$modelIdは画像をサポートしていません。写真を添付することはできますが、送信は機能しません。';
  }

  @override
  String chatTitleUpdated(Object title) {
    return 'チャット名を変更: $title';
  }

  @override
  String get messageDeletedSuccessfully => 'メッセージが正常に削除されました';

  @override
  String get failedToDeleteMessage => 'メッセージの削除に失敗しました';

  @override
  String get regenerationStarted => '再生成が開始されました';

  @override
  String get failedToRegenerateMessage => 'メッセージの再生成に失敗しました';

  @override
  String get messageCopied => 'メッセージがコピーされました';

  @override
  String get failedToCopyMessage => 'メッセージのコピーに失敗しました';

  @override
  String get messageShared => 'メッセージが共有されました';

  @override
  String get failedToShareMessage => 'メッセージの共有に失敗しました';

  @override
  String get edit => '編集';

  @override
  String editToolTitle(String path) {
    return '編集 $path';
  }

  @override
  String patchToolTitle(String path) {
    return 'パッチ $path';
  }

  @override
  String get share => '共有';

  @override
  String get copyMessage => 'メッセージをコピー';

  @override
  String get delete => '削除';

  @override
  String get listen => '聞く';

  @override
  String get regenerate => '再生成';

  @override
  String get continueResponse => '応答を継続';

  @override
  String get like => 'いいね';

  @override
  String get dislike => 'いいねしない';

  @override
  String get copiedToClipboard => 'クリップボードにコピーされました';

  @override
  String get failedToCopy => 'コピーに失敗しました';

  @override
  String get messageDeleted => 'メッセージが削除されました';

  @override
  String get errorMessage => 'エラーメッセージ';

  @override
  String get welcomeMessage => 'ようこそ！今日はどのようにお手伝いできますか？';

  @override
  String get welcomeQuestion1 => '量子コンピューティングを簡単な言葉で説明してください';

  @override
  String get welcomeQuestion2 => '人工知能の最新トレンドは何ですか？';

  @override
  String get welcomeQuestion3 => '私のチームにプロのメールを書くのを手伝ってください';

  @override
  String get welcomeQuestion4 => 'より良いプログラマーになるために何を学ぶべきですか？';

  @override
  String get welcomeQuestion5 => '週末のプロジェクトのためのクリエイティブなアイデア5つ';

  @override
  String get welcomeQuestion6 => '個人の成長に役立つ良い本はありますか？';

  @override
  String get welcomeQuestion7 => '私のスタートアップの名前を考えてください';

  @override
  String get welcomeQuestion8 => '健康的な一週間の食事プランを作成してください';

  @override
  String get welcomeQuestion9 => 'Flutter 開発のベストプラクティスは何ですか？';

  @override
  String get welcomeQuestion10 => '非同期と同期プログラミングの違いは何ですか？';

  @override
  String get welcomeQuestion11 => 'コードのパフォーマンスを最適化する方法は？';

  @override
  String get welcomeQuestion12 => '最も有用なプログラミング設計パターンは？';

  @override
  String get welcomeQuestion13 => '機械学習の基礎を教えてください';

  @override
  String get welcomeQuestion14 => 'クラウドコンピューティングの主要概念は？';

  @override
  String get welcomeQuestion15 => '初心者向けにブロックチェーン技術を説明してください';

  @override
  String get welcomeQuestion16 => '技術的な観点からインターネットはどのように動作しますか？';

  @override
  String get welcomeQuestion17 => '最高の生産性テクニックは何ですか？';

  @override
  String get welcomeQuestion18 => '集中力と注意力を向上させる方法は？';

  @override
  String get welcomeQuestion19 => '最大の生産性を得るための日課を作成してください';

  @override
  String get welcomeQuestion20 => '成功につながる良い習慣は？';

  @override
  String get welcomeQuestion21 => 'ソフトウェアエンジニアリングの面接にどう準備するか？';

  @override
  String get welcomeQuestion22 => 'テック業界で最も価値のあるスキルは？';

  @override
  String get welcomeQuestion23 => '給与を交渉する方法は？';

  @override
  String get welcomeQuestion24 => '働きたいトップテック企業は？';

  @override
  String get welcomeQuestion25 => '2026年の宇宙探査の最新ブレイクスルーは？';

  @override
  String get welcomeQuestion26 => 'AIが医療をどのように変えているか？';

  @override
  String get welcomeQuestion27 => '2026年の最もエキサイティングなテクノロジーは？';

  @override
  String get welcomeQuestion28 => '再生可能エネルギーの未来は？';

  @override
  String get welcomeQuestion29 => '最も重要な哲学的な質問は？';

  @override
  String get welcomeQuestion30 => '問題に対してより批判的に考える方法は？';

  @override
  String get welcomeQuestion31 => '新しいスキルを学ぶ最良の方法は？';

  @override
  String get welcomeQuestion32 => '難しいものを学ぶ際にモチベーションを維持する方法は？';

  @override
  String get welcomeQuestion33 => '2026年に学ぶべき最良のプログラミング言語は？';

  @override
  String get welcomeQuestion34 => '強力なポートフォリオを作成する方法は？';

  @override
  String get welcomeQuestion35 => '生産性を高めるトップAIツールは？';

  @override
  String get welcomeQuestion36 => '機械学習は実際にどのように動作するのか？';

  @override
  String get welcomeQuestion37 => 'コードレビューのベストプラクティスは？';

  @override
  String get welcomeQuestion38 => 'クリーンで保守しやすいコードを書く方法は？';

  @override
  String get welcomeQuestion39 => 'マイクロサービスとは何か、いつ使用すべきか？';

  @override
  String get welcomeQuestion40 => 'REST APIとGraphQLの違いは？';

  @override
  String get welcomeQuestion41 => '学ぶべき最良のクラウドプラットフォームは？';

  @override
  String get welcomeQuestion42 => '技術面接にどう準備するか？';

  @override
  String get welcomeQuestion43 => '開発者に必要なソフトスキルは？';

  @override
  String get welcomeQuestion44 => '開発者として給与交渉を行う方法は？';

  @override
  String get welcomeQuestion45 => 'リモートワークに最適なツールは？';

  @override
  String get welcomeQuestion46 => '在宅勤務で生産性を維持する方法は？';

  @override
  String get welcomeQuestion47 => '最良のプロジェクト管理手法は？';

  @override
  String get welcomeQuestion48 => '難しい同僚とどう対処するか？';

  @override
  String get welcomeQuestion49 => 'リーダーシップに関するベストブックは？';

  @override
  String get welcomeQuestion50 => '成功したテックスタートアップを立ち上げる方法は？';

  @override
  String get welcomeQuestion51 => 'ウェブ開発の最新トレンドは？';

  @override
  String get welcomeQuestion52 => 'ブロックチェーン技術はどのように動作するのか？';

  @override
  String get welcomeQuestion53 => 'NFTとは何か、注目すべき点は？';

  @override
  String get welcomeQuestion54 => 'メタバースの概念を説明してください';

  @override
  String get welcomeQuestion55 => 'コーディングに最適なAIモデルは？';

  @override
  String get welcomeQuestion56 => 'ChatGPTを効果的に使用する方法は？';

  @override
  String get welcomeQuestion57 => 'AIの倫理的側面は？';

  @override
  String get welcomeQuestion58 => 'AIは将来的にお仕事にどのような影響を与えるか？';

  @override
  String get welcomeQuestion59 => 'サイバーセguridadのベストプラクティスは？';

  @override
  String get welcomeQuestion60 => 'オンラインでのプライバシーを守る方法は？';

  @override
  String get welcomeQuestion61 => 'データサイエンスに最適なツールは？';

  @override
  String get welcomeQuestion62 => 'データを効果的に可視化する方法は？';

  @override
  String get welcomeQuestion63 => 'モバイルアプリ開発に最適なフレームワークは？';

  @override
  String get welcomeQuestion64 => 'クロスプラットフォームアプリを作成する方法は？';

  @override
  String get welcomeQuestion65 => 'ゲーム開発に最適なエンジンは？';

  @override
  String get welcomeQuestion66 => '3Dモデリングを始める方法は？';

  @override
  String get welcomeQuestion67 => 'ビデオ編集に最適なツールは？';

  @override
  String get welcomeQuestion68 => '魅力的なコンテンツを作成する方法は？';

  @override
  String get welcomeQuestion69 => 'ソーシャルメディア戦略のベストプラクティスは？';

  @override
  String get welcomeQuestion70 => '個人ブランドを構築する方法は？';

  @override
  String get welcomeQuestion71 => 'ネットワーキングのベストアドバイスは？';

  @override
  String get welcomeQuestion72 => '素晴らしいプレゼンテーションを作成する方法は？';

  @override
  String get welcomeQuestion73 => '時間管理のベストテクニックは？';

  @override
  String get welcomeQuestion74 => '燃え尽き症候群を避ける方法は？';

  @override
  String get welcomeQuestion75 => '瞑想アプリのベストセレクションは？';

  @override
  String get welcomeQuestion76 => '睡眠の質を向上させる方法は？';

  @override
  String get welcomeQuestion77 => '最高のトレーニングルーチンは？';

  @override
  String get welcomeQuestion78 => '予算を抑えつつ健康的に食べる方法は？';

  @override
  String get welcomeQuestion79 => 'テック関係者向けの最高の旅行先は？';

  @override
  String get welcomeQuestion80 => '新しい言語を素早く学ぶ方法は？';

  @override
  String get welcomeQuestion81 => 'リモートチームでの効果的なコラボレーションは？';

  @override
  String get welcomeQuestion82 => '効果的なコードレビューの方法は？';

  @override
  String get welcomeQuestion83 => 'ソフトウェアアーキテクトに必要なトップスキルは？';

  @override
  String get welcomeQuestion84 => 'スケーラブルなデータベースシステムを設計する方法は？';

  @override
  String get welcomeQuestion85 => '学ぶべき最良のDevOpsツールは？';

  @override
  String get welcomeQuestion86 => 'CI/CDパイプラインを実装する方法は？';

  @override
  String get welcomeQuestion87 => 'コンテナーオーケストレーションプラットフォームとは？';

  @override
  String get welcomeQuestion88 => 'サーバーレスコンピューティングの利点は？';

  @override
  String get welcomeQuestion89 => 'APIセキュリティのベストプラクティスは？';

  @override
  String get welcomeQuestion90 => 'モバイルアプリのパフォーマンスを最適化する方法は？';

  @override
  String get welcomeQuestion91 => 'プログレッシブウェブアプリとは何か？';

  @override
  String get welcomeQuestion92 => 'アクセシブルなウェブアプリを作成する方法は？';

  @override
  String get welcomeQuestion93 => 'UI/UXデザインのベストプラクティスは？';

  @override
  String get welcomeQuestion94 => 'ユーザーリサーチを効果的に実施する方法は？';

  @override
  String get welcomeQuestion95 => 'A/Bテストのベスト戦略は？';

  @override
  String get welcomeQuestion96 => 'ユーザー行動データを分析する方法は？';

  @override
  String get welcomeQuestion97 => '成長ハッキングのベストテクニックは？';

  @override
  String get welcomeQuestion98 => '製品周りにコミュニティを構築する方法は？';

  @override
  String get welcomeQuestion99 => 'カスタマーサポートに最適なツールは？';

  @override
  String get welcomeQuestion100 => 'カスタマーフィードバックを効果的に処理する方法は？';

  @override
  String get welcomeQuestion101 => 'ReactとVueの違いは？';

  @override
  String get welcomeQuestion102 => 'TypeScriptがJavaScript開発をどのように改善するか？';

  @override
  String get welcomeQuestion103 => 'REST API設計のベストプラクティスは？';

  @override
  String get welcomeQuestion104 => 'ウェブアプリの認証を実装する方法は？';

  @override
  String get welcomeQuestion105 => 'GraphQLがRESTよりも優れている点は？';

  @override
  String get welcomeQuestion106 => 'データベースクエリのパフォーマンスを最適化する方法は？';

  @override
  String get welcomeQuestion107 => 'マイクロサービスアーキテクチャパターンとは？';

  @override
  String get welcomeQuestion108 => 'キャッシュ戦略を実装する方法は？';

  @override
  String get welcomeQuestion109 => 'JavaScriptのテストフレームワークのベストセレクションは？';

  @override
  String get welcomeQuestion110 => 'Reactコンポーネントのユニットテストを書く方法は？';

  @override
  String get welcomeQuestion111 => 'OOPのSOLID原則とは？';

  @override
  String get welcomeQuestion112 => 'Pythonでデザインパターンを実装する方法は？';

  @override
  String get welcomeQuestion113 => 'Gitワークフローのベストプラクティスは？';

  @override
  String get welcomeQuestion114 => 'マージコンフリクトを効果的に解決する方法は？';

  @override
  String get welcomeQuestion115 => 'コンテナ化のベストプラクティスは？';

  @override
  String get welcomeQuestion116 => 'Dockerコンテナを保護する方法は？';

  @override
  String get welcomeQuestion117 => 'Kubernetesでのデプロイ戦略とは？';

  @override
  String get welcomeQuestion118 => 'アプリケーションのパフォーマンスをモニタリングする方法は？';

  @override
  String get welcomeQuestion119 => 'ログ記録のベストプラクティスは？';

  @override
  String get welcomeQuestion120 => '分散システムでのエラーハンドリング方法は？';

  @override
  String get continueConversation => '会話を継続';

  @override
  String get generatingSuggestions => '提案を生成中...';

  @override
  String get searchChats => 'チャットを検索...';

  @override
  String noChatsFound(Object query) {
    return '指定されたクエリに対してチャットが見つかりませんでした';
  }

  @override
  String get tryDifferentSearchTerm => '異なる検索語を試してください';

  @override
  String get appShortName => 'ChatORAI';

  @override
  String get typeYourMessage => 'メッセージを入力してください...';

  @override
  String get addImage => '画像';

  @override
  String get addCamera => 'カメラ';

  @override
  String get addFile => 'ファイル';

  @override
  String get selectLanguage => '言語を選択';

  @override
  String get searchFavorites => 'お気に入りを検索';

  @override
  String get showAllModels => 'すべてのモデルを表示';

  @override
  String get showFavoritesOnly => 'お気に入りのみを表示';

  @override
  String get noFavoriteModels => 'お気に入りのモデルがありません';

  @override
  String get tapHeartToAddFavorites => 'モデルの心臓アイコンをタップしてお気に入りに追加';

  @override
  String get addToFavorites => 'お気に入りに追加';

  @override
  String get removeFromFavorites => 'お気に入りから削除';

  @override
  String get recentModels => '最近使用したモデル';

  @override
  String get loadingSkills => 'スキルを読み込み中';

  @override
  String get noSkillsInstalled => 'インストールされているスキルはありません';

  @override
  String get noSkillsMatchSearch => '検索に一致するスキルがありません';

  @override
  String get allSkillsRequirePermission => 'すべてのスキルには権限が必要です';

  @override
  String skillExecuted(Object name) {
    return 'スキルが実行されました';
  }

  @override
  String get configuration => '設定';

  @override
  String get stats => '統計';

  @override
  String get usageStatistics => '使用統計';

  @override
  String get totalSessions => 'セッション数';

  @override
  String get totalMessages => 'メッセージ数';

  @override
  String get days => '日';

  @override
  String get totalTokens => '合計トークン数';

  @override
  String get totalCost => '合計コスト';

  @override
  String get avgCostPerDay => '1日平均コスト';

  @override
  String get avgTokensPerSession => '平均トークン数/セッション';

  @override
  String get medianTokensPerSession => '中央値トークン数/セッション';

  @override
  String get cacheRead => 'キャッシュ読み取り';

  @override
  String get cacheWrite => 'キャッシュ書き込み';

  @override
  String get toolUsage => 'ツール使用状況';

  @override
  String get modelUsage => 'モデル使用状況';

  @override
  String get noStatsAvailable => '統計情報がありません';

  @override
  String get reasoningTokens => '推論トークン';

  @override
  String get addProvider => 'プロバイダーを追加';

  @override
  String get applySettings => '設定を適用';

  @override
  String get copyCodeTooltip => 'コードをコピー';

  @override
  String get copiedFeedback => 'コピーしました';

  @override
  String get defaultSuggestion1 => 'このトピックについて詳しく教えてください';

  @override
  String get defaultSuggestion2 => '例を挙げていただけますか？';

  @override
  String get defaultSuggestion3 => '代替案はありますか？';

  @override
  String get deleteChat => 'チャットを削除';

  @override
  String get manageProviders => 'プロバイダーを管理';

  @override
  String get micAutoRestart => '再試行中...';

  @override
  String get micNoSpeechDetected => '聞こえませんでした。もう一度お試しくください。';

  @override
  String get micStartFailed => 'マイクの起動に失敗しました';

  @override
  String get micUnavailable => 'マイクが利用できません';

  @override
  String get modelParameters => 'モデルパラメータ';

  @override
  String get modelSettings => 'モデル設定';

  @override
  String get noInternetConnection => 'インターネット接続がありません';

  @override
  String get noModelSelected => 'モデルが選択されていません';

  @override
  String get openaiCompatibleApi => 'OpenAI 互換 API';

  @override
  String get openaiCompatibleApiDescription => '任意の OpenAI 互換 API エンドポイントに接続';

  @override
  String get permissionAlways => '常に許可';

  @override
  String get permissionAlwaysConfirm => 'Always allow';

  @override
  String get permissionDialogPatterns => 'アクセス要求:';

  @override
  String get permissionOnce => '一度のみ';

  @override
  String get permissionReject => '拒否';

  @override
  String get providers => 'プロバイダー';

  @override
  String get refreshQuestions => '質問を更新';

  @override
  String get resetToDefaults => 'デフォルトにリセット';

  @override
  String get settingsApplied => '設定が正常に適用されました';

  @override
  String get speechErrorNetwork => 'ネットワークエラー。インターネット接続を確認してください。';

  @override
  String get speechErrorNoMatch => '音声を認識できませんでした。もう一度お試しください。';

  @override
  String get speechErrorNotAuthorized => 'マイクへのアクセス権がありません。設定で権限を確認してください。';

  @override
  String get speechErrorServer => '認識サーバーエラー。後でもう一度お試しください。';

  @override
  String get speechErrorTimeout => 'リスニングがタイムアウトしました。何も聞こえませんでした。';

  @override
  String get speechErrorTooManyRequests => 'リクエストが多すぎます。後でもう一度お試しください。';

  @override
  String get speechErrorUnknown => '音声認識エラー';

  @override
  String get speechListening => '話してください...';

  @override
  String get speechPhase2 => '聞こえません...もう少し大きな声で';

  @override
  String get speechPreparing => '準備中...';

  @override
  String get speechProcessing => '処理中...';

  @override
  String speechStartError(Object error) {
    return '開始エラー: $error';
  }

  @override
  String get systemPrompt => 'システムプロンプト';

  @override
  String get systemPromptDescription => 'AIアシスタントへの指示';

  @override
  String get systemPromptSuggestion =>
      'あなたは有用なアシスタントです。会話を続け、最後のメッセージに対して3つの具体的で論理的な続きを提案してください。ユーザーと同じ言語で回答してください。';

  @override
  String get temperature => '温度';

  @override
  String get temperatureDescription => 'ランダム性を制御: 低=より集中、高=より創造的';

  @override
  String get toggleNavigatorTooltip => 'ナビゲーターを切り替え';

  @override
  String get userPromptSuggestion =>
      'このメッセージに対して3つの具体的で論理的な続きを提案してください。リストのみで回答し、追加テキストは含めないでください。';

  @override
  String get versionLabel => 'バージョン:';

  @override
  String get welcomeGreeting1 => '聞いて、探索して、作ろう — 一緒に考えましょう。';

  @override
  String get welcomeGreeting2 => '質問したり、タスクを説明したり、会話を始めたりしてください。';

  @override
  String get welcomeGreeting3 => '質問するか、探索を始めましょう。';

  @override
  String get welcomeGreeting4 =>
      'どんな質問でも、アイデアを共有しても、助けてと言っても — ここにいるので助けになります。';

  @override
  String get welcomeGreeting5 => 'アイデアがありますか？一緒に考えましょう。';

  @override
  String get welcomeGreeting6 => '会話の方向性を決めます。';

  @override
  String get welcomeGreeting7 => '今日は何を探索しますか？';

  @override
  String get welcomeGreeting8 => '考えを書いてください。一緒に分析しましょう。';

  @override
  String get welcomeGreeting9 => '好奇心は大歓迎です。';

  @override
  String get welcomeGreeting10 => 'あなたの質問が次の私の答えです。';

  @override
  String get welcomeGreeting11 => 'アイデアを答えに変えましょう。';

  @override
  String get welcomeGreeting12 => '質問を入力してください。残りは私の仕事です。';

  @override
  String modelDoesNotSupportFiles(Object modelId) {
    return 'モデル $modelId はファイルをサポートしていません。ファイルを添付することはできますが、送信は機能しません。';
  }

  @override
  String generatingSuggestionsFailed(Object error) {
    return '提案の生成に失敗しました: $error';
  }

  @override
  String get toggleSidebarTooltip => 'サイドバーを切り替え';

  @override
  String get openMenuTooltip => 'メニューを開く';

  @override
  String get addFileTooltip => 'ファイルを追加';

  @override
  String get modelSettingsTooltip => 'モデル設定';

  @override
  String get switchAgentTooltip => 'エージェントを切り替え';

  @override
  String get selectModelTooltip => 'モデルを選択';

  @override
  String get removeFileTooltip => 'ファイルを削除';

  @override
  String get goToParentSessionTooltip => '親セッションに移動';

  @override
  String get previousSiblingTooltip => '前の兄弟';

  @override
  String get nextSiblingTooltip => '次の兄弟';

  @override
  String get cancellingRetryTooltip => '再試行をキャンセル中...';

  @override
  String get stopGenerationTooltip => '生成を停止';

  @override
  String get question => '質問';

  @override
  String get skip => 'スキップ';

  @override
  String get answer => '回答';

  @override
  String get noAgentsAvailable => '利用可能なエージェントがありません';

  @override
  String permissionAlwaysConfirmDescription(Object title) {
    return 'これによりアプリが再起動するまで \"$title\" が許可されます。';
  }

  @override
  String get chatActionsMenuTooltip => 'チャットメニュー';

  @override
  String get startListening => '音声入力を開始';

  @override
  String get stopListening => '音声入力を停止';

  @override
  String get listening => '話してください...';

  @override
  String get sendMessage => 'メッセージを送信';

  @override
  String get maxTokens => '最大トークン数';

  @override
  String get maxTokensDescription => '生成される応答の最大長';

  @override
  String get activeModel => 'アクティブなモデル';

  @override
  String apiLimitExceeded(Object limit) {
    return 'API制限超過: $limit';
  }

  @override
  String valueExceedsApiLimit(Object limit) {
    return '値がAPI制限 ($limit) を超えています。最大値を使用します。';
  }

  @override
  String get micStopFailed => 'マイクの停止に失敗しました';

  @override
  String get errorProcessingRequest =>
      '申し訳ありません。リクエストの処理中にエラーが発生しました。もう一度お試しください。';

  @override
  String rateLimitRetryMessage(Object seconds) {
    return 'レート制限に達しました。$seconds秒後に再試行します...';
  }

  @override
  String get messageNotFound => 'メッセージが見つかりません';

  @override
  String get errorEditingMessage => 'メッセージの編集エラー';

  @override
  String get errorEditAndSendMessage => 'メッセージの編集と送信エラー';

  @override
  String get defaultSuggestion4 => 'これは実際にどのように適用されますか？';

  @override
  String get fileAttachedButNotSupported => 'ファイルが添付されましたが、現在のモデルではサポートされていません';

  @override
  String get expandTooltip => '展開';

  @override
  String get collapseTooltip => '折りたたむ';

  @override
  String get addProviderTitleEdit => 'プロバイダーを編集';

  @override
  String get addProviderTitleAdd => 'プロバイダーを追加';

  @override
  String get addProviderLabelProvider => 'プロバイダー';

  @override
  String get addProviderCustomName => 'カスタムプロバイダー...';

  @override
  String get addProviderFieldProviderName => 'プロバイダー名';

  @override
  String get addProviderHintProviderName => '例: マイカスタムAI';

  @override
  String get addProviderLabelApiKey => 'API キー';

  @override
  String get addProviderHintApiKey => 'API キーを入力してください';

  @override
  String get addProviderHintCustomApiKey => 'ローカルプロバイダーは任意';

  @override
  String get addProviderLabelBaseUrl => 'ベース URL';

  @override
  String get addProviderHintBaseUrl => 'https://api.example.com/v1';

  @override
  String get addProviderActionSave => '保存';

  @override
  String get addProviderErrorApiKeyRequired => 'API キーが必要です';

  @override
  String get selectModels => 'モデルを選択';

  @override
  String get deselectAll => '全選択解除';

  @override
  String get selectAll => '全選択';

  @override
  String get modelsAvailable => '利用可能なモデルがありません';

  @override
  String get modelsMatchSearch => '検索に一致するモデルがありません';

  @override
  String selectModelsCount(Object count, Object total) {
    return '$total 中 $count 選択';
  }

  @override
  String modelsLoadError(Object error) {
    return 'モデルの読み込みに失敗しました: $error';
  }

  @override
  String get systemPromptHint => 'あなたは有用なアシスタントです...';

  @override
  String get temperatureHint => '0.0 - 2.0';

  @override
  String get loadingSettings => '設定を読み込み中...';

  @override
  String errorApplyingSettings(Object error) {
    return '設定の適用中にエラーが発生しました: $error';
  }

  @override
  String deleteProviderTitle(Object providerName) {
    return '$providerName を削除しますか?';
  }

  @override
  String get deleteProviderContent =>
      'これによりプロバイダーとすべての設定が削除されます。モデルを使用するには再度追加する必要があります。';

  @override
  String get errorLoadingProviders => 'プロバイダーの読み込みに失敗しました';

  @override
  String get noProvidersConfigured => 'プロバイダーが設定されていません';

  @override
  String get addProviderToGetStarted => '開始するには API キーを持つプロバイダーを追加してください';

  @override
  String statsError(Object error) {
    return 'エラー: $error';
  }

  @override
  String get total => '合計';

  @override
  String modelsProviderCountFormat(Object count, Object providerName) {
    return '$providerName · $count';
  }

  @override
  String get mcpServers => 'MCP サーバー';

  @override
  String get mcpAddServer => 'MCP サーバーを追加';

  @override
  String get mcpAddServerTitle => 'MCP サーバーを追加';

  @override
  String get mcpNameLabel => '名前';

  @override
  String get mcpNameHint => '例: filesystem';

  @override
  String get mcpNameHelper => 'chatorai.json で使用する一意の識別子';

  @override
  String get mcpTypeLocal => 'ローカル';

  @override
  String get mcpTypeRemote => 'リモート';

  @override
  String get mcpTypeLocalTooltip => 'お使いのマシンで実行';

  @override
  String get mcpTypeRemoteTooltip => 'HTTP/SSE エンドポイント';

  @override
  String get mcpCommandLabel => 'コマンド';

  @override
  String get mcpCommandHint => 'uvx mcp-server-filesystem ~/docs';

  @override
  String get mcpCommandHelper => '引数を空白で区切った完全なコマンド';

  @override
  String get mcpUrlLabel => 'URL';

  @override
  String get mcpUrlHint => 'https://example.com/mcp';

  @override
  String get mcpUrlHelper => '完全な MCP エンドポイント URL';

  @override
  String get mcpEnvLabel => '環境変数 (JSON)';

  @override
  String get mcpEnvHint => 'GITHUB_TOKEN=ghp_xxx';

  @override
  String get mcpEnvHelper => '任意。文字列キーの JSON オブジェクトを貼り付けます（例: 単一の TOKEN エントリ）。';

  @override
  String get mcpTokenLabel => 'アクセストークン';

  @override
  String get mcpTokenHint => 'トークンだけを貼り付け（Bearer / 引用符は不要）';

  @override
  String get mcpTokenHelper => '任意。公開サーバーは空のままで可。トークンのみ貼り付ければヘッダーは自動で追加されます。';

  @override
  String get mcpAuthTypeLabel => 'トークン種別';

  @override
  String get mcpAuthTypeHelper =>
      'トークンの送信方法: Bearer (Authorization)、ApiKey (X-Api-Key)、またはそのままの Token。';

  @override
  String get mcpHeadersLabel => 'ヘッダー (JSON)';

  @override
  String get mcpHeadersHint => 'Authorization=Bearer token';

  @override
  String get mcpHeadersHelper => '任意。ヘッダーの JSON オブジェクトを貼り付けます。';

  @override
  String get mcpFormTab => 'フォーム';

  @override
  String get mcpRawTab => '生 JSON';

  @override
  String get mcpRawLabel => 'サーバーオブジェクト (JSON)';

  @override
  String get mcpRawHelper =>
      'ドキュメント通りにサーバーオブジェクトを貼り付けます。サーバー名は外側のキーです（例: searxng）。mcpServers で囲まれた全体のブロックもそのまま貼り付けできます。';

  @override
  String mcpParseError(Object field, Object message) {
    return '$field の JSON が無効です: $message';
  }

  @override
  String get mcpAddAction => '追加';

  @override
  String get mcpCancelAction => 'キャンセル';

  @override
  String get mcpRemoveTitle => 'MCP サーバーを削除しますか？';

  @override
  String mcpRemoveContent(Object name) {
    return 'chatorai.json から \"$name\" を削除しますか？';
  }

  @override
  String get mcpRemoveAction => '削除';

  @override
  String get mcpEditAction => '編集';

  @override
  String get mcpEditServerTitle => 'MCP サーバーを編集';

  @override
  String get mcpSaveAction => '保存';

  @override
  String get mcpNoServers => 'MCP サーバーが設定されていません';

  @override
  String get mcpNoServersHint => 'ツールを拡張するために MCP サーバーを追加してください';

  @override
  String get mcpTooltipAdd => 'サーバーを追加';

  @override
  String get mcpTooltipRefresh => '更新';

  @override
  String get mcpMarketplaceTab => 'マーケットプレイス';

  @override
  String get mcpInstalledTab => 'インストール済み';

  @override
  String get mcpInstall => 'インストール';

  @override
  String get mcpInstalled => 'インストール済み';

  @override
  String get mcpMarketplaceSearchHint => 'サーバーを検索…';

  @override
  String get mcpMarketplaceEmpty => '検索条件に一致するサーバーがありません';

  @override
  String get mcpMarketCategoryAll => 'すべて';

  @override
  String get mcpMarketCategorySearch => '検索';

  @override
  String get mcpMarketCategoryDocs => 'ドキュメント';

  @override
  String get mcpMarketCategoryDesign => 'デザイン';

  @override
  String get mcpMarketCategoryDev => '開発';

  @override
  String get mcpMarketCategoryFinance => '金融';

  @override
  String get mcpMarketCategoryTravel => '旅行';

  @override
  String get mcpMarketCategoryJobs => '求人';

  @override
  String get mcpMarketCategoryProductivity => '生産性';

  @override
  String get mcpMarketCategorySocial => 'ソーシャル';

  @override
  String get mcpMarketCategoryOther => 'その他';

  @override
  String get mcpMarketNeedsToken => '鍵が必要';

  @override
  String get mcpMarketDescExa =>
      'Exa は AI ワークフロー向けにウェブ検索とコードドキュメント検索を提供します。そのコネクターは、回答に根拠となる外部情報が必要な場合に、関連するウェブページや技術文書、ソース資料をリアルタイムで見つけるためのコンテキストをアシスタントに供給します。';

  @override
  String get mcpMarketDescContext7 =>
      'Context7 は AI 搭載のプログラマーやコードエディター向けに最新のコード例とドキュメントを提供します。その MCP コネクターは現在のライブラリコンテキストをアシスタントのワークフローに統合し、タブ切り替えを減らし、生成されるコードが古い API、存在しないメソッド、古い実装パターンを避けるよう支援します。';

  @override
  String get mcpMarketDescHuggingFace =>
      'Hugging Face は音声アシスタントを Hugging Face Hub や数千の Gradio アプリに接続します。そのコネクターはモデル、データセット、スペース、アプリのコンテキストを AI ワークフローに統合し、発見、実験、機械学習研究に活用できます。';

  @override
  String get mcpMarketDescParallel =>
      'Parallel Search は検索主体の AI ワークフロー向けにリアルタイムのウェブ検索とコンテンツ抽出を提供します。そのリモート MCP サーバーは、最新のウェブページコンテキストの取得やページの検証、そして新しい情報を要する質問やトピック調査時の抽出コンテンツ活用をアシスタントに支援します。';

  @override
  String get mcpMarketDescTavily =>
      'Tavily は検索・取得・調査の API を通じて AI エージェントにリアルタイムのウェブリソースアクセスを提供します。そのコネクターはアシスタントがライブデータに基づいて回答し、関連コンテンツを抽出し、安全制御を伴う本番エージェントワークフローを支援します。';

  @override
  String get mcpMarketDescGithub =>
      'GitHub はコード、課題、プルリクエスト、プロジェクト履歴の共同作業のためのプラットフォームです。その公式リモート MCP サーバーは、ソースの変更、レビュー、開発フロー、GitHub プロジェクトの状態を理解するための構造化されたリポジトリコンテキストをアシスタントに提供します。';

  @override
  String get mcpMarketDescPostman =>
      'Postman はコーディングエージェントや開発者ワークフローに API コンテキストを提供します。そのコネクターは API 定義、ドキュメント、コラボレーションのコンテキストをアシスタントの作業に統合し、エージェントが統合や実装の詳細を分析できるようにします。';

  @override
  String get mcpMarketDescSlack =>
      'Slack はチームメッセージ、チャンネル、ユーザー、共有ワークスペースを束ねるコラボレーションのハブです。そのリモート MCP サーバーはワークスペースの会話コンテキストをアシスタントのワークフローに統合し、ユーザーが回答を見つけ、議論を要約し、チャンネル間の活動を把握することを支援します。';

  @override
  String get mcpMarketDescFigma =>
      'Figma は UI 設計、プロトタイピング、開発者への引き継ぎのためのプロダクトデザインプラットフォームです。そのリモート MCP サーバーはファイル、プロジェクト、開発モードのコンテキストをアシスタントのワークフローに取り込み、エージェントが視覚的な作業を理解し、実装タスクに対応付けることを可能にします。';

  @override
  String get mcpMarketDescCanva =>
      'Canva はプレゼン、SNS 用グラフィック、ドキュメント、ブランド素材を制作するためのビジュアルコミュニケーションプラットフォームです。そのリモート MCP サーバーは Canva のプロジェクト、アセット、書き出しファイル、コメントへのアシスタントのアクセスを提供し、収集した情報をもとにクリエイティブ作品の検討・編集・準備を行えるようにします。';

  @override
  String get mcpMarketDescStripe =>
      'Stripe は決済処理、請求、顧客、開発者向けドキュメントを担う決済・金融インフラのプラットフォームです。そのリモート MCP サーバーは Stripe が裏付けるアカウントと実装のコンテキストをアシスタントに提供し、顧客フロー、請求の問い合わせ、決済タスクを理解することを支援します。';

  @override
  String get mcpMarketDescTrivago =>
      'Trivago は座標、都市、国、日付、旅行コンテキストに基づいてホテルや宿泊施設を検索することを支援します。そのコネクターは宿泊検索のコンテキストをアシスタントに提供し、目的地や名所の近くで適した宿泊先を見つけることを支援します。';

  @override
  String get mcpMarketDescSend =>
      'Send は共有可能なドキュメント、1 ページのドキュメント、プレゼン、スライドの作成を支援します。そのコネクターはアシスタントが求められた素材を公開リンク、インタラクティブなページ、追跡可能な配信物に変換できるようにします。';

  @override
  String get mcpMarketDescZiprecruiter =>
      'ZipRecruiter は職名、企業、場所、給与、距離、働き方、雇用形態、投稿日でリアルタイムの求人を検索することを支援します。そのコネクターは申し込みを ZipRecruiter に戻す前に、求職コンテキストをアシスタントのワークフローに統合します。';

  @override
  String get mcpMarketDescAdobeCreativity =>
      'Adobe for Creativity は Photoshop、Lightroom、Illustrator、Firefly、Premiere、Express、InDesign、Stock の能力を AI 主導のクリエイティブ作業と結びつけます。ユーザーは自然言語を用いて写真、デザイン素材、映像プロジェクトを生成・編集・強化でき、作業は Adobe アカウントに紐付いたままです。';

  @override
  String get mcpInstallToGlobal => 'グローバルにインストール';

  @override
  String get mcpInstallToProject => 'プロジェクトにインストール';

  @override
  String get mcpScopeGlobal => 'グローバル';

  @override
  String get mcpScopeProject => 'プロジェクト';

  @override
  String get mcpScopeGlobalProject => 'グローバル + プロジェクト';

  @override
  String mcpRemoveFromScope(String scope) {
    return '$scope から削除';
  }

  @override
  String get mcpRemoveFromAll => 'すべての場所から削除';

  @override
  String get mcpTokenDialogTitle => '認証';

  @override
  String get mcpTokenDialogTitleHint => 'このサーバーとの認証方法を選択してください';

  @override
  String get mcpTokenInputLabel => 'トークン';

  @override
  String get mcpTokenInputHint => 'アクセストークンを貼り付けてください';

  @override
  String get mcpTokenInputHelper => 'Authorization: Bearer <token> として送信されます';

  @override
  String get mcpOAuthClientIdLabel => 'クライアント ID';

  @override
  String get mcpOAuthClientIdHint => 'OAuth 2.1 クライアント ID';

  @override
  String get mcpOAuthClientSecretLabel => 'クライアントシークレット';

  @override
  String get mcpOAuthClientSecretHint => 'OAuth 2.1 クライアントシークレット（オプション）';

  @override
  String get mcpOAuthScopeLabel => 'スコープ';

  @override
  String get mcpOAuthScopeHint => '例: read write';

  @override
  String get mcpAuthConfirm => '確認';

  @override
  String get agentsInstructions => 'エージェント指示';

  @override
  String get agentsInstructionsSubtitle => 'AGENTS.md とカスタム指示ファイルを管理';

  @override
  String get agentsMdHint => '# プロジェクトのルール\n- 簡潔に\n- 先にテストを書く';

  @override
  String get agentsMdSaved => 'AGENTS.md を保存しました';

  @override
  String get instructionsAutoDetectedTitle => '検出されたファイル';

  @override
  String get instructionsAutoDetectedHelper =>
      'このスコープで見つかった AGENTS.md と CLAUDE.md。タップして表示または編集します。';

  @override
  String get instructionsFileNotCreated => '未作成';

  @override
  String get instructionsFileReadOnly => '読み取り専用';

  @override
  String get instructionsBadgeGlobal => 'グローバル';

  @override
  String get instructionsBadgeProject => 'プロジェクト';

  @override
  String get instructionsViewFile => '表示';

  @override
  String get instructionsEditFile => '編集';

  @override
  String get instructionsSectionTitle => '指示ファイル';

  @override
  String get instructionsSectionHelper =>
      'AGENTS.md の後に順番に追加される追加の Markdown ファイル。';

  @override
  String get instructionsAdd => '指示を追加';

  @override
  String get instructionsAddInline => '手動で記述';

  @override
  String get instructionsUploadFile => '.md ファイルをアップロード';

  @override
  String get instructionsEmpty => '指示ファイルはまだありません';

  @override
  String get instructionsEmptyHint => '手動で指示を追加するか、Markdown ファイルをアップロードしてください。';

  @override
  String get instructionsNameLabel => '名前';

  @override
  String get instructionsNameHint => 'coding-style';

  @override
  String get instructionsContentLabel => '内容';

  @override
  String get instructionsContentHint => 'Markdown で指示を記述してください…';

  @override
  String get instructionsAddedInline => '指示を追加しました';

  @override
  String instructionsAddedFile(Object name) {
    return 'ファイルを追加しました: $name';
  }

  @override
  String get instructionsRemoveTitle => '指示を削除';

  @override
  String instructionsRemoveContent(Object name) {
    return '「$name」を指示から削除しますか？';
  }

  @override
  String get instructionsRemoved => '指示を削除しました';

  @override
  String get instructionsEditTitle => '指示パスを編集';

  @override
  String get instructionsPathLabel => 'パス';

  @override
  String get instructionsUpdated => '指示を更新しました';

  @override
  String get instructionsScopeGlobal => 'グローバル';

  @override
  String get instructionsScopeProject => 'プロジェクト';

  @override
  String get instructionsScopeGlobalHint => 'どこでも適用されます。ユーザー設定に保存されます。';

  @override
  String get instructionsScopeProjectHint => '現在のプロジェクトフォルダに適用されます。';

  @override
  String get instructionsCreateAgents => 'AGENTS.md を作成';

  @override
  String instructionsSaveError(Object error) {
    return '保存できませんでした: $error';
  }

  @override
  String get configScopeGlobal => 'グローバル';

  @override
  String get configScopeProject => 'プロジェクト';

  @override
  String get configProjectOverrides => 'プロジェクト設定はグローバル設定を上書きします。';

  @override
  String get configPathLabel => 'パス';

  @override
  String get configStatusLabel => 'ステータス';

  @override
  String get configContentsTitle => 'ファイルの内容';

  @override
  String get configExists => 'あり';

  @override
  String get configNotFound => '見つかりません';

  @override
  String get configWillBeCreated => '保存時に作成されます。';

  @override
  String get skillsTitle => 'スキル';

  @override
  String get skillsSubtitle => 'アシスタントが必要に応じて読み込める再利用可能な機能パック。';

  @override
  String get skillsSectionTitle => 'インストール済みスキル';

  @override
  String get skillsSectionHelper =>
      '各スキルは SKILL.md を含むフォルダです。自作するか URL からインストールできます。';

  @override
  String get skillsNewSkill => '新しいスキル';

  @override
  String get skillsInstallFromUrl => 'URL からインストール';

  @override
  String get skillsNameLabel => '名前';

  @override
  String get skillsNameHint => '例：コードレビュアー';

  @override
  String get skillsDescriptionLabel => '説明';

  @override
  String get skillsDescriptionHint => 'このスキルの機能の概要';

  @override
  String get skillsContentLabel => 'SKILL.md の内容';

  @override
  String get skillsContentHint => '# 見出し\nアシスタントへの指示…';

  @override
  String get skillsUrlLabel => 'index.json の URL';

  @override
  String get skillsUrlHint => 'https://example.com/skills';

  @override
  String get skillsApiKeyLabel => 'API キー（任意）';

  @override
  String get skillsReadOnly => '読み取り専用';

  @override
  String skillsFilesCount(int count) {
    return '$count ファイル';
  }

  @override
  String get skillsCreated => 'スキルを作成しました';

  @override
  String get skillsSaved => 'スキルを保存しました';

  @override
  String get skillsRemoved => 'スキルを削除しました';

  @override
  String skillsInstalled(int count) {
    return '$count 個のスキルをインストールしました';
  }

  @override
  String get skillsInstallNone => 'その URL にスキルが見つかりません';

  @override
  String get skillsRemoveTitle => 'スキルを削除';

  @override
  String skillsRemoveContent(String name) {
    return '「$name」を削除しますか？ディスクからフォルダが削除されます。';
  }

  @override
  String skillsSaveError(String error) {
    return '完了できませんでした：$error';
  }

  @override
  String get skillsEmpty => 'スキルがまだありません';

  @override
  String get skillsEmptyHint => 'スキルを作成するか URL からインストールして始めましょう。';

  @override
  String get skillsMarketplaceTab => 'マーケットプレイス';

  @override
  String get skillsMarketplaceSearchHint => 'スキルを検索';

  @override
  String get skillsMarketplaceEmpty => '検索に一致するスキルがありません。';

  @override
  String get skillsInstalledBadge => 'インストール済み';

  @override
  String get skillsInstallAction => 'インストール';

  @override
  String get skillsInstallToGlobal => 'Global にインストール';

  @override
  String get skillsInstallToProject => 'Project にインストール';

  @override
  String skillsInstalledToast(String name) {
    return '$name · インストール済み';
  }

  @override
  String get skillsTabGlobalTooltip => 'すべてのプロジェクトで使えるスキル';

  @override
  String get skillsTabProjectTooltip => 'このプロジェクト限定のスキル';

  @override
  String get skillsTabMarketplaceTooltip => '既製スキルの閲覧とインストール';

  @override
  String get skillsPreviewClose => '閉じる';

  @override
  String get skillsCategoryAll => 'すべて';

  @override
  String get skillsCategoryCoding => 'コーディング';

  @override
  String get skillsCategoryWriting => 'ライティング';

  @override
  String get skillsCategoryResearch => 'リサーチ';

  @override
  String get skillsCategoryDesign => 'デザイン';

  @override
  String get skillsCategoryProductivity => '生産性';

  @override
  String get skillsCategoryData => 'データ';

  @override
  String get skillsCategoryOther => 'その他';

  @override
  String get commonSave => '保存';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonAdd => '追加';

  @override
  String get commonRemove => '削除';

  @override
  String get commonEdit => '編集';

  @override
  String get toolResultOriginal => 'オリジナル';

  @override
  String get toolResultRestore => '復元';

  @override
  String get toolResultRestoredSnackbar => '編集前の状態にファイルを復元しました';

  @override
  String get toolResultOriginalTitle => '編集前の元のコンテンツ';

  @override
  String restoreFailed(String error) {
    return '復元に失敗しました：$error';
  }

  @override
  String get compactingIndicator => '圧縮中...';

  @override
  String get compactionAgentName => '圧縮';

  @override
  String get workspaces => 'ワークスペース';

  @override
  String get directoryTitle => 'ディレクトリ';

  @override
  String get searchDirectories => 'ディレクトリを検索';

  @override
  String get addDirectory => 'ディレクトリを追加';

  @override
  String get removeDirectory => 'ディレクトリを削除';

  @override
  String get noWorkspacesFound => 'ディレクトリが見つかりません';

  @override
  String get switchWorkspaceTitle => 'ワークスペースを切り替え';

  @override
  String get currentSessionWillBeStopped => '現在のセッションは停止されます。';

  @override
  String get continueText => '続行';

  @override
  String get changeWorkingDirectory => '現在のディレクトリを変更';

  @override
  String get sessionsTitle => 'セッション';

  @override
  String get noSessions => 'セッションはまだありません';

  @override
  String get searchSessions => 'セッションを検索';

  @override
  String get newSession => '新しいセッション';
}
