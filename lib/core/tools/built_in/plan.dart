import 'package:chatorai/core/tools/tool.dart';

ToolDef createPlanExitTool() {
  return ToolDef(
    id: 'plan_exit',
    description:
        'Use this tool when you have completed the planning phase and are ready to exit plan agent.\n\n'
        'This tool will ask the user if they want to switch to build agent to start implementing the plan.\n\n'
        'Call this tool:\n'
        '- After you have written a complete plan to the plan file\n'
        '- After you have clarified any questions with the user\n'
        '- When you are confident the plan is ready for implementation\n\n'
        'Do NOT call this tool:\n'
        '- Before you have created or finalized the plan\n'
        '- If you still have unanswered questions about the implementation\n'
        '- If the user has indicated they want to continue planning',
    inputSchema: {'type': 'object', 'properties': {}, 'required': []},
    execute: (input, ctx) async {
      final answer = await ctx.askQuestion(
        question:
            'Plan is complete. Would you like to switch to build agent and start implementing?',
        options: ['Yes, switch to build agent', 'No, continue with plan agent'],
        multiple: false,
      );

      final confirmed = answer.toLowerCase().startsWith('yes');

      return ToolOutput(
        confirmed
            ? 'User approved switching to build agent. Proceed with implementation.'
            : 'User chose to continue with plan agent. Refine the plan further.',
        metadata: {'approved': confirmed, 'answer': answer},
      );
    },
    formatValidationError: (input, errors) {
      return 'The plan_exit tool does not accept parameters. Errors: ${errors.map((e) => e.toString()).join('; ')}';
    },
  );
}
