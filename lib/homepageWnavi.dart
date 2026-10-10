import 'package:brainy_challenge/Games/crossword.dart';
import 'package:brainy_challenge/Games/wordSearch.dart';
import 'package:brainy_challenge/Games/sudoku.dart';
import 'package:brainy_challenge/Widgets/button.dart';
import 'package:brainy_challenge/Widgets/carouselCard.dart';
import 'package:brainy_challenge/scorePage.dart'; // Make sure to create/import your ScorePage
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class Homepage2 extends StatefulWidget {
  Homepage2({
    super.key,
    required this.badgeID,
    required this.name,
  });

  final String badgeID;
  final String name;

  @override
  State<Homepage2> createState() => _Homepage2State();
}

class _Homepage2State extends State<Homepage2> {
  bool isLoading = false;

  final CarouselController controller = CarouselController(initialItem: 1);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// Checks Firebase for existing score before navigating
  Future<void> _handleGameNavigation(
    BuildContext context, {
    required Widget gameWidget,
    required String game,
  }) async {
    setState(() => isLoading = true);

    try {
      final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
      final DataSnapshot snapshot =
          await dbRef.child('leaderboard/${widget.badgeID}').get();

      if (!context.mounted) return;

      // If record exists and contains a completion time/score
      if (snapshot.exists && snapshot.child('${game}Score').value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScorePage(
              badgeId: widget.badgeID,
              name: widget.name,
              scoreData: data,
              game: game,
            ),
          ),
        );
      } else {
        // No score found -> Navigate to game
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => gameWidget),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking score: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 5,
        toolbarHeight: 55,
        title: Expanded(
          child: Column(
            children: [
              Text(
                'Welcome to Brainy Challenge',
                style: GoogleFonts.playfairDisplay(
                    fontStyle: FontStyle.italic,
                    fontSize: 26,
                    fontWeight: FontWeight.w600),
              ),
              //Text('Brainy Challenge!'),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /** 
                  myButton(
                    text: 'Sudoku',
                    onTap: () {
                      _handleGameNavigation(
                        context,
                        gameWidget: Sudoku(
                          badgeId: widget.badgeID,
                          name: widget.name,
                        ),
                        game: 'sudoku',
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  myButton(
                    text: 'Word Search',
                    onTap: () {
                      _handleGameNavigation(
                        context,
                        gameWidget: WordSearch(
                          badgeId: widget.badgeID,
                          name: widget.name,
                        ),
                        game: 'wordSearch',
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  myButton(
                    text: 'Crossword',
                    onTap: () {
                      _handleGameNavigation(
                        context,
                        gameWidget: Crossword(
                          badgeId: widget.badgeID,
                          name: widget.name,
                        ),
                        game: 'crossword',
                      );
                    },
                  ),

                  */
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 300),
                    child: CarouselView(
                      itemExtent: 350,
                      controller: controller,
                      itemSnapping: true,
                      onTap: (int index) {
                        final myCard = myCarouselCard.values[index];

                        switch (myCard) {
                          case myCarouselCard.game1:
                            _handleGameNavigation(
                              context,
                              gameWidget: Sudoku(
                                badgeId: widget.badgeID,
                                name: widget.name,
                              ),
                              game: 'sudoku',
                            );
                            break;
                          case myCarouselCard.game2:
                            _handleGameNavigation(
                              context,
                              gameWidget: WordSearch(
                                badgeId: widget.badgeID,
                                name: widget.name,
                              ),
                              game: 'wordSearch',
                            );
                            break;
                          case myCarouselCard.game3:
                            _handleGameNavigation(
                              context,
                              gameWidget: Crossword(
                                badgeId: widget.badgeID,
                                name: widget.name,
                              ),
                              game: 'crossword',
                            );
                            break;
                        }
                      },
                      children:
                          myCarouselCard.values.map((myCarouselCard myCard) {
                        // Clean children list without GestureDetector
                        return HeroLayoutCard(myCard: myCard);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

enum myCarouselCard {
  game1(
    'https://cdn-icons-png.flaticon.com/256/7399/7399655.png',
    'Sudoku',
  ),

  game2(
    'https://play-lh.googleusercontent.com/KdXrqpLJ25ZiUEjg9IHgawlf9p4JROjHfnclRAijI_5RKIaAC5zuazvDBv2Rkx0EsBa348CEZGMw0GWGYhhLVQ=s0-br30',
    'Word Search',
  ),
  game3(
    'https://cdn-icons-png.flaticon.com/512/2247/2247617.png',
    'Cross Word',
  );

  const myCarouselCard(this.picture, this.title);
  final String picture;
  final String title;
  // final Function onTap;
}
