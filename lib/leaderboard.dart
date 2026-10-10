import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Added 'Overall' to the games list
  final List<Map<String, String>> games = [
    {
      'title': 'Sudoku',
      'scoreKey': 'sudokuScore',
      'timeKey': 'crosswordCompletedAt'
    },
    {
      'title': 'Word Search',
      'scoreKey': 'wordSearchScore',
      'timeKey': 'wordSearchcompletedAt'
    },
    {
      'title': 'Crossword',
      'scoreKey': 'crosswordScore',
      'timeKey': 'crosswordCompletedAt'
    },
    {'title': 'Overall', 'scoreKey': 'overall'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: games.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Fetches leaderboard data and calculates overall sums if needed
  Future<List<Map<String, dynamic>>> _fetchLeaderboardData(
    String scoreKey,
  ) async {
    try {
      final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
      final DataSnapshot snapshot = await dbRef.child('leaderboard').get();

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final Map rawData = snapshot.value as Map;
      List<Map<String, dynamic>> scores = [];

      rawData.forEach((badgeId, value) {
        if (value is Map) {
          if (scoreKey == 'overall') {
            // Check if user has completed ALL THREE games
            final sudoku = value['sudokuScore'];
            final wordSearch = value['wordSearchScore'];
            final crossword = value['crosswordScore'];

            if (sudoku != null && wordSearch != null && crossword != null) {
              final int totalTime =
                  (sudoku as int) + (wordSearch as int) + (crossword as int);
              scores.add({
                'badgeId': badgeId,
                'name': value['name'] ?? 'Unknown',
                'table': value['table'] ?? 'Unknown',
                'score': totalTime,
              });
            }
          } else {
            // Individual game tab logic
            if (value[scoreKey] != null) {
              scores.add({
                'badgeId': badgeId,
                'name': value['name'] ?? 'Unknown',
                'table': value['tableNum'] ?? 'Unknown',
                'score': value[scoreKey],
                //'time': value[timeKey],
              });
            }
          }
        }
      });

      // Sort from fastest total time to slowest (ascending order)
      scores.sort((a, b) => (a['score'] as int).compareTo(b['score'] as int));

      return scores;
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // Allows tabs to fit comfortably across the top
          tabs: games.map((game) => Tab(text: game['title'])).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: games.map((game) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchLeaderboardData(game['scoreKey']!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final scores = snapshot.data ?? [];

              if (scores.isEmpty) {
                return Center(
                  child: Text(
                    game['scoreKey'] ==
                            'overall'.toString() // Or simply match overall text
                        ? 'No players have completed all 3 games yet!'
                        : 'No scores recorded for this game yet!',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ListView.builder(
                itemCount: scores.length,
                padding: const EdgeInsets.all(12),
                itemBuilder: (context, index) {
                  final entry = scores[index];
                  final rank = index + 1;
                  final name = entry['name'];
                  final badgeId = entry['badgeId'];
                  final table = entry['table'];
                  final score = entry['score'];
                  final time = entry['timeFinished'];

                  // Highlight top 3 ranks
                  Color rankColor = Colors.grey.shade200;
                  Color textColor = Colors.black87;
                  if (rank == 1) {
                    rankColor = Colors.amber.shade300;
                  } else if (rank == 2) {
                    rankColor = Colors.grey.shade400;
                  } else if (rank == 3) {
                    rankColor = Colors.brown.shade300;
                  }

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: rankColor,
                        child: Text(
                          '$rank',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //Text('Badge ID: $badgeId'),
                          Text('Table: $table'),
                          // Text('Finished at: $time'),
                        ],
                      ),
                      trailing: Text(
                        '${score}s',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
