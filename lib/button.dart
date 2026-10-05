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
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Center(child: Text(text)),
      ),
    );
  }
}
