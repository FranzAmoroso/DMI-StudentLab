import 'package:sqflite/sqflite.dart';

Future<void> quizAnswered(Database db) async {
  await db.execute(
  '''
    CREATE TABLE IF NOT EXISTS quiz_answered(
    answered_id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,
    choice_id TEXT NOT NULL,
    is_correct INTEGER NOT NULL,
    answered_at INTEGER NOT NULL,
    FOREIGN KEY (session_id) REFERENCES quiz_session (session_id)
    )
  ''');
}