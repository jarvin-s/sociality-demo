import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sociality/api/game_session_api.dart';
import 'package:sociality/screens/guest_lobby_screen.dart';
import 'package:sociality/services/player_identity.dart';

const Color _kPink = Color(0xFFEA1F86);
const Color _kNavyDeep = Color(0xFF1F2070);

class JoinCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final t = normalizeJoinCodeTyping(newValue.text);
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key, this.initialJoinCode});

  /// Deep link `?code=` from web or route arguments.
  final String? initialJoinCode;

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _isScanning = false;
  bool _hasScanned = false;
  bool _joinBusy = false;
  bool _settingCodeFromScan = false;

  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    final prefill = widget.initialJoinCode;
    if (prefill != null && prefill.trim().isNotEmpty) {
      _codeController.text = normalizeJoinCodeTyping(prefill);
    }
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _attemptJoin({String? scannedPayload}) async {
    if (_joinBusy) return;

    final raw = scannedPayload ?? _codeController.text;
    final code = parseJoinCodeFromQrOrText(raw);
    if (code == null || !isValidJoinCodeFormat(code)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Voer een geldige spelcode in (6 tekens: A-Z zonder I/L/O, en 1-9).',
            ),
          ),
        );
      }
      return;
    }
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vul je naam in.')),
        );
      }
      return;
    }

    setState(() => _joinBusy = true);
    try {
      await clearPlayerIdentity();
      final result = await joinGameSession(joinCode: code, playerName: name);
      final self = result.selfPlayer;
      if (self != null) {
        await savePlayerIdentity(self);
      }
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => GuestLobbyScreen(
            joinCode: code,
            initialSnapshot: result.snapshot,
            selfPlayerId: result.selfPlayerId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _joinBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _kNavyDeep,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;

          return Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
              ),

              Positioned.fill(
                child: FadeTransition(
                  opacity: _fade,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      28,
                      topPad + 90,
                      28,
                      24 + bottomPad,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        const Text(
                          'Meedoen',
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
                          'Voer je naam en spelcode in, of scan de QR-code van de host.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.35,
                          ),
                        ),

                        SizedBox(height: h * 0.14),

                        _FieldLabel('Jouw naam'),
                        const SizedBox(height: 8),
                        _JoinTextField(
                          controller: _nameController,
                          hint: 'bijvoorbeeld: Sam',
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 18),
                        _FieldLabel('Spelcode (6 tekens)'),
                        const SizedBox(height: 8),
                        _JoinCodeBoxes(
                          controller: _codeController,
                          onCompleted: () {
                            if (!_joinBusy && !_settingCodeFromScan) {
                              _attemptJoin();
                            }
                          },
                        ),

                        const SizedBox(height: 22),
                        _ScanRow(
                          isScanning: _isScanning,
                          onToggle: () => setState(() {
                            _isScanning = !_isScanning;
                            if (!_isScanning) _hasScanned = false;
                          }),
                        ),

                        if (_isScanning) ...[
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: SizedBox(
                              width: double.infinity,
                              height: 280,
                              child: MobileScanner(
                                onDetect: (capture) {
                                  if (_hasScanned || _joinBusy) return;
                                  final String? raw =
                                      capture.barcodes.first.rawValue;
                                  if (raw == null) return;
                                  final parsed =
                                      parseJoinCodeFromQrOrText(raw);
                                  if (parsed == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Geen geldige spelcode in deze QR-code.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  _settingCodeFromScan = true;
                                  setState(() {
                                    _hasScanned = true;
                                    _isScanning = false;
                                    _codeController.text = parsed;
                                  });
                                  _settingCodeFromScan = false;
                                  _attemptJoin(scannedPayload: raw);
                                },
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),
                        _NextButton(
                          label: 'Meedoen',
                          busy: _joinBusy,
                          onTap: _attemptJoin,
                        ),
                      ],
                    ),
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
          );
        },
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.7),
        letterSpacing: 0.3,
      ),
    );
  }
}

class _JoinTextField extends StatelessWidget {
  const _JoinTextField({
    required this.controller,
    required this.hint,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hint;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      cursorColor: _kPink,
      style: const TextStyle(
        fontSize: 18,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontStyle: FontStyle.italic,
          letterSpacing: 0,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kPink, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
    );
  }
}

const int _kJoinCodeLength = 6;

class _JoinCodeBoxes extends StatefulWidget {
  const _JoinCodeBoxes({
    required this.controller,
    required this.onCompleted,
  });

  final TextEditingController controller;
  final VoidCallback onCompleted;

  @override
  State<_JoinCodeBoxes> createState() => _JoinCodeBoxesState();
}

class _JoinCodeBoxesState extends State<_JoinCodeBoxes> {
  final FocusNode _focus = FocusNode();
  int _lastLength = 0;

  @override
  void initState() {
    super.initState();
    _lastLength = widget.controller.text.length;
    widget.controller.addListener(_onChanged);
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _onChanged() {
    if (!mounted) return;
    final len = widget.controller.text.length;
    final justCompleted =
        len >= _kJoinCodeLength && _lastLength < _kJoinCodeLength;
    _lastLength = len;
    setState(() {});
    if (justCompleted) {
      _focus.unfocus();
      widget.onCompleted();
    }
  }

  void _activate() {
    if (!_focus.hasFocus) {
      FocusScope.of(context).requestFocus(_focus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final hasFocus = _focus.hasFocus;
    final activeIndex = text.length >= _kJoinCodeLength
        ? _kJoinCodeLength - 1
        : text.length;

    return Stack(
      children: [
        Offstage(
          offstage: false,
          child: SizedBox(
            width: 1,
            height: 1,
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                autofocus: false,
                showCursor: false,
                enableSuggestions: false,
                autocorrect: false,
                enableInteractiveSelection: false,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: <TextInputFormatter>[
                  JoinCodeFormatter(),
                  LengthLimitingTextInputFormatter(_kJoinCodeLength),
                ],
              ),
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _activate,
          child: Row(
            children: [
              for (var i = 0; i < _kJoinCodeLength; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _CodeBox(
                    char: i < text.length ? text[i] : '',
                    isFilled: i < text.length,
                    isActive: hasFocus && i == activeIndex,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({
    required this.char,
    required this.isFilled,
    required this.isActive,
  });

  final String char;
  final bool isFilled;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive
        ? _kPink
        : Colors.white.withValues(alpha: isFilled ? 0.25 : 0.1);
    final borderWidth = isActive ? 2.0 : 1.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isFilled ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      alignment: Alignment.center,
      child: Text(
        char,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0,
          height: 1.0,
        ),
      ),
    );
  }
}

class _ScanRow extends StatefulWidget {
  const _ScanRow({required this.isScanning, required this.onToggle});
  final bool isScanning;
  final VoidCallback onToggle;

  @override
  State<_ScanRow> createState() => _ScanRowState();
}

class _ScanRowState extends State<_ScanRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggle,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kPink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isScanning ? 'Stop scannen' : 'Scan QR-code',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.isScanning
                          ? 'Tik om te annuleren'
                          : 'Open de camera om te scannen',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.55),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                widget.isScanning
                    ? Icons.close_rounded
                    : Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.4),
                size: 24,
              ),
            ],
          ),
        ),
      ),
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
