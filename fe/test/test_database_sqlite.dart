import 'package:fe/database/database_conf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  test('Database initialization', () async {
    final Database db = await databaseInit();

    expect(db.isOpen, true);

    await db.close();
  });
}