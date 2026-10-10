import 'package:brainy_challenge/homepage.dart';
import 'package:brainy_challenge/homepageWnavi.dart';
import 'package:brainy_challenge/leaderboard.dart';
import 'package:flutter/material.dart';
import 'Widgets/txtfield.dart';
import 'Widgets/button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

class namePage extends StatefulWidget {
  namePage({super.key});

  @override
  State<namePage> createState() => _namePageState();
}

/**
 * ) async {
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
 */ /// reference to check if badgeid alr exist

class _namePageState extends State<namePage> {
  Future<void> register({
    //FirebaseDatabase.instance.ref();

    required String name,
    required String badgeId,
    required String table,
  }) async {
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
    final DataSnapshot snapshot =
        await dbRef.child('leaderboard/$badgeId').get();
    if (badgeId == "admin123" && table == '123') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                LeaderboardPage()), // Replace with your target page
      );
      //go to admin page
    } else if (snapshot.exists) {
      Homepage2(
        badgeID: badgeId,
        name: name,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => Homepage2(
                  badgeID: badgeId,
                  name: name,
                )), // Replace with your target page
      );
    } else {
      final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

      // Uses staffId directly to avoid duplicate keys for the same staff
      await dbRef.child('leaderboard/$badgeId').set({
        'name': name,
        'badgeId': badgeId,
        'tableNum': table,
      });

      if (!context.mounted) return;

      // Navigate to your next page (e.g., HomePage or LeaderboardPage)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => Homepage2(
                  badgeID: badgeId,
                  name: name,
                )), // Replace with your target page
      );
    }
  }

  TextEditingController nameCTRL = TextEditingController();

  TextEditingController badgeCTRL = TextEditingController();

  TextEditingController tableCTRL = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      heightFactor: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //logo

              const SizedBox(
                height: 25,
              ),
              // app name
              Text("Register",
                  // style: fontTheme.textTheme.titleLarge,
                  style: GoogleFonts.roboto(
                    color: Colors.black,
                    fontSize: 42,
                  )),
              const SizedBox(
                height: 25,
              ),
              //name
              Txtfield(
                  hintText: "Name", obscureText: false, controller: nameCTRL),
              const SizedBox(
                height: 20,
              ),
              //email
              Txtfield(
                hintText: "Badge ID",
                obscureText: false,
                controller: badgeCTRL,
              ),
              const SizedBox(
                height: 20,
              ),
              //password 1
              Txtfield(
                hintText: "Table Number",
                obscureText: false,
                controller: tableCTRL,
              ),
              const SizedBox(
                height: 20,
              ),
              //password

              const SizedBox(
                height: 25,
              ),
              myButton(
                  text: "Register",
                  onTap: () => register(
                      name: nameCTRL.text,
                      badgeId: badgeCTRL.text,
                      table: tableCTRL.text)),
              const SizedBox(
                height: 25,
              ),
            ]),
      ),
    ));
  }
}
