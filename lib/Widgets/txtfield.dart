import 'package:flutter/material.dart';

class Txtfield extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;
  final bool readOnly;

  const Txtfield({
    super.key,
    required this.hintText,
    this.obscureText = false,
    required this.controller,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.only(left: 10.0),
      height: 55,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.lightBlue,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(30.0),
        color: Colors.transparent,
      ),
      child: TextField(
        obscureText: obscureText,
        controller: controller,
        decoration: InputDecoration(
          prefix: const SizedBox(
            width: 10,
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.black,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
