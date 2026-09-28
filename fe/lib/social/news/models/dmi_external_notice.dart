class DmiExternalNotice {
  final int id;
  final String title;
  final String content;
  final String? teacher;
  final String originalUrl;
  final DateTime publishedOn;

  const DmiExternalNotice({
    required this.id,
    required this.title,
    required this.content,
    required this.teacher,
    required this.originalUrl,
    required this.publishedOn,
  });

  factory DmiExternalNotice.fromJson(Map<String, dynamic> json) {
    return DmiExternalNotice(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      teacher: json['teacher'] as String?,
      originalUrl: json['original_url'] as String? ?? '',
      publishedOn: DateTime.parse(json['published_on'] as String),
    );
  }
}
