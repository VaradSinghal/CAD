import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global in-memory scores list
final List<Map<String, dynamic>> globalScores = [];

/// Load scores from disk
Future<void> loadScores() async {
  final prefs = await SharedPreferences.getInstance();
  final data = prefs.getString('leaderboard');
  if (data != null) {
    final list = jsonDecode(data) as List;
    globalScores.clear();
    globalScores.addAll(list.cast<Map<String, dynamic>>());
  }
}

/// Save scores to disk
Future<void> saveScores() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('leaderboard', jsonEncode(globalScores));
}

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await loadScores();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final scores = globalScores;

    return Scaffold(
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
              // Top bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'LEADERBOARD',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
              ),

              // Trophy header
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.white.withValues(alpha: 0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    const Text('🎰', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(
                      _loading
                          ? 'Loading...'
                          : scores.isEmpty
                              ? 'No games played yet!'
                              : 'Best: ${scores.first['name']} — ${scores.first['score']} pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      scores.isEmpty
                          ? 'Play to earn your spot!'
                          : '${scores.length} game${scores.length == 1 ? '' : 's'} played',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Scores list
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : scores.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.emoji_events_outlined,
                                    size: 80,
                                    color:
                                        Colors.white.withValues(alpha: 0.15)),
                                const SizedBox(height: 16),
                                const Text(
                                    'Play a game to see your scores here!',
                                    style: TextStyle(
                                        color: Colors.white38, fontSize: 16)),
                                const SizedBox(height: 24),
                                GestureDetector(
                                  onTap: () => Navigator.pushReplacementNamed(
                                      context, '/slot'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: const Text('START PLAYING',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            letterSpacing: 3)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: scores.length,
                            itemBuilder: (context, index) {
                              final entry = scores[index];
                              return _buildScoreCard(
                                rank: index + 1,
                                name: (entry['name'] as String?) ?? 'Player',
                                score: entry['score'] as int,
                                date: (entry['date'] as String?) ?? '',
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard({
    required int rank,
    required String name,
    required int score,
    required String date,
  }) {
    final Color rankColor;
    final IconData rankIcon;
    if (rank == 1) {
      rankColor = Colors.white;
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = Colors.white70;
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = Colors.white54;
      rankIcon = Icons.emoji_events;
    } else {
      rankColor = Colors.white38;
      rankIcon = Icons.star_border;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            rank <= 3
                ? rankColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              rank <= 3 ? rankColor.withValues(alpha: 0.4) : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: rankColor, width: 2),
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(rankIcon, color: rankColor, size: 24)
                  : Text('#$rank',
                      style: TextStyle(
                          color: rankColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
            ),
          ),
          const SizedBox(width: 16),

          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        color: rank <= 3 ? rankColor : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                Text('$score pts • $date',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),

          // Score on right
          Text('$score',
              style: TextStyle(
                  color: rank <= 3 ? rankColor : Colors.white70,
                  fontSize: 24,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
