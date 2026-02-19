import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_search.dart';

const String _keySavedSearches = 'saved_searches';

class SavedSearchService {
  static Future<List<SavedSearch>> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_keySavedSearches}_$userId';
    final json = prefs.getString(key);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => SavedSearch.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(String userId, List<SavedSearch> list) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_keySavedSearches}_$userId';
    await prefs.setString(
      key,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> add(String userId, SavedSearch search) async {
    final list = await load(userId);
    if (list.any((s) => s.id == search.id)) return;
    list.add(search);
    await save(userId, list);
  }

  static Future<void> remove(String userId, String searchId) async {
    final list = await load(userId);
    list.removeWhere((s) => s.id == searchId);
    await save(userId, list);
  }
}
