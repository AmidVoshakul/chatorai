import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/plan.dart';
import 'package:chatorai/core/chat/chat/question_option.dart'
    show QuestionOption;
import 'package:test/test.dart';

void main() {
  group('Plan Tool Integration Tests', () {
    const defaultSessionId = 'ses_plan-integration-001';

    group('Plan Enter Integration', () {
      test('synthetic user message creation on confirmation', () async {
        final askQuestionCalls = <String>[];
        final switchAgentCalls = <String?>[];
        final switchAgentMessages = <String>[];

        final ctx = ToolContext(
          toolCallId: 'plan-int-${DateTime.now().microsecondsSinceEpoch}',
          sessionId: defaultSessionId,
          abortSignal: null,
          ask:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {},
          askQuestion:
              ({
                required String question,
                List<QuestionOption> options = const [],
                bool multiple = false,
              }) async {
                askQuestionCalls.add(question);
                return 'Yes, switch to plan agent';
              },
          switchAgent: (String agentId, {String? messageText}) {
            switchAgentCalls.add(agentId);
            switchAgentMessages.add(messageText ?? '');
          },
        );

        final tool = createPlanEnterTool();
        final output = await tool.execute({}, ctx);

        expect(output.metadata?['approved'], isTrue);
        expect(askQuestionCalls, hasLength(1));
        expect(askQuestionCalls.first, contains('switch to plan agent'));
        expect(switchAgentCalls, contains('plan'));
        expect(
          switchAgentMessages.first,
          'Switched to plan agent. Create a plan.',
        );
        expect(output.output, contains('plan agent'));
      });

      test(
        'agent switching behavior: general → plan on confirmation',
        () async {
          final switchAgentCalls = <String?>[];

          final ctx = ToolContext(
            toolCallId: 'plan-int-${DateTime.now().microsecondsSinceEpoch}',
            sessionId: defaultSessionId,
            abortSignal: null,
            ask:
                ({
                  required String permission,
                  required List<String> patterns,
                  Map<String, dynamic>? metadata,
                  List<String>? always,
                }) async {},
            askQuestion:
                ({
                  required String question,
                  List<QuestionOption> options = const [],
                  bool multiple = false,
                }) async => 'Yes',
            switchAgent: (String agentId, {String? messageText}) {
              switchAgentCalls.add(agentId);
            },
          );

          final tool = createPlanEnterTool();
          final output = await tool.execute({}, ctx);

          expect(switchAgentCalls, contains('plan'));
          expect(switchAgentCalls.length, equals(1));
          expect(output.metadata?['approved'], isTrue);
        },
      );

      test('no agent switching when user declines', () async {
        final switchAgentCalls = <String?>[];

        final ctx = ToolContext(
          toolCallId: 'plan-int-${DateTime.now().microsecondsSinceEpoch}',
          sessionId: defaultSessionId,
          abortSignal: null,
          ask:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {},
          askQuestion:
              ({
                required String question,
                List<QuestionOption> options = const [],
                bool multiple = false,
              }) async => 'No, continue',
          switchAgent: (String agentId, {String? messageText}) {
            switchAgentCalls.add(agentId);
          },
        );

        final tool = createPlanEnterTool();
        final output = await tool.execute({}, ctx);

        expect(switchAgentCalls, isEmpty);
        expect(output.metadata?['approved'], isFalse);
      });

      test('error case: missing session does not crash', () async {
        final switchAgentCalls = <String?>[];

        final ctx = ToolContext(
          toolCallId: 'plan-int-${DateTime.now().microsecondsSinceEpoch}',
          sessionId: null,
          abortSignal: null,
          ask:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {},
          askQuestion:
              ({
                required String question,
                List<QuestionOption> options = const [],
                bool multiple = false,
              }) async => 'Yes',
          switchAgent: (String agentId, {String? messageText}) {
            switchAgentCalls.add(agentId);
          },
        );

        final tool = createPlanEnterTool();
        final output = await tool.execute({}, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.metadata?['approved'], isTrue);
      });

      test('case-insensitive yes answers trigger switchAgent', () async {
        final switchAgentCalls = <String?>[];

        final ctx = ToolContext(
          toolCallId: 'plan-int-${DateTime.now().microsecondsSinceEpoch}',
          sessionId: defaultSessionId,
          abortSignal: null,
          ask:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {},
          askQuestion:
              ({
                required String question,
                List<QuestionOption> options = const [],
                bool multiple = false,
              }) async => 'YES',
          switchAgent: (String agentId, {String? messageText}) {
            switchAgentCalls.add(agentId);
          },
        );

        final tool = createPlanEnterTool();
        final output = await tool.execute({}, ctx);

        expect(switchAgentCalls, contains('plan'));
        expect(output.metadata?['approved'], isTrue);
      });

      test('formatValidationError returns descriptive message', () {
        final tool = createPlanEnterTool();
        final errors = [
          SchemaValidationError(path: r'$.param', message: 'unknown parameter'),
        ];

        final formatted = tool.formatValidationError?.call({}, errors);
        expect(formatted, contains('unknown parameter'));
        expect(formatted, contains('plan_enter'));
      });
    });

    group('Plan Exit Integration', () {
      test('synthetic user message creation on confirmation', () async {
        final askQuestionCalls = <String>[];
        final switchAgentCalls = <String?>[];
        final switchAgentMessages = <String>[];

        final ctx = ToolContext(
          toolCallId: 'plan-int-${DateTime.now().microsecondsSinceEpoch}',
          sessionId: defaultSessionId,
          abortSignal: null,
          ask:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {},
          askQuestion:
              ({
                required String question,
                List<QuestionOption> options = const [],
                bool multiple = false,
              }) async {
                askQuestionCalls.add(question);
                return 'Yes, switch to build agent';
              },
          switchAgent: (String agentId, {String? messageText}) {
            switchAgentCalls.add(agentId);
            switchAgentMessages.add(messageText ?? '');
          },
        );

        final tool = createPlanExitTool();
        final output = await tool.execute({}, ctx);

        expect(output.metadata?['approved'], isTrue);
        expect(askQuestionCalls, hasLength(1));
        expect(askQuestionCalls.first, contains('switch to build agent'));
        expect(switchAgentCalls, contains('build'));
        expect(
          switchAgentMessages.first,
          'The plan has been approved, you can now edit files. Execute the plan',
        );
        expect(output.output, contains('build agent'));
      });

      test('agent switching behavior: plan → build on confirmation', () async {
        final switchAgentCalls = <String?>[];

        final ctx = ToolContext(
          toolCallId: 'plan-int-${DateTime.now().microsecondsSinceEpoch}',
          sessionId: defaultSessionId,
          abortSignal: null,
          ask:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {},
          askQuestion:
              ({
                required String question,
                List<QuestionOption> options = const [],
                bool multiple = false,
              }) async => 'Yes',
          switchAgent: (String agentId, {String? messageText}) {
            switchAgentCalls.add(agentId);
          },
        );

        final tool = createPlanExitTool();
        final output = await tool.execute({}, ctx);

        expect(switchAgentCalls, contains('build'));
        expect(switchAgentCalls.length, equals(1));
        expect(output.metadata?['approved'], isTrue);
      });

      test('no agent switching when user declines', () async {
        final switchAgentCalls = <String?>[];

        final ctx = ToolContext(
          toolCallId: 'plan-int-${DateTime.now().microsecondsSinceEpoch}',
          sessionId: defaultSessionId,
          abortSignal: null,
          ask:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {},
          askQuestion:
              ({
                required String question,
                List<QuestionOption> options = const [],
                bool multiple = false,
              }) async => 'No, continue planning',
          switchAgent: (String agentId, {String? messageText}) {
            switchAgentCalls.add(agentId);
          },
        );

        final tool = createPlanExitTool();
        final output = await tool.execute({}, ctx);

        expect(switchAgentCalls, isEmpty);
        expect(output.metadata?['approved'], isFalse);
        expect(output.output, contains('continue'));
      });

      test('error case: missing session does not crash', () async {
        final switchAgentCalls = <String?>[];

        final ctx = ToolContext(
          toolCallId: 'plan-int-${DateTime.now().microsecondsSinceEpoch}',
          sessionId: null,
          abortSignal: null,
          ask:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {},
          askQuestion:
              ({
                required String question,
                List<QuestionOption> options = const [],
                bool multiple = false,
              }) async => 'Yes',
          switchAgent: (String agentId, {String? messageText}) {
            switchAgentCalls.add(agentId);
          },
        );

        final tool = createPlanExitTool();
        final output = await tool.execute({}, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.metadata?['approved'], isTrue);
      });

      test('case-insensitive yes answers trigger switchAgent', () async {
        final switchAgentCalls = <String?>[];

        final ctx = ToolContext(
          toolCallId: 'plan-int-${DateTime.now().microsecondsSinceEpoch}',
          sessionId: defaultSessionId,
          abortSignal: null,
          ask:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {},
          askQuestion:
              ({
                required String question,
                List<QuestionOption> options = const [],
                bool multiple = false,
              }) async => 'yes',
          switchAgent: (String agentId, {String? messageText}) {
            switchAgentCalls.add(agentId);
          },
        );

        final tool = createPlanExitTool();
        final output = await tool.execute({}, ctx);

        expect(switchAgentCalls, contains('build'));
        expect(output.metadata?['approved'], isTrue);
      });

      test('formatValidationError returns descriptive message', () {
        final tool = createPlanExitTool();
        final errors = [
          SchemaValidationError(path: r'$.field', message: 'required'),
        ];

        final formatted = tool.formatValidationError?.call({}, errors);
        expect(formatted, contains('required'));
        expect(formatted, contains('plan_exit'));
      });
    });

    group('Plan Tools Cross-Flow', () {
      test(
        'plan_enter then plan_exit switches general → plan → build',
        () async {
          final sessionId =
              'ses_cross-flow-${DateTime.now().microsecondsSinceEpoch}';
          final planEnter = createPlanEnterTool();
          final planExit = createPlanExitTool();

          final enterSwitchCalls = <String?>[];
          final exitSwitchCalls = <String?>[];

          final enterCtx = ToolContext(
            toolCallId: 'cross-${DateTime.now().microsecondsSinceEpoch}',
            sessionId: sessionId,
            abortSignal: null,
            ask:
                ({
                  required String permission,
                  required List<String> patterns,
                  Map<String, dynamic>? metadata,
                  List<String>? always,
                }) async {},
            askQuestion:
                ({
                  required String question,
                  List<QuestionOption> options = const [],
                  bool multiple = false,
                }) async => 'Yes',
            switchAgent: (String agentId, {String? messageText}) {
              enterSwitchCalls.add(agentId);
            },
          );

          final enterOutput = await planEnter.execute({}, enterCtx);
          expect(enterSwitchCalls, contains('plan'));
          expect(enterOutput.metadata?['approved'], isTrue);

          final exitCtx = ToolContext(
            toolCallId: 'cross-${DateTime.now().microsecondsSinceEpoch}',
            sessionId: sessionId,
            abortSignal: null,
            ask:
                ({
                  required String permission,
                  required List<String> patterns,
                  Map<String, dynamic>? metadata,
                  List<String>? always,
                }) async {},
            askQuestion:
                ({
                  required String question,
                  List<QuestionOption> options = const [],
                  bool multiple = false,
                }) async => 'Yes',
            switchAgent: (String agentId, {String? messageText}) {
              exitSwitchCalls.add(agentId);
            },
          );

          final exitOutput = await planExit.execute({}, exitCtx);
          expect(exitSwitchCalls, contains('build'));
          expect(exitOutput.metadata?['approved'], isTrue);
        },
      );

      test(
        'plan_enter decline keeps agent unchanged for subsequent plan_exit',
        () async {
          final sessionId =
              'ses_decline-flow-${DateTime.now().microsecondsSinceEpoch}';
          final planEnter = createPlanEnterTool();
          final planExit = createPlanExitTool();

          final enterSwitchCalls = <String?>[];

          final enterCtx = ToolContext(
            toolCallId: 'decline-${DateTime.now().microsecondsSinceEpoch}',
            sessionId: sessionId,
            abortSignal: null,
            ask:
                ({
                  required String permission,
                  required List<String> patterns,
                  Map<String, dynamic>? metadata,
                  List<String>? always,
                }) async {},
            askQuestion:
                ({
                  required String question,
                  List<QuestionOption> options = const [],
                  bool multiple = false,
                }) async => 'No',
            switchAgent: (String agentId, {String? messageText}) {
              enterSwitchCalls.add(agentId);
            },
          );

          await planEnter.execute({}, enterCtx);
          expect(enterSwitchCalls, isEmpty);

          final exitSwitchCalls = <String?>[];
          final exitCtx = ToolContext(
            toolCallId: 'decline-${DateTime.now().microsecondsSinceEpoch}',
            sessionId: sessionId,
            abortSignal: null,
            ask:
                ({
                  required String permission,
                  required List<String> patterns,
                  Map<String, dynamic>? metadata,
                  List<String>? always,
                }) async {},
            askQuestion:
                ({
                  required String question,
                  List<QuestionOption> options = const [],
                  bool multiple = false,
                }) async => 'Yes',
            switchAgent: (String agentId, {String? messageText}) {
              exitSwitchCalls.add(agentId);
            },
          );

          final exitOutput = await planExit.execute({}, exitCtx);
          expect(exitSwitchCalls, contains('build'));
          expect(exitOutput.metadata?['approved'], isTrue);
        },
      );
    });
  });
}
