import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sociality/api/game_session_api.dart';
import 'package:sociality/screens/story_play_screen.dart';

const Color _kParticipantNavy = Color(0xFF2A337E);
const Color _kParticipantPink = Color(0xFFE9338F);

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

class _ParticipantScreenState extends State<ParticipantScreen> {
  bool _loading = true;
  bool _startingGame = false;
  String? _error;
  String? _gameCode;
  List<String> _participants = const <String>[];
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
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
        final labels = snap.participantLabels;
        if (labels.isEmpty) return;
        setState(() => _participants = labels);
      } catch (_) {}
    });
  }

  Future<void> _primeParticipantFetch(String normalized) async {
    try {
      final snap = await fetchGameSession(joinCode: normalized);
      if (!mounted) return;
      final labels = snap.participantLabels;
      if (labels.isEmpty) return;
      setState(() => _participants = labels);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  Future<void> _startSession() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await createGameSession(
        currentStory: widget.currentStory,
        hostName: widget.hostName,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _gameCode = result.joinCode;
        _participants = result.participantLabels ??
            <String>['${widget.hostName} (Host)'];
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
    }
  }

  String get _joinQrPayload => 'https://sociality-demo.vercel.app/join?code=${_gameCode ?? ''}';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _kParticipantNavy,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: Colors.white,
                  tooltip:
                      MaterialLocalizations.of(context).backButtonTooltip,
                ),
              ),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: _kParticipantNavy,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: Colors.white,
                  tooltip:
                      MaterialLocalizations.of(context).backButtonTooltip,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E8C),
                        ),
                        onPressed: _startSession,
                        child: const Text('Opnieuw proberen'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final code = _gameCode!;
    final count = _participants.length;

    return Scaffold(
      backgroundColor: _kParticipantNavy,
      body: SafeArea(
        child: Column(
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
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 250,
                        height: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const _ParticipantLogoFallback();
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Spelcode',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 10,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 33, 33, 33),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        code,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Scan om mee te doen',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: _joinQrPayload,
                          version: QrVersions.auto,
                          size: 168,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF2A337E),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF2A337E),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
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
                      '$count personen aangemeld',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 12,
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 12,
                        runSpacing: 10,
                        children: _participants
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
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _StartenButton(
                isLoading: _startingGame,
                onPressed: _startingGame ? null : _onStartGame,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantLogoFallback extends StatelessWidget {
  const _ParticipantLogoFallback();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.favorite,
          size: 100,
          color: _kParticipantPink,
        ),
        const SizedBox(height: 4),
        Text(
          'SOCIALITY',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _kParticipantPink,
            letterSpacing: 0.5,
            shadows: const [
              Shadow(
                color: Colors.white,
                offset: Offset(1.5, 1.5),
                blurRadius: 0,
              ),
              Shadow(
                color: Colors.white,
                offset: Offset(-1.5, -1.5),
                blurRadius: 0,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StartenButton extends StatelessWidget {
  const _StartenButton({
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            color: _kParticipantPink,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B1A50).withOpacity(0.55),
                offset: const Offset(0, 5),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    height: 26,
                    width: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Starten',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
