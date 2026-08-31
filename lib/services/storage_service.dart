import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment.dart';

/// שירות אחסון מקומי - שומר את כל התורים במכשיר עצמו (עובד גם ללא אינטרנט)
class StorageService {
  static const _appointmentsKey = 'appointments_v2';
  static const _settingsKey = 'sync_settings_v1';

  Future<List<Appointment>> loadAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_appointmentsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAppointments(List<Appointment> appointments) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(appointments.map((a) => a.toJson()).toList());
    await prefs.setString(_appointmentsKey, raw);
  }

  /// שמירת הגדרות סנכרון (ללא סיסמת ה-Wi-Fi, שנשמרת רק בזיכרון הזמני)
  Future<void> saveSyncSettings({
    required String token,
    required String owner,
    required String repo,
    required String path,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _settingsKey,
      jsonEncode({
        'token': token,
        'owner': owner,
        'repo': repo,
        'path': path,
      }),
    );
  }

  Future<Map<String, String>> loadSyncSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v?.toString() ?? ''));
  }
}
