import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';

class AlreadyHaveAnAccountCheck extends StatelessWidget {
  final bool login;
  final Function? press;
  const AlreadyHaveAnAccountCheck(
      {Key? key, this.login = true, required this.press})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          login ? "Don't have an Account ?" : "Already have an Account ?",
          style: TextStyle(color: Colors.grey[600]),
        ),
        GestureDetector(
          onTap: press as void Function()?,
          child: Text(
            login ? "Sign Up" : "Sign In",
            style:
                const TextStyle(color: navColor, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }
}
