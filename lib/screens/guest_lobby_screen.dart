import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sociality/api/game_session_api.dart';
import 'package:sociality/screens/story_play_screen.dart';

const Color _kGuestLobbyNavy = Color(0xFF2A337E);
const Color _kGuestLobbyPink = Color(0xFFE9338F);

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

  @override
  void initState() {
    super.initState();
    _snapshot = widget.initialSnapshot;
    _maybeEnterGameplay(_snapshot);
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refreshSession());
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshSession());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
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
      // Keep showing last snapshot; next poll retries (multi-device resilience).
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
    final labels =
        _snapshot.participantLabels(selfPlayerId: widget.selfPlayerId);
    final count = labels.length;

    return Scaffold(
      backgroundColor: _kGuestLobbyNavy,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                color: Colors.white,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Je bent in de wachtkamer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Wacht tot de host het spel start.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Spelcode',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.joinCode.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Deelnemers',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$count ${count == 1 ? 'persoon' : 'personen'} in de sessie',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 12,
                      runSpacing: 10,
                      children: labels
                          .map(
                            (name) => Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _kGuestLobbyPink.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Live bijgewerkt',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
