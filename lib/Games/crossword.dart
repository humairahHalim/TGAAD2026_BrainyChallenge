import 'package:flutter/material.dart';

class Crossword extends StatefulWidget {
  Crossword({required this.badgeID});

  String badgeID;

  @override
  State<Crossword> createState() => _CrosswordState();
}

class _CrosswordState extends State<Crossword> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
