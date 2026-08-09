import 'package:fe/database/database_conf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Database initialization', () async {
    final Database db = await databaseInit();

    expect(db.isOpen, true);

    await db.close();
  });
}