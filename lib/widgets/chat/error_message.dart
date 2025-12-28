import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chatorai/utils/snackbar_utils.dart';
import 'package:chatorai/services/chat_storage_service.dart';
import 'package:chatorai/utils/logger.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/widgets/chat/loading_indicator.dart';
import 'dart:convert';

// =============================================================================
// ERROR MESSAGE WIDGET
// =============================================================================

/// Initialize logger for this widget
final _logger = LogTags.errorMessage;

class ErrorMessage extends StatefulWidget {
  final String errorMessage;
  final String chatId;
  final String messageId;
  final ChatStorageService chatStorageService;
  final VoidCallback onMessageDeleted;
  final VoidCallback? onDelete;
  final Function(String)? onMessageUpdated;
  final bool isStreaming;
  final bool showLoadingFirst;

  const ErrorMessage({
    super.key,
    required this.errorMessage,
    required this.chatId,
    required this.messageId,
    required this.chatStorageService,
    required this.onMessageDeleted,
    this.onDelete,
    this.onMessageUpdated,
    this.isStreaming = false,
    this.showLoadingFirst = false,
  });

  @override
  State<ErrorMessage> createState() => _ErrorMessageState();
}

class _ErrorMessageState extends State<ErrorMessage> with TickerProviderStateMixin {
  // ===========================================================================
  // ANIMATION CONTROLLERS
  // ===========================================================================

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;

  // ===========================================================================
  // STATE VARIABLES
  // ===========================================================================

  bool _showLoading = true;
  bool _errorReadyToShow = false;

  // ===========================================================================
  // LIFECYCLE METHODS
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeState();
  }

  @override
  void didUpdateWidget(covariant ErrorMessage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle error message appearance during streaming
    if (oldWidget.errorMessage.isEmpty && widget.errorMessage.isNotEmpty) {
      _transitionToError();
    }

    // Reinitialize if showLoadingFirst flag changed
    if (oldWidget.showLoadingFirst != widget.showLoadingFirst) {
      _initializeState();
    }
  }

  @override
  void dispose() {
    _loadingController.removeStatusListener(_onLoadingAnimationComplete);
    _fadeController.dispose();
    _slideController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // INITIALIZATION METHODS
  // ===========================================================================

  void _initializeAnimations() {
    // Fade-in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Slide-in animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    // Loading animation
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadingAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeOut),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  void _initializeState() {
    if (widget.showLoadingFirst) {
      _showLoading = true;
      _errorReadyToShow = false;

      // Auto-transition to error after 300ms
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _showLoading = false;
            _errorReadyToShow = true;
          });
        }
      });
    } else {
      if (widget.errorMessage.isNotEmpty) {
        _errorReadyToShow = true;
        _showLoading = false;
        _loadingController.value = 1.0;
      } else {
        _showLoading = true;
        _errorReadyToShow = false;
      }
    }
  }

  // ===========================================================================
  // TRANSITION METHODS
  // ===========================================================================

  void _transitionToError() {
    _loadingController.removeStatusListener(_onLoadingAnimationComplete);

    setState(() {
      _showLoading = true;
      _errorReadyToShow = false;
    });

    _loadingController.reset();
    _loadingController.addStatusListener(_onLoadingAnimationComplete);
    _loadingController.forward();
  }

  void _onLoadingAnimationComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _showLoading = false;
        _errorReadyToShow = true;
      });

      _loadingController.removeStatusListener(_onLoadingAnimationComplete);
    }
  }

  // ===========================================================================
  // UI BUILDERS
  // ===========================================================================

  Widget _buildStreamingIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: ChatTypingDotsIndicator(dotSize: 6),
    );
  }

  // ===========================================================================
  // ACTION METHODS
  // ===========================================================================

  Future<void> _copyToClipboard() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.errorMessage));
      if (!mounted) return;
      SnackbarUtils.showSuccessSnackBar(
        context: context,
        message: AppLocalizations.of(context)!.copiedToClipboard,
        icon: Icons.copy,
      );
    } catch (e) {
      _logger.logError('[ErrorMessage] Failed to copy to clipboard: $e');
      if (!mounted) return;
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: AppLocalizations.of(context)!.failedToCopy,
        icon: Icons.error,
      );
    }
  }

  Future<void> _deleteMessage() async {
    try {
      await widget.chatStorageService.deleteMessageFromChat(
        widget.chatId,
        widget.messageId,
      );
      widget.onMessageDeleted();
      if (!mounted) return;
      SnackbarUtils.showSuccessSnackBar(
        context: context,
        message: AppLocalizations.of(context)!.messageDeleted,
        icon: Icons.delete,
      );
    } catch (e) {
      _logger.logError('[ErrorMessage] Failed to delete message: $e');
      if (!mounted) return;
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: AppLocalizations.of(context)!.failedToDeleteMessage,
        icon: Icons.error,
      );
    }
  }

  Future<void> _regenerateMessage() async {
    // Сначала удаляем сообщение об ошибке из UI
    widget.onMessageDeleted();
    
    // Затем вызываем callback для перегенерации
    // Это вызовет onRegenerateResponse в ChatScreen, который:
    // 1. Удалит последнее AI сообщение из БД (это сообщение об ошибке)
    // 2. Возьмет последнее user сообщение
    // 3. Сгенерирует новый ответ
    if (widget.onMessageUpdated != null) {
      widget.onMessageUpdated!('REGENERATE');
    }
  }

  // ===========================================================================
  // UTILITY METHODS
  // ===========================================================================

  Map<String, dynamic> _parseErrorDetails(String errorMessage) {
    try {
      final json = jsonDecode(errorMessage);

      if (json is Map<String, dynamic>) {
        if (json.containsKey('error')) {
          final error = json['error'];
          if (error is Map<String, dynamic>) {
            return {
              'message': error['message'] ?? 'Unknown error',
              'code': error['code'] ?? 'Unknown',
              'type': error['type'] ?? 'Error',
              'isJson': true,
            };
          }
        }
      }
    } catch (e) {
      // Not JSON, return as plain text
    }

    return {
      'message': errorMessage,
      'code': 'Unknown',
      'type': 'Error',
      'isJson': false,
    };
  }

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    // Parse error details
    final errorDetails = _parseErrorDetails(widget.errorMessage);
    final isJsonError = errorDetails['isJson'] as bool;
    final errorMessage = errorDetails['message'] as String;
    final errorCode = errorDetails['code'].toString();
    final errorType = errorDetails['type'] as String;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.error,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isJsonError
                            ? '$errorType Error (Code: $errorCode)'
                            : (localizations?.errorMessage ?? 'Error message'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Content
                  if (_errorReadyToShow)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isJsonError ? errorMessage : widget.errorMessage,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 13,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        if (isJsonError) const SizedBox(height: 8),
                        if (isJsonError)
                          Text(
                            'Error Code: $errorCode',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    )
                  else if (_showLoading)
                    FadeTransition(
                      opacity: _loadingAnimation,
                      child: _buildStreamingIndicator(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Action buttons
            Container(
              margin: const EdgeInsets.only(top: 4, bottom: 8),
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      size: 16,
                      color: theme.iconTheme.color?.withValues(alpha: 0.8),
                    ),
                    onPressed: _regenerateMessage,
                    tooltip: localizations?.regenerate ?? 'Regenerate',
                    splashRadius: 20,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.copy_all,
                      size: 16,
                      color: theme.iconTheme.color?.withValues(alpha: 0.8),
                    ),
                    onPressed: _copyToClipboard,
                    tooltip: localizations?.copyMessage ?? 'Copy',
                    splashRadius: 24,
                    hoverColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    focusColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      size: 16,
                      color: Colors.red.withValues(alpha: 0.7),
                    ),
                    onPressed: _deleteMessage,
                    tooltip: localizations?.delete ?? 'Delete',
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
