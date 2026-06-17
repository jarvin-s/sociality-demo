import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:sociality/api/api_config.dart';

const String _kGameSessionsPath = '/api/gamesessions';

/// Characters used for 6-digit join codes (no I, L, O, or 0).
const String kJoinCodeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ123456789';

final Set<String> _kJoinCodeCharSet = kJoinCodeAlphabet.split('').toSet();

bool isValidJoinCodeFormat(String code) {
  final u = code.trim().toUpperCase();
  if (u.length != 6) return false;
  for (var i = 0; i < u.length; i++) {
    if (!_kJoinCodeCharSet.contains(u[i])) return false;
  }
  return true;
}

/// Keeps only allowed characters, uppercase, max length 6.
String normalizeJoinCodeTyping(String raw) {
  final buf = StringBuffer();
  for (final c in raw.toUpperCase().split('')) {
    if (_kJoinCodeCharSet.contains(c) && buf.length < 6) {
      buf.write(c);
    }
  }
  return buf.toString();
}

/// Parses a QR payload (`https://…/join?code=ABC123`) or raw code string.
String? parseJoinCodeFromQrOrText(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.queryParameters['code'] != null) {
    final q = uri.queryParameters['code']!.trim();
    final fromQuery = normalizeJoinCodeTyping(q);
    if (fromQuery.length == 6) return fromQuery;
  }
  final normalized = normalizeJoinCodeTyping(trimmed);
  return normalized.length == 6 ? normalized : null;
}

Uri gameSessionsCreateUri() {
  final base = storiesApiBaseUri();
  return base.replace(
    path: _kGameSessionsPath,
    query: null,
  );
}

Uri _gamesessionsBaseUri() {
  final base = storiesApiBaseUri();
  return Uri(
    scheme: base.scheme,
    host: base.host,
    port: base.hasPort ? base.port : null,
    pathSegments: <String>[
      ...base.pathSegments.where((s) => s.isNotEmpty),
      'api',
      'gamesessions',
    ],
  );
}

Uri gameSessionsJoinUri(String joinCode) {
  final root = _gamesessionsBaseUri();
  return root.replace(
    pathSegments: <String>[
      ...root.pathSegments,
      joinCode.trim(),
      'join',
    ],
  );
}

Uri gameSessionFetchUri(String joinCode) {
  final root = _gamesessionsBaseUri();
  return root.replace(
    pathSegments: <String>[
      ...root.pathSegments,
      joinCode.trim(),
    ],
  );
}

Uri gameSessionStartUri(String joinCode) {
  final root = _gamesessionsBaseUri();
  return root.replace(
    pathSegments: <String>[
      ...root.pathSegments,
      joinCode.trim(),
      'start',
    ],
  );
}

Uri gameSessionVoteUri(String joinCode) {
  final root = _gamesessionsBaseUri();
  return root.replace(
    pathSegments: <String>[
      ...root.pathSegments,
      joinCode.trim(),
      'vote',
    ],
  );
}

Uri gameSessionChooseUri(String joinCode) {
  final root = _gamesessionsBaseUri();
  return root.replace(
    pathSegments: <String>[
      ...root.pathSegments,
      joinCode.trim(),
      'choose',
    ],
  );
}

int? _intFromJson(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
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
  const GameSessionCreateResult({
    required this.joinCode,
    required this.participantLabels,
    this.hostPlayer,
  });

  final String joinCode;
  final List<String> participantLabels;
  final GameSessionPlayer? hostPlayer;

  int? get hostPlayerId => hostPlayer?.id;
}

class GameSessionJoinResult {
  const GameSessionJoinResult({
    required this.snapshot,
    this.selfPlayer,
  });

  final GameSessionSnapshot snapshot;
  final GameSessionPlayer? selfPlayer;

  int? get selfPlayerId => selfPlayer?.id;
}

class GameSessionPlayer {
  const GameSessionPlayer({
    required this.id,
    required this.name,
    required this.isHost,
  });

  final int id;
  final String name;
  final bool isHost;
}

class CardOptionSnapshot {
  const CardOptionSnapshot({
    required this.id,
    required this.optionText,
    this.intervention,
    this.destinationCard,
  });

  final int id;
  final String optionText;

  final String? intervention;
  final CardSnapshot? destinationCard;
}

class CardSnapshot {
  const CardSnapshot({
    required this.id,
    required this.title,
    required this.situation,
    this.options = const <CardOptionSnapshot>[],
  });

  final int id;
  final String title;
  final String situation;
  final List<CardOptionSnapshot> options;

  bool get isLastRound {
    final upper = title.toUpperCase();
    if (RegExp(r'KAART\s*6').hasMatch(upper)) return true;
    if (options.isNotEmpty &&
        options.every((o) => o.destinationCard == null)) {
      return true;
    }
    return false;
  }
}

class GameSessionStorySnapshot {
  const GameSessionStorySnapshot({
    required this.id,
    required this.name,
    this.startingCard,
    this.cards = const <dynamic>[],
  });

  final int id;
  final String name;
  final Object? startingCard;
  final List<dynamic> cards;
}

class GameSessionStarted {
  const GameSessionStarted({
    required this.id,
    required this.joinCode,
    required this.status,
    required this.currentStory,
    required this.players,
    this.currentCard,
    required this.allVotesIn,
    this.votes = const <int, int>{},
  });

  final int id;
  final String joinCode;
  final String status;
  final GameSessionStorySnapshot currentStory;
  final List<GameSessionPlayer> players;
  final CardSnapshot? currentCard;
  final bool allVotesIn;

  /// Map of playerId -> cardOptionId for the current voting round.
  final Map<int, int> votes;
}

/// Parsed lobby or in-progress session from GET/POST session endpoints.
class GameSessionSnapshot {
  const GameSessionSnapshot({
    this.id,
    required this.joinCode,
    required this.status,
    required this.players,
    this.currentStory,
    this.currentCard,
    required this.allVotesIn,
    this.votes = const <int, int>{},
  });

  final int? id;
  final String joinCode;
  final String status;
  final List<GameSessionPlayer> players;
  final GameSessionStorySnapshot? currentStory;
  final CardSnapshot? currentCard;
  final bool allVotesIn;

  /// Map of playerId -> cardOptionId for the current voting round.
  final Map<int, int> votes;

  GameSessionStarted? get asStartedSessionOrNull {
    if (status != 'IN_PROGRESS') return null;
    if (id == null || currentStory == null) return null;
    return GameSessionStarted(
      id: id!,
      joinCode: joinCode,
      status: status,
      currentStory: currentStory!,
      players: players,
      currentCard: currentCard,
      allVotesIn: allVotesIn,
      votes: votes,
    );
  }

  List<String> participantLabels({int? selfPlayerId}) {
    final sorted = List<GameSessionPlayer>.from(players)
      ..sort((a, b) {
        if (a.isHost == b.isHost) return a.name.compareTo(b.name);
        return a.isHost ? -1 : 1;
      });
    return sorted.map((p) {
      final tags = <String>[];
      if (p.isHost) tags.add('Host');
      if (selfPlayerId != null && p.id == selfPlayerId) tags.add('Jij');
      return tags.isEmpty ? p.name : '${p.name} (${tags.join(', ')})';
    }).toList();
  }
}

GameSessionStorySnapshot? _currentStorySnapshotFromJsonNullable(Map<String, dynamic> json) {
  final raw = json['currentStory'];
  if (raw == null) return null;
  if (raw is! Map) return null;
  final m = Map<String, dynamic>.from(raw);
  final id = _intFromJson(m['id']);
  final name = m['name'];
  if (id == null || name is! String || name.trim().isEmpty) return null;
  final cardsRaw = m['cards'];
  final cards =
      cardsRaw is List<dynamic> ? List<dynamic>.from(cardsRaw) : const <dynamic>[];
  return GameSessionStorySnapshot(
    id: id,
    name: name.trim(),
    startingCard: m['startingCard'],
    cards: cards,
  );
}

CardSnapshot? _cardSnapshotFromJsonNullable(dynamic raw) {
  if (raw == null || raw is! Map) return null;
  final m = Map<String, dynamic>.from(raw);
  final id = _intFromJson(m['id']);
  final title = m['title'];
  final situation = m['situation'];
  if (id == null || title is! String || situation is! String) return null;
  final optionsRaw = m['options'];
  final options = <CardOptionSnapshot>[];
  if (optionsRaw is List<dynamic>) {
    for (final opt in optionsRaw) {
      final parsed = _cardOptionSnapshotFromJsonNullable(opt);
      if (parsed != null) options.add(parsed);
    }
  }
  return CardSnapshot(
    id: id,
    title: title.trim(),
    situation: situation.trim(),
    options: options,
  );
}

String? _interventionCodeFromJson(dynamic raw) {
  if (raw is String) {
    final code = raw.trim();
    return code.isEmpty ? null : code;
  }
  if (raw is Map) {
    final m = Map<String, dynamic>.from(raw);
    for (final key in <String>['name', 'code', 'id']) {
      final v = m[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
  }
  return null;
}

CardOptionSnapshot? _cardOptionSnapshotFromJsonNullable(dynamic raw) {
  if (raw == null || raw is! Map) return null;
  final m = Map<String, dynamic>.from(raw);
  final id = _intFromJson(m['id']);
  final optionText = m['optionText'];
  if (id == null || optionText is! String) return null;
  final destCard = _cardSnapshotFromJsonNullable(m['destinationCard']);
  return CardOptionSnapshot(
    id: id,
    optionText: optionText.trim(),
    intervention: _interventionCodeFromJson(m['intervention']),
    destinationCard: destCard,
  );
}

String? interventionImageAssetPath(String? interventionCode) {
  final code = interventionCode?.trim();
  if (code == null || code.isEmpty) return null;
  return 'assets/images/interventions/$code.jpeg';
}

GameSessionSnapshot _gameSessionSnapshotFromJson(
  Map<String, dynamic> decoded, {
  required String fallbackJoinCode,
}) {
  final join = (_joinCodeFromJson(decoded) ?? fallbackJoinCode).trim().toUpperCase();
  if (join.isEmpty) {
    throw Exception('Geen spelcode in antwoord');
  }
  final status = decoded['status'];
  if (status is! String || status.trim().isEmpty) {
    throw Exception('Ontbrekende sessiestatus');
  }
  final id = _intFromJson(decoded['id']);
  final players = _gameSessionPlayersFromJson(decoded);
  final story = _currentStorySnapshotFromJsonNullable(decoded);
  final allVotesIn = decoded['allVotesIn'] == true;
  final card = _cardSnapshotFromJsonNullable(decoded['currentCard']);
  final votes = _votesFromJson(decoded['votingRound']);
  return GameSessionSnapshot(
    id: id,
    joinCode: join,
    status: status.trim(),
    players: players,
    currentStory: story,
    currentCard: card,
    allVotesIn: allVotesIn,
    votes: votes,
  );
}

/// Parses `votingRound.votes` (a `{playerId: cardOptionId}` map) into
/// `Map<int, int>`. Returns an empty map when missing or malformed.
Map<int, int> _votesFromJson(dynamic votingRoundRaw) {
  if (votingRoundRaw is! Map) return const <int, int>{};
  final votingRound = Map<String, dynamic>.from(votingRoundRaw);
  final votesRaw = votingRound['votes'];
  if (votesRaw is! Map) return const <int, int>{};
  final out = <int, int>{};
  votesRaw.forEach((key, value) {
    final playerId = _intFromJson(key);
    final optionId = _intFromJson(value);
    if (playerId != null && optionId != null) {
      out[playerId] = optionId;
    }
  });
  return out;
}

GameSessionPlayer? _gameSessionPlayerFromJson(dynamic json) {
  if (json is! Map) return null;
  final m = Map<String, dynamic>.from(json);
  final id = _intFromJson(m['id']);
  final name = m['name'];
  if (id == null || name is! String || name.trim().isEmpty) return null;
  return GameSessionPlayer(
    id: id,
    name: name.trim(),
    isHost: m['isHost'] == true,
  );
}

List<GameSessionPlayer> _gameSessionPlayersFromJson(Map<String, dynamic> json) {
  final list = json['players'];
  if (list is! List<dynamic>) return const <GameSessionPlayer>[];
  final out = <GameSessionPlayer>[];
  for (final item in list) {
    final player = _gameSessionPlayerFromJson(item);
    if (player != null) out.add(player);
  }
  return out;
}

Future<GameSessionStarted> startGameSession({required String joinCode}) async {
  final code = joinCode.trim().toUpperCase();
  if (code.isEmpty) {
    throw Exception('Geen spelcode');
  }
  final uri = gameSessionStartUri(code);
  final response = await http.post(
    uri,
    headers: const {
      'Accept': '*/*',
      'Content-Type': 'application/json',
    },
    body: '{}',
  );
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(
      'Spel starten mislukt (${response.statusCode})',
    );
  }
  final decoded = jsonDecode(response.body);
  if (decoded is! Map<String, dynamic>) {
    throw Exception('Ongeldig antwoord van de server');
  }
  final snapshot = _gameSessionSnapshotFromJson(decoded, fallbackJoinCode: code);
  final started = snapshot.asStartedSessionOrNull;
  if (started == null) {
    throw Exception('Onvolledig sessie-antwoord');
  }
  return started;
}

Future<GameSessionSnapshot> fetchGameSession({required String joinCode}) async {
  final code = joinCode.trim().toUpperCase();
  if (!isValidJoinCodeFormat(code)) {
    throw Exception('Ongeldige spelcode');
  }
  final uri = gameSessionFetchUri(code);
  final response = await http.get(
    uri,
    headers: const {'Accept': '*/*'},
  );
  if (response.statusCode == 404) {
    throw Exception('Sessie niet gevonden');
  }
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Sessie ophalen mislukt (${response.statusCode})');
  }
  final decoded = jsonDecode(response.body);
  if (decoded is! Map<String, dynamic>) {
    throw Exception('Ongeldig antwoord van de server');
  }
  return _gameSessionSnapshotFromJson(decoded, fallbackJoinCode: code);
}

Future<GameSessionJoinResult> joinGameSession({
  required String joinCode,
  required String playerName,
}) async {
  final code = joinCode.trim().toUpperCase();
  if (!isValidJoinCodeFormat(code)) {
    throw Exception('Voer een geldige spelcode in (6 tekens)');
  }
  final name = playerName.trim();
  if (name.isEmpty) {
    throw Exception('Vul je naam in');
  }
  final uri = gameSessionsJoinUri(code);
  final response = await http.post(
    uri,
    headers: const {
      'Accept': '*/*',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(<String, dynamic>{'name': name}),
  );
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Meedoen mislukt (${response.statusCode})');
  }
  final decoded = jsonDecode(response.body);
  if (decoded is! Map<String, dynamic>) {
    throw Exception('Ongeldig antwoord van de server');
  }
  final sessionJson = decoded['session'];
  final sessionMap = sessionJson is Map<String, dynamic>
      ? sessionJson
      : (sessionJson is Map ? Map<String, dynamic>.from(sessionJson) : decoded);
  final snapshot = _gameSessionSnapshotFromJson(sessionMap, fallbackJoinCode: code);
  final selfPlayer = _gameSessionPlayerFromJson(decoded['player']);
  return GameSessionJoinResult(snapshot: snapshot, selfPlayer: selfPlayer);
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
  final players = _gameSessionPlayersFromJson(decoded);
  GameSessionPlayer? hostPlayer;
  for (final p in players) {
    if (p.isHost) {
      hostPlayer = p;
      break;
    }
  }
  List<String> labels;
  if (players.isNotEmpty) {
    final snapshot = GameSessionSnapshot(
      id: _intFromJson(decoded['id']),
      joinCode: code,
      status: 'LOBBY',
      players: players,
      allVotesIn: false,
    );
    labels = snapshot.participantLabels(selfPlayerId: hostPlayer?.id);
  } else {
    labels = _participantLabelsFromJson(decoded, hostName);
  }
  return GameSessionCreateResult(
    joinCode: code,
    participantLabels: labels,
    hostPlayer: hostPlayer,
  );
}

Future<GameSessionSnapshot> voteForCardOption({
  required String joinCode,
  required int playerId,
  required int cardOptionId,
}) async {
  final code = joinCode.trim().toUpperCase();
  if (code.isEmpty) {
    throw Exception('Geen spelcode');
  }
  final uri = gameSessionVoteUri(code);
  final response = await http.post(
    uri,
    headers: const {
      'Accept': '*/*',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(<String, dynamic>{
      'playerId': playerId,
      'cardOptionId': cardOptionId,
    }),
  );
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Stem uitbrengen mislukt (${response.statusCode})');
  }
  final decoded = jsonDecode(response.body);
  if (decoded is! Map<String, dynamic>) {
    throw Exception('Ongeldig antwoord van de server');
  }
  return _gameSessionSnapshotFromJson(decoded, fallbackJoinCode: code);
}

Future<GameSessionSnapshot> chooseCardOption({
  required String joinCode,
  required int playerId,
  required int cardOptionId,
}) async {
  final code = joinCode.trim().toUpperCase();
  if (code.isEmpty) {
    throw Exception('Geen spelcode');
  }
  final uri = gameSessionChooseUri(code);
  final response = await http.post(
    uri,
    headers: const {
      'Accept': '*/*',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(<String, dynamic>{
      'playerId': playerId,
      'cardOptionId': cardOptionId,
    }),
  );
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Keuze maken mislukt (${response.statusCode})');
  }
  final decoded = jsonDecode(response.body);
  if (decoded is! Map<String, dynamic>) {
    throw Exception('Ongeldig antwoord van de server');
  }
  return _gameSessionSnapshotFromJson(decoded, fallbackJoinCode: code);
}
