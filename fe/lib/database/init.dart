import "package:sqflite/sqflite.dart";

Future<void> initialization(Database db){
  final user = db.query('user',limit:1);

  if (user.isEmpty) // richiesta al server di un identificativo unico
  else // controlla i dati del db per vedere come dobbiamo procedere
}