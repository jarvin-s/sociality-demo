import 'package:shared_preferences/shared_preferences.dart';
import 'package:sociality/api/game_session_api.dart';

const String _kPlayerIdKey = 'player_id';
const String _kPlayerNameKey = 'player_name';
const String _kPlayerIsHostKey = 'player_is_host';

/// Persists the current player from API responses (id, name, isHost).
Future<void> savePlayerIdentity(GameSessionPlayer player) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kPlayerIdKey, player.id);
  await prefs.setString(_kPlayerNameKey, player.name);
  await prefs.setBool(_kPlayerIsHostKey, player.isHost);
}

Future<GameSessionPlayer?> loadPlayerIdentity() async {
  final prefs = await SharedPreferences.getInstance();
  final id = prefs.getInt(_kPlayerIdKey);
  final name = prefs.getString(_kPlayerNameKey);
  if (id == null || name == null) return null;
  return GameSessionPlayer(
    id: id,
    name: name,
    isHost: prefs.getBool(_kPlayerIsHostKey) ?? false,
  );
}

Future<void> clearPlayerIdentity() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kPlayerIdKey);
  await prefs.remove(_kPlayerNameKey);
  await prefs.remove(_kPlayerIsHostKey);
}
