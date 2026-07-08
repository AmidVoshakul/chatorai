class QuestionOption {
  final String label;
  final String? description;
  const QuestionOption({required this.label, this.description});

  factory QuestionOption.fromJson(dynamic json) {
    if (json is String) return QuestionOption(label: json, description: null);
    if (json is Map) {
      return QuestionOption(
        label: json['label'] as String? ?? json.toString(),
        description: json['description'] as String?,
      );
    }
    return QuestionOption(label: json.toString(), description: null);
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    if (description != null) 'description': description,
  };
}
