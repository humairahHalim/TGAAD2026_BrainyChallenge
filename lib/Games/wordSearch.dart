import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class WordSearch extends StatefulWidget {
  final String badgeId;
  final String name;

  const WordSearch({
    super.key,
    required this.badgeId,
    required this.name,
  });

  @override
  State<WordSearch> createState() => _WordSearchState();
}

class _WordSearchState extends State<WordSearch> {
  // 10x10 Static Word Search Grid
  final List<List<String>> grid = [
    ['F', 'L', 'U', 'T', 'T', 'E', 'R', 'K', 'T', 'V'],
    ['D', 'A', 'R', 'T', 'X', 'Y', 'Z', 'O', 'N', 'I'],
    ['W', 'I', 'D', 'G', 'E', 'T', 'E', 'A', 'R', 'S'],
    ['S', 'T', 'A', 'T', 'E', 'O', 'I', 'B', 'N', 'P'],
    ['G', 'U', 'Z', 'G', 'A', 'I', 'C', 'T', 'S', 'K'],
    ['H', 'R', 'J', 'B', 'Z', 'S', 'D', 'O', 'E', 'L'],
    ['R', 'S', 'I', 'U', 'V', 'W', 'X', 'Y', 'Z', 'A'],
    ['E', 'N', 'D', 'D', 'S', 'N', 'H', 'T', 'Y', 'K'],
    ['L', 'U', 'P', 'O', 'T', 'A', 'W', 'S', 'B', 'R'],
    ['V', 'M', 'E', 'Q', 'Z', 'A', 'B', 'C', 'D', 'E'],
  ];

  List<String> targetWords = [
    'FLUTTER',
    'DART',
    'WIDGET',
    'STATE',
    'GRID',
  ];

  late Set<Point<int>> selectedCells;
  late Set<Point<int>> foundCells;
  late Set<String> foundWords;

  Point<int>? dragStartPoint;

  // Timer State
  Timer? _timer;
  int secondsElapsed = 0;
  bool isGameFinished = false;
  bool isSubmitting = false;

  int get gridSize => grid.length;

  @override
  void initState() {
    super.initState();
    selectedCells = {};
    foundCells = {};
    foundWords = {};
    _startTimer(); // Starts automatically on load
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isGameFinished) {
        setState(() {
          secondsElapsed++;
        });
      }
    });
  }

  Future<void> _endGameAndSubmit() async {
    _timer?.cancel();
    setState(() {
      isGameFinished = true;
      isSubmitting = true;
    });

    final int finalScoreTime = secondsElapsed;

    try {
      // Firebase Realtime Database update using badgeId as key
      final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
      await dbRef.child('leaderboard/${widget.badgeId}').update({
        'name': widget.name,
        'badgeId': widget.badgeId,
        'wordSearchScore': finalScoreTime,
        'completedAt': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Error writing score to Firebase: $e');
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });

        // Completion Dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('🎉 Puzzle Completed!'),
            content: Text(
              'Great job, ${widget.name}!\n\n'
              'Time Taken: $finalScoreTime seconds\n'
              'Your score has been updated in the leaderboard.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss dialog
                  Navigator.of(context).pop(); // Return to previous screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  // --- Grid Touch & Selection Logic ---

  Point<int>? _getCellFromOffset(Offset localPosition, RenderBox box) {
    double cellSize = box.size.width / gridSize;
    int x = (localPosition.dx / cellSize).floor();
    int y = (localPosition.dy / cellSize).floor();

    if (x >= 0 && x < gridSize && y >= 0 && y < gridSize) {
      return Point(x, y);
    }
    return null;
  }

  void _onPanStart(DragStartDetails details, RenderBox box) {
    if (isGameFinished) return;
    Point<int>? cell = _getCellFromOffset(details.localPosition, box);
    if (cell != null) {
      setState(() {
        dragStartPoint = cell;
        selectedCells = {cell};
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details, RenderBox box) {
    if (isGameFinished || dragStartPoint == null) return;

    Point<int>? currentCell = _getCellFromOffset(details.localPosition, box);
    if (currentCell != null) {
      int dx = currentCell.x - dragStartPoint!.x;
      int dy = currentCell.y - dragStartPoint!.y;

      if (dx == 0 || dy == 0 || dx.abs() == dy.abs()) {
        int stepX = dx == 0 ? 0 : (dx > 0 ? 1 : -1);
        int stepY = dy == 0 ? 0 : (dy > 0 ? 1 : -1);
        int steps = max(dx.abs(), dy.abs());

        Set<Point<int>> path = {};
        for (int i = 0; i <= steps; i++) {
          path.add(Point(
              dragStartPoint!.x + stepX * i, dragStartPoint!.y + stepY * i));
        }

        setState(() {
          selectedCells = path;
        });
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (isGameFinished || selectedCells.isEmpty) return;

    String selectedWord = selectedCells.map((p) => grid[p.y][p.x]).join();
    String reversedWord = selectedWord.split('').reversed.join();

    String? matchedWord;
    if (targetWords.contains(selectedWord) &&
        !foundWords.contains(selectedWord)) {
      matchedWord = selectedWord;
    } else if (targetWords.contains(reversedWord) &&
        !foundWords.contains(reversedWord)) {
      matchedWord = reversedWord;
    }

    setState(() {
      if (matchedWord != null) {
        foundWords.add(matchedWord);
        foundCells.addAll(selectedCells);

        // Check if all words have been found
        if (foundWords.length == targetWords.length) {
          _endGameAndSubmit();
        }
      }
      selectedCells = {};
      dragStartPoint = null;
    });
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              'Time: ${secondsElapsed}s',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, // Prevents backing out accidentally
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Timer Header

          /** 
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Time: ${secondsElapsed}s',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          */
          // Word List Target Display
          /**  Wrap(
            spacing: 10,
            runSpacing: 8,
            children: targetWords.map((word) {
              bool isFound = foundWords.contains(word);
              return Chip(
                label: Text(
                  word,
                  style: TextStyle(
                    decoration: isFound ? TextDecoration.lineThrough : null,
                    color: isFound ? Colors.grey : Colors.black,
                    fontWeight: isFound ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                backgroundColor:
                    isFound ? Colors.grey.shade300 : Colors.blue.shade100,
              );
            }).toList(),
          ),
          

          */
          Text(
            'Find words related to Top Glove!',
            style: TextStyle(
              //fontFamily: GoogleFonts.
              fontSize: 30,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                const Text(
                  'Words left:',
                  style: TextStyle(
                    fontSize: 25,
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  (targetWords.length - foundWords.length).toString(),
                  style: TextStyle(
                    fontSize: 25,
                    color: Colors.amber,
                  ),
                ),
                /** SizedBox(
                  width: 5,
                ),
                Text('You found:'),
                SizedBox(
                  width: 5,
                ),
                Text(
                  foundWords.length.toString(),
                ),
                */
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Grid Area
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Builder(
                    builder: (context) {
                      return GestureDetector(
                        onPanStart: (d) {
                          final box = context.findRenderObject() as RenderBox;
                          _onPanStart(d, box);
                        },
                        onPanUpdate: (d) {
                          final box = context.findRenderObject() as RenderBox;
                          _onPanUpdate(d, box);
                        },
                        onPanEnd: _onPanEnd,
                        child: Container(
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: Colors.blueAccent, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            children: [
                              GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: gridSize * gridSize,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: gridSize,
                                ),
                                itemBuilder: (context, index) {
                                  int x = index % gridSize;
                                  int y = index ~/ gridSize;
                                  Point<int> point = Point(x, y);

                                  bool isSelected =
                                      selectedCells.contains(point);
                                  bool isFound = foundCells.contains(point);

                                  Color bgColor = Colors.transparent;
                                  if (isSelected) {
                                    bgColor = Colors.orange.shade300;
                                  } else if (isFound) {
                                    bgColor = Colors.green.shade200;
                                  }

                                  return Container(
                                    margin: const EdgeInsets.all(1),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Center(
                                      child: Text(
                                        grid[y][x],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isFound || isSelected
                                              ? Colors.black
                                              : Colors.blueGrey.shade800,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (isSubmitting)
                                Container(
                                  color: Colors.white70,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
