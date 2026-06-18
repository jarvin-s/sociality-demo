import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sociality/api/game_session_api.dart';
import 'package:sociality/services/player_identity.dart';

const Color _kPink = Color(0xFFEA1F86);
const Color _kNavyDeep = Color(0xFF1F2070);
const Color _kPanelSurface = Color(0xFFF5E9DF);
const Color _kSelectedBorder = Color(0xFF2ECC71);

class _WedgeClipper extends CustomClipper<Path> {
  const _WedgeClipper(this.rightCut);
  final double rightCut;

  @override
  Path getClip(Size size) => Path()
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height * rightCut)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_WedgeClipper o) => o.rightCut != rightCut;
}

enum _GamePhase {
  choosing,
  waitingForVotes,
  results,
  debateVote,
  debateVoteResult,
  debateIntro,
  debate,
  revote,
  waitingForRevotes,
  hostChoosing,
  waitingForHost,
  finalResult,
}

class StoryPlayScreen extends StatefulWidget {
  const StoryPlayScreen({super.key, this.session});

  final GameSessionStarted? session;

  @override
  State<StoryPlayScreen> createState() => _StoryPlayScreenState();
}

class _StoryPlayScreenState extends State<StoryPlayScreen>
    with TickerProviderStateMixin {
  _GamePhase _phase = _GamePhase.choosing;
  int? _selectedOptionId;
  int? _revoteOptionId;
  bool _submittingVote = false;
  bool _submittingChoose = false;

  bool? _debateVoteChoice;

  static const int _debateDuration = 90;
  int _timerSeconds = _debateDuration;
  Timer? _debateTimer;
  Timer? _pollTimer;

  late final AnimationController _introController;
  late final Animation<Offset> _introSlide;

  GameSessionPlayer? _selfPlayer;
  List<GameSessionPlayer> _players = const [];
  CardSnapshot? _currentCard;
  bool _allVotesIn = false;
  int? _lastCardId;
  Map<int, int> _votes = const <int, int>{};
  bool _areVotesLocked = false;

  String? _interventionCode;
  CardSnapshot? _pendingNextCard;
  bool _pendingEndGame = false;

  bool get _isHost => _selfPlayer?.isHost ?? false;
  String get _joinCode => widget.session?.joinCode ?? '';
  bool get _isGameComplete => _phase == _GamePhase.finalResult;

  bool _isLastRoundCard(CardSnapshot? card) => card?.isLastRound ?? false;

  void _enterGameWon() {
    _pollTimer?.cancel();
    _phase = _GamePhase.finalResult;
    _submittingChoose = false;
    _submittingVote = false;
  }

  Future<void> _returnToSituationChoosing() async {
    _pollTimer?.cancel();
    await clearPlayerIdentity();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/config', (_) => false);
  }

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _introSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _introController, curve: Curves.easeOut));

    _currentCard = widget.session?.currentCard;
    _allVotesIn = widget.session?.allVotesIn ?? false;
    _lastCardId = _currentCard?.id;
    _players = widget.session?.players ?? const [];
    _votes = widget.session?.votes ?? const <int, int>{};
    _areVotesLocked = widget.session?.areVotesLocked ?? false;

    if (_isLastRoundCard(_currentCard) && (_currentCard?.options.isEmpty ?? true)) {
      _phase = _GamePhase.finalResult;
    } else if (_areVotesLocked) {
      _phase = _GamePhase.results;
    }

    _loadIdentityAndStartPolling();
  }

  Future<void> _loadIdentityAndStartPolling() async {
    final player = await loadPlayerIdentity();
    if (!mounted) return;
    setState(() => _selfPlayer = player);
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    if (_joinCode.isEmpty) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  Future<void> _poll() async {
    if (!mounted || _joinCode.isEmpty || _isGameComplete || _interventionCode != null) {
      return;
    }
    try {
      final snap = await fetchGameSession(joinCode: _joinCode);
      if (!mounted) return;

      final newCard = snap.currentCard;
      final cardChanged = newCard != null && newCard.id != _lastCardId;
      final sessionEnded = newCard == null && _isLastRoundCard(_currentCard);

      setState(() {
        final oldCard = _currentCard;
        _allVotesIn = snap.allVotesIn;
        _areVotesLocked = snap.areVotesLocked;
        _votes = snap.votes;
        if (snap.players.isNotEmpty) _players = snap.players;

        if (cardChanged && _interventionCode == null) {
          final intervention = _interventionForCardTransition(oldCard, newCard);
          final assetPath = interventionImageAssetPath(intervention);
          if (intervention != null && assetPath != null) {
            _interventionCode = intervention;
            _pendingNextCard = newCard;
            _pendingEndGame = false;
            _lastCardId = newCard.id;
            _submittingChoose = false;
            _submittingVote = false;
          } else {
            _currentCard = newCard;
            _lastCardId = newCard.id;
            _resetForNewCard();
            if (_isLastRoundCard(newCard) && newCard.options.isEmpty) {
              _enterGameWon();
            }
          }
        } else if (sessionEnded) {
          _enterGameWon();
        } else if (newCard != null && _interventionCode == null) {
          _currentCard = newCard;
        }

        if (snap.areVotesLocked && _interventionCode == null && !_isGameComplete) {
          _submittingChoose = false;
          _phase = _GamePhase.results;
        }
      });

      _handlePhaseTransitions();
    } catch (_) {}
  }

  void _resetForNewCard() {
    _phase = _GamePhase.choosing;
    _selectedOptionId = null;
    _revoteOptionId = null;
    _debateVoteChoice = null;
    _submittingVote = false;
    _submittingChoose = false;
    _votes = const <int, int>{};
    _areVotesLocked = false;
    _debateTimer?.cancel();
  }

  void _handlePhaseTransitions() {
    if (_isGameComplete) return;
    if (_phase == _GamePhase.waitingForVotes && _allVotesIn) {
      setState(() {
        _phase = _isHost ? _GamePhase.results : _GamePhase.waitingForHost;
      });
    }
    if (_phase == _GamePhase.waitingForRevotes && _allVotesIn) {
      setState(() {
        _phase = _isHost ? _GamePhase.results : _GamePhase.waitingForHost;
      });
    }
  }

  @override
  void dispose() {
    _debateTimer?.cancel();
    _pollTimer?.cancel();
    _introController.dispose();
    clearPlayerIdentity();
    super.dispose();
  }

  Future<void> _submitVote(int cardOptionId) async {
    final player = _selfPlayer;
    if (player == null || _joinCode.isEmpty || _areVotesLocked) return;
    setState(() {
      _selectedOptionId = cardOptionId;
      _submittingVote = true;
    });
    try {
      final snap = await voteForCardOption(
        joinCode: _joinCode,
        playerId: player.id,
        cardOptionId: cardOptionId,
      );
      if (!mounted) return;
      setState(() {
        _submittingVote = false;
        _allVotesIn = snap.allVotesIn;
        _votes = snap.votes;
        if (snap.players.isNotEmpty) _players = snap.players;
        // Players stay in the choosing phase so they can keep switching their
        // answer until the host locks the answers in.
        _phase = _GamePhase.choosing;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submittingVote = false;
        _selectedOptionId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _lockInAnswers() async {
    final player = _selfPlayer;
    if (player == null || !_isHost || _joinCode.isEmpty) return;
    setState(() => _submittingChoose = true);
    try {
      final snap = await lockGameSessionVotes(
        joinCode: _joinCode,
        playerId: player.id,
      );
      if (!mounted) return;
      setState(() {
        _votes = snap.votes;
        _areVotesLocked = snap.areVotesLocked;
        if (snap.players.isNotEmpty) _players = snap.players;
        _submittingChoose = false;
        _phase = _GamePhase.results;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submittingChoose = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _submitRevote(int cardOptionId) async {
    final player = _selfPlayer;
    if (player == null || _joinCode.isEmpty) return;
    setState(() {
      _revoteOptionId = cardOptionId;
      _submittingVote = true;
    });
    try {
      final snap = await voteForCardOption(
        joinCode: _joinCode,
        playerId: player.id,
        cardOptionId: cardOptionId,
      );
      if (!mounted) return;
      setState(() {
        _submittingVote = false;
        _allVotesIn = snap.allVotesIn;
        _votes = snap.votes;
        if (snap.players.isNotEmpty) _players = snap.players;
        _phase = snap.allVotesIn
            ? (_isHost ? _GamePhase.results : _GamePhase.waitingForHost)
            : _GamePhase.waitingForRevotes;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submittingVote = false;
        _revoteOptionId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _submitChoose(int cardOptionId) async {
    final player = _selfPlayer;
    if (player == null || _joinCode.isEmpty) return;
    final intervention = _interventionForOptionId(cardOptionId);
    setState(() => _submittingChoose = true);
    try {
      final snap = await chooseCardOption(
        joinCode: _joinCode,
        playerId: player.id,
        cardOptionId: cardOptionId,
      );
      if (!mounted) return;
      final newCard = snap.currentCard;
      final endGame = newCard == null && _isLastRoundCard(_currentCard);
      final assetPath = interventionImageAssetPath(intervention);
      if (intervention != null && assetPath != null) {
        _showInterventionThenAdvance(
          interventionCode: intervention,
          nextCard: newCard,
          endGame: endGame,
          allVotesIn: snap.allVotesIn,
          votes: snap.votes,
        );
        return;
      }
      if (endGame) {
        setState(_enterGameWon);
        return;
      }
      setState(() {
        _submittingChoose = false;
        _currentCard = newCard;
        _allVotesIn = snap.allVotesIn;
        if (newCard != null) _lastCardId = newCard.id;
        _resetForNewCard();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submittingChoose = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _startDebate() {
    setState(() => _phase = _GamePhase.debateIntro);
    _introController.forward();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      _introController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _phase = _GamePhase.debate;
          _timerSeconds = _debateDuration;
        });
        _debateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) return;
          setState(() => _timerSeconds--);
          if (_timerSeconds <= 0) {
            timer.cancel();
            setState(() => _phase = _GamePhase.revote);
          }
        });
      });
    });
  }

  void _skipDebate() {
    _debateTimer?.cancel();
    setState(() => _phase = _GamePhase.revote);
  }

  String get _sceneTitle {
    final cardTitle = _currentCard?.title.trim();
    if (cardTitle != null && cardTitle.isNotEmpty) {
      return cardTitle.toUpperCase();
    }
    final name = widget.session?.currentStory.name.trim();
    if (name != null && name.isNotEmpty) {
      return 'HET ${name.toUpperCase()}';
    }
    return 'VERHAAL';
  }

  String get _situationText {
    return _currentCard?.situation ?? '';
  }

  List<CardOptionSnapshot> get _options => _currentCard?.options ?? [];

  String? _interventionForOptionId(int optionId) {
    for (final opt in _options) {
      if (opt.id == optionId) return opt.intervention;
    }
    return null;
  }

  String? _interventionForCardTransition(CardSnapshot? from, CardSnapshot? to) {
    if (from == null || to == null) return null;
    for (final opt in from.options) {
      if (opt.destinationCard?.id == to.id) return opt.intervention;
    }
    return null;
  }

  void _showInterventionThenAdvance({
    required String interventionCode,
    required CardSnapshot? nextCard,
    required bool endGame,
    bool allVotesIn = false,
    Map<int, int> votes = const <int, int>{},
  }) {
    setState(() {
      _interventionCode = interventionCode;
      _pendingNextCard = nextCard;
      _pendingEndGame = endGame;
      _allVotesIn = allVotesIn;
      _votes = votes;
      _submittingChoose = false;
      _submittingVote = false;
      if (nextCard != null) _lastCardId = nextCard.id;
    });
  }

  void _completeIntervention() {
    final nextCard = _pendingNextCard;
    final endGame = _pendingEndGame;
    setState(() {
      _interventionCode = null;
      _pendingNextCard = null;
      _pendingEndGame = false;
      if (endGame) {
        _enterGameWon();
        return;
      }
      _currentCard = nextCard;
      if (nextCard != null) _lastCardId = nextCard.id;
      _resetForNewCard();
      if (_isLastRoundCard(nextCard) && (nextCard?.options.isEmpty ?? true)) {
        _enterGameWon();
      }
    });
  }

  int _voteCountFor(int optionId) =>
      _votes.values.where((v) => v == optionId).length;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final showBack = widget.session == null;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _kNavyDeep,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;

            return Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: h * 0.34,
                  child: ClipPath(
                    clipper: const _WedgeClipper(0.84),
                    child: Container(color: _kPink),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: showBack ? 52 : 8),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 4, 28, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _sceneTitle,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                  height: 0.95,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildSituationCard(),
                              if (_interventionCode != null) ...[
                                const SizedBox(height: 20),
                                _buildInterventionShowcase(),
                              ],
                            ],
                          ),
                        ),
                      ),
                      _buildBottomPanel(context),
                    ],
                  ),
                ),
                if (showBack)
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
                if (_phase == _GamePhase.debateIntro)
                  SlideTransition(
                    position: _introSlide,
                    child: Container(
                      color: _kNavyDeep,
                      child: Image.asset(
                        'assets/images/debat.png',
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSituationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _situationText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Colors.black.withValues(alpha: 0.92),
            ),
          ),
          if (_isGameComplete) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _kPink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Gefeliciteerd! Jullie hebben het verhaal voltooid.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInterventionShowcase() {
    final assetPath = interventionImageAssetPath(_interventionCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Interventie',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: assetPath == null
              ? Container(
                  height: 160,
                  color: Colors.white.withValues(alpha: 0.08),
                  alignment: Alignment.center,
                  child: Text(
                    'Interventiekaart niet gevonden',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                )
              : Image.asset(
                  assetPath,
                  fit: BoxFit.fitWidth,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: Colors.white.withValues(alpha: 0.08),
                    alignment: Alignment.center,
                    child: Text(
                      'Interventiekaart niet gevonden',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kPanelSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        28,
        22,
        28,
        22 + MediaQuery.paddingOf(context).bottom,
      ),
      child: _interventionCode != null
          ? _buildInterventionContinuePanel()
          : switch (_phase) {
        _GamePhase.choosing || _GamePhase.debateIntro => _buildChoosingPanel(),
        _GamePhase.waitingForVotes => _buildWaitingPanel(),
        _GamePhase.results => _buildResultsPanel(),
        _GamePhase.debateVote => _buildDebateVotePanel(),
        _GamePhase.debateVoteResult => _buildDebateVoteResultPanel(),
        _GamePhase.debate => _buildDebatePanel(),
        _GamePhase.revote => _buildRevotePanel(),
        _GamePhase.waitingForRevotes => _buildWaitingPanel(),
        _GamePhase.hostChoosing => _buildHostChoosingPanel(),
        _GamePhase.waitingForHost => _buildWaitingForHostPanel(),
        _GamePhase.finalResult => SizedBox(
          width: double.infinity,
          height: MediaQuery.sizeOf(context).height * 0.36,
          child: _buildFinalResultPanel(),
        ),
      },
    );
  }

  Widget _buildInterventionContinuePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Lees de interventiekaart',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Bespreek de kaart met de groep. Ga daarna door naar de volgende situatie.',
          style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _completeIntervention,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Ga verder',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoosingPanel() {
    if (_isGameComplete) return _buildFinalResultPanel();
    final opts = _options;
    if (opts.isEmpty) {
      if (_isLastRoundCard(_currentCard)) {
        return _buildFinalResultPanel();
      }
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Wat doe je?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < opts.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _StoryChoiceButton(
            label: opts[i].optionText,
            isSelected: opts[i].id == _selectedOptionId,
            isDisabled: _submittingVote && opts[i].id != _selectedOptionId,
            onPressed: (_submittingVote || _submittingChoose)
                ? null
                : () => _submitVote(opts[i].id),
          ),
        ],
        const SizedBox(height: 18),
        if (_isHost && !_areVotesLocked)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submittingChoose ? null : _lockInAnswers,
              icon: const Icon(Icons.lock_rounded, size: 20),
              label: const Text(
                'ANTWOORDEN VERGRENDELEN',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kNavyDeep,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _kNavyDeep.withValues(alpha: 0.3),
                disabledForegroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          )
        else
          Text(
            _selectedOptionId == null
                ? 'Kies een antwoord. Je kunt nog wisselen tot de host vergrendelt.'
                : 'Je kunt je antwoord nog wijzigen tot de host vergrendelt.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
          ),
        if (_submittingChoose) ...[
          const SizedBox(height: 16),
          const Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: _kPink),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWaitingPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Wachten op andere spelers...',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 18),
        for (final opt in _options)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _StoryChoiceButton(
              label: opt.optionText,
              isSelected: opt.id == _selectedOptionId || opt.id == _revoteOptionId,
              isDisabled: opt.id != _selectedOptionId && opt.id != _revoteOptionId,
              onPressed: null,
            ),
          ),
        const SizedBox(height: 8),
        const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _kPink),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsPanel() {
    if (_isGameComplete) return _buildFinalResultPanel();
    final opts = _options;
    final onLastRound = _isLastRoundCard(_currentCard);
    final voteTotal = _players.isEmpty ? _votes.length : _players.length;
    final showVoteCounts = _areVotesLocked && voteTotal > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Antwoorden vergrendeld!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 16),
        Text(
          _isHost
              ? (onLastRound
                  ? 'Kies de afsluiting — daarna is het verhaal klaar:'
                  : 'Kies welke optie de groep volgt:')
              : 'De host kiest nu welke optie de groep volgt.',
          style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < opts.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _StoryChoiceButton(
            label: opts[i].optionText,
            isSelected: false,
            isDisabled: !_isHost || _submittingChoose,
            voteCount: showVoteCounts ? _voteCountFor(opts[i].id) : null,
            voteTotal: showVoteCounts ? voteTotal : null,
            onPressed:
                !_isHost || _submittingChoose ? null : () => _submitChoose(opts[i].id),
          ),
        ],
        if (_submittingChoose || !_isHost) ...[
          const SizedBox(height: 16),
          const Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: _kPink),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDebateVotePanel() {
    final voted = _debateVoteChoice != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          voted ? 'Wachten op andere spelers...' : 'Wil jij debatteren?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: voted ? Colors.black54 : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        if (!voted)
          const Text(
            'De stemmen liggen dicht bij elkaar. Wil de groep een debat voeren?',
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
          ),
        const SizedBox(height: 20),
        _DebateVoteButton(
          label: 'Ja, debatteren!',
          icon: Icons.thumb_up_rounded,
          isSelected: _debateVoteChoice == true,
          isDisabled: voted && _debateVoteChoice != true,
          color: _kNavyDeep,
          onPressed: voted ? null : () => setState(() => _debateVoteChoice = true),
        ),
        const SizedBox(height: 12),
        _DebateVoteButton(
          label: 'Nee, overslaan',
          icon: Icons.thumb_down_rounded,
          isSelected: _debateVoteChoice == false,
          isDisabled: voted && _debateVoteChoice != false,
          color: Colors.black54,
          onPressed: voted ? null : () => setState(() => _debateVoteChoice = false),
        ),
        if (voted) ...[
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => setState(() => _phase = _GamePhase.debateVoteResult),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPink,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Bekijk resultaat',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDebateVoteResultPanel() {
    final yesWins = _debateVoteChoice == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Wil de groep debatteren?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: yesWins ? Colors.green.shade100 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: yesWins ? Colors.green.shade300 : Colors.red.shade200,
            ),
          ),
          child: Text(
            yesWins
                ? 'De groep wil debatteren! Start de debatronde.'
                : 'De groep wil geen debat. Stem direct opnieuw.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: yesWins
              ? _startDebate
              : () => setState(() => _phase = _GamePhase.revote),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPink,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            yesWins ? 'Start debatronde' : 'Sla debat over',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDebatePanel() {
    final double progress = _timerSeconds / _debateDuration;
    final opts = _options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DEBAT',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _kPink,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Omdat de antwoorden dicht bij elkaar liggen, gaan we een debat voeren. Per groep leg je uit waarom jouw keuze de meest logische is. Daarna stemmen jullie opnieuw.',
                    style: TextStyle(fontSize: 14, height: 1.45, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    backgroundColor: Colors.black12,
                    valueColor: AlwaysStoppedAnimation(
                      _timerSeconds <= 10 ? Colors.red : _kNavyDeep,
                    ),
                  ),
                  Center(
                    child: Text(
                      '$_timerSeconds',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _timerSeconds <= 10 ? Colors.red : _kNavyDeep,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Wat doe je?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < opts.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _StoryChoiceButton(label: opts[i].optionText, isSelected: false, isDisabled: true, onPressed: null),
        ],
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: _skipDebate,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black54,
            side: const BorderSide(color: Colors.black26),
          ),
          child: const Text('Overslaan'),
        ),
      ],
    );
  }

  Widget _buildRevotePanel() {
    final opts = _options;
    if (opts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Stem opnieuw!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < opts.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _StoryChoiceButton(
            label: opts[i].optionText,
            isSelected: false,
            isDisabled: _submittingVote,
            onPressed: _submittingVote ? null : () => _submitRevote(opts[i].id),
          ),
        ],
      ],
    );
  }

  Widget _buildHostChoosingPanel() {
    final opts = _options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Kies de volgende kaart',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < opts.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _StoryChoiceButton(
            label: opts[i].optionText,
            isSelected: false,
            isDisabled: _submittingChoose,
            onPressed: _submittingChoose ? null : () => _submitChoose(opts[i].id),
          ),
        ],
        if (_submittingChoose) ...[
          const SizedBox(height: 16),
          const Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: _kPink),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWaitingForHostPanel() {
    if (_isGameComplete) return _buildFinalResultPanel();
    final voteTotal = _areVotesLocked
        ? (_players.isEmpty ? _votes.length : _players.length)
        : null;
    final showVoteCounts = _areVotesLocked && (voteTotal ?? 0) > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _areVotesLocked ? 'Antwoorden vergrendeld!' : 'Alle stemmen zijn binnen!',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 16),
        const Text(
          'Wachten tot de host een keuze maakt...',
          style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
        ),
        const SizedBox(height: 16),
        for (final opt in _options)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _StoryChoiceButton(
              label: opt.optionText,
              isSelected: false,
              isDisabled: true,
              voteCount: showVoteCounts ? _voteCountFor(opt.id) : null,
              voteTotal: showVoteCounts ? voteTotal : null,
              onPressed: null,
            ),
          ),
        const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _kPink),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalResultPanel() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              size: 52,
              color: _kPink,
            ),
            const SizedBox(height: 20),
            const Text(
              'Spel afgerond!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Jullie hebben het verhaal samen doorlopen. Goed gedaan!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _returnToSituationChoosing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Terug naar situatiekeuze',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebateVoteButton extends StatelessWidget {
  const _DebateVoteButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDisabled,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDisabled;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDisabled ? 0.35 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _kSelectedBorder : color.withValues(alpha: 0.4),
                width: isSelected ? 3 : 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isSelected ? Colors.white : color, size: 22),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, color: _kSelectedBorder, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryChoiceButton extends StatelessWidget {
  const _StoryChoiceButton({
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    required this.onPressed,
    this.voteCount,
    this.voteTotal,
  });

  final String label;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onPressed;
  final int? voteCount;
  final int? voteTotal;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDisabled ? 0.35 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _kPink,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: _kSelectedBorder, width: 3)
                  : null,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 88),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle, color: _kSelectedBorder, size: 22),
                        ],
                      ],
                    ),
                  ),
                  if (voteCount != null && voteTotal != null)
                    Positioned(
                      top: 8,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person,  
                              size: 16,
                              color: _kNavyDeep,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$voteCount/$voteTotal',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _kNavyDeep,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
