import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/utils/snackbar_utils.dart';
import 'package:chatorai/services/chat_storage_service.dart';
import 'package:chatorai/utils/logger.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/widgets/chat/loading_indicator.dart';
import 'dart:convert';

// ===========================================================================
// LOGGER
// ===========================================================================

final _logger = LogTags.errorMessage;

// ===========================================================================
// WIDGET CLASS
// ===========================================================================

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

// ===========================================================================
// STATE CLASS
// ===========================================================================

class _ErrorMessageState extends State<ErrorMessage>
    with TickerProviderStateMixin {
  // =======================================================================
  // ANIMATION CONTROLLERS
  // =======================================================================

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;

  // =======================================================================
  // STATE VARIABLES
  // =======================================================================

  bool _showLoading = true;
  bool _errorReadyToShow = false;

  // =======================================================================
  // LIFECYCLE
  // =======================================================================

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeState();
  }

  @override
  void didUpdateWidget(covariant ErrorMessage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.errorMessage.isEmpty && widget.errorMessage.isNotEmpty) {
      _transitionToError();
    }

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

  // =======================================================================
  // INITIALIZATION
  // =======================================================================

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: ChatoraiDurations.slow,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      duration: ChatoraiDurations.normal,
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _loadingController = AnimationController(
      duration: ChatoraiDurations.normal,
      vsync: this,
    );
    _loadingAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  void _initializeState() {
    if (widget.showLoadingFirst) {
      _showLoading = true;
      _errorReadyToShow = false;

      Future.delayed(ChatoraiDurations.normal, () {
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

  // =======================================================================
  // TRANSITIONS
  // =======================================================================

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

  // =======================================================================
  // PUBLIC API
  // =======================================================================

  // =======================================================================
  // PRIVATE METHODS
  // =======================================================================

  Widget _buildStreamingIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: ChatoraiSpacing.sm),
      child: ChatTypingDotsIndicator(
        dotSize: ChatoraiSizes.chatTypingDotsDefaultSize,
      ),
    );
  }

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
      // Not JSON
    }

    return {
      'message': errorMessage,
      'code': 'Unknown',
      'type': 'Error',
      'isJson': false,
    };
  }

  // =======================================================================
  // ACTIONS
  // =======================================================================

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
    widget.onMessageDeleted();

    if (widget.onMessageUpdated != null) {
      widget.onMessageUpdated!('REGENERATE');
    }
  }

  // =======================================================================
  // BUILD METHOD
  // =======================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

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
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ChatoraiSpacing.md,
                vertical: ChatoraiSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
                boxShadow: [
                  BoxShadow(
                    color: ChatoraiColors.black05,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                  width: ChatoraiBorderWidth.thinBold,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error,
                        size: ChatoraiIconSizes.actionIcon,
                        color: ChatoraiColors.error,
                      ),
                      const SizedBox(width: ChatoraiSpacing.sm),
                      Expanded(
                        child: Text(
                          isJsonError
                              ? '$errorType Error (Code: $errorCode)'
                              : (localizations?.errorMessage ??
                                    'Error message'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ChatoraiColors.error,
                            fontSize: ChatoraiFontSizes.md,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: ChatoraiSpacing.sm),

                  if (_errorReadyToShow)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isJsonError ? errorMessage : widget.errorMessage,
                          style: TextStyle(
                            color: ChatoraiColors.error,
                            fontSize: ChatoraiFontSizes.sm,
                            height: ChatoraiSizes.errorTextLineHeight,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        if (isJsonError)
                          const SizedBox(height: ChatoraiSpacing.sm),
                        if (isJsonError)
                          Text(
                            'Error Code: $errorCode',
                            style: TextStyle(
                              color: ChatoraiColors.error,
                              fontSize: ChatoraiFontSizes.md,
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

            const SizedBox(height: ChatoraiSpacing.sm),

            Container(
              margin: const EdgeInsets.only(
                top: ChatoraiSpacing.xs,
                bottom: ChatoraiSpacing.sm,
              ),
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      size: ChatoraiIconSizes.actionIcon,
                      color: theme.iconTheme.color?.withValues(
                        alpha: ChatoraiIconOpacity.high,
                      ),
                    ),
                    onPressed: _regenerateMessage,
                    tooltip: localizations?.regenerate ?? 'Regenerate',
                    splashRadius: ChatoraiSizes.sidebarSplashRadiusExpanded,
                  ),
                  const SizedBox(width: ChatoraiSpacing.sm),
                  IconButton(
                    icon: Icon(
                      Icons.copy_all,
                      size: ChatoraiIconSizes.actionIcon,
                      color: theme.iconTheme.color?.withValues(
                        alpha: ChatoraiIconOpacity.high,
                      ),
                    ),
                    onPressed: _copyToClipboard,
                    tooltip: localizations?.copyMessage ?? 'Copy',
                    splashRadius: ChatoraiSizes.iconButtonSplashRadius,
                    hoverColor: theme.colorScheme.primary.withValues(
                      alpha: ChatoraiIconOpacity.low,
                    ),
                    focusColor: theme.colorScheme.primary.withValues(
                      alpha: ChatoraiIconOpacity.low,
                    ),
                  ),
                  const SizedBox(width: ChatoraiSpacing.sm),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      size: ChatoraiIconSizes.actionIcon,
                      color: ChatoraiColors.error.withValues(
                        alpha: ChatoraiIconOpacity.medium,
                      ),
                    ),
                    onPressed: _deleteMessage,
                    tooltip: localizations?.delete ?? 'Delete',
                    splashRadius: ChatoraiSizes.sidebarSplashRadiusExpanded,
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
