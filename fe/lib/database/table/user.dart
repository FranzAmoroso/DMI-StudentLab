import "package:sqflite/sqflite.dart";

Future<void> user(Database db) async {
  await db.execute(
    '''
        CREATE TABLE IF NOT EXISTS user (
          id INTEGER PRIMARY KEY,
          nome TEXT DEFAULT 'Student',
          cognome TEXT DEFAULT 'Lab',
          numero_matricola TEXT,
          universita TEXT,
          dipartimento TEXT,
          corso TEXT
        )
    '''
  );
}