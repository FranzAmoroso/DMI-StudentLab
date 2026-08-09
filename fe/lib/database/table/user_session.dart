import 'package:sqflite/sqflite.dart';

Future<void> userSession(Database db) async {
  await db.execute(
    '''
      CREATE TABLE IF NOT EXISTS user_session (
      session_id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL, 
      token TEXT UNIQUE, 
      login_timestamp INTEGER,
      FOREIGN KEY (user_id) REFERENCES user(id)
      )
    '''
  );
}