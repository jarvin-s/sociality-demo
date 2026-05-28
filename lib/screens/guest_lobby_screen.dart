import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sociality/api/game_session_api.dart';
import 'package:sociality/screens/story_play_screen.dart';
import 'package:sociality/services/player_identity.dart';

const Color _kNavyDeep = Color(0xFF1F2070);

class GuestLobbyScreen extends StatefulWidget {
  const GuestLobbyScreen({
    super.key,
    required this.joinCode,
    required this.initialSnapshot,
    this.selfPlayerId,
  });

  final String joinCode;
  final GameSessionSnapshot initialSnapshot;
  final int? selfPlayerId;

  @override
  State<GuestLobbyScreen> createState() => _GuestLobbyScreenState();
}

class _GuestLobbyScreenState extends State<GuestLobbyScreen> {
  static const Duration _pollInterval = Duration(seconds: 2);

  late GameSessionSnapshot _snapshot;
  Timer? _pollTimer;
  bool _navigatedToPlay = false;
  String? _playerName;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.initialSnapshot;
    _loadPlayerName();
    _maybeEnterGameplay(_snapshot);
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refreshSession());
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshSession());
  }

  Future<void> _loadPlayerName() async {
    final player = await loadPlayerIdentity();
    if (!mounted) return;
    setState(() => _playerName = player?.name);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    if (!_navigatedToPlay) {
      clearPlayerIdentity();
    }
    super.dispose();
  }

  Future<void> _refreshSession() async {
    if (!mounted || _navigatedToPlay) return;
    try {
      final next =
          await fetchGameSession(joinCode: widget.joinCode.toUpperCase());
      if (!mounted || _navigatedToPlay) return;
      setState(() => _snapshot = next);
      _maybeEnterGameplay(next);
    } catch (_) {
      // Keep polling; next attempt retries.
    }
  }

  void _maybeEnterGameplay(GameSessionSnapshot s) {
    if (_navigatedToPlay) return;
    final started = s.asStartedSessionOrNull;
    if (started == null) return;
    _navigatedToPlay = true;
    _pollTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (context) => StoryPlayScreen(session: started),
        ),
        (route) => route.isFirst,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: _kNavyDeep,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _playerName ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2,
                      height: 0.93,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Wacht tot de host het spel start.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: topPad + 12,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
