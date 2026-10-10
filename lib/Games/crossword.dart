import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

// Model to represent a clue and its position on the grid
class CrosswordClue {
  final int number;
  final String clue;
  final String answer;
  final int startX; // Column index (0-based)
  final int startY; // Row index (0-based)
  final bool isAcross;

  CrosswordClue({
    required this.number,
    required this.clue,
    required this.answer,
    required this.startX,
    required this.startY,
    required this.isAcross,
  });
}

class Crossword extends StatefulWidget {
  final String badgeId;
  final String name;

  const Crossword({
    super.key,
    required this.badgeId,
    required this.name,
  });

  @override
  State<Crossword> createState() => _CrosswordPageState();
}

class _CrosswordPageState extends State<Crossword> {
  static const int gridRows = 12;
  static const int gridCols = 12;

  // 1. Manually Defined Clues & Answers
  final List<CrosswordClue> clues = [
    // Across Clues
    CrosswordClue(
      number: 1,
      clue: 'The V in RIVER stands for',
      answer: 'VALUE',
      startX: 7,
      startY: 0,
      isAcross: false,
    ),
    CrosswordClue(
      number: 3,
      clue: 'Tough times create _____ men',
      answer: 'STRONG',
      startX: 2,
      startY: 4,
      isAcross: false,
    ),
    CrosswordClue(
      number: 5,
      clue: 'What is said 3 times at the end of Top Quality & Efficiency Claps',
      answer: 'IMPROVE',
      startX: 5,
      startY: 4,
      isAcross: false,
    ),
    // Down Clues
    CrosswordClue(
      number: 2,
      clue: 'Other than Malaysia, Top Glove has factories in what country?',
      answer: 'THAILAND',
      startX: 3,
      startY: 2,
      isAcross: true,
    ),
    CrosswordClue(
      number: 4,
      clue: 'What animal does not go to school according to TS\'s philosophy?',
      answer: 'TIGER',
      startX: 4,
      startY: 4,
      isAcross: true,
    ),
    CrosswordClue(
      number: 6,
      clue: 'The 3rd verb in the 5 Healthy Wells Clap',
      answer: 'WORK',
      startX: 0,
      startY: 6,
      isAcross: true,
    ),
    CrosswordClue(
      number: 7,
      clue:
          'If you improve 1% every day for 10 years, you will improve 6000 ____ times',
      answer: 'TRILLION',
      startX: 4,
      startY: 7,
      isAcross: true,
    ),
    CrosswordClue(
      number: 8,
      clue: 'Name of Top Glove\'s female mascot',
      answer: 'GLOVY',
      startX: 2,
      startY: 9,
      isAcross: true,
    ),
  ];

  // Grid Data Structures
  late List<List<String>> solutionGrid;
  late List<List<String>> userGrid;
  late List<List<int?>> numberGrid;
  late List<List<TextEditingController>> controllers;
  late List<List<FocusNode>> focusNodes;

  // Timer & Game State
  Timer? _timer;
  int secondsElapsed = 0;
  bool isGameFinished = false;
  bool isSubmitting = false;
  CrosswordClue? selectedClue;

  @override
  void initState() {
    super.initState();
    _initGrids();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var row in controllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    for (var row in focusNodes) {
      for (var node in row) {
        node.dispose();
      }
    }
    super.dispose();
  }

  // --- Grid Construction ---

  void _initGrids() {
    solutionGrid =
        List.generate(gridRows, (_) => List.generate(gridCols, (_) => ''));
    userGrid =
        List.generate(gridRows, (_) => List.generate(gridCols, (_) => ''));
    numberGrid =
        List.generate(gridRows, (_) => List.generate(gridCols, (_) => null));
    controllers = List.generate(
      gridRows,
      (_) => List.generate(gridCols, (_) => TextEditingController()),
    );
    focusNodes = List.generate(
      gridRows,
      (_) => List.generate(gridCols, (_) => FocusNode()),
    );

    // Overlay clues onto solution grid
    for (var clue in clues) {
      numberGrid[clue.startY][clue.startX] = clue.number;

      for (int i = 0; i < clue.answer.length; i++) {
        int r = clue.isAcross ? clue.startY : clue.startY + i;
        int c = clue.isAcross ? clue.startX + i : clue.startX;
        solutionGrid[r][c] = clue.answer[i];
      }
    }
  }

  // --- Validation & Firebase Submission ---

  void _checkWordCompletion() {
    bool allCorrect = true;

    for (int r = 0; r < gridRows; r++) {
      for (int c = 0; c < gridCols; c++) {
        if (solutionGrid[r][c].isNotEmpty) {
          if (userGrid[r][c].toUpperCase() != solutionGrid[r][c]) {
            allCorrect = false;
            break;
          }
        }
      }
      if (!allCorrect) break;
    }

    if (allCorrect && !isGameFinished) {
      _endGameAndSubmit();
    }
  }

  final Stopwatch _stopwatch = Stopwatch();

  void _startTimer() {
    _stopwatch.start();
    // Tick every 16ms (~60 FPS) to keep the UI updating smoothly
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!isGameFinished) {
        setState(() {}); // Triggers UI rebuild to fetch elapsed time
      } else {
        _timer?.cancel();
      }
    });
  }

  void _stopTimer() {
    _stopwatch.stop();
    _timer?.cancel();
  }

  Future<void> _endGameAndSubmit() async {
    _timer?.cancel();
    setState(() {
      isGameFinished = true;
      isSubmitting = true;
    });

    final int finalTime = _stopwatch.elapsedMicroseconds;

    try {
      final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
      await dbRef.child('leaderboard/${widget.badgeId}').update({
        'name': widget.name,
        'badgeId': widget.badgeId,
        'crosswordScore': finalTime,
        'crosswordCompletedAt': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Firebase submit error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('🎉 Crossword Completed!'),
            content: Text(
              'Awesome work, ${widget.name}!\n\n'
              'Time Taken: ${formattedTime(_stopwatch.elapsedMicroseconds)} milliseconds\n'
              'Your score has been updated in the leaderboard.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
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

  // --- Cell & Clue Selection Helpers ---

  bool _isCellInClue(int r, int c, CrosswordClue? clue) {
    if (clue == null) return false;
    for (int i = 0; i < clue.answer.length; i++) {
      int cr = clue.isAcross ? clue.startY : clue.startY + i;
      int cc = clue.isAcross ? clue.startX + i : clue.startX;
      if (cr == r && cc == c) return true;
    }
    return false;
  }

  void _onCellChanged(String value, int r, int c) {
    if (value.isEmpty) return;

    // Keep only the last typed char
    String char = value.substring(value.length - 1).toUpperCase();
    controllers[r][c].value = TextEditingValue(
      text: char,
      selection: TextSelection.collapsed(offset: char.length),
    );
    userGrid[r][c] = char;

    // Auto-advance focus along selected clue or next open cell
    _advanceFocus(r, c);
    _checkWordCompletion();
  }

  void _advanceFocus(int r, int c) {
    if (selectedClue != null) {
      int nextR = selectedClue!.isAcross ? r : r + 1;
      int nextC = selectedClue!.isAcross ? c + 1 : c;

      if (nextR < gridRows &&
          nextC < gridCols &&
          solutionGrid[nextR][nextC].isNotEmpty) {
        focusNodes[nextR][nextC].requestFocus();
        return;
      }
    }

    // Default right advance
    if (c + 1 < gridCols && solutionGrid[r][c + 1].isNotEmpty) {
      focusNodes[r][c + 1].requestFocus();
    } else if (r + 1 < gridRows && solutionGrid[r + 1][0].isNotEmpty) {
      focusNodes[r + 1][0].requestFocus();
    }
  }

  String formattedTime(int time) {
    //final totalMicroseconds = _stopwatch.elapsedMicroseconds;

    final seconds = time ~/ 1000000;
    final microseconds = time % 1000000;
    final ms3Digit = ((time % 1000000) ~/ 1000).toString().padLeft(3, '0');

    return '${seconds}:${ms3Digit}';
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              'Time: ${formattedTime(_stopwatch.elapsedMicroseconds)}s',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Crossword Grid
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: gridRows * gridCols,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridCols,
                      ),
                      itemBuilder: (context, index) {
                        int r = index ~/ gridCols;
                        int c = index % gridCols;

                        bool isPlayable = solutionGrid[r][c].isNotEmpty;
                        bool isHighlighted = _isCellInClue(r, c, selectedClue);

                        if (!isPlayable) {
                          return Container(color: Colors.transparent);
                        }

                        return Container(
                          decoration: BoxDecoration(
                            color: isHighlighted
                                ? Colors.lightBlue[100]
                                : Colors.white,
                            border: Border.all(color: Colors.grey, width: 0.5),
                          ),
                          child: Stack(
                            children: [
                              // Clue Number Badge
                              if (numberGrid[r][c] != null)
                                Positioned(
                                  top: 1,
                                  left: 2,
                                  child: Text(
                                    '${numberGrid[r][c]}',
                                    style: const TextStyle(
                                      fontSize: 6,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              // Text Input
                              Center(
                                child: TextField(
                                  controller: controllers[r][c],
                                  focusNode: focusNodes[r][c],
                                  enabled: !isGameFinished,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.text,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  maxLength: 1,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onTap: () {
                                    // Find clue associated with cell
                                    setState(() {
                                      selectedClue = clues.firstWhere(
                                        (cl) => _isCellInClue(r, c, cl),
                                        orElse: () => clues.first,
                                      );
                                    });
                                  },
                                  onChanged: (val) => _onCellChanged(val, r, c),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Clues List Display
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildClueSection('Down', false)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildClueSection('Across', true)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isSubmitting)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClueSection(String title, bool isAcross) {
    final filteredClues = clues.where((c) => c.isAcross == isAcross).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Divider(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: filteredClues.length,
            itemBuilder: (context, index) {
              final clue = filteredClues[index];
              bool isSelected = selectedClue == clue;

              return InkWell(
                onTap: () {
                  setState(() {
                    selectedClue = clue;
                  });
                  focusNodes[clue.startY][clue.startX].requestFocus();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  color:
                      isSelected ? Colors.orange.shade100 : Colors.transparent,
                  child: Text(
                    '${clue.number}. ${clue.clue}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
