import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Errore già pronto per l'utente: una frase semplice e un suggerimento.
///
/// Regola StudentLab (Play Store): nell'app non compaiono codici HTTP, testi
/// tecnici, token o ID. Il server restituisce già frasi semplici (con un codice
/// breve, es. «codice DRV-02», che serve a ritrovare il dettaglio nel registro
/// diagnostico degli admin). Qui si gestiscono i casi in cui il server non
/// risponde con una frase utilizzabile.
class UserFacingError implements Exception {
  final String message;
  final int? status;
  const UserFacingError(this.message, {this.status});
  @override
  String toString() => message;
}

/// Messaggio per una risposta HTTP non riuscita.
String friendlyHttpMessage(http.Response response, String fallback) {
  final String? detail = serverDetail(response);
  if (detail != null) return detail;
  return friendlyStatusMessage(response.statusCode, fallback);
}

/// Frase del server, se è una frase leggibile (non JSON, non HTML, non troppo lunga).
String? serverDetail(http.Response response) {
  try {
    final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map && decoded['detail'] is String) {
      final String text = (decoded['detail'] as String).trim();
      if (isReadable(text)) return text;
    }
  } catch (_) {/* corpo non JSON: si usa il messaggio generico */}
  return null;
}

bool isReadable(String text) =>
    text.isNotEmpty &&
    text.length <= 260 &&
    !text.contains('<') &&
    !text.contains('Traceback') &&
    !text.startsWith('{') &&
    !text.startsWith('[') &&
    !RegExp(r'^(HTTP|\d{3}\b)').hasMatch(text);

String friendlyStatusMessage(int status, String fallback) {
  final String base = fallback.trim().replaceAll(RegExp(r'[.:]$'), '');
  switch (status) {
    case 400:
    case 422:
      return '$base. Alcuni dati non sono validi: controlla e riprova.';
    case 401:
      return 'La sessione è scaduta. Accedi di nuovo e riprova.';
    case 403:
      return 'Non hai i permessi per questa operazione.';
    case 404:
      return '$base. La funzione non è disponibile in questo momento: aggiorna l’app o riprova più tardi.';
    case 409:
      return '$base. I dati sono cambiati nel frattempo: aggiorna la pagina e riprova.';
    case 413:
      return 'Il file è troppo grande per questa operazione.';
    case 429:
      return 'Troppe richieste ravvicinate. Attendi qualche secondo e riprova.';
    default:
      return status >= 500
          ? '$base. Il servizio non risponde: riprova tra qualche minuto.'
          : '$base. Riprova tra poco.';
  }
}

/// Messaggio per qualsiasi errore (rete, timeout, risposta del server).
String friendlyError(Object error, String fallback) {
  if (error is UserFacingError) return error.message;
  if (error is TimeoutException) {
    return 'La connessione è lenta e l’operazione non è terminata. Riprova.';
  }
  if (error is http.ClientException || error.runtimeType.toString() == 'SocketException') {
    return 'Connessione assente o instabile. Controlla la rete e riprova.';
  }
  final String text = error.toString().replaceFirst(RegExp(r'^(Exception|Bad state|StateError): ?'), '').trim();
  if (isReadable(text) && !text.contains('Exception') && !text.contains('Error:')) return text;
  return fallback;
}
