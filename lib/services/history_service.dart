import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_item.dart';

class HistoryService {
  static const String _keyHistory = 'scan_history';
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Geçmişi getir
  static List<HistoryItem> getHistory() {
    final jsonString = _prefs?.getString(_keyHistory);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => HistoryItem.fromJson(json)).toList();
  }

  // Yeni kayıt ekle
  static Future<void> addHistory(HistoryItem item) async {
    final history = getHistory();
    history.insert(0, item); // En yeniler başta

    // Maksimum 50 kayıt tutalım
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }

    final jsonString = json.encode(history.map((e) => e.toJson()).toList());
    await _prefs?.setString(_keyHistory, jsonString);
  }

  // Geçmişi temizle
  static Future<void> clearHistory() async {
    await _prefs?.remove(_keyHistory);
  }

  // Tek kayıt sil
  static Future<void> deleteHistory(String id) async {
    final history = getHistory();
    history.removeWhere((item) => item.id == id);

    final jsonString = json.encode(history.map((e) => e.toJson()).toList());
    await _prefs?.setString(_keyHistory, jsonString);
  }
}
