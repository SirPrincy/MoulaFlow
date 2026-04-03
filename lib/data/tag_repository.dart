import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';
import 'storage_keys.dart';

class TagRepository {
  Future<List<TagDefinition>> loadTags() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tagsData = prefs.getString(StorageKeys.tags);
    if (tagsData == null) return [];
    final List<dynamic> jsonList = jsonDecode(tagsData);
    return jsonList.map((json) => TagDefinition.fromJson(json)).toList();
  }

  Future<void> saveTags(List<TagDefinition> tags) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.tags,
      jsonEncode(tags.map((t) => t.toJson()).toList()),
    );
  }
}
