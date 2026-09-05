class MessageData {
  final String text;
  final String? imagePath;
  final String? imageType;
  final String? imageName;
  final String? base64Data;
  final String? delegateAgentId;
  final String? agentMention;
  final String? attachedDocPath;

  /// When true the message must execute as a delegated subagent task:
  /// [text] holds the original invocation shown in the parent session and
  /// [taskPrompt] carries the expanded template for the child session.
  final bool runAsSubtask;
  final String? taskPrompt;

  /// Short card title of the delegated task.
  final String? taskTitle;

  MessageData({
    required this.text,
    this.imagePath,
    this.imageType,
    this.imageName,
    this.base64Data,
    this.delegateAgentId,
    this.agentMention,
    this.attachedDocPath,
    this.runAsSubtask = false,
    this.taskPrompt,
    this.taskTitle,
  });
}
