import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sociality/api/game_session_api.dart';
import 'package:sociality/services/player_identity.dart';

const Color _kStoryNavy = Color(0xFF29367C);
const Color _kStoryPink = Color(0xFFE4318C);
const Color _kStoryCardBeige = Color(0xFFF5E9DF);
const Color _kStorySelectedBorder = Color(0xFF2ECC71);

class _PersonProfile {
  const _PersonProfile({required this.name, required this.age, required this.bio});
  final String name;
  final int age;
  final String bio;
}

enum _GamePhase { choosing, results, debateVote, debateVoteResult, debateIntro, debate, revote, finalResult }

class StoryPlayScreen extends StatefulWidget {
  const StoryPlayScreen({super.key, this.session});

  /// Live session after host starts the game; drives titles when present.
  final GameSessionStarted? session;

  @override
  State<StoryPlayScreen> createState() => _StoryPlayScreenState();
}

class _StoryPlayScreenState extends State<StoryPlayScreen>
    with TickerProviderStateMixin {
  _GamePhase _phase = _GamePhase.choosing;
  int? _selectedChoice;
  int? _revoteChoice;

  final int _votesA = 2;
  final int _votesB = 3;

  bool? _debateVoteChoice; // true = yes, false = no
  final int _debateVotesYes = 3;
  final int _debateVotesNo = 2;

  static const int _debateDuration = 90;
  int _timerSeconds = _debateDuration;
  Timer? _debateTimer;

  // Animation for the debate intro image
  late final AnimationController _introController;
  late final Animation<Offset> _introSlide;

  static const String _kDefaultTitle = 'HET SKATEPARK: DE START';
  static const List<_PersonProfile> _profiles = [
    _PersonProfile(
      name: 'Jayden Smits',
      age: 16,
      bio: 'Jayden komt elke dag na school naar het skatepark. Hij wil de baan uitbreiden met een overkapping zodat hij ook bij regen kan skaten. Hij snapt niet waarom de buurt zo moeilijk doet — voor hem is het gewoon een plek om vrienden te ontmoeten en zijn tricks te oefenen.',
    ),
    _PersonProfile(
      name: 'Greet van Dijk',
      age: 58,
      bio: 'Greet woont al jaren vlak naast het skatepark en heeft regelmatig last van harde muziek en rondhangend volk. Ze is niet tegen de jongeren, maar vindt dat er duidelijkere afspraken moeten komen over tijden en gedrag in de buurt.',
    ),
  ];

  static const String _body =
      'Jongeren in een middelgroot drop willen hun skatebaan uitbreiden met een overkapping en bankjes. De baan aan velden. Het is een populaire hangplek. Dat zorgt soms voor overlast door brommers, harde muziek en af en toe signalen van drugsgebruik of -dealen';

  static const String _choiceA =
      'Je richt je eerst op gesprekken met de jongeren. Speel kaart 1A.';
  static const String _choiceB =
      'Je gaat voor draagvlak en richt je op het verzet in de buurt. Speel kaart 1B.';

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
  }

  @override
  void dispose() {
    _debateTimer?.cancel();
    _introController.dispose();
    clearPlayerIdentity();
    super.dispose();
  }

  void _startDebate() {
    setState(() => _phase = _GamePhase.debateIntro);
    _introController.forward();
    // After 2.5s slide the image back out, then show debate UI
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

  void _showProfileSheet(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
        child: _ProfileCard(profiles: _profiles),
      ),
    );
  }

  void _skipDebate() {
    _debateTimer?.cancel();
    setState(() => _phase = _GamePhase.revote);
  }

  String get _sceneTitle {
    final name = widget.session?.currentStory.name.trim();
    if (name != null && name.isNotEmpty) {
      return 'HET ${name.toUpperCase()}: DE START';
    }
    return _kDefaultTitle;
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  _sceneTitle,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: _kStoryPink,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _showProfileSheet(context),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _kStoryPink.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.people_alt_rounded,
                                    color: _kStoryPink,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _body,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.45,
                              color: Colors.black.withValues(alpha: 0.98),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Expanded(child: SizedBox.shrink()),
                  _buildBottomPanel(context),
                ],
              ),
            ),

            // Debate intro image overlay
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
        _GamePhase.results => _buildResultsPanel(),
        _GamePhase.debateVote => _buildDebateVotePanel(),
        _GamePhase.debateVoteResult => _buildDebateVoteResultPanel(),
        _GamePhase.debate => _buildDebatePanel(),
        _GamePhase.revote => _buildRevotePanel(),
        _GamePhase.finalResult => _buildFinalResultPanel(),
      },
    );
  }

  Widget _buildChoosingPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _selectedChoice != null ? 'Wachten op andere spelers...' : 'Wat doe je?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _selectedChoice != null ? Colors.black54 : Colors.black,
          ),
        ),
        const SizedBox(height: 18),
        _StoryChoiceButton(
          label: _choiceA,
          isSelected: _selectedChoice == 0,
          isDisabled: _selectedChoice != null && _selectedChoice != 0,
          onPressed: _selectedChoice == null
              ? () => setState(() => _selectedChoice = 0)
              : null,
        ),
        const SizedBox(height: 12),
        _StoryChoiceButton(
          label: _choiceB,
          isSelected: _selectedChoice == 1,
          isDisabled: _selectedChoice != null && _selectedChoice != 1,
          onPressed: _selectedChoice == null
              ? () => setState(() => _selectedChoice = 1)
              : null,
        ),
        if (_selectedChoice != null) ...[
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => setState(() => _phase = _GamePhase.results),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black54,
              side: const BorderSide(color: Colors.black26),
            ),
            child: const Text('🧪 Simuleer stemresultaat'),
          ),
        ],
      ],
    );
  }

  Widget _buildResultsPanel() {
    final total = _votesA + _votesB;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Stemresultaat',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 16),
        _VoteBar(label: 'Kaart 1A', votes: _votesA, total: total, color: _kStoryPink),
        const SizedBox(height: 10),
        _VoteBar(label: 'Kaart 1B', votes: _votesB, total: total, color: _kStoryNavy),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.shade300),
          ),
          child: const Text(
            'Stemmen zijn bijna gelijk verdeeld! Start een debatronde.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => setState(() => _phase = _GamePhase.debateVote),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kStoryPink,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            'Laat de groep stemmen',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
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
          OutlinedButton(
            onPressed: () => setState(() => _phase = _GamePhase.debateVoteResult),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black54,
              side: const BorderSide(color: Colors.black26),
            ),
            child: const Text('🧪 Simuleer debatstemming'),
          ),
        ],
      ],
    );
  }

  Widget _buildDebateVoteResultPanel() {
    final total = _debateVotesYes + _debateVotesNo;
    final yesWins = _debateVotesYes >= _debateVotesNo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Wil de groep debatteren?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 16),
        _VoteBar(label: 'Ja', votes: _debateVotesYes, total: total, color: _kStoryNavy),
        const SizedBox(height: 10),
        _VoteBar(label: 'Nee', votes: _debateVotesNo, total: total, color: Colors.black38),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header row: DEBAT label + circular timer
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
        // Cards shown as reference (not tappable)
        const Text(
          'Wat doe je?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 12),
        _StoryChoiceButton(label: _choiceA, isSelected: false, isDisabled: true, onPressed: null),
        const SizedBox(height: 10),
        _StoryChoiceButton(label: _choiceB, isSelected: false, isDisabled: true, onPressed: null),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _revoteChoice != null ? 'Wachten op andere spelers...' : 'Stem opnieuw!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _revoteChoice != null ? Colors.black54 : Colors.black,
          ),
        ),
        const SizedBox(height: 18),
        _StoryChoiceButton(
          label: _choiceA,
          isSelected: _revoteChoice == 0,
          isDisabled: _revoteChoice != null && _revoteChoice != 0,
          onPressed: _revoteChoice == null
              ? () => setState(() => _revoteChoice = 0)
              : null,
        ),
        const SizedBox(height: 12),
        _StoryChoiceButton(
          label: _choiceB,
          isSelected: _revoteChoice == 1,
          isDisabled: _revoteChoice != null && _revoteChoice != 1,
          onPressed: _revoteChoice == null
              ? () => setState(() => _revoteChoice = 1)
              : null,
        ),
        if (_revoteChoice != null) ...[
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => setState(() => _phase = _GamePhase.finalResult),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black54,
              side: const BorderSide(color: Colors.black26),
            ),
            child: const Text('🧪 Simuleer eindresultaat'),
          ),
        ],
      ],
    );
  }

  Widget _buildFinalResultPanel() {
    final winner = _revoteChoice == 0 ? 'Kaart 1A' : 'Kaart 1B';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Eindresultaat',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kStoryPink,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'De groep kiest: $winner',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
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

class _ProfileCard extends StatefulWidget {
  const _ProfileCard({required this.profiles});
  final List<_PersonProfile> profiles;

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profiles[_index];
    const double avatarRadius = 58.0;
    const double navyHeight = 96.0;

    return Container(
      height: 460,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Container(height: navyHeight, color: _kStoryNavy),
              Expanded(
                child: Container(
                  color: _kStoryCardBeige,
                  padding: const EdgeInsets.fromLTRB(24, avatarRadius + 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        profile.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _kStoryPink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Leeftijd: ${profile.age}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'OVER ${profile.name.split(' ').first.toUpperCase()}:',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _kStoryPink,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          profile.bio,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.55,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.fade,
                        ),
                      ),
                      const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 38,
                          child: _index > 0
                              ? GestureDetector(
                                  onTap: () => setState(() => _index--),
                                  child: const Icon(
                                    Icons.chevron_left_rounded,
                                    size: 30,
                                    color: _kStoryPink,
                                  ),
                                )
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(widget.profiles.length, (i) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: i == _index ? 20 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: i == _index
                                      ? Colors.black87
                                      : Colors.black38,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                        ),
                        SizedBox(
                          width: 38,
                          child: _index < widget.profiles.length - 1
                              ? GestureDetector(
                                  onTap: () => setState(() => _index++),
                                  child: const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 30,
                                    color: _kStoryPink,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ],
          ),
          // Close button
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
          Positioned(
            top: navyHeight - avatarRadius,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: avatarRadius * 2,
                height: avatarRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _kStoryPink, width: 4),
                  color: _kStoryNavy,
                ),
                child: const ClipOval(
                  child: Icon(Icons.person, size: 64, color: Colors.white70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoteBar extends StatelessWidget {
  const _VoteBar({
    required this.label,
    required this.votes,
    required this.total,
    required this.color,
  });

  final String label;
  final int votes;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : votes / total,
              minHeight: 20,
              backgroundColor: Colors.black12,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$votes', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _StoryChoiceButton extends StatelessWidget {
  const _StoryChoiceButton({
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final bool isDisabled;
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
            decoration: BoxDecoration(
              color: _kStoryPink,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: _kStorySelectedBorder, width: 3)
                  : null,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 88),
              child: Padding(
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
            ),
          ),
        ),
      ),
    );
  }
}
