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
  String get appDescription => 'AI モデルとの会話アプリケーションです。\n\n特徴:\n• さまざまな AI モデルとの会話\n• チャット履歴の保存\n• ダークとライト テーマ\n• 適応型インターフェース\n\nDeveloped with ❤️ using Flutter';

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
  String get featuresDisplayedBasedOnActualModelCapabilities => '実際のモデルの機能に基づいて特徴が表示されます';

  @override
  String get noModelsFound => 'モデルが見つかりません';

  @override
  String get noAvailableModels => '利用可能なモデルがありません';

  @override
  String get tryADifferentSearchQuery => '異なる検索クエリを試してください';

  @override
  String get tryRefreshingOrCheckYourInternetConnection => '更新またはインターネット接続を確認してください';

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
  String get areYouSureYouWantToRegenerateThisMessage => 'このメッセージを再生成してもよろしいですか？';

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
  String get welcomeQuestion25 => '2025年の宇宙探査の最新ブレイクスルーは？';

  @override
  String get welcomeQuestion26 => 'AIが医療をどのように変えているか？';

  @override
  String get welcomeQuestion27 => '2025年の最もエキサイティングなテクノロジーは？';

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
  String get welcomeQuestion33 => '2025年に学ぶべき最良のプログラミング言語は？';

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
  String get systemPromptSuggestion => 'あなたは有用なアシスタントです。会話を続け、最後のメッセージに対して3つの具体的で論理的な続きを提案してください。ユーザーと同じ言語で回答してください。';

  @override
  String get temperature => '温度';

  @override
  String get temperatureDescription => 'ランダム性を制御: 低=より集中、高=より創造的';

  @override
  String get toggleNavigatorTooltip => 'ナビゲーターを切り替え';

  @override
  String get userPromptSuggestion => 'このメッセージに対して3つの具体的で論理的な続きを提案してください。リストのみで回答し、追加テキストは含めないでください。';

  @override
  String get versionLabel => 'バージョン:';

  @override
  String get welcomeGreeting1 => '聞いて、探索して、作ろう — 一緒に考えましょう。';

  @override
  String get welcomeGreeting2 => '質問したり、タスクを説明したり、会話を始めたりしてください。';

  @override
  String get welcomeGreeting3 => '質問するか、探索を始めましょう。';

  @override
  String get welcomeGreeting4 => 'どんな質問でも、アイデアを共有しても、助けてと言っても — ここにいるので助けになります。';

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
  String get errorProcessingRequest => '申し訳ありません。リクエストの処理中にエラーが発生しました。もう一度お試しください。';

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
  String get deleteProviderContent => 'これによりプロバイダーとすべての設定が削除されます。モデルを使用するには再度追加する必要があります。';

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
}
