import 'package:shared_preferences/shared_preferences.dart';


class FavoritesService {
  static const _key = "favorites";

  static Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> toggleFavorite(String pair) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList(_key) ?? [];

    if (favs.contains(pair)) {
      favs.remove(pair);
    } else {
      favs.add(pair);
    }
    prefs.setStringList(_key, favs);
  }

  static Future<bool> isFavorite(String pair) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).contains(pair);
  }
}
