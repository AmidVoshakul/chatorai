import 'package:flutter/material.dart';
import 'package:chatorai/features/chat/data/models/chat/tool_result_part.dart';
import 'generic_body.dart';

class WebfetchBody extends StatelessWidget {
  final ThemeData theme;
  final ToolResultPart part;
  final bool displayFull;
  final bool isError;
  final String Function(String) previewOutput;
  final Widget Function(String displayedBody, bool isError) buildResultFooter;

  const WebfetchBody({
    required this.theme,
    required this.part,
    required this.displayFull,
    required this.isError,
    required this.previewOutput,
    required this.buildResultFooter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final original = part.result ?? '';
    final displayed = displayFull ? original : previewOutput(original);
    return GenericBody(
      theme: theme,
      displayedBody: displayed,
      isError: isError,
      buildResultFooter: buildResultFooter,
    );
  }
}
