import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../services/auth_session.dart';
import '../../services/device_key_service.dart';
import '../repositories/study_plan_local_repository.dart';

class StudyPlanSyncService {
  static const String _baseUrl = 'https://dmi-student-lab.vercel.app';

  final AuthSession _session;
  final DeviceKeyService _deviceKeys;
  final StudyPlanLocalRepository _repository;

  StudyPlanSyncService({
    AuthSession? session,
    DeviceKeyService? deviceKeys,
    StudyPlanLocalRepository? repository,
  })  : _session = session ?? AuthSession.instance,
        _deviceKeys = deviceKeys ?? DeviceKeyService(),
        _repository = repository ?? StudyPlanLocalRepository();

  Future<void> refreshGuestPlan() async {
    final String deviceId = await _deviceKeys.getDeviceId();
    await _repository.refreshGuestFromQuizAttempts(deviceId);
  }

  Future<void> onAuthenticated(int userId) async {
    final String deviceId = await _deviceKeys.getDeviceId();
    await _repository.refreshGuestFromQuizAttempts(deviceId);
    await _claimPendingGuest(userId);
    await refreshRemote(userId);
  }

  Future<void> refreshRemote(int userId) async {
    if (!_session.isAuthenticated || _session.currentUserId != userId) return;
    final http.Response response = await http.get(
      Uri.parse('$_baseUrl/study-plan/bootstrap'),
      headers: _headers,
    );
    final Map<String, dynamic> plan = _decodeMap(response);
    await _repository.mergeBootstrap(userId, plan);
  }

  Future<void> _claimPendingGuest(int userId) async {
    final List<Map<String, dynamic>> pending = await _repository.pendingGuestSyncPayload(userId);
    for (final Map<String, dynamic> source in pending) {
      try {
        final http.Response response = await http.post(
          Uri.parse('$_baseUrl/study-plan/sync'),
          headers: <String, String>{..._headers, 'Content-Type': 'application/json'},
          body: jsonEncode(<String, dynamic>{
            'session_uuid': source['session_uuid'],
            'device_id': source['device_id'],
            'device_label': source['device_label'],
            'source_type': 'guest',
            'contributions': source['contributions'],
          }),
        );
        _decodeMap(response);
        await _repository.markGuestClaimed(source['source_key'].toString(), userId);
      } catch (_) {
        // Il login non deve fallire se il piano non è temporaneamente sincronizzabile.
      }
    }
  }

  Future<Map<String, dynamic>> setRemoteSessionEnabled(String sessionUuid, bool enabled) async {
    final http.Response response = await http.patch(
      Uri.parse('$_baseUrl/study-plan/sessions/${Uri.encodeComponent(sessionUuid)}/association'),
      headers: <String, String>{..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{'contribution_enabled': enabled}),
    );
    final Map<String, dynamic> plan = _decodeMap(response);
    final int? userId = _session.currentUserId;
    if (userId != null) await _repository.mergeBootstrap(userId, plan);
    return plan;
  }

  Map<String, String> get _headers {
    final String? token = _session.accessToken;
    if (token == null || token.trim().isEmpty) throw StateError('Sessione StudentLab non disponibile.');
    return <String, String>{'Accept': 'application/json', 'Authorization': 'Bearer ${token.trim()}'};
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    dynamic decoded;
    try { decoded = response.body.trim().isEmpty ? <String, dynamic>{} : jsonDecode(response.body); } catch (_) { decoded = null; }
    if (response.statusCode >= 200 && response.statusCode < 300 && decoded is Map) return Map<String, dynamic>.from(decoded);
    final String detail = decoded is Map ? decoded['detail']?.toString().trim() ?? '' : '';
    throw Exception(detail.isEmpty ? 'Non è stato possibile sincronizzare il Ripasso.' : detail);
  }
}
