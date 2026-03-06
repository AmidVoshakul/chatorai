// Barrel file for all providers - Riverpod 2.x Pure Notifiers

export 'package:chatorai/providers/theme_provider.dart';
export 'package:chatorai/providers/language_provider.dart';
export 'package:chatorai/providers/model_provider.dart'
    show modelProvider, openRouterServiceProvider, networkServiceProvider;
export 'package:chatorai/providers/model_settings_provider.dart';
export 'package:chatorai/providers/chat/chat_providers.dart'
    hide currentChatProvider;
export 'package:chatorai/providers/chat/chat_state_provider.dart';
export 'package:chatorai/providers/chat/streaming_provider.dart';
export 'package:chatorai/providers/chat/sidebar_provider.dart';
export 'package:chatorai/providers/chat/chat_actions_provider.dart';
export 'package:chatorai/providers/chat/streaming_content_controller.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/providers/chat/streaming_content_controller.dart';

final streamingContentProvider =
    NotifierProvider<StreamingContentNotifier, StreamingContentState>(
      StreamingContentNotifier.new,
    );
