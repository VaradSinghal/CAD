import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Global in-memory scores list
final List<Map<String, dynamic>> globalScores = [];

/// Load scores from global Firestore
Future<void> loadScores({bool isDaily = false}) async {
  try {
    Query query = FirebaseFirestore.instance.collection('leaderboard');

    if (isDaily) {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      query = query.where('timestamp', isGreaterThanOrEqualTo: startOfDay);
      
      final snapshot = await query.get();
      
      var allDocs = snapshot.docs.map((d) => d.data() as Map<String, dynamic>).toList();
      allDocs.sort((a, b) => (b['score'] as int? ?? 0).compareTo(a['score'] as int? ?? 0));
      
      globalScores.clear();
      globalScores.addAll(allDocs.take(20));
      
    } else {
      final snapshot = await query
          .orderBy('score', descending: true)
          .limit(20)
          .get();

      globalScores.clear();
      for (var doc in snapshot.docs) {
        globalScores.add(doc.data() as Map<String, dynamic>);
      }
    }
  } catch (e) {
    debugPrint('Failed to load Firestore scores: $e');
  }
}

/// Save scores to global Firestore
Future<void> saveScores(Map<String, dynamic> scoreData) async {
  try {
    await FirebaseFirestore.instance.collection('leaderboard').add({
      'name': scoreData['name'],
      'score': scoreData['score'],
      'date': scoreData['date'],
      'mobile': scoreData['mobile'], // Added
      'regNo': scoreData['regNo'],   // Added
      'timestamp': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    debugPrint('Failed to save Firestore score: $e');
  }
}

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _isDaily = true; // Default to Daily
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await loadScores(isDaily: _isDaily);
    if (mounted) {
      setState(() => _loading = false);
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scores = globalScores;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
          child: Column(
            children: [
              // Premium App Bar
              _buildAppBar(context),

              // Daily/Global Toggle
              _buildToggle(),

              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : scores.isEmpty
                        ? _buildEmptyState(context)
                        : _buildLeaderboardContent(scores),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'LEADERBOARD',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isDaily) {
                  setState(() => _isDaily = true);
                  _load();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isDaily ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'DAILY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isDaily ? Colors.black : Colors.white60,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isDaily) {
                  setState(() => _isDaily = false);
                  _load();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isDaily ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'GLOBAL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_isDaily ? Colors.black : Colors.white60,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined,
              size: 100, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          const Text(
            'NO CHAMPIONS YET',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, '/slot'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Text(
                'START PLAYING',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardContent(List<Map<String, dynamic>> scores) {
    final podiumScores = scores.take(3).toList();
    final remainingScores = scores.skip(3).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        // Podium Section
        if (podiumScores.isNotEmpty) ...[
          _buildPodium(podiumScores),
          const SizedBox(height: 30),
        ],

        // List Header
        if (remainingScores.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 15),
            child: Text(
              _isDaily ? 'TODAY\'S BEST' : 'WORLD RANKINGS',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ),

        // List Section
        ...remainingScores.asMap().entries.map((entry) {
          final index = entry.key;
          final scoreData = entry.value;
          return _buildAnimatedScoreTile(
            rank: index + 4,
            name: scoreData['name'] ?? 'Player',
            score: scoreData['score'] ?? 0,
            delay: (index + 4) * 0.1,
          );
        }),
      ],
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> podium) {
    return Container(
      height: 240,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (podium.length > 1)
            _buildPodiumSpot(
              podium[1],
              2,
              160,
              const Color(0xFFC0C0C0), // Silver
              0.2,
            ),
          const SizedBox(width: 15),
          // 1st Place
          if (podium.isNotEmpty)
            _buildPodiumSpot(
              podium[0],
              1,
              200,
              const Color(0xFFFFD700), // Gold
              0.0,
            ),
          const SizedBox(width: 15),
          // 3rd Place
          if (podium.length > 2)
            _buildPodiumSpot(
              podium[2],
              3,
              140,
              const Color(0xFFCD7F32), // Bronze
              0.4,
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumSpot(Map<String, dynamic> data, int rank, double height,
      Color color, double delay) {
    return Expanded(
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay, delay + 0.4, curve: Curves.easeOut),
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: Interval(delay, delay + 0.4, curve: Curves.easeOut),
          )),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Avatar/Icon
              Container(
                width: rank == 1 ? 70 : 60,
                height: rank == 1 ? 70 : 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  border: Border.all(color: color, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    rank == 1 ? '👑' : (rank == 2 ? '🥈' : '🥉'),
                    style: TextStyle(fontSize: rank == 1 ? 32 : 28),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Name
              Text(
                data['name'] ?? 'Player',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              // Score
              Text(
                '${data['score']} PTS',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 15),
              // Podium Base
              Container(
                height: height - 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withValues(alpha: 0.4),
                      color.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedScoreTile({
    required int rank,
    required String name,
    required int score,
    required double delay,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          (delay * 0.5).clamp(0.0, 1.0),
          ((delay * 0.5) + 0.3).clamp(0.0, 1.0),
          curve: Curves.easeOut,
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (delay * 0.5).clamp(0.0, 1.0),
            ((delay * 0.5) + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          )),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    // Rank
                    SizedBox(
                      width: 35,
                      child: Text(
                        '#$rank',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Avatar Placeholder
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.person_outline,
                            color: Colors.white60, size: 24),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Name
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // Score
                    Text(
                      '$score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
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
