import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:sociality/api/api_config.dart';

const String _kGameSessionsPath = '/api/gamesessions';

Uri gameSessionsCreateUri() {
  final base = storiesApiBaseUri();
  return base.replace(
    path: _kGameSessionsPath,
    query: null,
  );
}

String? _joinCodeFromJson(Map<String, dynamic> json) {
  for (final key in <String>['code', 'joinCode', 'gameCode', 'pin', 'join_code']) {
    final v = json[key];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  final session = json['session'];
  if (session is Map<String, dynamic>) {
    for (final key in <String>['code', 'joinCode']) {
      final v = session[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
  }
  return null;
}

List<String> _participantLabelsFromJson(
  Map<String, dynamic> json,
  String hostName,
) {
  final list = json['participants'];
  if (list is! List<dynamic>) {
    return <String>['$hostName (Host)'];
  }
  final out = <String>[];
  for (final item in list) {
    if (item is String && item.trim().isNotEmpty) {
      out.add(item.trim());
    } else if (item is Map) {
      final m = Map<String, dynamic>.from(item);
      final name = m['name'] ?? m['displayName'] ?? m['userName'];
      if (name is String && name.trim().isNotEmpty) {
        final isHost = m['isHost'] == true || m['host'] == true;
        out.add(isHost ? '${name.trim()} (Host)' : name.trim());
      }
    }
  }
  if (out.isEmpty) return <String>['$hostName (Host)'];
  return out;
}

class GameSessionCreateResult {
  const GameSessionCreateResult({required this.joinCode, this.participantLabels});

  final String joinCode;
  final List<String>? participantLabels;
}

Future<GameSessionCreateResult> createGameSession({
  required int currentStory,
  required String hostName,
}) async {
  final uri = gameSessionsCreateUri();
  final response = await http.post(
    uri,
    headers: const {
      'Accept': '*/*',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(<String, dynamic>{
      'currentStory': currentStory,
      'hostName': hostName,
    }),
  );
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(
      'Sessie starten mislukt (${response.statusCode})',
    );
  }
  final decoded = jsonDecode(response.body);
  if (decoded is! Map<String, dynamic>) {
    throw Exception('Ongeldig antwoord van de server');
  }
  final code = _joinCodeFromJson(decoded);
  if (code == null || code.isEmpty) {
    throw Exception('Geen spelcode ontvangen');
  }
  final labels = _participantLabelsFromJson(decoded, hostName);
  return GameSessionCreateResult(joinCode: code, participantLabels: labels);
}
