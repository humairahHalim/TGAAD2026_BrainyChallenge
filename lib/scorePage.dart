import 'package:brainy_challenge/Widgets/button.dart';
import 'package:flutter/material.dart';

class ScorePage extends StatelessWidget {
  final String badgeId;
  final String name;
  final Map<String, dynamic> scoreData;
  final String game;

  const ScorePage({
    super.key,
    required this.badgeId,
    required this.name,
    required this.scoreData,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    final int timeTaken = scoreData['${game}Score'] ?? 0;

    final seconds = timeTaken ~/ 1000000;
    final ms3Digit = ((timeTaken % 1000000) ~/ 1000).toString().padLeft(3, '0');
    final String score = '${seconds}:${ms3Digit}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Result'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
              const SizedBox(height: 16),
              Text(
                'Already Completed!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Player: $name ($badgeId)',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Your ${game} score: ${score}s',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 32),
              myButton(
                text: 'Back to Home',
                onTap: () => Navigator.pop(context),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
