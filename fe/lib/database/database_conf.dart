import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'table/user.dart';
import 'table/quiz_answered.dart';
import 'table/quiz_session.dart';
import 'table/user_session.dart';


Future<Database> databaseInit() async {
  final databasePath = await getDatabasesPath();
  final path = join(databasePath, 'User.db');

  final Database database = await openDatabase(
    path,
    version: 1,
    onCreate: (Database db, int version) async {
      await user(db);
      await userSession(db);
      await quizSession(db);
      await quizAnswered(db);
    }
  );

  return database;
}

