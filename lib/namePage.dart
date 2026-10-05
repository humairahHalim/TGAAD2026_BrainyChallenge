import 'package:brainy_challenge/homepage.dart';
import 'package:flutter/material.dart';
import 'txtfield.dart';
import 'button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

class namePage extends StatefulWidget {
  namePage({super.key});

  @override
  State<namePage> createState() => _namePageState();
}

class _namePageState extends State<namePage> {
  Future<void> register({
    //FirebaseDatabase.instance.ref();

    required String name,
    required String badgeId,
    required String table,
  }) async {
    if (badgeId == "admin123") {
      //go to admin page
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
            builder: (context) => Homepage(
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
