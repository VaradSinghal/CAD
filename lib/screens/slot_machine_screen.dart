import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'leaderboard_screen.dart';

const List<Map<String, String>> allHeads = [
  {'asset': 'assets/heads/buggsbunny.png', 'name': 'Bugs Bunny'},
  {'asset': 'assets/heads/doreamon.png', 'name': 'Doraemon'},
];

const List<Map<String, String>> allTorsos = [
  {'asset': 'assets/torso/Popeye.png', 'name': 'Popeye'},
  {'asset': 'assets/torso/mrBean.png', 'name': 'Mr Bean'},
];

const List<Map<String, String>> allLegs = [
  {'asset': 'assets/legs/Kalia.png', 'name': 'Kalia'},
  {'asset': 'assets/legs/mickeymouse.png', 'name': 'Mickey Mouse'},
];

class SlotMachineScreen extends StatefulWidget {
  const SlotMachineScreen({super.key});

  @override
  State<SlotMachineScreen> createState() => _SlotMachineScreenState();
}

class _SlotMachineScreenState extends State<SlotMachineScreen>
    with TickerProviderStateMixin {
  final Random _random = Random();

  int _headIndex = 0, _torsoIndex = 0, _legsIndex = 0;
  bool _isSpinning = false, _showResults = false;
  final _headCtrl = TextEditingController();
  final _torsoCtrl = TextEditingController();
  final _legsCtrl = TextEditingController();
  int _score = 0;
  String _feedback = '';
  Color _feedbackColor = Colors.white;
  String _playerName = 'Player';

  late AnimationController _headAnim, _torsoAnim, _legsAnim;
  late AnimationController _leverController;
  late Animation<double> _leverAnimation;
  int _headNext = 0, _torsoNext = 0, _legsNext = 0;
  bool _headStopped = false, _torsoStopped = false, _legsStopped = false;

  @override
  void initState() {
    super.initState();
    _headAnim = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    _torsoAnim = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    _legsAnim = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);

    _headAnim.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_headStopped) {
        setState(() {
          _headIndex = _headNext;
          _headNext = _random.nextInt(allHeads.length);
        });
        _headAnim.forward(from: 0);
      }
    });
    _torsoAnim.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_torsoStopped) {
        setState(() {
          _torsoIndex = _torsoNext;
          _torsoNext = _random.nextInt(allTorsos.length);
        });
        _torsoAnim.forward(from: 0);
      }
    });
    _legsAnim.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_legsStopped) {
        setState(() {
          _legsIndex = _legsNext;
          _legsNext = _random.nextInt(allLegs.length);
        });
        _legsAnim.forward(from: 0);
      }
    });

    _leverController = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _leverAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 60),
    ]).animate(
        CurvedAnimation(parent: _leverController, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) _playerName = args;
  }

  @override
  void dispose() {
    _headAnim.dispose();
    _torsoAnim.dispose();
    _legsAnim.dispose();
    _leverController.dispose();
    _headCtrl.dispose();
    _torsoCtrl.dispose();
    _legsCtrl.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning) return;
    setState(() {
      _isSpinning = true;
      _showResults = false;
      _headCtrl.clear();
      _torsoCtrl.clear();
      _legsCtrl.clear();
      _feedback = '';
      _headStopped = _torsoStopped = _legsStopped = false;
    });
    _leverController.forward(from: 0);
    _headNext = _random.nextInt(allHeads.length);
    _torsoNext = _random.nextInt(allTorsos.length);
    _legsNext = _random.nextInt(allLegs.length);
    _headAnim.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _torsoAnim.forward(from: 0);
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _legsAnim.forward(from: 0);
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _headStopped = true;
        setState(() => _headIndex = _random.nextInt(allHeads.length));
      }
    });
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        _torsoStopped = true;
        setState(() => _torsoIndex = _random.nextInt(allTorsos.length));
      }
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _legsStopped = true;
        setState(() {
          _legsIndex = _random.nextInt(allLegs.length);
          _isSpinning = false;
          _showResults = true;
        });
      }
    });
  }

  bool _match(String g, String c) =>
      g.trim().toLowerCase() == c.trim().toLowerCase();

  void _submitGuesses() {
    int correct = 0;
    final cH = allHeads[_headIndex]['name']!;
    final cT = allTorsos[_torsoIndex]['name']!;
    final cL = allLegs[_legsIndex]['name']!;
    if (_match(_headCtrl.text, cH)) correct++;
    if (_match(_torsoCtrl.text, cT)) correct++;
    if (_match(_legsCtrl.text, cL)) correct++;
    int pts = correct * 10 + (correct == 3 ? 20 : 0);
    setState(() {
      _score += pts;
      if (correct == 3) {
        _feedback = '🎉 PERFECT! +$pts pts';
        _feedbackColor = Colors.greenAccent;
      } else if (correct >= 1) {
        _feedback = '$correct/3 correct! +$pts pts';
        _feedbackColor = Colors.white70;
      } else {
        _feedback = '❌ Wrong! It was $cH, $cT, $cL';
        _feedbackColor = Colors.redAccent;
      }
      _showResults = false;
    });
  }

  void _endGame() {
    globalScores.add({
      'name': _playerName,
      'score': _score,
      'date': DateTime.now().toString().substring(0, 16),
    });
    globalScores
        .sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    saveScores();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        title: const Text('Game Over!',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_playerName,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
          const SizedBox(height: 4),
          Text('$_score pts',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900)),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _score = 0;
                _feedback = '';
                _showResults = false;
              });
            },
            child: const Text('Play Again',
                style: TextStyle(color: Colors.white70, fontSize: 15)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text('Home',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4), fontSize: 15)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.black,
          image: DecorationImage(
            image: AssetImage('assets/bg.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Responsive reel height based on available screen height
              final availableH = constraints.maxHeight;
              final reelH = (availableH * 0.12).clamp(60.0, 110.0);

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: availableH),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // ── Top bar ──
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.arrow_back_ios_new,
                                      color: Colors.white60, size: 16),
                                ),
                              ),
                              Expanded(
                                child: Text(_playerName,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1)),
                              ),
                              GestureDetector(
                                onTap: _endGame,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('END',
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.6),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: availableH * 0.12),

                        // ── Slot machine + lever ──
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Machine
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.12)),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Title badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: const Text('SLOT MACHINE',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 2)),
                                    ),
                                    const SizedBox(height: 8),

                                    // Reels container
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withValues(alpha: 0.5),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.1)),
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(11),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _reel(allHeads, _headIndex,
                                                _headNext, _headAnim,
                                                _headStopped || !_isSpinning,
                                                reelH),
                                            _reel(allTorsos, _torsoIndex,
                                                _torsoNext, _torsoAnim,
                                                _torsoStopped || !_isSpinning,
                                                reelH),
                                            _reel(allLegs, _legsIndex,
                                                _legsNext, _legsAnim,
                                                _legsStopped || !_isSpinning,
                                                reelH),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 6),

                            // Lever
                            _buildLever(reelH * 3 + 80),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // ── Guess panel ──
                        if (_showResults) _buildGuessPanel(),

                        // ── Feedback ──
                        if (_feedback.isNotEmpty)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              color: _feedbackColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      _feedbackColor.withValues(alpha: 0.2)),
                            ),
                            child: Text(_feedback,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: _feedbackColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _reel(List<Map<String, String>> items, int idx, int nextIdx,
      AnimationController anim, bool stopped, double h) {
    if (stopped) {
      return SizedBox(
        height: h,
        child: Center(
          child: Image.asset(items[idx]['asset']!, fit: BoxFit.contain),
        ),
      );
    }
    return AnimatedBuilder(
      animation: anim,
      builder: (_, _) {
        final p = anim.value;
        return SizedBox(
          height: h,
          child: Stack(children: [
            Positioned.fill(
              child: FractionalTranslation(
                translation: Offset(-p, 0),
                child: Image.asset(items[idx]['asset']!, fit: BoxFit.contain),
              ),
            ),
            Positioned.fill(
              child: FractionalTranslation(
                translation: Offset(1.0 - p, 0),
                child: Image.asset(items[nextIdx]['asset']!,
                    fit: BoxFit.contain),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildLever(double totalH) {
    return GestureDetector(
      onTap: _isSpinning ? null : _spin,
      child: AnimatedBuilder(
        animation: _leverAnimation,
        builder: (_, _) {
          return SizedBox(
            width: 40,
            height: totalH,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Track
                Positioned(
                  top: 20,
                  child: Container(
                    width: 8,
                    height: totalH - 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.12),
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                // Handle
                Positioned(
                  top: 10 + (_leverAnimation.value * (totalH - 100)),
                  child: Column(children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.3, -0.3),
                          colors: [
                            Colors.white.withValues(alpha: 0.9),
                            Colors.white.withValues(alpha: 0.5),
                            Colors.white.withValues(alpha: 0.25),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.white.withValues(alpha: 0.15),
                              blurRadius: 8),
                        ],
                      ),
                    ),
                    Container(
                      width: 5,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ]),
                ),
                // Base
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 36,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Center(
                      child: Text('PULL',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 7,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGuessPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text('GUESS THE CHARACTERS',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2)),
          const SizedBox(height: 8),
          _field('Head', _headCtrl),
          const SizedBox(height: 5),
          _field('Torso', _torsoCtrl),
          const SizedBox(height: 5),
          _field('Legs', _legsCtrl),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _submitGuesses,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('SUBMIT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          hintText: '$label belongs to...',
          hintStyle:
              TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 13),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          ),
        ),
      ),
    );
  }
}
