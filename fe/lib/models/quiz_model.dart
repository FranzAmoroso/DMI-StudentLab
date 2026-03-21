class QuizModel {
  final String idQuestion;
  final String text;
  final List<Option> option;
  final Map<String,dynamic> metadata;

  QuizModel({required this.idQuestion, required this.text, required this.option, required this.metadata});

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    var list = json['option'] as List;
    List<Option> optionList = list.map((i) => Option.fromJson(i)).toList();

    return QuizModel (
      idQuestion: json['id_question'].toString(),
      text: json['text'],
      option: optionList,
      metadata: json['metadata'],
    );
  }
}

class Option {
  final String id;
  final String text;

  Option({required this.id, required this.text});

  factory Option.fromJson(Map<String,dynamic> json) {
    return Option(id: json['id'], text: json['text']);
  }
}