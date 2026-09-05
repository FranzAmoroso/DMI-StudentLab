class QuizModel {
  final String idQuestion;
  final String idCorrect;
  final String text;
  final List<Option> option;
  final Map<String, dynamic> metadata;

  final String formalExplanation;
  final String informalExplanation;
  final String questionResponseExplanation;

  QuizModel({
    required this.idQuestion,
    required this.idCorrect,
    required this.text,
    required this.option,
    required this.metadata,
    required this.formalExplanation,
    required this.informalExplanation,
    required this.questionResponseExplanation,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawOptions = json['option'];
    final List<Option> optionList = rawOptions is List
        ? rawOptions.whereType<Map>().map((i) => Option.fromJson(Map<String, dynamic>.from(i))).toList()
        : <Option>[];

    return QuizModel(
      idQuestion: json['id_question'].toString(),

      idCorrect: json['id_correct']?.toString() ?? '',

      text: json['text']?.toString() ?? '',

      option: optionList,

      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : <String, dynamic>{},

      formalExplanation:
          json['formal_explanation'] ?? '',

      informalExplanation:
          json['informal_explanation'] ?? '',

      questionResponseExplanation:
          json['question_response_explanation'] ?? '',
    );
  }
}

class Option {
  final String id;
  final String text;

  Option({
    required this.id,
    required this.text,
  });

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      id: json['id'].toString(),
      text: json['text'].toString(),
    );
  }
}

