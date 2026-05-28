import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sociality/api/game_session_api.dart';
import 'package:sociality/services/player_identity.dart';

const Color _kStoryNavy = Color(0xFF29367C);
const Color _kStoryPink = Color(0xFFE4318C);
const Color _kStoryCardBeige = Color(0xFFF5E9DF);
const Color _kStorySelectedBorder = Color(0xFF2ECC71);

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

    if (_isLastRoundCard(_currentCard) && (_currentCard?.options.isEmpty ?? true)) {
      _phase = _GamePhase.finalResult;
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
    if (!mounted || _joinCode.isEmpty || _isGameComplete) return;
    try {
      final snap = await fetchGameSession(joinCode: _joinCode);
      if (!mounted) return;

      final newCard = snap.currentCard;
      final cardChanged = newCard != null && newCard.id != _lastCardId;
      final sessionEnded = newCard == null && _isLastRoundCard(_currentCard);

      setState(() {
        if (newCard != null) {
          _currentCard = newCard;
        }
        _allVotesIn = snap.allVotesIn;
        _votes = snap.votes;
        if (snap.players.isNotEmpty) _players = snap.players;

        if (cardChanged) {
          _lastCardId = newCard.id;
          _resetForNewCard();
          if (_isLastRoundCard(newCard) && newCard.options.isEmpty) {
            _enterGameWon();
          }
        } else if (sessionEnded) {
          _enterGameWon();
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
    if (player == null || _joinCode.isEmpty) return;
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
        _phase = snap.allVotesIn
            ? (_isHost ? _GamePhase.results : _GamePhase.waitingForHost)
            : _GamePhase.waitingForVotes;
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
    setState(() => _submittingChoose = true);
    try {
      final snap = await chooseCardOption(
        joinCode: _joinCode,
        playerId: player.id,
        cardOptionId: cardOptionId,
      );
      if (!mounted) return;
      final newCard = snap.currentCard;
      if (newCard == null && _isLastRoundCard(_currentCard)) {
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

  /// Returns the `X/Y` label (votes for option / total players) once all
  /// votes are in, or `null` when counts shouldn't be shown yet.
  String? _voteCountLabel(int optionId) {
    if (!_allVotesIn) return null;
    final total = _players.length;
    if (total == 0) return null;
    final count = _votes.values.where((v) => v == optionId).length;
    return '$count/$total';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _kStoryNavy,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.session == null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: Colors.white,
                        tooltip: MaterialLocalizations.of(context)
                            .backButtonTooltip,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                      decoration: BoxDecoration(
                        color: _kStoryCardBeige,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _sceneTitle,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _kStoryPink,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _situationText,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.45,
                              color: Colors.black.withValues(alpha: 0.98),
                            ),
                          ),
                          if (_isGameComplete) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _kStoryPink,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.emoji_events_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
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
                    ),
                  ),
                  const Expanded(child: SizedBox.shrink()),
                  _buildBottomPanel(context),
                ],
              ),
            ),

            if (_phase == _GamePhase.debateIntro)
              SlideTransition(
                position: _introSlide,
                child: Container(
                  color: _kStoryNavy,
                  child: Image.asset(
                    'assets/images/debat.png',
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kStoryCardBeige,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        22,
        22,
        22 + MediaQuery.paddingOf(context).bottom,
      ),
      child: switch (_phase) {
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
            isSelected: false,
            isDisabled: _submittingVote,
            onPressed: _submittingVote ? null : () => _submitVote(opts[i].id),
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
            child: CircularProgressIndicator(strokeWidth: 2, color: _kStoryPink),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsPanel() {
    if (_isGameComplete) return _buildFinalResultPanel();
    final opts = _options;
    final onLastRound = _isLastRoundCard(_currentCard);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Alle stemmen zijn binnen!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 16),
        if (_isHost) ...[
          Text(
            onLastRound
                ? 'Kies de afsluiting — daarna is het verhaal klaar:'
                : 'Kies welke optie de groep volgt:',
            style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < opts.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _StoryChoiceButton(
              label: opts[i].optionText,
              isSelected: false,
              isDisabled: _submittingChoose,
              voteCountLabel: _voteCountLabel(opts[i].id),
              onPressed: _submittingChoose ? null : () => _submitChoose(opts[i].id),
            ),
          ],
          if (_submittingChoose) ...[
            const SizedBox(height: 16),
            const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: _kStoryPink),
              ),
            ),
          ],
        ] else ...[
          const Text(
            'Wachten tot de host een keuze maakt...',
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 16),
          const Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: _kStoryPink),
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
          color: _kStoryNavy,
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
              backgroundColor: _kStoryPink,
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
            backgroundColor: _kStoryPink,
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
                      color: _kStoryPink,
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
                      _timerSeconds <= 10 ? Colors.red : _kStoryNavy,
                    ),
                  ),
                  Center(
                    child: Text(
                      '$_timerSeconds',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _timerSeconds <= 10 ? Colors.red : _kStoryNavy,
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
              child: CircularProgressIndicator(strokeWidth: 2, color: _kStoryPink),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWaitingForHostPanel() {
    if (_isGameComplete) return _buildFinalResultPanel();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Alle stemmen zijn binnen!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
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
              voteCountLabel: _voteCountLabel(opt.id),
              onPressed: null,
            ),
          ),
        const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _kStoryPink),
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
              color: _kStoryPink,
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
                  backgroundColor: _kStoryPink,
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
                color: isSelected ? _kStorySelectedBorder : color.withValues(alpha: 0.4),
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
                  const Icon(Icons.check_circle, color: _kStorySelectedBorder, size: 20),
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
    this.voteCountLabel,
  });

  final String label;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onPressed;
  final String? voteCountLabel;

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
              color: _kStoryPink,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: _kStorySelectedBorder, width: 3)
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
                          const Icon(Icons.check_circle, color: _kStorySelectedBorder, size: 22),
                        ],
                      ],
                    ),
                  ),
                  if (voteCountLabel != null)
                    Positioned(
                      top: 8,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          voteCountLabel!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.0,
                          ),
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
