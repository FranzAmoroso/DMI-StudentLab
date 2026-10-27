import 'upload_items.dart';

/// Sul web non si può aprire una cartella dal selettore: si usa il trascinamento.
bool get canPickFolder => false;

Future<UploadSelection?> pickFolder() async => null;
