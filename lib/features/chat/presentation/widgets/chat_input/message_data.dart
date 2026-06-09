class MessageData {
  final String text;
  final String? imagePath;
  final String? imageType;
  final String? base64Data;
  final String? delegateAgentId;

  MessageData({
    required this.text,
    this.imagePath,
    this.imageType,
    this.base64Data,
    this.delegateAgentId,
  });
}
