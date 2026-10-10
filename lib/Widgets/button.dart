import 'package:flutter/material.dart';

class myButton extends StatelessWidget {
  final String text;
  final void Function()? onTap;

  const myButton({super.key, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        decoration: BoxDecoration(
            color: Colors.lightBlue[100],
            borderRadius: BorderRadius.circular(30.0),
            border: Border.all(
              color: Colors.lightBlueAccent,
            )),
        child: Center(child: Text(text)),
      ),
    );
  }
}
