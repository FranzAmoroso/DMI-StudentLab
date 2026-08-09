import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Future<Database> databaseInit() async {
  final databasePath = await getDatabasesPath();
  final path = join(databasePath, 'User.db');

  final Database database = await openDatabase(
    path,
    version: 1,
    onCreate: (Database db, int version) async {
      await db.execute(
        'CREATE TABLE user_session (user_id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, token TEXT UNIQUE, login_timestamp INTEGER)'
      );
    }
  );

  return database;
}

