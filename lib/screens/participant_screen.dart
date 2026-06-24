import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sociality/api/game_session_api.dart';
import 'package:sociality/screens/story_play_screen.dart';
import 'package:sociality/services/player_identity.dart';
import 'package:sociality/widgets/lobby_sections.dart';

const Color _kPink = Color(0xFFEA1F86);

class ParticipantScreen extends StatefulWidget {
  const ParticipantScreen({
    super.key,
    required this.hostName,
    required this.currentStory,
  });

  final String hostName;
  final int currentStory;

  @override
  State<ParticipantScreen> createState() => _ParticipantScreenState();
}

class _ParticipantScreenState extends State<ParticipantScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _startingGame = false;
  String? _error;
  String? _gameCode;
  int? _hostPlayerId;
  List<String> _participants = const <String>[];
  Timer? _pollTimer;

  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _startSession();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _beginPollingParticipants() {
    _pollTimer?.cancel();
    final code = _gameCode;
    if (code == null || code.isEmpty) return;
    final normalized = code.trim().toUpperCase();
    _primeParticipantFetch(normalized);
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted) return;
      try {
        final snap = await fetchGameSession(joinCode: normalized);
        if (!mounted) return;
        final selfId = _hostPlayerId ?? _inferHostIdFromSnapshot(snap);
        final labels = snap.participantLabels(selfPlayerId: selfId);
        if (labels.isEmpty) return;
        setState(() {
          if (selfId != null && _hostPlayerId == null) _hostPlayerId = selfId;
          _participants = labels;
        });
      } catch (_) {}
    });
  }

  int? _inferHostIdFromSnapshot(GameSessionSnapshot snap) {
    for (final p in snap.players) {
      if (p.isHost) return p.id;
    }
    return null;
  }

  Future<void> _primeParticipantFetch(String normalized) async {
    try {
      final snap = await fetchGameSession(joinCode: normalized);
      if (!mounted) return;
      final selfId = _hostPlayerId ?? _inferHostIdFromSnapshot(snap);
      final labels = snap.participantLabels(selfPlayerId: selfId);
      if (labels.isEmpty) return;
      setState(() {
        if (selfId != null && _hostPlayerId == null) _hostPlayerId = selfId;
        _participants = labels;
      });
    } catch (_) {}
  }

  Future<void> _startSession() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await clearPlayerIdentity();
      final result = await createGameSession(
        currentStory: widget.currentStory,
        hostName: widget.hostName,
      );
      final host = result.hostPlayer;
      if (host != null) {
        await savePlayerIdentity(host);
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _gameCode = result.joinCode;
        _hostPlayerId = result.hostPlayerId;
        _participants = result.participantLabels.isNotEmpty
            ? result.participantLabels
            : <String>['${widget.hostName} (Host, Jij)'];
        _error = null;
      });
      _beginPollingParticipants();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _onStartGame() async {
    final code = _gameCode;
    if (code == null || code.isEmpty) return;
    _pollTimer?.cancel();
    setState(() => _startingGame = true);
    try {
      final session = await startGameSession(joinCode: code);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (context) => StoryPlayScreen(session: session),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      setState(() => _startingGame = false);
      _beginPollingParticipants();
    }
  }

  String get _joinQrPayload =>
      'https://sociality-demo.vercel.app/join?code=${_gameCode ?? ''}';

  @override
  Widget build(BuildContext context) {
    return LobbyShell(
      fade: _fade,
      child: _loading
          ? const _LobbyLoadingBody()
          : _error != null
              ? _LobbyErrorBody(
                  message: _error!,
                  onRetry: _startSession,
                )
              : _LobbyReadyBody(
                  gameCode: _gameCode!,
                  joinQrPayload: _joinQrPayload,
                  participants: _participants,
                  startingGame: _startingGame,
                  onStartGame: _onStartGame,
                ),
    );
  }
}

class _LobbyLoadingBody extends StatelessWidget {
  const _LobbyLoadingBody();

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(28, topPad + 90, 28, 24 + bottomPad),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10),
          Text(
            'Lobby',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              letterSpacing: -2,
              height: 0.93,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Sessie wordt aangemaakt…',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white,
              height: 1.35,
            ),
          ),
          Spacer(),
          Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          Spacer(),
        ],
      ),
    );
  }
}

class _LobbyErrorBody extends StatelessWidget {
  const _LobbyErrorBody({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(28, topPad + 90, 28, 24 + bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            'Lobby',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              letterSpacing: -2,
              height: 0.93,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Er ging iets mis bij het aanmaken van de sessie.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.35,
            ),
          ),
          const Spacer(),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _NextButton(label: 'Opnieuw proberen', onTap: onRetry),
          const Spacer(),
        ],
      ),
    );
  }
}

class _LobbyReadyBody extends StatelessWidget {
  const _LobbyReadyBody({
    required this.gameCode,
    required this.joinQrPayload,
    required this.participants,
    required this.startingGame,
    required this.onStartGame,
  });

  final String gameCode;
  final String joinQrPayload;
  final List<String> participants;
  final bool startingGame;
  final VoidCallback onStartGame;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(28, topPad + 90, 28, 24 + bottomPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Lobby',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                  height: 0.93,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Deel de spelcode of QR-code zodat anderen kunnen meedoen.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.35,
                ),
              ),
              SizedBox(height: h * 0.08),
              Center(
                child: LobbyGameCodeDisplay(code: gameCode),
              ),
              const SizedBox(height: 28),
              Center(
                child: LobbyQrDisplay(payload: joinQrPayload),
              ),
              const SizedBox(height: 28),
              LobbyParticipantsGroup(names: participants),
              const SizedBox(height: 14),
              const LobbyLiveIndicator(),
              const SizedBox(height: 28),
              _NextButton(
                label: 'Starten',
                busy: startingGame,
                onTap: onStartGame,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NextButton extends StatefulWidget {
  const _NextButton({
    required this.label,
    required this.onTap,
    this.busy = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool busy;

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.busy ? 0.55 : 1,
      child: GestureDetector(
        onTap: widget.busy ? null : widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: _kPink,
              borderRadius: BorderRadius.circular(50),
            ),
            alignment: Alignment.center,
            child: widget.busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
