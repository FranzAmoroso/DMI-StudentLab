import 'package:sqflite/sqflite.dart';

Future<void> userSession(Database db) async {
  await db.execute(
    '''
      CREATE TABLE IF NOT EXISTS user_session (
      user_id INTEGER PRIMARY KEY AUTOINCREMENT, 
      username TEXT DEFAULT 'StudentLab', 
      token TEXT UNIQUE, 
      login_timestamp INTEGER
      )
    '''
  );
}