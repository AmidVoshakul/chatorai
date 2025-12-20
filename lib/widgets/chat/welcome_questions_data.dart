/// Welcome questions data for new chats
/// 
/// This file contains a curated list of popular questions that users can start with.
/// Add, remove, or modify questions as needed. The system will randomly select 4 questions
/// to display when a new chat is created or when the chat is empty.
class WelcomeQuestionsData {
  /// All available welcome questions
  static const List<String> allQuestions = [
    // General AI assistance
    'Explain quantum computing in simple terms',
    'What are the latest trends in artificial intelligence?',
    'Help me write a professional email to my team',
    'What should I learn to become a better programmer?',
    
    // Creative & brainstorming
    'Give me 5 creative ideas for a weekend project',
    'What are some good books for personal development?',
    'Help me brainstorm names for my new startup',
    'Create a meal plan for a healthy week',
    
    // Technical & coding
    'What are the best practices for Flutter development?',
    'Explain the difference between async and sync programming',
    'How do I optimize my code for better performance?',
    'What are the most useful programming design patterns?',
    
    // Learning & education
    'Teach me the basics of machine learning',
    'What are the key concepts of cloud computing?',
    'Explain blockchain technology to a beginner',
    'How does the internet work from a technical perspective?',
    
    // Productivity & life
    'What are the best productivity techniques?',
    'How can I improve my focus and concentration?',
    'Give me a daily routine for maximum productivity',
    'What are some good habits for success?',
    
    // Business & career
    'How to prepare for a software engineering interview?',
    'What skills are most valuable in tech industry?',
    'How to negotiate a salary increase?',
    'What are the top tech companies to work for?',
    
    // Science & technology
    'What are the latest breakthroughs in space exploration?',
    'How is AI changing healthcare?',
    'What are the most exciting technologies of 2025?',
    'Explain the future of renewable energy',
    
    // Philosophy & thinking
    'What are the most important philosophical questions?',
    'How can I think more critically about problems?',
    'What are the best ways to learn new skills?',
    'How do I stay motivated when learning something difficult?',
  ];

  /// Get a random subset of questions
  static List<String> getRandomQuestions({int count = 4}) {
    if (count >= allQuestions.length) {
      return allQuestions;
    }
    
    // Create a copy to avoid modifying the original
    final shuffled = List<String>.from(allQuestions)..shuffle();
    return shuffled.take(count).toList();
  }

  /// Get questions by category
  static List<String> getQuestionsByCategory(String category) {
    final categoryMap = {
      'technical': [
        'What are the best practices for Flutter development?',
        'Explain the difference between async and sync programming',
        'How do I optimize my code for better performance?',
        'What are the most useful programming design patterns?',
      ],
      'creative': [
        'Give me 5 creative ideas for a weekend project',
        'What are some good books for personal development?',
        'Help me brainstorm names for my new startup',
        'Create a meal plan for a healthy week',
      ],
      'learning': [
        'Teach me the basics of machine learning',
        'What are the key concepts of cloud computing?',
        'Explain blockchain technology to a beginner',
        'How does the internet work from a technical perspective?',
      ],
      'productivity': [
        'What are the best productivity techniques?',
        'How can I improve my focus and concentration?',
        'Give me a daily routine for maximum productivity',
        'What are some good habits for success?',
      ],
      'career': [
        'How to prepare for a software engineering interview?',
        'What skills are most valuable in tech industry?',
        'How to negotiate a salary increase?',
        'What are the top tech companies to work for?',
      ],
      'science': [
        'What are the latest breakthroughs in space exploration?',
        'How is AI changing healthcare?',
        'What are the most exciting technologies of 2025?',
        'Explain the future of renewable energy',
      ],
      'philosophy': [
        'What are the most important philosophical questions?',
        'How can I think more critically about problems?',
        'What are the best ways to learn new skills?',
        'How do I stay motivated when learning something difficult?',
      ],
    };
    
    return categoryMap[category] ?? [];
  }

  /// Get all available categories
  static List<String> getCategories() {
    return [
      'technical',
      'creative', 
      'learning',
      'productivity',
      'career',
      'science',
      'philosophy',
    ];
  }

  /// Add a new question to the list
  static void addQuestion(String question) {
    // Note: This is a static method for API purposes, but since we can't modify
    // the const list at runtime, this would need to be implemented with a 
    // persistent storage solution if dynamic modification is needed
    // For now, questions must be added manually to the const list
  }
}
