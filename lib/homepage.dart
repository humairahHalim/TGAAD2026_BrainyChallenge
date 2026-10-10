import 'package:brainy_challenge/Games/crossword.dart';
import 'package:brainy_challenge/Games/wordSearch.dart';
import 'package:brainy_challenge/Widgets/button.dart';
import 'package:brainy_challenge/Games/sudoku.dart';
import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  Homepage({
    required this.badgeID,
    required this.name,
  });

  String badgeID;
  String name;

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              myButton(
                text: 'Sudoku',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Sudoku(
                              badgeId: widget.badgeID,
                              name: widget.name,
                            )),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.all(15),
              ),
              myButton(
                text: 'Word Search',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => WordSearch(
                              badgeId: widget.badgeID,
                              name: widget.name,
                            )),
                  );
                },
              ),
              const Padding(padding: EdgeInsets.all(15)),
              myButton(
                text: 'Crossword',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Crossword(
                              badgeId: widget.badgeID,
                              name: widget.name,
                            )),
                  );
                },
              ),
              const Padding(padding: EdgeInsets.all(15)),
            ],
          ),
        ),
      ),
    );
  }
}
