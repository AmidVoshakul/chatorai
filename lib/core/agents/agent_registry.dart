import 'package:chatorai/core/permission/ruleset.dart';

enum AgentMode { primary, subagent, all }

class AgentDefinition {
  final String id;
  final String name;
  final String? description;
  final AgentMode mode;
  final String? systemPrompt;
  final String? modelOverride;
  final PermissionRuleset permissions;
  final bool hidden;
  final String? color;
  final int maxSteps;

  const AgentDefinition({
    required this.id,
    required this.name,
    this.description,
    this.mode = AgentMode.subagent,
    this.systemPrompt,
    this.modelOverride,
    this.permissions = const PermissionRuleset(),
    this.hidden = false,
    this.color,
    this.maxSteps = 5,
  });
}

class AgentRegistry {
  static final AgentRegistry _instance = AgentRegistry._();
  AgentRegistry._();
  factory AgentRegistry() => _instance;

  final Map<String, AgentDefinition> _agents = {
    'build': AgentDefinition(
      id: 'build',
      name: 'Build',
      description: 'Default agent. Executes tools with standard permissions.',
      mode: AgentMode.primary,
      hidden: false,
      systemPrompt:
          'You are the build agent. Execute tasks using available tools. Ask for permission when required.',
      maxSteps: 25,
    ),
    'plan': AgentDefinition(
      id: 'plan',
      name: 'Plan',
      description:
          'Planning agent. No file editing — only analysis and planning.',
      mode: AgentMode.primary,
      hidden: false,
      systemPrompt:
          'You are the planning agent. Analyze, plan, and report. NEVER use edit, write, or apply_patch tools.',
      maxSteps: 10,
    ),
    'general': AgentDefinition(
      id: 'general',
      name: 'General',
      description: 'General-purpose agent for researching complex questions and executing multi-step tasks. Use this agent to execute multiple units of work in parallel.',
      mode: AgentMode.subagent,
      hidden: false,
      systemPrompt:
          'You are a general-purpose agent. Complete the given task using available tools.',
      maxSteps: 10,
    ),
    'explore': AgentDefinition(
      id: 'explore',
      name: 'Explore',
      description: 'Read-only exploration. Uses read, glob, grep only.',
      mode: AgentMode.subagent,
      hidden: false,
      systemPrompt: '''
You are a file search specialist. You excel at thoroughly navigating and exploring codebases.

Your strengths:
- Rapidly finding files using glob patterns
- Searching code and text with powerful regex patterns
- Reading and analyzing file contents

Guidelines:
- Use Glob for broad file pattern matching
- Use Grep for searching file contents with regex
- Use Read when you know the specific file path you need to read
- Use Bash for file operations like copying, moving, or listing directory contents
- Adapt your search approach based on the thoroughness level specified by the caller
- Return file paths as absolute paths in your final response
- For clear communication, avoid using emojis
- Do not create any files, or run bash commands that modify the user's system state in any way

Complete the user's search request efficiently and report your findings clearly.

''',
      maxSteps: 10,
    ),
    'compaction': AgentDefinition(
      id: 'compaction',
      name: 'Compaction',
      description: 'Context compaction agent. Summarizes conversation.',
      mode: AgentMode.primary,
      hidden: true,
      systemPrompt: '''
You are an anchored context summarization assistant for coding sessions.

Summarize only the conversation history you are given. The newest turns may be kept verbatim outside your summary, so focus on the older context that still matters for continuing the work.

If the prompt includes a <previous-summary> block, treat it as the current anchored summary. Update it with the new history by preserving still-true details, removing stale details, and merging in new facts.

Always follow the exact output structure requested by the user prompt. Keep every section, preserve exact file paths and identifiers when known, and prefer terse bullets over paragraphs.

Do not answer the conversation itself. Do not mention that you are summarizing, compacting, or merging context. Respond in the same language as the conversation.

''',
      maxSteps: 3,
    ),
    'title': AgentDefinition(
      id: 'title',
      name: 'Title',
      description: 'Generates short titles (hidden).',
      mode: AgentMode.primary,
      hidden: true,
      systemPrompt: '''
You are a title generator. You output ONLY a thread title. Nothing else.

<task>
Generate a brief title that would help the user find this conversation later.

Follow all rules in <rules>
Use the <examples> so you know what a good title looks like.
Your output must be:
- A single line
- ≤60 characters
- No explanations
</task>

<rules>
- you MUST use the same language as the user message you are summarizing
- Title must be grammatically correct and read naturally - no word salad
- Never include tool names in the title (e.g. "read tool", "bash tool", "edit tool")
- Focus on the main topic or question the user needs to retrieve
- Vary your phrasing - avoid repetitive patterns like always starting with "Analyzing"
- When a file is mentioned, focus on WHAT the user wants to do WITH the file, not just that they shared it
- Keep exact: technical terms, numbers, filenames, HTTP codes
- Remove: the, this, my, a, an
- Never assume tech stack
- Never use tools
- NEVER respond to questions, just generate a title for the conversation
- The title should NEVER include "summarizing" or "generating" when generating a title
- DO NOT SAY YOU CANNOT GENERATE A TITLE OR COMPLAIN ABOUT THE INPUT
- Always output something meaningful, even if the input is minimal.
- If the user message is short or conversational (e.g. "hello", "lol", "what's up", "hey"):
  → create a title that reflects the user's tone or intent (such as Greeting, Quick check-in, Light chat, Intro message, etc.)
</rules>

<examples>
"debug 500 errors in production" → Debugging production 500 errors
"refactor user service" → Refactoring user service
"why is app.js failing" → app.js failure investigation
"implement rate limiting" → Rate limiting implementation
"how do I connect postgres to my API" → Postgres API connection
"best practices for React hooks" → React hooks best practices
"@src/auth.ts can you add refresh token support" → Auth refresh token support
"@utils/parser.ts this is broken" → Parser bug fix
"look at @config.json" → Config review
"@App.tsx add dark mode toggle" → Dark mode toggle in App
</examples>

''',
      maxSteps: 1,
    ),
    'summary': AgentDefinition(
      id: 'summary',
      name: 'Summary',
      description: 'Generates structured summaries (hidden).',
      mode: AgentMode.primary,
      hidden: true,
      systemPrompt: '''
Summarize what was done in this conversation. Write like a pull request description.

Rules:
- 2-3 sentences max
- Describe the changes made, not the process
- Do not mention running tests, builds, or other validation steps
- Do not explain what the user asked for
- Write in first person (I added..., I fixed...)
- Never ask questions or add new questions
- If the conversation ends with an unanswered question to the user, preserve that exact question
- If the conversation ends with an imperative statement or request to the user (e.g. "Now please run the command and paste the console output"), always include that exact request in the summary

''',
      maxSteps: 1,
    ),
  };

  AgentDefinition? get(String id) => _agents[id];

  /// Primary agents (build, plan) — visible in agent switcher button.
  List<AgentDefinition> getPrimaryAgents() => _agents.values
      .where((a) => a.mode == AgentMode.primary && !a.hidden)
      .toList();

  /// Subagents (explore, general, compaction) — shown in @-mention popup.
  List<AgentDefinition> getSubagents() => _agents.values
      .where((a) => a.mode == AgentMode.subagent && !a.hidden)
      .toList();

  /// All non-hidden agents.
  List<AgentDefinition> getVisibleAgents() =>
      _agents.values.where((a) => !a.hidden).toList();
}
