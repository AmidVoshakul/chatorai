import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/features/chat/data/models/chat/question_option.dart';

ToolDef createPlanEnterTool() {
  return ToolDef(
    id: 'plan_enter',
    description:
        'Use this tool to suggest switching to plan agent when the user\'s request would benefit from planning before implementation.\n\n'
        'If they explicitly mention wanting to create a plan ALWAYS call this tool first.\n\n'
        'This tool will ask the user if they want to switch to plan agent.\n\n'
        'Call this tool when:\n'
        '- The user\'s request is complex and would benefit from planning first\n'
        '- You want to research and design before making changes\n'
        '- The task involves multiple files or significant architectural decisions\n\n'
        'Do NOT call this tool:\n'
        '- For simple, straightforward tasks\n'
        '- When the user explicitly wants immediate implementation',
    inputSchema: {'type': 'object', 'properties': {}, 'required': []},
    execute: (input, ctx) async {
      final answer = await ctx.askQuestion(
        question:
            'This task is complex. Would you like to switch to plan agent to create a plan first?',
        options: const [
          QuestionOption(label: 'Yes, switch to plan agent', description: null),
          QuestionOption(
            label: 'No, continue with current agent',
            description: null,
          ),
        ],
        multiple: false,
      );

      final confirmed = answer.toLowerCase().startsWith('yes');

      if (confirmed) {
        ctx.switchAgent?.call(
          'plan',
          messageText: 'Switched to plan agent. Create a plan.',
        );
      }

      return ToolOutput(
        confirmed
            ? 'User approved switching to plan agent. Create a plan.'
            : 'User chose to continue with current agent. Proceed with implementation.',
        metadata: {'approved': confirmed, 'answer': answer},
      );
    },
    formatValidationError: (input, errors) {
      return 'The plan_enter tool does not accept parameters. Errors: ${errors.map((e) => e.toString()).join('; ')}';
    },
  );
}

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
        options: const [
          QuestionOption(
            label: 'Yes, switch to build agent',
            description: null,
          ),
          QuestionOption(
            label: 'No, continue with plan agent',
            description: null,
          ),
        ],
        multiple: false,
      );

      final confirmed = answer.toLowerCase().startsWith('yes');

      if (confirmed) {
        ctx.switchAgent?.call(
          'build',
          messageText:
              'The plan has been approved, you can now edit files. Execute the plan',
        );
      }

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
