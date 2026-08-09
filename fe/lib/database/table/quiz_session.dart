import 'package:sqflite/sqflite.dart';

Future<void> quizSession(Database db) async {
  await db.execute(
    '''
      CREATE TABLE IF NOT EXISTS quiz_session (
      session_id INTEGER PRIMARY KEY AUTOINCREMENT, 
      user_id INTEGER NOT NULL, 
      quiz_id INTEGER NOT NULL, 
      question_answer INTEGER DEFAULT 0, 
      question_correct INTEGER DEFAULT 0,
      question_wrong INTEGER DEFAULT 0,
      score INTEGER DEFAULT 0,
      FOREIGN KEY (user_id) REFERENCES user_session(user_id)
      )
    '''
  );
}