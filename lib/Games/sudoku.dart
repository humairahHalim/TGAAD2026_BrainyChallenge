import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

class Sudoku extends StatefulWidget {
  Sudoku({
    required this.badgeId,
    required this.name,
  });

  String badgeId;
  String name;

  @override
  State<Sudoku> createState() => _SudokuState();
}

class _SudokuState extends State<Sudoku> {
  // --- Static Easy Sudoku Puzzle ---
  // 0 represents empty editable cells
  final List<List<int>> initialBoard = [
    [5, 3, 0, 0, 7, 0, 0, 0, 0],
    [6, 0, 0, 1, 9, 5, 0, 0, 0],
    [0, 9, 8, 0, 0, 0, 0, 6, 0],
    [8, 0, 0, 0, 6, 0, 0, 0, 3],
    [4, 0, 0, 8, 0, 3, 0, 0, 1],
    [7, 0, 0, 0, 2, 0, 0, 0, 6],
    [0, 6, 0, 0, 0, 0, 2, 8, 0],
    [0, 0, 0, 4, 1, 9, 0, 0, 5],
    [0, 0, 0, 0, 8, 0, 0, 7, 9],
  ];

  // The full solved matrix for validation
  final List<List<int>> solutionBoard = [
    [5, 3, 4, 6, 7, 8, 9, 1, 2],
    [6, 7, 2, 1, 9, 5, 3, 4, 8],
    [1, 9, 8, 3, 4, 2, 5, 6, 7],
    [8, 5, 9, 7, 6, 1, 4, 2, 3],
    [4, 2, 6, 8, 5, 3, 7, 9, 1],
    [7, 1, 3, 9, 2, 4, 8, 5, 6],
    [9, 6, 1, 5, 3, 7, 2, 8, 4],
    [2, 8, 7, 4, 1, 9, 6, 3, 5],
    [3, 4, 5, 2, 8, 6, 1, 7, 9],
  ];

  late List<List<int>> currentBoard;
  // Matrix tracking set of mini-note numbers (1-9) for each cell
  late List<List<Set<int>>> notesBoard;

  int? selectedRow;
  int? selectedCol;
  bool isNoteMode = false; // Toggle between Normal vs Note Mode

  // --- Timer State ---
  late Timer _timer;
  int _secondsElapsed = 0;
  bool _isCompleted = false;
  bool _isSubmitting = false;

  // --- Firebase Reference ---

  //final DatabaseReference _dbRef =
  //  FirebaseDatabase.instance.ref('sudoku_scores');

  @override
  void initState() {
    super.initState();
    // Deep copy initial board so user edits don't corrupt base template
    currentBoard = List.generate(
      9,
      (r) => List.generate(9, (c) => initialBoard[r][c]),
    );

    // Initialize 9x9 matrix of empty Sets for cell pencil marks
    notesBoard = List.generate(
      9,
      (_) => List.generate(9, (_) => <int>{}),
    );

    // 1. Start the timer immediately on page load
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isCompleted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Prevent memory leaks when navigating away
    super.dispose();
  }

  // --- Input & Game Logic ---
  void _onCellTap(int row, int col) {
    // Prevent editing initial fixed numbers or after completion
    if (initialBoard[row][col] != 0 || _isCompleted) return;

    setState(() {
      selectedRow = row;
      selectedCol = col;
    });
  }

  void _onNumberInput(int number) {
    if (selectedRow == null || selectedCol == null || _isCompleted) return;
    final r = selectedRow!;
    final c = selectedCol!;

    // Cannot edit fixed initial clues
    if (initialBoard[r][c] != 0) return;

    setState(() {
      if (number == 0) {
        // Clear value and notes for selected cell
        currentBoard[r][c] = 0;
        notesBoard[r][c].clear();
        return;
      }

      if (isNoteMode) {
        // Only allow adding notes if cell doesn't have a solid value
        if (currentBoard[r][c] == 0) {
          if (notesBoard[r][c].contains(number)) {
            notesBoard[r][c].remove(number);
          } else {
            notesBoard[r][c].add(number);
          }
        }
      } else {
        // Place Normal Big Number
        currentBoard[r][c] = number;
        notesBoard[r][c].clear(); // Remove notes inside filled cell

        // Remove this candidate note from overlapping row, column, & 3x3 block
        _clearRelatedNotes(r, c, number);

        _checkCompletion();
      }
    });
  }

  void _clearRelatedNotes(int row, int col, int value) {
    for (int i = 0; i < 9; i++) {
      notesBoard[row][i].remove(value); // Row
      notesBoard[i][col].remove(value); // Column
    }
  }

  void _checkCompletion() {
    // Verify if current board completely matches solution
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (currentBoard[r][c] != solutionBoard[r][c]) {
          return; // Not finished yet or contains errors
        }
      }
    }

    // Board solved!
    _timer.cancel();
    setState(() {
      _isCompleted = true;
    });

    _submitTimeToFirebase();
  }

  // --- 2. Submit Time to Firebase Realtime Database ---
  Future<void> _submitTimeToFirebase() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Firebase Realtime Database update using badgeId as key
      final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
      await dbRef.child('leaderboard/${widget.badgeId}').update({
        'name': widget.name,
        'badgeId': widget.badgeId,
        'timeTakenSeconds': _secondsElapsed,
        'completedAt': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Error writing score to Firebase: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String get _formattedTime {
    final minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Congratulations!'),
        content: Text(
            'You completed the Sudoku puzzle in $_formattedTime.\nYour score has been submitted to Firebase!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // --- UI Components ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.timer_outlined, color: Colors.blue),
            const SizedBox(width: 6),
            Text(
              _formattedTime,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 16),
            // Header Stats: Difficulty & Timer
            /** 
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      _formattedTime,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            */
            // Sudoku Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2.0),
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 81,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 9,
                    ),
                    itemBuilder: (context, index) {
                      final row = index ~/ 9;
                      final col = index % 9;
                      final value = currentBoard[row][col];
                      final isInitial = initialBoard[row][col] != 0;
                      final isSelected =
                          row == selectedRow && col == selectedCol;

                      // Border styling for 3x3 box outlines
                      final borderTop = row % 3 == 0 ? 2.0 : 0.5;
                      final borderLeft = col % 3 == 0 ? 2.0 : 0.5;
                      final borderBottom = row == 8 ? 2.0 : 0.5;
                      final borderRight = col == 8 ? 2.0 : 0.5;

                      return GestureDetector(
                        onTap: () => _onCellTap(row, col),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.withOpacity(0.3)
                                : isInitial
                                    ? Colors.grey.shade300
                                    : Colors.white,
                            border: Border(
                              top: BorderSide(
                                  width: borderTop, color: Colors.black),
                              left: BorderSide(
                                  width: borderLeft, color: Colors.black),
                              bottom: BorderSide(
                                  width: borderBottom, color: Colors.black),
                              right: BorderSide(
                                  width: borderRight, color: Colors.black),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              value == 0 ? '' : '$value',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: isInitial
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isInitial
                                    ? Colors.black
                                    : Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const Spacer(),
            // Numpad Control Panel
            if (_isSubmitting)
              const CircularProgressIndicator()
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children:
                          List.generate(5, (i) => _buildNumpadButton(i + 1)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ...List.generate(4, (i) => _buildNumpadButton(i + 6)),
                        // Clear cell button
                        IconButton.filledTonal(
                          onPressed: () => _onNumberInput(0),
                          icon: const Icon(Icons.backspace_outlined),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpadButton(int number) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(16),
      ),
      onPressed: () => _onNumberInput(number),
      child: Text(
        '$number',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
