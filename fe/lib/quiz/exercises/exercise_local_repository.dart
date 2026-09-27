import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';

import 'package:fe/quiz/exercises/exercise_models.dart';
import 'package:fe/quiz/exercises/flashcard_scheduler.dart';
import 'package:fe/local_storage/database/app_database.dart';
import 'package:fe/local_storage/database/database_tables.dart';
import 'package:fe/local_storage/models/quiz_attempt_answer_local.dart';
import 'package:fe/local_storage/repositories/quiz_attempt_local_repository.dart';

/// Esercizi e flashcard senza account: tutto resta sul telefono (SQLite v14),
/// come i tentativi dei quiz da ospite. Il Ripasso li legge da qui.
class ExerciseLocalRepository {
  final AppDatabase _database;
  final QuizAttemptLocalRepository _attempts;

  ExerciseLocalRepository({AppDatabase? database, QuizAttemptLocalRepository? attempts})
      : _database = database ?? AppDatabase.instance,
        _attempts = attempts ?? QuizAttemptLocalRepository(database: database);

  /// Salva una sessione di esercizi svolta da ospite (già corretta dal server).
  Future<void> saveGuestSession({
    required String department,
    required String course,
    required String subject,
    required List<ExerciseItem> items,
    required Map<String, Map<String, dynamic>> answers,
    required Map<String, ExerciseResult> results,
  }) async {
    final List<ExerciseItem> answered = items.where((ExerciseItem i) => results.containsKey(i.id)).toList();
    if (answered.isEmpty) return;
    final int attemptId = await _attempts.startGuestAttempt(
      department: department,
      course: course,
      subject: subject,
      totalQuestions: answered.length,
    );
    for (final ExerciseItem item in answered) {
      final ExerciseResult result = results[item.id]!;
      final Map<String, dynamic> answer = answers[item.id] ?? const <String, dynamic>{};
      await _attempts.saveAnswer(QuizAttemptAnswerLocal(
        attemptId: attemptId,
        questionId: item.id,
        argument: item.argument,
        questionText: item.text,
        // Il Ripasso mostra "Hai risposto: …": un riassunto leggibile della risposta.
        selectedOptionId: 'esercizio',
        selectedOptionText: answerSummary(item, answer),
        correctOptionId: '',
        correctOptionText: result.solutionText,
        formalExplanation: result.explanation,
        informalExplanation: null,
        questionResponseExplanation: null,
        selectedAnswerExplanation: null,
        correctAnswerExplanation: result.solutionText,
        isCorrect: result.isCorrect,
        responseTimeSeconds: null,
        answeredAt: DateTime.now(),
        questionType: item.type,
        answerPayload: jsonEncode(answer),
        correctPayload: result.solution == null ? null : jsonEncode(result.solution),
        score: result.score,
      ));
    }
    await _attempts.completeAttempt(attemptId);
  }

  // ------------------------------------------------------------------ flashcard
  String _key(String department, String course, String subject, String cardId) =>
      '${department.toLowerCase()}|${course.toLowerCase()}|${subject.toLowerCase()}|$cardId';

  Future<Map<String, Map<String, dynamic>>> flashcardStates(String department, String course, String subject) async {
    final Database db = await _database.database;
    final List<Map<String, dynamic>> rows = await db.query(
      DatabaseTables.flashcardReviewsLocal,
      where: 'department = ? AND course = ? AND subject = ?',
      whereArgs: <Object?>[department.toLowerCase(), course.toLowerCase(), subject.toLowerCase()],
    );
    return <String, Map<String, dynamic>>{for (final Map<String, dynamic> r in rows) r['card_id'].toString(): r};
  }

  Future<Map<String, dynamic>> reviewFlashcard({
    required String department,
    required String course,
    required String subject,
    required String cardId,
    required int grade,
    String? argument,
  }) async {
    final Database db = await _database.database;
    final String key = _key(department, course, subject, cardId);
    final List<Map<String, dynamic>> rows =
        await db.query(DatabaseTables.flashcardReviewsLocal, where: 'card_key = ?', whereArgs: <Object?>[key], limit: 1);
    final Map<String, dynamic> current = rows.isEmpty ? <String, dynamic>{} : rows.first;
    final int reviews = (current['reviews'] as num?)?.toInt() ?? 0;
    final FlashcardSchedule next = FlashcardScheduler.next(
      ease: (current['ease'] as num?)?.toDouble() ?? 2.5,
      intervalDays: (current['interval_days'] as num?)?.toInt() ?? 0,
      reviews: reviews,
      grade: grade,
    );
    final DateTime now = DateTime.now().toUtc();
    final Map<String, Object?> values = <String, Object?>{
      'card_key': key,
      'department': department.toLowerCase(),
      'course': course.toLowerCase(),
      'subject': subject.toLowerCase(),
      'card_id': cardId,
      'argument': argument ?? current['argument'],
      'ease': next.ease,
      'interval_days': next.intervalDays,
      'due_at': now.add(next.wait).toIso8601String(),
      'reviews': reviews + 1,
      'lapses': ((current['lapses'] as num?)?.toInt() ?? 0) + (grade < 2 && reviews > 0 ? 1 : 0),
      'last_grade': grade,
      'updated_at': now.toIso8601String(),
    };
    await db.insert(DatabaseTables.flashcardReviewsLocal, values, conflictAlgorithm: ConflictAlgorithm.replace);
    return values;
  }

  /// Prima le schede scadute, poi al massimo [newLimit] nuove.
  List<ExerciseItem> dueOrder(List<ExerciseItem> cards, Map<String, Map<String, dynamic>> states,
      {int limit = 20, int newLimit = 10}) {
    final DateTime now = DateTime.now().toUtc();
    final List<(DateTime, ExerciseItem)> due = <(DateTime, ExerciseItem)>[];
    final List<ExerciseItem> fresh = <ExerciseItem>[];
    for (final ExerciseItem card in cards) {
      final Map<String, dynamic>? state = states[card.id];
      if (state == null) {
        fresh.add(card);
        continue;
      }
      final DateTime at = DateTime.tryParse(state['due_at']?.toString() ?? '')?.toUtc() ?? now;
      if (!at.isAfter(now)) due.add((at, card));
    }
    due.sort(((DateTime, ExerciseItem) a, (DateTime, ExerciseItem) b) => a.$1.compareTo(b.$1));
    final List<ExerciseItem> result = due.map(((DateTime, ExerciseItem) e) => e.$2).take(limit).toList();
    final int room = (limit - result.length).clamp(0, newLimit);
    return <ExerciseItem>[...result, ...fresh.take(room)];
  }
}

/// Riassunto leggibile di una risposta (per il Ripasso e lo storico).
String answerSummary(ExerciseItem item, Map<String, dynamic> answer) {
  switch (item.type) {
    case 'ordina':
      final Map<String, String> texts = {
        for (final Map<String, dynamic> i in asMapList(item.data['items'])) i['id'].toString(): i['text']?.toString() ?? ''
      };
      return asStringList(answer['order']).map((String id) => texts[id] ?? id).join(' → ');
    case 'abbina':
      final Map<String, String> left = {for (final l in asMapList(item.data['left'])) l['id'].toString(): '${l['text']}'};
      final Map<String, String> right = {for (final r in asMapList(item.data['right'])) r['id'].toString(): '${r['text']}'};
      return asMap(answer['pairs']).entries.map((MapEntry<String, dynamic> e) => '${left[e.key]} → ${right['${e.value}']}').join('; ');
    case 'completa':
    case 'numerica':
      return asMap(answer['values']).values.join(', ');
    case 'traccia':
      return asMap(answer['cells']).values.join(', ');
    case 'errore':
      return 'Riga ${asStringList(answer['lines']).join(', ')}';
    case 'grafo':
      return asStringList(answer['order']).join(' → ');
    case 'flashcard':
      return const <String>['Per niente', 'A fatica', 'Bene', 'Facile'][(int.tryParse('${answer['grade']}') ?? 0).clamp(0, 3)];
    case 'codice':
      return 'Codice consegnato';
    case 'scelta':
      final Map<String, String> texts = {
        for (final Map<String, dynamic> o in asMapList(item.data['options'])) o['id'].toString(): o['text']?.toString() ?? ''
      };
      return asStringList(answer['selected']).map((String id) => texts[id] ?? id).join(', ');
    default:
      return '';
  }
}
