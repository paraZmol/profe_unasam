enum SuggestionType { profesor, facultad, escuela }

enum SuggestionStatus { pending, approved, rejected }

class Suggestion {
  final String id;
  final String userId;
  final String userAlias;
  final SuggestionType type;
  final SuggestionStatus status;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  Suggestion({
    required this.id,
    required this.userId,
    required this.userAlias,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.data,
  });
}
